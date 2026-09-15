from __future__ import annotations

from dataclasses import dataclass
from typing import Callable

from .db import qualified_name, quote_name


TemplateBuilder = Callable[[dict], tuple[str, list]]


@dataclass(frozen=True)
class SQLTemplate:
    key: str
    category: str
    title: str
    description: str
    parameters: tuple[str, ...]
    builder: TemplateBuilder


def _p(params: dict, name: str, default: str = "") -> str:
    value = str(params.get(name) or default).strip()
    if not value:
        raise ValueError(f"Parametro obrigatorio nao informado: {name}")
    return value


def _table(params: dict, schema_key="schema", table_key="table") -> str:
    return qualified_name(_p(params, schema_key), _p(params, table_key))


def _column(params: dict, column_key="column") -> str:
    return quote_name(_p(params, column_key))


def _list_tables(params: dict):
    return """
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(CASE WHEN p.index_id IN (0, 1) THEN p.rows ELSE 0 END) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name
ORDER BY s.name, t.name
""", []


def _columns_by_table(params: dict):
    return """
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE s.name = ? AND t.name = ?
ORDER BY c.column_id
""", [_p(params, "schema"), _p(params, "table")]


def _search_column(params: dict):
    return """
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.name LIKE '%' + ? + '%'
ORDER BY s.name, t.name, c.name
""", [_p(params, "term")]


def _primary_keys(params: dict):
    return """
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    kc.name AS constraint_name
FROM sys.key_constraints kc
JOIN sys.tables t ON t.object_id = kc.parent_object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.index_columns ic ON ic.object_id = t.object_id AND ic.index_id = kc.unique_index_id
JOIN sys.columns c ON c.object_id = t.object_id AND c.column_id = ic.column_id
WHERE kc.type = 'PK'
ORDER BY s.name, t.name, ic.key_ordinal
""", []


def _foreign_keys(params: dict):
    return """
SELECT
    fk.name AS fk_name,
    sch_parent.name AS parent_schema,
    tab_parent.name AS parent_table,
    col_parent.name AS parent_column,
    sch_ref.name AS referenced_schema,
    tab_ref.name AS referenced_table,
    col_ref.name AS referenced_column
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.tables tab_parent ON fkc.parent_object_id = tab_parent.object_id
JOIN sys.schemas sch_parent ON tab_parent.schema_id = sch_parent.schema_id
JOIN sys.columns col_parent ON fkc.parent_object_id = col_parent.object_id AND fkc.parent_column_id = col_parent.column_id
JOIN sys.tables tab_ref ON fkc.referenced_object_id = tab_ref.object_id
JOIN sys.schemas sch_ref ON tab_ref.schema_id = sch_ref.schema_id
JOIN sys.columns col_ref ON fkc.referenced_object_id = col_ref.object_id AND fkc.referenced_column_id = col_ref.column_id
ORDER BY parent_schema, parent_table, fk.name
""", []


def _relationships_of_table(params: dict):
    sql, args = _foreign_keys(params)
    return sql.replace("ORDER BY parent_schema, parent_table, fk.name", """
WHERE (sch_parent.name = ? AND tab_parent.name = ?)
   OR (sch_ref.name = ? AND tab_ref.name = ?)
ORDER BY parent_schema, parent_table, fk.name
"""), [_p(params, "schema"), _p(params, "table"), _p(params, "schema"), _p(params, "table")]


def _referencing_table(params: dict):
    sql, _ = _foreign_keys(params)
    return sql.replace("ORDER BY parent_schema, parent_table, fk.name", """
WHERE sch_ref.name = ? AND tab_ref.name = ?
ORDER BY parent_schema, parent_table, fk.name
"""), [_p(params, "schema"), _p(params, "table")]


def _referenced_by_table(params: dict):
    sql, _ = _foreign_keys(params)
    return sql.replace("ORDER BY parent_schema, parent_table, fk.name", """
WHERE sch_parent.name = ? AND tab_parent.name = ?
ORDER BY referenced_schema, referenced_table, fk.name
"""), [_p(params, "schema"), _p(params, "table")]


def _tables_without_pk(params: dict):
    return """
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE NOT EXISTS (
    SELECT 1
    FROM sys.key_constraints kc
    WHERE kc.parent_object_id = t.object_id
      AND kc.type = 'PK'
)
ORDER BY s.name, t.name
""", []


def _tables_without_fk(params: dict):
    return """
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys fk WHERE fk.parent_object_id = t.object_id
)
ORDER BY s.name, t.name
""", []


def _largest_tables(params: dict):
    return """
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(CASE WHEN p.index_id IN (0, 1) THEN p.rows ELSE 0 END) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name
ORDER BY row_count DESC
""", []


def _same_name_columns(params: dict):
    return """
SELECT
    c.name AS column_name,
    COUNT(DISTINCT CONCAT(s.name, '.', t.name)) AS table_count,
    STRING_AGG(CONCAT(s.name, '.', t.name), ', ') AS tables
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
GROUP BY c.name
HAVING COUNT(DISTINCT CONCAT(s.name, '.', t.name)) > 1
ORDER BY table_count DESC, c.name
""", []


def _identifier_candidates(params: dict):
    return """
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.name LIKE '%ID%'
   OR c.name LIKE '%COD%'
   OR c.name LIKE '%CODIGO%'
   OR c.name LIKE '%CPF%'
   OR c.name LIKE '%CNPJ%'
   OR c.name LIKE '%MATRIC%'
   OR c.name LIKE '%CHAVE%'
ORDER BY s.name, t.name, c.name
""", []


def _table_profile(params: dict):
    table = _table(params)
    return f"""
SELECT
    COUNT_BIG(1) AS total_rows
FROM {table}
""", []


def _distinct_values(params: dict):
    table = _table(params)
    col = _column(params)
    return f"""
SELECT DISTINCT
    CAST({col} AS nvarchar(4000)) AS value
FROM {table}
WHERE {col} IS NOT NULL
ORDER BY CAST({col} AS nvarchar(4000))
""", []


def _null_percent(params: dict):
    table = _table(params)
    col = _column(params)
    return f"""
SELECT
    COUNT_BIG(1) AS total_rows,
    SUM(CASE WHEN {col} IS NULL THEN 1 ELSE 0 END) AS null_rows,
    CAST(100.0 * SUM(CASE WHEN {col} IS NULL THEN 1 ELSE 0 END) / NULLIF(COUNT_BIG(1), 0) AS decimal(10,2)) AS null_percent
FROM {table}
""", []


def _intersection(params: dict):
    source = qualified_name(_p(params, "source_schema"), _p(params, "source_table"))
    target = qualified_name(_p(params, "target_schema"), _p(params, "target_table"))
    source_col = quote_name(_p(params, "source_column"))
    target_col = quote_name(_p(params, "target_column"))
    return f"""
SELECT
    COUNT(DISTINCT s.{source_col}) AS source_distinct_values,
    COUNT(DISTINCT t.{target_col}) AS matching_distinct_values
FROM {source} s
LEFT JOIN {target} t ON s.{source_col} = t.{target_col}
WHERE s.{source_col} IS NOT NULL
""", []


def _orphans(params: dict):
    source = qualified_name(_p(params, "source_schema"), _p(params, "source_table"))
    target = qualified_name(_p(params, "target_schema"), _p(params, "target_table"))
    source_col = quote_name(_p(params, "source_column"))
    target_col = quote_name(_p(params, "target_column"))
    return f"""
SELECT
    s.{source_col} AS orphan_value,
    COUNT_BIG(1) AS occurrence_count
FROM {source} s
LEFT JOIN {target} t ON s.{source_col} = t.{target_col}
WHERE s.{source_col} IS NOT NULL
  AND t.{target_col} IS NULL
GROUP BY s.{source_col}
ORDER BY occurrence_count DESC
""", []


def _join_suggestion(params: dict):
    source = qualified_name(_p(params, "source_schema"), _p(params, "source_table"))
    target = qualified_name(_p(params, "target_schema"), _p(params, "target_table"))
    source_col = quote_name(_p(params, "source_column"))
    target_col = quote_name(_p(params, "target_column"))
    return f"""
SELECT
    s.*,
    t.*
FROM {source} s
JOIN {target} t ON s.{source_col} = t.{target_col}
""", []


def _bridge_tables(params: dict):
    return """
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    COUNT(DISTINCT fk.object_id) AS foreign_key_count,
    COUNT(DISTINCT c.column_id) AS column_count
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.foreign_keys fk ON fk.parent_object_id = t.object_id
LEFT JOIN sys.columns c ON c.object_id = t.object_id
GROUP BY s.name, t.name
HAVING COUNT(DISTINCT fk.object_id) >= 2
ORDER BY foreign_key_count DESC, column_count ASC
""", []


def _indexed_columns(params: dict):
    return """
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    i.name AS index_name,
    i.is_unique,
    i.is_primary_key
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
JOIN sys.tables t ON t.object_id = i.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE i.is_hypothetical = 0
ORDER BY s.name, t.name, i.name, ic.key_ordinal
""", []


TEMPLATES: list[SQLTemplate] = [
    SQLTemplate("list_tables", "Estrutura do banco", "Listar tabelas", "Lista schemas, tabelas e quantidade aproximada de linhas.", tuple(), _list_tables),
    SQLTemplate("columns_by_table", "Estrutura do banco", "Listar colunas por tabela", "Lista colunas de uma tabela.", ("schema", "table"), _columns_by_table),
    SQLTemplate("search_column", "Busca de campos para de-para", "Buscar coluna por termo", "Procura colunas pelo nome.", ("term",), _search_column),
    SQLTemplate("primary_keys", "Chaves e relacionamentos", "Listar primary keys", "Lista PKs declaradas.", tuple(), _primary_keys),
    SQLTemplate("foreign_keys", "Chaves e relacionamentos", "Listar foreign keys", "Lista FKs declaradas.", tuple(), _foreign_keys),
    SQLTemplate("relationships_of_table", "Chaves e relacionamentos", "Relacionamentos de uma tabela", "Mostra FKs entrando e saindo.", ("schema", "table"), _relationships_of_table),
    SQLTemplate("referencing_table", "Chaves e relacionamentos", "Tabelas que referenciam uma tabela", "Mostra tabelas que apontam para a tabela informada.", ("schema", "table"), _referencing_table),
    SQLTemplate("referenced_by_table", "Chaves e relacionamentos", "Tabelas referenciadas por uma tabela", "Mostra tabelas apontadas pela tabela informada.", ("schema", "table"), _referenced_by_table),
    SQLTemplate("tables_without_pk", "Estrutura do banco", "Tabelas sem primary key", "Lista tabelas sem PK.", tuple(), _tables_without_pk),
    SQLTemplate("tables_without_fk", "Estrutura do banco", "Tabelas sem foreign key", "Lista tabelas sem FK de saida.", tuple(), _tables_without_fk),
    SQLTemplate("largest_tables", "Estrutura do banco", "Maiores tabelas por linhas", "Ordena tabelas por quantidade aproximada de linhas.", tuple(), _largest_tables),
    SQLTemplate("same_name_columns", "Busca de campos para de-para", "Colunas com mesmo nome em varias tabelas", "Ajuda a encontrar possiveis joins.", tuple(), _same_name_columns),
    SQLTemplate("identifier_candidates", "Busca de campos para de-para", "Possiveis identificadores por padrao", "Busca ID, COD, CPF, CNPJ, matricula e chave.", tuple(), _identifier_candidates),
    SQLTemplate("table_profile", "Migracao e de-para", "Perfil basico de uma tabela", "Conta linhas da tabela.", ("schema", "table"), _table_profile),
    SQLTemplate("distinct_values", "Qualidade e preenchimento", "Valores distintos de uma coluna", "Lista valores distintos limitados.", ("schema", "table", "column"), _distinct_values),
    SQLTemplate("null_percent", "Qualidade e preenchimento", "Percentual de nulos de uma coluna", "Calcula nulos e percentual.", ("schema", "table", "column"), _null_percent),
    SQLTemplate("intersection", "Validacao de relacionamento", "Validacao de intersecao entre duas colunas", "Conta valores da origem que aparecem no destino.", ("source_schema", "source_table", "source_column", "target_schema", "target_table", "target_column"), _intersection),
    SQLTemplate("orphans", "Validacao de relacionamento", "Registros orfaos entre duas tabelas", "Lista valores da origem sem correspondencia no destino.", ("source_schema", "source_table", "source_column", "target_schema", "target_table", "target_column"), _orphans),
    SQLTemplate("join_suggestion", "Validacao de relacionamento", "Sugestao de JOIN entre duas tabelas", "Gera SELECT com JOIN para validar relacionamento.", ("source_schema", "source_table", "source_column", "target_schema", "target_table", "target_column"), _join_suggestion),
    SQLTemplate("bridge_tables", "Migracao e de-para", "Possiveis tabelas ponte", "Tabelas com multiplas FKs.", tuple(), _bridge_tables),
    SQLTemplate("indexed_columns", "Chaves e relacionamentos", "Colunas com indice", "Lista colunas indexadas.", tuple(), _indexed_columns),
]


def templates_by_category() -> dict[str, list[SQLTemplate]]:
    grouped: dict[str, list[SQLTemplate]] = {}
    for template in TEMPLATES:
        grouped.setdefault(template.category, []).append(template)
    return grouped


def get_template(key: str) -> SQLTemplate:
    for template in TEMPLATES:
        if template.key == key:
            return template
    raise KeyError(key)
