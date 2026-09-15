from __future__ import annotations

import pandas as pd
import streamlit as st

from .exporter import (
    context_edges_dataframe,
    context_nodes_dataframe,
    graph_context_json,
    markdown_summary,
)
from .graph_builder import (
    build_central_context,
    build_full_context,
    build_path_context,
    build_selected_context,
    combine_relationships,
    filter_relationships,
    find_column_matches,
    graph_context_metrics,
)
from .graphing import make_relationship_figure
from .relationship_finder import describe_paths


def _table_options(tables: pd.DataFrame) -> list[str]:
    if tables.empty:
        return []
    return sorted((tables["schema_name"] + "." + tables["table_name"]).tolist())


def _schema_options(tables: pd.DataFrame) -> list[str]:
    if tables.empty:
        return []
    return sorted(tables["schema_name"].dropna().unique().tolist())


def _render_analytics(graph, relationships: pd.DataFrame, tables: pd.DataFrame, columns: pd.DataFrame, paths=None) -> None:
    metrics = graph_context_metrics(graph, relationships, tables, columns)
    summary = metrics["summary"]
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Tabelas", summary["tables"])
    c2.metric("Relacionamentos", summary["relationships"])
    c3.metric("FKs reais", summary["real_relationships"])
    c4.metric("Hipoteses", summary["inferred_relationships"])
    st.caption(f"Tabela mais conectada no contexto: {summary['most_connected_table'] or '-'}")

    tabs = st.tabs(
        [
            "Tabelas",
            "Relacionamentos",
            "Tabelas ponte",
            "Campos candidatos",
            "Relevancia",
            "Caminhos",
            "Exportar contexto",
        ]
    )
    with tabs[0]:
        left, right = st.columns(2)
        with left:
            st.subheader("Sem PK")
            st.dataframe(metrics["tables_without_pk"], use_container_width=True, hide_index=True)
        with right:
            st.subheader("Sem FK")
            st.dataframe(metrics["tables_without_fk"], use_container_width=True, hide_index=True)
    with tabs[1]:
        st.dataframe(relationships, use_container_width=True, hide_index=True)
        st.subheader("Colunas recorrentes")
        st.dataframe(metrics["recurring_columns"], use_container_width=True, hide_index=True)
    with tabs[2]:
        st.caption("Sugestao heuristica, nao conclusao definitiva.")
        st.dataframe(metrics["bridge_tables"], use_container_width=True, hide_index=True)
    with tabs[3]:
        st.dataframe(metrics["candidate_columns"], use_container_width=True, hide_index=True)
    with tabs[4]:
        st.caption("Ranking simples para priorizar investigacao de de-para.")
        st.dataframe(metrics["relevance"], use_container_width=True, hide_index=True)
    with tabs[5]:
        if paths:
            for item in paths:
                st.markdown(f"**Caminho {item['path_id']}**: `{item['tables']}`")
                st.caption(f"Confiança: {item['confidence_label']} ({item['confidence_score']})")
                st.code(item["validation_sql"], language="sql")
        else:
            st.info("Nenhuma trilha selecionada neste contexto.")
    with tabs[6]:
        nodes_df = context_nodes_dataframe(graph, columns)
        edges_df = context_edges_dataframe(relationships)
        st.download_button(
            "CSV - tabelas e colunas exibidas",
            data=nodes_df.to_csv(index=False).encode("utf-8-sig"),
            file_name="contexto_mapa_tabelas.csv",
            mime="text/csv",
        )
        st.download_button(
            "CSV - relacionamentos exibidos",
            data=edges_df.to_csv(index=False).encode("utf-8-sig"),
            file_name="contexto_mapa_relacionamentos.csv",
            mime="text/csv",
        )
        st.download_button(
            "JSON - nos e arestas",
            data=graph_context_json(graph, relationships),
            file_name="contexto_mapa.json",
            mime="application/json",
        )
        st.download_button(
            "Markdown - resumo analitico",
            data=markdown_summary(summary, metrics),
            file_name="contexto_mapa.md",
            mime="text/markdown",
        )


def _render_graph_and_context(graph, relationships, tables, columns, show_labels, hover_labels, paths=None) -> None:
    if graph.number_of_nodes() == 0:
        st.info("Nenhum relacionamento encontrado para os filtros atuais.")
        return
    fig = make_relationship_figure(
        graph,
        show_edge_labels=show_labels,
        edge_labels_on_hover=hover_labels,
    )
    st.plotly_chart(fig, use_container_width=True)
    st.download_button(
        "HTML - grafo atual",
        data=fig.to_html(include_plotlyjs="cdn").encode("utf-8"),
        file_name="contexto_mapa.html",
        mime="text/html",
    )
    _render_analytics(graph, relationships, tables, columns, paths=paths)


def render_relational_map(
    tables: pd.DataFrame,
    columns: pd.DataFrame,
    real_relationships: pd.DataFrame,
    inferred_relationships: pd.DataFrame,
) -> None:
    if tables.empty:
        st.info("Carregue os metadados para usar o mapa relacional.")
        return

    table_options = _table_options(tables)
    schema_options = _schema_options(tables)

    st.warning(
        "O mapa completo nao e renderizado por padrao. Escolha uma tabela central, um conjunto de tabelas ou uma trilha."
    )

    mode = st.radio(
        "Modo",
        ["Tabela Central", "Tabelas Selecionadas", "Trilha entre Duas Tabelas", "Grafo Completo"],
        horizontal=True,
        key="map_mode",
    )

    with st.expander("Filtros do mapa", expanded=True):
        c1, c2, c3, c4 = st.columns(4)
        selected_schemas = c1.multiselect("Schema", schema_options, key="map_filter_schemas")
        include_inferred = c2.checkbox("Incluir inferidos", value=False, key="map_include_inferred")
        max_nodes = c3.slider("Maximo de nos", 10, 250, 80, 10, key="map_max_nodes")
        relation_scope = c4.multiselect(
            "Tipo relacionamento",
            ["REAL_FK", "INFERRED_HYPOTHESIS"],
            default=["REAL_FK", "INFERRED_HYPOTHESIS"] if include_inferred else ["REAL_FK"],
            key="map_relationship_scope",
        )
        c5, c6, c7 = st.columns(3)
        search_term = c5.text_input("Buscar tabela/coluna", key="map_search_term")
        show_labels = c6.checkbox("Mostrar labels das arestas", value=False, key="map_show_edge_labels")
        hover_labels = c7.checkbox("Labels no hover", value=True, key="map_hover_edge_labels")

    relationships = combine_relationships(real_relationships, inferred_relationships, include_inferred)
    relationships = filter_relationships(
        relationships,
        schemas=selected_schemas,
        table_or_column_term=search_term,
        relationship_kinds=relation_scope,
    )

    graph = None
    context_relationships = pd.DataFrame()
    path_context = None
    path_descriptions = None

    if mode == "Tabela Central":
        c1, c2, c3 = st.columns(3)
        central_table = c1.selectbox("Tabela central", table_options, key="map_central_table")
        depth = c2.selectbox("Profundidade", [1, 2, 3, 4], index=1, key="map_central_depth")
        direction = c3.selectbox("Direcao", ["ambos", "entrada", "saida"], key="map_central_direction")
        if st.button("Montar contexto da tabela central", type="primary"):
            graph, context_relationships = build_central_context(
                relationships,
                tables,
                columns,
                central_table=central_table,
                depth=int(depth),
                direction=direction,
                max_nodes=max_nodes,
            )
            st.session_state["graph_context"] = (graph, context_relationships, None)

    elif mode == "Tabelas Selecionadas":
        prepared_tables = [
            table for table in st.session_state.get("sql_tables_for_map", []) if table in table_options
        ]
        if prepared_tables and "map_selected_tables" not in st.session_state:
            st.session_state["map_selected_tables"] = prepared_tables
        selected_tables = st.multiselect("Tabelas", table_options, key="map_selected_tables")
        c1, c2 = st.columns(2)
        add_intermediates = c1.checkbox(
            "Adicionar tabelas intermediarias automaticamente",
            value=True,
            key="map_selected_add_intermediates",
        )
        max_depth = c2.selectbox("Profundidade intermediaria", [1, 2, 3, 4], index=2, key="map_selected_depth")
        if st.button("Montar contexto selecionado", type="primary"):
            graph, context_relationships = build_selected_context(
                relationships,
                tables,
                columns,
                selected_tables=selected_tables,
                add_intermediates=add_intermediates,
                max_depth=int(max_depth),
                max_nodes=max_nodes,
            )
            st.session_state["graph_context"] = (graph, context_relationships, None)

    elif mode == "Trilha entre Duas Tabelas":
        c1, c2, c3 = st.columns([2, 2, 1])
        source_table = c1.selectbox("Tabela A", table_options, key="map_path_source_table")
        target_table = c2.selectbox(
            "Tabela B",
            table_options,
            index=min(1, len(table_options) - 1),
            key="map_path_target_table",
        )
        max_depth = c3.selectbox("Profundidade maxima", [1, 2, 3, 4], index=2, key="map_path_depth")
        if st.button("Encontrar trilhas", type="primary"):
            path_descriptions = describe_paths(
                real_relationships,
                inferred_relationships,
                source_table,
                target_table,
                max_depth=int(max_depth),
                include_inferred=include_inferred,
            )
            st.session_state["graph_paths"] = path_descriptions

        path_descriptions = st.session_state.get("graph_paths", [])
        if path_descriptions:
            rows = [
                {
                    "path_id": item["path_id"],
                    "tables": item["tables"],
                    "intermediate_tables": item["intermediate_tables"],
                    "relationship_types": item["relationship_types"],
                    "confidence_label": item["confidence_label"],
                    "confidence_score": item["confidence_score"],
                }
                for item in path_descriptions
            ]
            st.dataframe(pd.DataFrame(rows), use_container_width=True, hide_index=True)
            selected_path_id = st.selectbox(
                "Visualizar caminho no grafo",
                [item["path_id"] for item in path_descriptions],
                key="map_path_to_visualize",
            )
            path_context = next(item for item in path_descriptions if item["path_id"] == selected_path_id)
            st.code(path_context["validation_sql"], language="sql")
            graph, context_relationships = build_path_context(path_context["steps"], tables, columns)
            st.session_state["graph_context"] = (graph, context_relationships, [path_context])
        else:
            st.info("Informe as tabelas e clique em Encontrar trilhas.")

    else:
        st.error("O grafo completo pode ficar poluido e pesado em bases grandes.")
        show_full = st.checkbox("Mostrar grafo completo mesmo assim", value=False, key="map_show_full_graph")
        if show_full and st.button("Montar grafo completo", type="primary"):
            graph, context_relationships = build_full_context(
                relationships,
                tables,
                columns,
                max_nodes=max_nodes,
            )
            st.session_state["graph_context"] = (graph, context_relationships, None)

    context = st.session_state.get("graph_context")
    if not context:
        st.info("Selecione um modo e monte um contexto para renderizar o grafo.")
        return

    graph, context_relationships, path_contexts = context
    if search_term:
        matches = find_column_matches(columns, search_term, set(graph.nodes))
        if not matches.empty:
            st.subheader("Campos encontrados no contexto")
            st.dataframe(matches, use_container_width=True, hide_index=True)
            for node in matches["table_key"].unique():
                if node in graph:
                    graph.nodes[node]["is_highlighted"] = True

    _render_graph_and_context(
        graph,
        context_relationships,
        tables,
        columns,
        show_labels=show_labels,
        hover_labels=hover_labels,
        paths=path_contexts,
    )
