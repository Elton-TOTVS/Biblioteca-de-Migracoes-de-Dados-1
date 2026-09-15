from __future__ import annotations

import pandas as pd

from .security import is_sensitive_column


KEY_HINTS = ("id", "cod", "codigo", "matricula", "cpf", "cnpj", "ra")
DEPARA_HINTS = (
    "cod",
    "codigo",
    "id",
    "descricao",
    "nome",
    "status",
    "situacao",
    "curso",
    "turma",
    "serie",
    "periodo",
)


def classify_column(column_name: str) -> str:
    name = (column_name or "").lower()
    if any(hint in name for hint in ("cpf", "cnpj", "rg")):
        return "identificador sensivel"
    if any(hint in name for hint in KEY_HINTS):
        return "chave/identificador"
    if any(hint in name for hint in DEPARA_HINTS):
        return "candidato para de-para"
    return "atributo comum"


def global_search(
    tables: pd.DataFrame,
    columns: pd.DataFrame,
    relationships: pd.DataFrame,
    term: str,
) -> pd.DataFrame:
    term = (term or "").strip().lower()
    if not term:
        return pd.DataFrame()

    table_hits = tables[
        tables["schema_name"].str.lower().str.contains(term, na=False)
        | tables["table_name"].str.lower().str.contains(term, na=False)
    ].copy()
    table_hits["match_type"] = "tabela"
    table_hits["column_name"] = ""
    table_hits["data_type"] = ""
    table_hits["classification"] = "tabela candidata"
    table_hits["is_potentially_sensitive"] = False

    column_hits = columns[
        columns["schema_name"].str.lower().str.contains(term, na=False)
        | columns["table_name"].str.lower().str.contains(term, na=False)
        | columns["column_name"].str.lower().str.contains(term, na=False)
        | columns["data_type"].str.lower().str.contains(term, na=False)
    ].copy()
    column_hits["match_type"] = "coluna"
    column_hits["row_count"] = None
    column_hits["classification"] = column_hits["column_name"].map(classify_column)
    column_hits["is_potentially_sensitive"] = column_hits["column_name"].map(is_sensitive_column)

    rel_hits = pd.DataFrame()
    if relationships is not None and not relationships.empty:
        rel_hits = relationships[
            relationships.astype(str).apply(
                lambda row: row.str.lower().str.contains(term, na=False).any(),
                axis=1,
            )
        ].copy()
        if not rel_hits.empty:
            rel_hits = pd.DataFrame(
                {
                    "schema_name": rel_hits["source_schema"],
                    "table_name": rel_hits["source_table"],
                    "row_count": None,
                    "match_type": "relacionamento",
                    "column_name": rel_hits["source_column"] + " -> " + rel_hits["target_column"],
                    "data_type": rel_hits["relationship_type"],
                    "classification": rel_hits["confidence_label"],
                    "is_potentially_sensitive": False,
                }
            )

    common = [
        "schema_name",
        "table_name",
        "row_count",
        "match_type",
        "column_name",
        "data_type",
        "classification",
        "is_potentially_sensitive",
    ]
    frames = [
        frame.reindex(columns=common)
        for frame in (table_hits, column_hits, rel_hits)
        if frame is not None and not frame.empty
    ]
    return pd.concat(frames, ignore_index=True) if frames else pd.DataFrame(columns=common)
