from __future__ import annotations

from datetime import datetime

import pandas as pd
import streamlit as st

from .config import ConnectionConfig
from .db import connect
from .exports import to_excel_bytes, to_json_bytes, to_markdown_bytes
from .sql_runner import execute_safe_query
from .sql_safety import validate_readonly_sql
from .sql_templates import SQLTemplate, templates_by_category


DEFAULT_SQL = """SELECT
    s.name AS schema_name,
    t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
ORDER BY s.name, t.name;"""


def _ensure_state() -> None:
    st.session_state.setdefault("safe_sql_editor", DEFAULT_SQL)
    st.session_state.setdefault("safe_sql_params", [])
    st.session_state.setdefault("safe_sql_history", [])
    st.session_state.setdefault("safe_sql_result", pd.DataFrame())
    st.session_state.setdefault("safe_sql_executed_sql", "")


def _record_history(query: str, status: str, elapsed: float | None = None, rows: int | None = None) -> None:
    item = {
        "executed_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "query_preview": " ".join((query or "").split())[:180],
        "status": status,
        "elapsed_seconds": round(elapsed or 0, 3) if elapsed is not None else None,
        "row_count": rows,
    }
    history = st.session_state.setdefault("safe_sql_history", [])
    history.insert(0, item)
    del history[50:]


def _template_params(template: SQLTemplate) -> dict:
    values = {}
    if not template.parameters:
        return values
    cols = st.columns(min(len(template.parameters), 3))
    for index, param in enumerate(template.parameters):
        label = param.replace("_", " ").title()
        values[param] = cols[index % len(cols)].text_input(label, key=f"sql_template_param_{template.key}_{param}")
    return values


def _render_templates() -> None:
    st.subheader("Consultas uteis para descoberta de dados")
    grouped = templates_by_category()
    category = st.selectbox("Categoria", list(grouped.keys()), key="sql_template_category")
    template = st.selectbox(
        "Consulta pronta",
        grouped[category],
        format_func=lambda item: item.title,
        key="sql_template_selected",
    )
    st.caption(template.description)
    params = _template_params(template)

    col1, col2 = st.columns(2)
    if col1.button("Carregar query no editor", key="sql_load_template"):
        try:
            sql, args = template.builder(params)
            st.session_state["safe_sql_editor"] = sql.strip()
            st.session_state["safe_sql_params"] = args
            st.success("Query carregada no editor.")
        except Exception as exc:
            st.error(f"Nao foi possivel gerar a query: {exc}")

    if col2.button("Executar template", key="sql_execute_template"):
        try:
            sql, args = template.builder(params)
            st.session_state["safe_sql_editor"] = sql.strip()
            st.session_state["safe_sql_params"] = args
            _execute_current_query()
        except Exception as exc:
            st.error(f"Nao foi possivel executar o template: {exc}")


def _execute_current_query() -> None:
    cfg: ConnectionConfig = st.session_state["connection_config"]
    sql = st.session_state.get("safe_sql_editor", "")
    params = st.session_state.get("safe_sql_params", []) if "?" in sql else []
    limit = st.session_state.get("safe_sql_limit", 500)
    with connect(cfg) as conn:
        result = execute_safe_query(conn, sql, params=params, limit=limit)
    st.session_state["safe_sql_result"] = result.dataframe
    st.session_state["safe_sql_executed_sql"] = result.executed_sql
    _record_history(sql, "sucesso", result.elapsed_seconds, result.row_count)
    st.success(f"Consulta executada em {result.elapsed_seconds:.3f}s. Linhas retornadas: {result.row_count}.")


def _render_result_actions(df: pd.DataFrame) -> None:
    if df.empty:
        return
    st.subheader("Exportar resultado atual")
    c1, c2, c3, c4 = st.columns(4)
    c1.download_button(
        "CSV",
        data=df.to_csv(index=False).encode("utf-8-sig"),
        file_name="consulta_segura_resultado.csv",
        mime="text/csv",
        key="sql_export_csv",
    )
    c2.download_button(
        "Excel",
        data=to_excel_bytes({"resultado": df}),
        file_name="consulta_segura_resultado.xlsx",
        mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        key="sql_export_excel",
    )
    c3.download_button(
        "JSON",
        data=to_json_bytes(df),
        file_name="consulta_segura_resultado.json",
        mime="application/json",
        key="sql_export_json",
    )
    c4.download_button(
        "Markdown",
        data=to_markdown_bytes(df),
        file_name="consulta_segura_resultado.md",
        mime="text/markdown",
        key="sql_export_markdown",
    )


def _render_session_history() -> None:
    history = st.session_state.get("safe_sql_history", [])
    st.subheader("Historico da sessao")
    if not history:
        st.info("Nenhuma consulta executada nesta sessao.")
        return
    st.dataframe(pd.DataFrame(history), use_container_width=True, hide_index=True)


def _extract_table_keys(df: pd.DataFrame) -> list[str]:
    if df.empty:
        return []
    if {"schema_name", "table_name"}.issubset(df.columns):
        return sorted((df["schema_name"].astype(str) + "." + df["table_name"].astype(str)).dropna().unique().tolist())
    if {"parent_schema", "parent_table"}.issubset(df.columns):
        return sorted((df["parent_schema"].astype(str) + "." + df["parent_table"].astype(str)).dropna().unique().tolist())
    return []


def _render_integration_actions(df: pd.DataFrame) -> None:
    tables = _extract_table_keys(df)
    if not tables:
        return
    st.subheader("Acoes com tabelas encontradas")
    st.caption("As acoes preparam contexto para outras abas; a navegacao continua manual.")
    selected = st.multiselect("Tabelas encontradas", tables, default=tables[: min(10, len(tables))], key="sql_found_tables")
    if st.button("Preparar para Mapa Relacional", key="sql_prepare_map"):
        st.session_state["sql_tables_for_map"] = selected
        st.success("Tabelas guardadas na sessao para uso no Mapa Relacional.")
    if len(selected) >= 2 and st.button("Preparar para Relationship Finder", key="sql_prepare_finder"):
        st.session_state["finder_source_table"] = selected[0]
        st.session_state["finder_target_table"] = selected[1]
        st.success("Tabela A e B preenchidas para a aba Relationship Finder.")


def render_safe_sql_explorer(cfg: ConnectionConfig) -> None:
    _ensure_state()
    st.session_state["connection_config"] = cfg

    st.warning("Somente consultas SELECT sao permitidas. Nenhum comando altera dados ou estrutura do banco.")
    c1, c2, c3 = st.columns(3)
    c1.metric("Banco", cfg.database or "-")
    c2.metric("Usuario", "Trusted Connection" if cfg.trusted_connection else (cfg.user or "-"))
    limit = c3.selectbox("Limite maximo de linhas", [100, 500, 1000, 5000], index=1, key="safe_sql_limit")

    with st.expander("Consultas prontas", expanded=True):
        _render_templates()

    st.subheader("Editor SQL")
    st.text_area(
        "SQL",
        height=260,
        key="safe_sql_editor",
        help="Use apenas SELECT. Templates parametrizados podem manter placeholders ? internamente.",
    )

    col_validate, col_execute = st.columns(2)
    if col_validate.button("Validar consulta", key="safe_sql_validate"):
        ok, errors = validate_readonly_sql(st.session_state["safe_sql_editor"])
        if ok:
            st.success("Consulta validada como somente leitura.")
        else:
            st.error("\n".join(errors))
            _record_history(st.session_state["safe_sql_editor"], "bloqueada")

    if col_execute.button("Executar consulta", type="primary", key="safe_sql_execute"):
        try:
            _execute_current_query()
        except Exception as exc:
            st.error(f"Consulta bloqueada ou falhou: {exc}")
            _record_history(st.session_state["safe_sql_editor"], "erro")

    executed_sql = st.session_state.get("safe_sql_executed_sql", "")
    if executed_sql:
        with st.expander("SQL executado com limite aplicado"):
            st.code(executed_sql, language="sql")

    df = st.session_state.get("safe_sql_result", pd.DataFrame())
    if not df.empty:
        st.subheader("Resultado")
        st.caption(f"Exibindo ate {limit} linhas.")
        st.dataframe(df, use_container_width=True, hide_index=True)
        _render_integration_actions(df)
        _render_result_actions(df)

    with st.expander("Historico local da sessao", expanded=False):
        _render_session_history()
