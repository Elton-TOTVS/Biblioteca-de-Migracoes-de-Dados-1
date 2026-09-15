from __future__ import annotations

import pandas as pd
import streamlit as st

from src.config import ConnectionConfig
from src.db import connect, read_sql
from src.exports import to_excel_bytes, to_json_bytes, to_markdown_bytes
from src.metadata import build_metadata
from src.profiling import load_sample_rows, profile_columns_for_table
from src.relationships import (
    find_paths,
    infer_relationships,
    real_fk_relationships,
)
from src.search import classify_column, global_search
from src.security import mask_sensitive_dataframe, mark_sensitive_columns
from src.ui_graph import render_relational_map
from src.ui_sql_explorer import render_safe_sql_explorer


st.set_page_config(page_title="SQL Server Migration Explorer", layout="wide")


def get_config_from_sidebar() -> ConnectionConfig:
    env_cfg = ConnectionConfig.from_env()
    st.sidebar.header("Conexao SQL Server")
    host = st.sidebar.text_input("Servidor", value=env_cfg.host, key="conn_host")
    port = st.sidebar.text_input("Porta", value=env_cfg.port, key="conn_port")
    database = st.sidebar.text_input("Banco", value=env_cfg.database, key="conn_database")
    driver = st.sidebar.text_input("Driver ODBC", value=env_cfg.driver, key="conn_driver")
    trusted = st.sidebar.checkbox("Trusted Connection", value=env_cfg.trusted_connection, key="conn_trusted")
    user = st.sidebar.text_input("Usuario", value=env_cfg.user, disabled=trusted, key="conn_user")
    password = st.sidebar.text_input("Senha", value=env_cfg.password, type="password", disabled=trusted, key="conn_password")
    encrypt = st.sidebar.selectbox("Encrypt", ["yes", "no"], index=0 if env_cfg.encrypt == "yes" else 1, key="conn_encrypt")
    trust_cert = st.sidebar.selectbox(
        "TrustServerCertificate",
        ["yes", "no"],
        index=0 if env_cfg.trust_server_certificate == "yes" else 1,
        key="conn_trust_cert",
    )
    return ConnectionConfig(
        host=host,
        port=port,
        database=database,
        user=user,
        password=password,
        driver=driver,
        trusted_connection=trusted,
        encrypt=encrypt,
        trust_server_certificate=trust_cert,
    )


def metadata_or_empty(name: str) -> pd.DataFrame:
    metadata = st.session_state.get("metadata") or {}
    return metadata.get(name, pd.DataFrame())


def load_metadata(cfg: ConnectionConfig, schemas_text: str) -> None:
    schemas = [item.strip() for item in schemas_text.split(",") if item.strip()]
    with connect(cfg) as conn:
        metadata = build_metadata(conn, schemas or None)
    metadata["columns"] = mark_sensitive_columns(metadata["columns"])
    st.session_state["metadata"] = metadata
    st.session_state["real_relationships"] = real_fk_relationships(metadata["foreign_keys"])
    st.session_state["inferred_relationships"] = pd.DataFrame()


def relationships_combined() -> pd.DataFrame:
    frames = [
        st.session_state.get("real_relationships", pd.DataFrame()),
        st.session_state.get("inferred_relationships", pd.DataFrame()),
    ]
    frames = [frame for frame in frames if frame is not None and not frame.empty]
    return pd.concat(frames, ignore_index=True) if frames else pd.DataFrame()


def test_connection(cfg: ConnectionConfig) -> None:
    try:
        with connect(cfg) as conn:
            result = read_sql(conn, "SELECT DB_NAME() AS database_name, SUSER_SNAME() AS login_name;")
        st.sidebar.success(
            f"Conectado em {result.iloc[0]['database_name']} como {result.iloc[0]['login_name']}"
        )
    except Exception as exc:
        st.sidebar.error(f"Falha na conexao: {exc}")


def render_dashboard() -> None:
    tables = metadata_or_empty("tables")
    columns = metadata_or_empty("columns")
    real = st.session_state.get("real_relationships", pd.DataFrame())

    if tables.empty:
        st.info("Carregue os metadados para ver a visao geral.")
        return

    pk_keys = columns.loc[columns["is_primary_key"].astype(bool), "schema_name"] + "." + columns.loc[
        columns["is_primary_key"].astype(bool), "table_name"
    ]
    table_keys = tables["schema_name"] + "." + tables["table_name"]
    tables_no_pk = tables.loc[~table_keys.isin(set(pk_keys))]

    related_tables = set()
    if not real.empty:
        related_tables.update((real["source_schema"] + "." + real["source_table"]).tolist())
        related_tables.update((real["target_schema"] + "." + real["target_table"]).tolist())
    tables_no_fk = tables.loc[~table_keys.isin(related_tables)]

    c1, c2, c3, c4, c5 = st.columns(5)
    c1.metric("Schemas", tables["schema_name"].nunique())
    c2.metric("Tabelas", len(tables))
    c3.metric("Colunas", len(columns))
    c4.metric("FKs reais", len(real))
    c5.metric("Hipoteses", len(st.session_state.get("inferred_relationships", pd.DataFrame())))

    left, right = st.columns(2)
    with left:
        st.subheader("Maiores tabelas")
        st.dataframe(tables.sort_values("row_count", ascending=False).head(20), use_container_width=True, hide_index=True)
        st.subheader("Tabelas sem chave primaria")
        st.dataframe(tables_no_pk.head(50), use_container_width=True, hide_index=True)
    with right:
        st.subheader("Distribuicao de tipos")
        st.dataframe(
            columns.groupby("data_type", as_index=False).size().sort_values("size", ascending=False),
            use_container_width=True,
            hide_index=True,
        )
        st.subheader("Tabelas sem relacionamento declarado")
        st.dataframe(tables_no_fk.head(50), use_container_width=True, hide_index=True)

    if not real.empty:
        degree = pd.concat(
            [
                real["source_schema"] + "." + real["source_table"],
                real["target_schema"] + "." + real["target_table"],
            ],
            ignore_index=True,
        ).value_counts().reset_index()
        degree.columns = ["table_name", "relationship_degree"]
        st.subheader("Possiveis tabelas centrais")
        st.dataframe(degree.head(20), use_container_width=True, hide_index=True)


def render_table_explorer(cfg: ConnectionConfig, mask_sensitive: bool) -> None:
    tables = metadata_or_empty("tables")
    columns = metadata_or_empty("columns")
    if tables.empty:
        st.info("Carregue os metadados para explorar tabelas.")
        return

    options = sorted((tables["schema_name"] + "." + tables["table_name"]).tolist())
    selected = st.selectbox("Tabela", options, key="explorer_table")
    schema_name, table_name = selected.split(".", 1)
    row_info = tables[(tables["schema_name"] == schema_name) & (tables["table_name"] == table_name)]
    st.caption(f"Linhas aproximadas: {int(row_info.iloc[0]['row_count']) if not row_info.empty else 0}")

    table_columns = columns[(columns["schema_name"] == schema_name) & (columns["table_name"] == table_name)].copy()
    table_columns["classification"] = table_columns["column_name"].map(classify_column)
    st.subheader("Colunas")
    st.dataframe(table_columns, use_container_width=True, hide_index=True)

    sample_limit = st.slider("Linhas de amostra", 10, 500, 100, 10, key="explorer_sample_limit")
    profile_sample = st.slider("Exemplos por coluna", 5, 100, 25, 5, key="explorer_profile_sample")
    if st.button("Carregar amostra e estatisticas", type="primary"):
        try:
            with connect(cfg) as conn:
                sample = load_sample_rows(conn, schema_name, table_name, sample_limit)
                profile = profile_columns_for_table(conn, columns, schema_name, table_name, sample_size=profile_sample)
            st.session_state["last_sample"] = mask_sensitive_dataframe(sample, mask_sensitive)
            st.session_state["last_profile"] = profile
        except Exception as exc:
            st.error(f"Falha ao carregar detalhes: {exc}")

    if "last_sample" in st.session_state:
        st.subheader("Amostra limitada")
        st.dataframe(st.session_state["last_sample"], use_container_width=True, hide_index=True)
    if "last_profile" in st.session_state:
        st.subheader("Estatisticas por coluna")
        profile = st.session_state["last_profile"].copy()
        if mask_sensitive and not profile.empty:
            profile.loc[profile["is_potentially_sensitive"].astype(bool), "examples"] = "***"
        st.dataframe(profile, use_container_width=True, hide_index=True)


def render_relationships(cfg: ConnectionConfig) -> None:
    tables = metadata_or_empty("tables")
    columns = metadata_or_empty("columns")
    real = st.session_state.get("real_relationships", pd.DataFrame())
    inferred = st.session_state.get("inferred_relationships", pd.DataFrame())
    if tables.empty:
        st.info("Carregue os metadados para analisar relacionamentos.")
        return

    st.subheader("Relacionamentos reais")
    st.caption("Origem: apenas foreign keys declaradas no SQL Server. Confianca alta.")
    st.dataframe(real, use_container_width=True, hide_index=True)

    st.subheader("Relacionamentos inferidos")
    st.caption("Hipoteses por heuristica. Nunca sao certeza; valide com o SQL sugerido.")
    all_tables = sorted((tables["schema_name"] + "." + tables["table_name"]).tolist())
    selected_tables = st.multiselect(
        "Tabelas para inferencia",
        all_tables,
        default=all_tables[: min(20, len(all_tables))],
        key="relationships_inference_tables",
    )
    left, right, third = st.columns(3)
    sample_size = left.slider("Amostra por coluna", 20, 300, 100, 20, key="relationships_sample_size")
    min_score = right.slider("Score minimo", 30, 90, 45, 5, key="relationships_min_score")
    include_values = third.checkbox("Comparar amostras de valores", value=True, key="relationships_include_values")

    if st.button("Gerar hipoteses inferidas", type="primary"):
        try:
            with connect(cfg) as conn:
                inferred = infer_relationships(
                    conn,
                    columns,
                    tables,
                    selected_tables=selected_tables,
                    include_value_samples=include_values,
                    sample_size=sample_size,
                    min_score=min_score,
                )
            st.session_state["inferred_relationships"] = inferred
        except Exception as exc:
            st.error(f"Falha ao gerar hipoteses: {exc}")

    st.dataframe(inferred, use_container_width=True, hide_index=True)


def render_relationship_finder() -> None:
    tables = metadata_or_empty("tables")
    real = st.session_state.get("real_relationships", pd.DataFrame())
    inferred = st.session_state.get("inferred_relationships", pd.DataFrame())
    if tables.empty:
        st.info("Carregue os metadados para buscar caminhos.")
        return

    options = sorted((tables["schema_name"] + "." + tables["table_name"]).tolist())
    c1, c2, c3, c4 = st.columns([2, 2, 1, 1])
    source_table = c1.selectbox("Tabela A", options, key="finder_source_table")
    target_table = c2.selectbox("Tabela B", options, index=min(1, len(options) - 1), key="finder_target_table")
    depth = c3.number_input("Profundidade", min_value=1, max_value=4, value=2, key="finder_depth")
    include_inferred = c4.checkbox("Incluir hipoteses", value=False, key="finder_include_inferred")

    paths = find_paths(real, inferred, source_table, target_table, max_depth=int(depth), include_inferred=include_inferred)
    if not paths:
        st.info("Nenhum caminho encontrado com os filtros atuais.")
        return
    for idx, path in enumerate(paths, start=1):
        with st.expander(f"Caminho {idx} ({len(path)} etapa(s))", expanded=idx == 1):
            df = pd.DataFrame(path)
            st.dataframe(df, use_container_width=True, hide_index=True)
            if not df[df["relationship_type"] != "REAL_FK"].empty:
                st.warning("Este caminho contem hipotese inferida. Valide com consulta SQL antes de usar.")


def render_global_search() -> None:
    tables = metadata_or_empty("tables")
    columns = metadata_or_empty("columns")
    if tables.empty:
        st.info("Carregue os metadados para usar a busca.")
        return
    term = st.text_input("Buscar por tabela, coluna, tipo ou relacionamento", key="global_search_term")
    results = global_search(tables, columns, relationships_combined(), term)
    st.dataframe(results, use_container_width=True, hide_index=True)


def render_graph() -> None:
    tables = metadata_or_empty("tables")
    columns = metadata_or_empty("columns")
    real = st.session_state.get("real_relationships", pd.DataFrame())
    inferred = st.session_state.get("inferred_relationships", pd.DataFrame())
    render_relational_map(tables, columns, real, inferred)


def render_exports() -> None:
    tables = metadata_or_empty("tables")
    columns = metadata_or_empty("columns")
    real = st.session_state.get("real_relationships", pd.DataFrame())
    inferred = st.session_state.get("inferred_relationships", pd.DataFrame())
    if tables.empty:
        st.info("Carregue os metadados para exportar.")
        return

    candidate_columns = columns.copy()
    candidate_columns["classification"] = candidate_columns["column_name"].map(classify_column)
    sheets = {
        "tabelas": tables,
        "colunas": candidate_columns,
        "relacionamentos_reais": real,
        "hipoteses_inferidas": inferred,
    }
    st.download_button(
        "Exportar Excel",
        data=to_excel_bytes(sheets),
        file_name="sqlserver_migration_explorer.xlsx",
        mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    )
    st.download_button(
        "Exportar colunas candidatas JSON",
        data=to_json_bytes(candidate_columns),
        file_name="colunas_candidatas.json",
        mime="application/json",
    )
    st.download_button(
        "Exportar hipoteses Markdown",
        data=to_markdown_bytes(inferred if not inferred.empty else pd.DataFrame()),
        file_name="hipoteses_relacionamento.md",
        mime="text/markdown",
    )


def main() -> None:
    st.title("SQL Server Migration Explorer")
    st.caption("Exploracao segura e somente leitura para apoiar de-para de migracao.")

    cfg = get_config_from_sidebar()
    schemas_text = st.sidebar.text_input("Schemas para analisar (opcional, separados por virgula)", value="", key="conn_schemas")
    mask_sensitive = st.sidebar.checkbox("Mascarar colunas sensiveis", value=True, key="mask_sensitive")
    col_a, col_b, col_c = st.sidebar.columns(3)
    if col_a.button("Testar"):
        test_connection(cfg)
    if col_b.button("Conectar", type="primary"):
        try:
            load_metadata(cfg, schemas_text)
            st.sidebar.success("Metadados carregados.")
        except Exception as exc:
            st.sidebar.error(f"Falha ao carregar metadados: {exc}")
    if col_c.button("Limpar"):
        for key in list(st.session_state.keys()):
            del st.session_state[key]
        st.rerun()

    tabs = st.tabs(
        [
            "Visao geral",
            "Explorador",
            "Relacionamentos",
            "Relationship Finder",
            "Mapa relacional",
            "Consultas SQL Seguras",
            "Busca global",
            "Exportacoes",
        ]
    )
    with tabs[0]:
        render_dashboard()
    with tabs[1]:
        render_table_explorer(cfg, mask_sensitive)
    with tabs[2]:
        render_relationships(cfg)
    with tabs[3]:
        render_relationship_finder()
    with tabs[4]:
        render_graph()
    with tabs[5]:
        render_safe_sql_explorer(cfg)
    with tabs[6]:
        render_global_search()
    with tabs[7]:
        render_exports()


if __name__ == "__main__":
    main()
