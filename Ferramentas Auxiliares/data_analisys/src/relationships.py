from __future__ import annotations

from dataclasses import asdict, dataclass
from difflib import SequenceMatcher
from itertools import combinations
import re

import networkx as nx
import pandas as pd

from .db import quote_name
from .metadata import profile_column


COMPATIBLE_TYPES = {
    "bigint": {"bigint", "int", "numeric", "decimal"},
    "int": {"int", "bigint", "smallint", "tinyint", "numeric", "decimal"},
    "smallint": {"smallint", "int", "bigint", "tinyint", "numeric", "decimal"},
    "tinyint": {"tinyint", "smallint", "int", "bigint", "numeric", "decimal"},
    "numeric": {"numeric", "decimal", "int", "bigint", "smallint", "tinyint"},
    "decimal": {"decimal", "numeric", "int", "bigint", "smallint", "tinyint"},
    "varchar": {"varchar", "nvarchar", "char", "nchar", "text"},
    "nvarchar": {"nvarchar", "varchar", "char", "nchar", "ntext"},
    "char": {"char", "nchar", "varchar", "nvarchar"},
    "nchar": {"nchar", "char", "varchar", "nvarchar"},
    "uniqueidentifier": {"uniqueidentifier", "varchar", "nvarchar", "char", "nchar"},
    "date": {"date", "datetime", "datetime2", "smalldatetime"},
    "datetime": {"datetime", "datetime2", "smalldatetime", "date"},
    "datetime2": {"datetime2", "datetime", "smalldatetime", "date"},
}
STOP_WORDS = {"id", "cod", "codigo", "cd", "nr", "num", "fk", "idfk", "de", "para"}


@dataclass(frozen=True)
class Relationship:
    source_schema: str
    source_table: str
    source_column: str
    target_schema: str
    target_table: str
    target_column: str
    relationship_type: str
    confidence_score: int
    confidence_label: str
    evidence: str
    validation_sql: str
    fk_name: str = ""

    def to_dict(self) -> dict:
        return asdict(self)


def empty_relationships() -> pd.DataFrame:
    return pd.DataFrame(
        columns=[
            "source_schema",
            "source_table",
            "source_column",
            "target_schema",
            "target_table",
            "target_column",
            "relationship_type",
            "confidence_score",
            "confidence_label",
            "evidence",
            "validation_sql",
            "fk_name",
        ]
    )


def table_key(schema_name: str, table_name: str) -> str:
    return f"{schema_name}.{table_name}"


def normalize_name(name: str) -> str:
    text = re.sub(r"[^a-zA-Z0-9]+", "_", name or "").lower()
    tokens = [token for token in text.split("_") if token and token not in STOP_WORDS]
    return "_".join(tokens)


def type_compatible(left: str, right: str) -> bool:
    left = (left or "").lower()
    right = (right or "").lower()
    return left == right or right in COMPATIBLE_TYPES.get(left, set())


def confidence_label(score: int) -> str:
    if score >= 80:
        return "alta"
    if score >= 55:
        return "media"
    return "baixa"


def make_validation_sql(rel: Relationship | dict) -> str:
    data = rel.to_dict() if isinstance(rel, Relationship) else rel
    source_table = f"{quote_name(data['source_schema'])}.{quote_name(data['source_table'])}"
    target_table = f"{quote_name(data['target_schema'])}.{quote_name(data['target_table'])}"
    source_column = quote_name(data["source_column"])
    target_column = quote_name(data["target_column"])
    return f"""SELECT TOP 100
    a.*,
    b.*
FROM {source_table} AS a
JOIN {target_table} AS b
  ON a.{source_column} = b.{target_column};"""


def real_fk_relationships(foreign_keys: pd.DataFrame) -> pd.DataFrame:
    rows: list[Relationship] = []
    for fk in foreign_keys.to_dict("records"):
        evidence = "Foreign key declarada no SQL Server"
        if fk.get("is_disabled"):
            evidence += "; constraint desabilitada"
        if fk.get("is_not_trusted"):
            evidence += "; constraint nao confiavel pelo otimizador"
        rel = Relationship(
            source_schema=fk["source_schema"],
            source_table=fk["source_table"],
            source_column=fk["source_column"],
            target_schema=fk["target_schema"],
            target_table=fk["target_table"],
            target_column=fk["target_column"],
            relationship_type="REAL_FK",
            confidence_score=100 if not fk.get("is_disabled") else 90,
            confidence_label="alta",
            evidence=evidence,
            validation_sql="",
            fk_name=fk.get("fk_name", ""),
        )
        rows.append(rel)

    output = pd.DataFrame([row.to_dict() for row in rows])
    if output.empty:
        return empty_relationships()
    output["validation_sql"] = output.apply(lambda row: make_validation_sql(row.to_dict()), axis=1)
    return output


def _column_key(column: dict) -> tuple[str, str, str]:
    return (column["schema_name"], column["table_name"], column["column_name"])


def _score_pair(left: dict, right: dict, profiles: dict | None = None) -> tuple[int, list[str]]:
    score = 0
    reasons: list[str] = []
    left_norm = normalize_name(left["column_name"])
    right_norm = normalize_name(right["column_name"])
    name_similarity = SequenceMatcher(None, left_norm, right_norm).ratio()

    if left_norm and left_norm == right_norm:
        score += 35
        reasons.append("nomes normalizados identicos")
    elif name_similarity >= 0.82:
        score += 25
        reasons.append(f"nomes parecidos ({name_similarity:.0%})")
    elif left_norm and right_norm and (left_norm in right_norm or right_norm in left_norm):
        score += 18
        reasons.append("um nome contem o outro")

    if type_compatible(left["data_type"], right["data_type"]):
        score += 20
        reasons.append("tipos de dados compativeis")
    else:
        return 0, []

    if left.get("is_indexed") or right.get("is_indexed"):
        score += 10
        reasons.append("ao menos uma coluna possui indice")
    if left.get("is_primary_key") or right.get("is_primary_key"):
        score += 15
        reasons.append("ao menos uma coluna e chave primaria")
    elif left.get("is_unique_indexed") or right.get("is_unique_indexed"):
        score += 12
        reasons.append("ao menos uma coluna possui indice unico")
    if not left.get("is_nullable") or not right.get("is_nullable"):
        score += 5
        reasons.append("ao menos uma coluna nao aceita nulo")

    if profiles:
        lp = profiles.get(_column_key(left))
        rp = profiles.get(_column_key(right))
        if lp and rp:
            left_values = set(lp.get("sample_values") or [])
            right_values = set(rp.get("sample_values") or [])
            smaller = min(len(left_values), len(right_values))
            if smaller:
                overlap_ratio = len(left_values & right_values) / smaller
                if overlap_ratio >= 0.8:
                    score += 25
                    reasons.append(f"alta sobreposicao de amostras ({overlap_ratio:.0%})")
                elif overlap_ratio >= 0.35:
                    score += 15
                    reasons.append(f"sobreposicao parcial de amostras ({overlap_ratio:.0%})")
            left_distinct = int(lp.get("distinct_values") or 0)
            right_distinct = int(rp.get("distinct_values") or 0)
            if left_distinct and right_distinct:
                ratio = min(left_distinct, right_distinct) / max(left_distinct, right_distinct)
                if ratio >= 0.6:
                    score += 8
                    reasons.append("cardinalidade distinta relativamente proxima")
    return min(score, 99), reasons


def _looks_joinable(column_name: str, data_type: str) -> bool:
    name = (column_name or "").lower()
    dtype = (data_type or "").lower()
    has_key_name = any(token in name for token in ("id", "cod", "codigo", "matricula", "cpf", "cnpj", "ra"))
    has_join_type = dtype in {
        "bigint",
        "int",
        "smallint",
        "tinyint",
        "numeric",
        "decimal",
        "varchar",
        "nvarchar",
        "char",
        "nchar",
        "uniqueidentifier",
    }
    return has_key_name and has_join_type


def infer_relationships(
    conn,
    columns: pd.DataFrame,
    tables: pd.DataFrame,
    selected_tables: list[str] | None = None,
    include_value_samples: bool = True,
    sample_size: int = 100,
    min_score: int = 45,
) -> pd.DataFrame:
    cols = columns.copy()
    cols["table_key"] = cols["schema_name"] + "." + cols["table_name"]
    if selected_tables:
        cols = cols[cols["table_key"].isin(selected_tables)]

    profiles: dict | None = {} if include_value_samples else None
    candidate_columns = [
        row
        for row in cols.to_dict("records")
        if _looks_joinable(row["column_name"], row["data_type"])
    ]

    if include_value_samples:
        for col in candidate_columns:
            try:
                profiles[_column_key(col)] = profile_column(
                    conn,
                    col["schema_name"],
                    col["table_name"],
                    col["column_name"],
                    sample_size=sample_size,
                )
            except Exception as exc:
                profiles[_column_key(col)] = {"sample_values": [], "profile_error": str(exc)}

    rows: list[Relationship] = []
    for left, right in combinations(candidate_columns, 2):
        if left["schema_name"] == right["schema_name"] and left["table_name"] == right["table_name"]:
            continue
        score, reasons = _score_pair(left, right, profiles)
        if score < min_score:
            continue
        rel = Relationship(
            source_schema=left["schema_name"],
            source_table=left["table_name"],
            source_column=left["column_name"],
            target_schema=right["schema_name"],
            target_table=right["table_name"],
            target_column=right["column_name"],
            relationship_type="INFERRED_HYPOTHESIS",
            confidence_score=score,
            confidence_label=confidence_label(score),
            evidence="Hipotese inferida; validar com SQL. Motivos: " + "; ".join(reasons),
            validation_sql="",
        )
        rows.append(rel)

    output = pd.DataFrame([row.to_dict() for row in rows])
    if output.empty:
        return empty_relationships()
    output["validation_sql"] = output.apply(lambda row: make_validation_sql(row.to_dict()), axis=1)
    return output.sort_values(["confidence_score", "source_table"], ascending=[False, True])


def relationship_graph(real: pd.DataFrame, inferred: pd.DataFrame | None = None) -> nx.MultiDiGraph:
    graph = nx.MultiDiGraph()
    frames = [real]
    if inferred is not None and not inferred.empty:
        frames.append(inferred)
    for frame in frames:
        if frame is None or frame.empty:
            continue
        for row in frame.to_dict("records"):
            source = table_key(row["source_schema"], row["source_table"])
            target = table_key(row["target_schema"], row["target_table"])
            graph.add_node(source)
            graph.add_node(target)
            graph.add_edge(
                source,
                target,
                source_schema=row["source_schema"],
                source_table=row["source_table"],
                target_schema=row["target_schema"],
                target_table=row["target_table"],
                relationship_type=row["relationship_type"],
                confidence_score=row["confidence_score"],
                confidence_label=row.get("confidence_label", ""),
                source_column=row["source_column"],
                target_column=row["target_column"],
                evidence=row["evidence"],
                validation_sql=row.get("validation_sql", ""),
                fk_name=row.get("fk_name", ""),
            )
    return graph


def find_paths(
    real: pd.DataFrame,
    inferred: pd.DataFrame,
    source_table: str,
    target_table: str,
    max_depth: int = 3,
    include_inferred: bool = False,
) -> list[list[dict]]:
    graph = relationship_graph(real, inferred if include_inferred else None)
    if source_table not in graph or target_table not in graph:
        return []
    simple_graph = nx.Graph()
    for u, v in graph.edges():
        simple_graph.add_edge(u, v)

    paths: list[list[dict]] = []
    for node_path in nx.all_simple_paths(simple_graph, source_table, target_table, cutoff=max_depth):
        steps: list[dict] = []
        for left, right in zip(node_path, node_path[1:]):
            edge_data = graph.get_edge_data(left, right) or graph.get_edge_data(right, left)
            if not edge_data:
                break
            best = sorted(edge_data.values(), key=lambda item: item["confidence_score"], reverse=True)[0]
            steps.append({"from_table": left, "to_table": right, **best})
        if len(steps) == len(node_path) - 1:
            paths.append(steps)
    return paths
