from __future__ import annotations

import math

import networkx as nx
import plotly.graph_objects as go


def make_relationship_figure(
    graph: nx.MultiDiGraph,
    show_edge_labels: bool = False,
    edge_labels_on_hover: bool = True,
):
    if graph.number_of_nodes() == 0:
        return go.Figure()

    undirected = nx.Graph()
    for node in graph.nodes:
        undirected.add_node(node)
    for u, v, data in graph.edges(data=True):
        undirected.add_edge(u, v, relationship_type=data.get("relationship_type", ""))

    try:
        pos = nx.spring_layout(undirected, seed=42, k=0.8)
    except (ImportError, ModuleNotFoundError):
        pos = nx.circular_layout(undirected)

    real_x, real_y, real_hover = [], [], []
    inferred_x, inferred_y, inferred_hover = [], [], []
    label_x, label_y, label_text = [], [], []
    for u, v, data in graph.edges(data=True):
        x0, y0 = pos[u]
        x1, y1 = pos[v]
        hover = (
            f"<b>{u} -> {v}</b><br>"
            f"Origem: {data.get('source_table', '')}.{data.get('source_column', '')}<br>"
            f"Destino: {data.get('target_table', '')}.{data.get('target_column', '')}<br>"
            f"Tipo: {data.get('relationship_type', '')}<br>"
            f"Confianca: {data.get('confidence_label', '')} ({data.get('confidence_score', '')})"
        )
        target = (
            (real_x, real_y, real_hover)
            if data.get("relationship_type") == "REAL_FK"
            else (inferred_x, inferred_y, inferred_hover)
        )
        target[0].extend([x0, x1, None])
        target[1].extend([y0, y1, None])
        target[2].extend([hover, hover, None])
        label_x.append((x0 + x1) / 2)
        label_y.append((y0 + y1) / 2)
        label_text.append(data.get("label", ""))

    edge_real = go.Scatter(
        x=real_x,
        y=real_y,
        line=dict(width=1.5, color="#2563eb"),
        hovertext=real_hover,
        hoverinfo="text" if edge_labels_on_hover else "none",
        mode="lines",
        name="FK real",
    )
    edge_inferred = go.Scatter(
        x=inferred_x,
        y=inferred_y,
        line=dict(width=1, color="#f97316", dash="dot"),
        hovertext=inferred_hover,
        hoverinfo="text" if edge_labels_on_hover else "none",
        mode="lines",
        name="Hipotese inferida",
    )

    node_x, node_y, labels, hover, sizes, colors, line_widths = [], [], [], [], [], [], []
    degrees = dict(nx.Graph(graph).degree)
    for node, attrs in graph.nodes(data=True):
        x, y = pos[node]
        node_x.append(x)
        node_y.append(y)
        labels.append(node)
        row_count = int(attrs.get("row_count") or 0)
        degree = int(degrees.get(node, 0))
        size = 14 + min(math.log10(row_count + 1) * 3, 18) + min(degree * 1.5, 18)
        sizes.append(size)
        if attrs.get("is_central"):
            colors.append("#dc2626")
            line_widths.append(4)
        elif attrs.get("is_highlighted"):
            colors.append("#7c3aed")
            line_widths.append(3)
        else:
            colors.append("#0f766e")
            line_widths.append(1)
        hover.append(
            f"<b>{node}</b><br>"
            f"Schema: {attrs.get('schema_name', '')}<br>"
            f"Tabela: {attrs.get('table_name', '')}<br>"
            f"Linhas: {row_count}<br>"
            f"Colunas: {attrs.get('column_count', 0)}<br>"
            f"PKs: {attrs.get('pk_columns', '') or '-'}<br>"
            f"FKs: {attrs.get('fk_columns', '') or '-'}<br>"
            f"Candidatas: {attrs.get('candidate_columns', '') or '-'}"
        )

    nodes = go.Scatter(
        x=node_x,
        y=node_y,
        mode="markers+text",
        text=labels,
        textposition="top center",
        marker=dict(size=sizes, color=colors, line=dict(width=line_widths, color="#0f172a")),
        hovertext=hover,
        hoverinfo="text",
        name="Tabelas",
    )

    data = [edge_real, edge_inferred]
    if show_edge_labels:
        data.append(
            go.Scatter(
                x=label_x,
                y=label_y,
                mode="text",
                text=label_text,
                textfont=dict(size=10, color="#475569"),
                hoverinfo="skip",
                name="Labels de joins",
            )
        )
    data.append(nodes)

    fig = go.Figure(data=data)
    fig.update_layout(
        height=650,
        margin=dict(l=10, r=10, t=30, b=10),
        showlegend=True,
        xaxis=dict(showgrid=False, zeroline=False, visible=False),
        yaxis=dict(showgrid=False, zeroline=False, visible=False),
    )
    return fig
