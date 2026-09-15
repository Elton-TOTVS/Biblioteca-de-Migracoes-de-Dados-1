from __future__ import annotations

import pandas as pd

from .db import qualified_name, quote_name, read_sql


def load_tables(conn, schemas: list[str] | None = None) -> pd.DataFrame:
    where = ""
    params: list[str] = []
    if schemas:
        where = "AND s.name IN ({})".format(",".join("?" for _ in schemas))
        params.extend(schemas)

    return read_sql(
        conn,
        f"""
        SELECT
            s.name AS schema_name,
            t.name AS table_name,
            SUM(CASE WHEN p.index_id IN (0, 1) THEN p.rows ELSE 0 END) AS row_count
        FROM sys.tables t
        JOIN sys.schemas s ON s.schema_id = t.schema_id
        LEFT JOIN sys.partitions p ON p.object_id = t.object_id
        WHERE t.is_ms_shipped = 0
          {where}
        GROUP BY s.name, t.name
        ORDER BY s.name, t.name;
        """,
        params,
    )


def load_columns(conn, schemas: list[str] | None = None) -> pd.DataFrame:
    where = ""
    params: list[str] = []
    if schemas:
        where = "AND s.name IN ({})".format(",".join("?" for _ in schemas))
        params.extend(schemas)

    return read_sql(
        conn,
        f"""
        WITH pk_columns AS (
            SELECT ic.object_id, ic.column_id
            FROM sys.indexes i
            JOIN sys.index_columns ic
              ON ic.object_id = i.object_id AND ic.index_id = i.index_id
            WHERE i.is_primary_key = 1
        ),
        unique_columns AS (
            SELECT ic.object_id, ic.column_id
            FROM sys.indexes i
            JOIN sys.index_columns ic
              ON ic.object_id = i.object_id AND ic.index_id = i.index_id
            WHERE i.is_unique = 1
        ),
        indexed_columns AS (
            SELECT DISTINCT ic.object_id, ic.column_id
            FROM sys.index_columns ic
            JOIN sys.indexes i
              ON i.object_id = ic.object_id AND i.index_id = ic.index_id
            WHERE i.is_hypothetical = 0
        ),
        fk_columns AS (
            SELECT parent_object_id AS object_id, parent_column_id AS column_id
            FROM sys.foreign_key_columns
        )
        SELECT
            s.name AS schema_name,
            t.name AS table_name,
            c.name AS column_name,
            ty.name AS data_type,
            c.max_length,
            c.precision,
            c.scale,
            c.is_nullable,
            c.column_id,
            CAST(CASE WHEN pk.object_id IS NULL THEN 0 ELSE 1 END AS bit) AS is_primary_key,
            CAST(CASE WHEN fk.object_id IS NULL THEN 0 ELSE 1 END AS bit) AS is_foreign_key,
            CAST(CASE WHEN uq.object_id IS NULL THEN 0 ELSE 1 END AS bit) AS is_unique_indexed,
            CAST(CASE WHEN ix.object_id IS NULL THEN 0 ELSE 1 END AS bit) AS is_indexed
        FROM sys.tables t
        JOIN sys.schemas s ON s.schema_id = t.schema_id
        JOIN sys.columns c ON c.object_id = t.object_id
        JOIN sys.types ty ON ty.user_type_id = c.user_type_id
        LEFT JOIN pk_columns pk ON pk.object_id = c.object_id AND pk.column_id = c.column_id
        LEFT JOIN fk_columns fk ON fk.object_id = c.object_id AND fk.column_id = c.column_id
        LEFT JOIN unique_columns uq ON uq.object_id = c.object_id AND uq.column_id = c.column_id
        LEFT JOIN indexed_columns ix ON ix.object_id = c.object_id AND ix.column_id = c.column_id
        WHERE t.is_ms_shipped = 0
          {where}
        ORDER BY s.name, t.name, c.column_id;
        """,
        params,
    )


def load_foreign_keys(conn, schemas: list[str] | None = None) -> pd.DataFrame:
    where = ""
    params: list[str] = []
    if schemas:
        where = "AND ps.name IN ({})".format(",".join("?" for _ in schemas))
        params.extend(schemas)

    return read_sql(
        conn,
        f"""
        SELECT
            fk.name AS fk_name,
            ps.name AS source_schema,
            pt.name AS source_table,
            pc.name AS source_column,
            rs.name AS target_schema,
            rt.name AS target_table,
            rc.name AS target_column,
            fkc.constraint_column_id AS ordinal,
            fk.is_disabled,
            fk.is_not_trusted
        FROM sys.foreign_keys fk
        JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
        JOIN sys.tables pt ON pt.object_id = fk.parent_object_id
        JOIN sys.schemas ps ON ps.schema_id = pt.schema_id
        JOIN sys.columns pc ON pc.object_id = pt.object_id AND pc.column_id = fkc.parent_column_id
        JOIN sys.tables rt ON rt.object_id = fk.referenced_object_id
        JOIN sys.schemas rs ON rs.schema_id = rt.schema_id
        JOIN sys.columns rc ON rc.object_id = rt.object_id AND rc.column_id = fkc.referenced_column_id
        WHERE pt.is_ms_shipped = 0
          AND rt.is_ms_shipped = 0
          {where}
        ORDER BY ps.name, pt.name, fk.name, fkc.constraint_column_id;
        """,
        params,
    )


def profile_column(conn, schema_name: str, table_name: str, column_name: str, sample_size: int = 100) -> dict:
    table_ref = qualified_name(schema_name, table_name)
    column_ref = quote_name(column_name)
    sample_size = max(1, min(int(sample_size), 500))

    stats = read_sql(
        conn,
        f"""
        SELECT
            COUNT_BIG(1) AS total_rows,
            SUM(CASE WHEN {column_ref} IS NULL THEN 1 ELSE 0 END) AS null_rows,
            COUNT(DISTINCT {column_ref}) AS distinct_values
        FROM {table_ref};
        """,
    ).iloc[0].to_dict()

    values = read_sql(
        conn,
        f"""
        SELECT DISTINCT TOP ({sample_size}) CAST({column_ref} AS nvarchar(4000)) AS sample_value
        FROM {table_ref}
        WHERE {column_ref} IS NOT NULL
        ORDER BY CAST({column_ref} AS nvarchar(4000));
        """,
    )["sample_value"].dropna().astype(str).tolist()
    stats["sample_values"] = values
    return stats


def build_metadata(conn, schemas: list[str] | None = None) -> dict[str, pd.DataFrame]:
    return {
        "tables": load_tables(conn, schemas),
        "columns": load_columns(conn, schemas),
        "foreign_keys": load_foreign_keys(conn, schemas),
    }
