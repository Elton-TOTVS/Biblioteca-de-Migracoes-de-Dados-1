from __future__ import annotations

from collections import Counter, deque
import math
import re

import networkx as nx
import pandas as pd

from .relationship_finder import path_table_sequence
from .search import classify_column


BRIDGE_NAME = re.compile(
    r"(?:matric|vinc|item|mov|hist|contrato|turma|pessoa|aluno|assoc|relac|ligacao|map)",
    re.IGNORECASE,
)
RELEVANT_COLUMN = re.compile(
    r"(?:cpf|cnpj|matric|codigo|cod|pessoa|aluno|cliente|contrato|curso|turma|serie|status|situacao)",
    re.IGNORECASE,
)


def table_key(schema_name: str, table_name: str) -> str:
    return f"{schema_name}.{table_name}"


def combine_relationships(real: pd.DataFrame, inferred: pd.DataFrame | None, include_inferred: bool) -> pd.DataFrame:
    frames = [real]
    if include_inferred and inferred is not None and not inferred.empty:
        frames.append(inferred)
    frames = [frame for frame in frames if frame is not None and not frame.empty]
    return pd.concat(frames, ignore_index=True) if frames else pd.DataFrame()


def filter_relationships(
    relationships: pd.DataFrame,
    schemas: list[str] | None = None,
    table_or_column_term: str = "",
    relationship_kinds: list[str] | None = None,
) -> pd.DataFrame:
    if relationships.empty:
        return relationships
    filtered = relationships.copy()
    if schemas:
        filtered = filtered[
            filtered["source_schema"].isin(schemas) | filtered["target_schema"].isin(schemas)
        ]
    if relationship_kinds:
        filtered = filtered[filtered["relationship_type"].isin(relationship_kinds)]
    term = (table_or_column_term or "").strip().lower()
    if term:
        filtered = filtered[
            filtered.astype(str).apply(
                lambda row: row.str.lower().str.contains(term, regex=False, na=False).any(),
                axis=1,
            )
        ]
    return filtered


def _empty_context() -> tuple[nx.MultiDiGraph, pd.DataFrame]:
    return nx.MultiDiGraph(), pd.DataFrame()


def _edge_tables(row: dict) -> tuple[str, str]:
    return table_key(row["source_schema"], row["source_table"]), table_key(row["target_schema"], row["target_table"])


def build_graph_from_relationships(
    relationships: pd.DataFrame,
    tables: pd.DataFrame,
    columns: pd.DataFrame,
    central_table: str | None = None,
    highlighted_tables: set[str] | None = None,
) -> nx.MultiDiGraph:
    graph = nx.MultiDiGraph()
    highlighted_tables = highlighted_tables or set()

    for row in relationships.to_dict("records"):
        source, target = _edge_tables(row)
        graph.add_node(source)
        graph.add_node(target)
        graph.add_edge(
            source,
            target,
            source_schema=row["source_schema"],
            source_table=row["source_table"],
            source_column=row["source_column"],
            target_schema=row["target_schema"],
            target_table=row["target_table"],
            target_column=row["target_column"],
            relationship_type=row["relationship_type"],
            confidence_score=int(row.get("confidence_score") or 0),
            confidence_label=row.get("confidence_label", ""),
            evidence=row.get("evidence", ""),
            validation_sql=row.get("validation_sql", ""),
            label=f"{row['source_column']} -> {row['target_column']}",
        )

    enrich_graph_nodes(graph, tables, columns, central_table, highlighted_tables)
    return graph


def enrich_graph_nodes(
    graph: nx.MultiDiGraph,
    tables: pd.DataFrame,
    columns: pd.DataFrame,
    central_table: str | None = None,
    highlighted_tables: set[str] | None = None,
) -> None:
    highlighted_tables = highlighted_tables or set()
    table_rows = {
        table_key(row["schema_name"], row["table_name"]): row
        for row in tables.to_dict("records")
    }
    for node in list(graph.nodes):
        schema_name, table_name = node.split(".", 1)
        node_columns = columns[
            (columns["schema_name"] == schema_name) & (columns["table_name"] == table_name)
        ]
        pks = node_columns.loc[node_columns.get("is_primary_key", False).astype(bool), "column_name"].tolist()
        fks = node_columns.loc[node_columns.get("is_foreign_key", False).astype(bool), "column_name"].tolist()
        candidates = [
            col
            for col in node_columns["column_name"].tolist()
            if classify_column(col) in {"chave/identificador", "identificador sensivel", "candidato para de-para"}
        ][:8]
        row_count = int(table_rows.get(node, {}).get("row_count") or 0)
        graph.nodes[node].update(
            {
                "schema_name": schema_name,
                "table_name": table_name,
                "row_count": row_count,
                "column_count": len(node_columns),
                "pk_columns": ", ".join(pks),
                "fk_columns": ", ".join(fks),
                "candidate_columns": ", ".join(candidates),
                "is_central": node == central_table,
                "is_highlighted": node in highlighted_tables,
            }
        )


def _limit_nodes(nodes: list[str], relationships: pd.DataFrame, max_nodes: int) -> set[str]:
    if len(nodes) <= max_nodes:
        return set(nodes)
    degree = Counter()
    for row in relationships.to_dict("records"):
        source, target = _edge_tables(row)
        degree[source] += 1
        degree[target] += 1
    return set(sorted(nodes, key=lambda item: degree[item], reverse=True)[:max_nodes])


def relationships_for_nodes(relationships: pd.DataFrame, nodes: set[str]) -> pd.DataFrame:
    if relationships.empty or not nodes:
        return relationships.iloc[0:0].copy()
    keys_source = relationships["source_schema"] + "." + relationships["source_table"]
    keys_target = relationships["target_schema"] + "." + relationships["target_table"]
    return relationships[keys_source.isin(nodes) & keys_target.isin(nodes)].copy()


def build_central_context(
    relationships: pd.DataFrame,
    tables: pd.DataFrame,
    columns: pd.DataFrame,
    central_table: str,
    depth: int = 2,
    direction: str = "ambos",
    max_nodes: int = 80,
) -> tuple[nx.MultiDiGraph, pd.DataFrame]:
    if relationships.empty or not central_table:
        return _empty_context()

    forward: dict[str, set[str]] = {}
    backward: dict[str, set[str]] = {}
    for row in relationships.to_dict("records"):
        source, target = _edge_tables(row)
        forward.setdefault(source, set()).add(target)
        backward.setdefault(target, set()).add(source)

    visited = {central_table}
    queue = deque([(central_table, 0)])
    while queue:
        node, level = queue.popleft()
        if level >= depth:
            continue
        neighbors = set()
        if direction in {"saida", "ambos"}:
            neighbors.update(forward.get(node, set()))
        if direction in {"entrada", "ambos"}:
            neighbors.update(backward.get(node, set()))
        for neighbor in sorted(neighbors):
            if neighbor not in visited:
                visited.add(neighbor)
                if len(visited) >= max_nodes:
                    break
                queue.append((neighbor, level + 1))
        if len(visited) >= max_nodes:
            break

    context_relationships = relationships_for_nodes(relationships, visited)
    graph = build_graph_from_relationships(
        context_relationships,
        tables,
        columns,
        central_table=central_table,
    )
    if central_table not in graph:
        graph.add_node(central_table)
        enrich_graph_nodes(graph, tables, columns, central_table)
    return graph, context_relationships


def _simple_graph_from_relationships(relationships: pd.DataFrame) -> nx.Graph:
    graph = nx.Graph()
    for row in relationships.to_dict("records"):
        source, target = _edge_tables(row)
        graph.add_edge(source, target)
    return graph


def build_selected_context(
    relationships: pd.DataFrame,
    tables: pd.DataFrame,
    columns: pd.DataFrame,
    selected_tables: list[str],
    add_intermediates: bool = False,
    max_depth: int = 4,
    max_nodes: int = 80,
) -> tuple[nx.MultiDiGraph, pd.DataFrame]:
    nodes = set(selected_tables)
    if add_intermediates and len(selected_tables) > 1:
        simple = _simple_graph_from_relationships(relationships)
        for index, source in enumerate(selected_tables):
            for target in selected_tables[index + 1 :]:
                try:
                    path = nx.shortest_path(simple, source, target)
                except (nx.NetworkXNoPath, nx.NodeNotFound):
                    continue
                if len(path) - 1 <= max_depth:
                    nodes.update(path)
                if len(nodes) >= max_nodes:
                    break
    nodes = _limit_nodes(list(nodes), relationships, max_nodes)
    context_relationships = relationships_for_nodes(relationships, nodes)
    graph = build_graph_from_relationships(
        context_relationships,
        tables,
        columns,
        highlighted_tables=set(selected_tables),
    )
    for node in nodes:
        if node not in graph:
            graph.add_node(node)
    enrich_graph_nodes(graph, tables, columns, highlighted_tables=set(selected_tables))
    return graph, context_relationships


def build_path_context(
    path: list[dict],
    tables: pd.DataFrame,
    columns: pd.DataFrame,
) -> tuple[nx.MultiDiGraph, pd.DataFrame]:
    if not path:
        return _empty_context()
    relationships = pd.DataFrame(path)
    graph = build_graph_from_relationships(
        relationships,
        tables,
        columns,
        highlighted_tables=set(path_table_sequence(path)),
    )
    return graph, relationships


def build_full_context(
    relationships: pd.DataFrame,
    tables: pd.DataFrame,
    columns: pd.DataFrame,
    max_nodes: int = 120,
) -> tuple[nx.MultiDiGraph, pd.DataFrame]:
    nodes = set()
    for row in relationships.to_dict("records"):
        source, target = _edge_tables(row)
        nodes.update([source, target])
    limited = _limit_nodes(list(nodes), relationships, max_nodes)
    context_relationships = relationships_for_nodes(relationships, limited)
    return build_graph_from_relationships(context_relationships, tables, columns), context_relationships


def find_column_matches(columns: pd.DataFrame, term: str, graph_nodes: set[str] | None = None) -> pd.DataFrame:
    term = (term or "").strip().lower()
    if not term:
        return pd.DataFrame()
    filtered = columns[columns["column_name"].str.lower().str.contains(term, regex=False, na=False)].copy()
    filtered["table_key"] = filtered["schema_name"] + "." + filtered["table_name"]
    if graph_nodes:
        filtered = filtered[filtered["table_key"].isin(graph_nodes)]
    return filtered[
        ["table_key", "schema_name", "table_name", "column_name", "data_type", "is_primary_key", "is_foreign_key"]
    ]


def bridge_table_candidates(graph: nx.MultiDiGraph, columns: pd.DataFrame) -> pd.DataFrame:
    rows = []
    undirected = nx.Graph(graph)
    for node in graph.nodes:
        degree = undirected.degree(node)
        schema_name, table_name = node.split(".", 1)
        node_columns = columns[
            (columns["schema_name"] == schema_name) & (columns["table_name"] == table_name)
        ]
        key_columns = int(
            node_columns.get("is_primary_key", False).astype(bool).sum()
            + node_columns.get("is_foreign_key", False).astype(bool).sum()
        )
        descriptive_columns = max(len(node_columns) - key_columns, 0)
        score = degree * 12
        if key_columns >= 2:
            score += 25
        if BRIDGE_NAME.search(table_name):
            score += 20
        if descriptive_columns <= max(key_columns, 2):
            score += 10
        if score >= 30:
            rows.append(
                {
                    "table_name": node,
                    "bridge_score": score,
                    "degree": degree,
                    "key_columns": key_columns,
                    "descriptive_columns": descriptive_columns,
                }
            )
    return pd.DataFrame(rows).sort_values("bridge_score", ascending=False) if rows else pd.DataFrame()


def migration_relevance(graph: nx.MultiDiGraph, columns: pd.DataFrame) -> pd.DataFrame:
    rows = []
    undirected = nx.Graph(graph)
    bridges = set(bridge_table_candidates(graph, columns).get("table_name", []))
    for node, attrs in graph.nodes(data=True):
        schema_name, table_name = node.split(".", 1)
        node_columns = columns[
            (columns["schema_name"] == schema_name) & (columns["table_name"] == table_name)
        ]
        has_pk = bool(node_columns.get("is_primary_key", False).astype(bool).any())
        has_fk = bool(node_columns.get("is_foreign_key", False).astype(bool).any())
        relevant_cols = node_columns["column_name"].str.contains(RELEVANT_COLUMN, regex=True, na=False).sum()
        row_count = int(attrs.get("row_count") or 0)
        degree = undirected.degree(node)
        score = 0
        score += 12 if has_pk else 0
        score += 14 if has_fk else 0
        score += min(int(relevant_cols) * 5, 25)
        score += min(degree * 5, 25)
        score += min(int(math.log10(row_count + 1) * 4), 20)
        score += 12 if node in bridges else 0
        rows.append(
            {
                "table_name": node,
                "relevance_score": min(score, 100),
                "degree": degree,
                "row_count": row_count,
                "relevant_columns": int(relevant_cols),
                "is_bridge_candidate": node in bridges,
            }
        )
    return pd.DataFrame(rows).sort_values("relevance_score", ascending=False) if rows else pd.DataFrame()


def graph_context_metrics(
    graph: nx.MultiDiGraph,
    relationships: pd.DataFrame,
    tables: pd.DataFrame,
    columns: pd.DataFrame,
) -> dict[str, pd.DataFrame | dict]:
    nodes = set(graph.nodes)
    real_count = int((relationships.get("relationship_type", pd.Series(dtype=str)) == "REAL_FK").sum())
    inferred_count = int((relationships.get("relationship_type", pd.Series(dtype=str)) != "REAL_FK").sum())
    undirected = nx.Graph(graph)
    degree_rows = [
        {"table_name": node, "degree": degree}
        for node, degree in sorted(undirected.degree, key=lambda item: item[1], reverse=True)
    ]
    degree_df = pd.DataFrame(degree_rows)
    context_columns = columns[(columns["schema_name"] + "." + columns["table_name"]).isin(nodes)].copy()
    recurring_columns = (
        context_columns["column_name"].str.upper().value_counts().reset_index()
        if not context_columns.empty
        else pd.DataFrame()
    )
    if not recurring_columns.empty:
        recurring_columns.columns = ["column_name", "occurrences"]
    candidates = context_columns[
        context_columns["column_name"].str.contains(RELEVANT_COLUMN, regex=True, na=False)
    ].copy()
    candidates["table_key"] = candidates["schema_name"] + "." + candidates["table_name"] if not candidates.empty else []
    no_pk = []
    no_fk = []
    for node in nodes:
        schema_name, table_name = node.split(".", 1)
        node_columns = columns[
            (columns["schema_name"] == schema_name) & (columns["table_name"] == table_name)
        ]
        if not bool(node_columns.get("is_primary_key", False).astype(bool).any()):
            no_pk.append(node)
        if not bool(node_columns.get("is_foreign_key", False).astype(bool).any()):
            no_fk.append(node)
    return {
        "summary": {
            "tables": len(nodes),
            "relationships": len(relationships),
            "real_relationships": real_count,
            "inferred_relationships": inferred_count,
            "most_connected_table": degree_df.iloc[0]["table_name"] if not degree_df.empty else "",
        },
        "degree": degree_df,
        "tables_without_pk": pd.DataFrame({"table_name": no_pk}),
        "tables_without_fk": pd.DataFrame({"table_name": no_fk}),
        "bridge_tables": bridge_table_candidates(graph, columns),
        "recurring_columns": recurring_columns.head(30),
        "candidate_columns": candidates[
            ["table_key", "column_name", "data_type", "is_primary_key", "is_foreign_key"]
        ].head(100) if not candidates.empty else pd.DataFrame(),
        "relevance": migration_relevance(graph, columns),
    }
