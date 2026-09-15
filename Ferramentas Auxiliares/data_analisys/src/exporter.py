from __future__ import annotations

import json

import networkx as nx
import pandas as pd


def context_nodes_dataframe(graph: nx.MultiDiGraph, columns: pd.DataFrame) -> pd.DataFrame:
    rows = []
    for node, attrs in graph.nodes(data=True):
        schema_name, table_name = node.split(".", 1)
        node_columns = columns[
            (columns["schema_name"] == schema_name) & (columns["table_name"] == table_name)
        ]
        rows.append(
            {
                "table_key": node,
                "schema_name": schema_name,
                "table_name": table_name,
                "row_count": attrs.get("row_count", 0),
                "column_count": len(node_columns),
                "pk_columns": attrs.get("pk_columns", ""),
                "fk_columns": attrs.get("fk_columns", ""),
                "candidate_columns": attrs.get("candidate_columns", ""),
            }
        )
    return pd.DataFrame(rows)


def context_edges_dataframe(relationships: pd.DataFrame) -> pd.DataFrame:
    return relationships.copy()


def graph_context_json(graph: nx.MultiDiGraph, relationships: pd.DataFrame) -> bytes:
    nodes = [
        {"id": node, **{key: str(value) for key, value in attrs.items()}}
        for node, attrs in graph.nodes(data=True)
    ]
    edges = relationships.to_dict("records") if relationships is not None and not relationships.empty else []
    return json.dumps({"nodes": nodes, "edges": edges}, ensure_ascii=False, indent=2, default=str).encode("utf-8")


def markdown_summary(summary: dict, metrics: dict[str, pd.DataFrame | dict]) -> bytes:
    lines = ["# Resumo do Mapa Relacional", ""]
    for key, value in summary.items():
        lines.append(f"- {key}: {value}")
    lines.append("")
    bridge_tables = metrics.get("bridge_tables")
    if isinstance(bridge_tables, pd.DataFrame) and not bridge_tables.empty:
        lines.append("## Possiveis Tabelas Ponte")
        lines.append(bridge_tables.head(20).to_markdown(index=False))
        lines.append("")
    relevance = metrics.get("relevance")
    if isinstance(relevance, pd.DataFrame) and not relevance.empty:
        lines.append("## Ranking de Relevancia")
        lines.append(relevance.head(30).to_markdown(index=False))
        lines.append("")
    return "\n".join(lines).encode("utf-8")
