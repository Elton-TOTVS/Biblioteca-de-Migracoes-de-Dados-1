from __future__ import annotations

import pandas as pd

from .db import qualified_name, quote_name, read_sql
from .security import mark_sensitive_columns


def load_sample_rows(
    conn,
    schema_name: str,
    table_name: str,
    limit: int = 100,
) -> pd.DataFrame:
    limit = max(1, min(int(limit), 1000))
    return read_sql(
        conn,
        f"SELECT TOP ({limit}) * FROM {qualified_name(schema_name, table_name)};",
    )


def profile_columns_for_table(
    conn,
    columns: pd.DataFrame,
    schema_name: str,
    table_name: str,
    sample_size: int = 50,
) -> pd.DataFrame:
    selected = columns[
        (columns["schema_name"] == schema_name) & (columns["table_name"] == table_name)
    ].copy()
    if selected.empty:
        return selected

    rows = []
    table_ref = qualified_name(schema_name, table_name)
    sample_size = max(1, min(int(sample_size), 200))

    for column in selected.to_dict("records"):
        col_ref = quote_name(column["column_name"])
        try:
            stats = read_sql(
                conn,
                f"""
                SELECT
                    COUNT_BIG(1) AS total_rows,
                    SUM(CASE WHEN {col_ref} IS NULL THEN 1 ELSE 0 END) AS null_rows,
                    COUNT(DISTINCT {col_ref}) AS distinct_values,
                    MIN(CAST({col_ref} AS nvarchar(4000))) AS min_value,
                    MAX(CAST({col_ref} AS nvarchar(4000))) AS max_value,
                    MIN(LEN(CAST({col_ref} AS nvarchar(4000)))) AS min_length,
                    MAX(LEN(CAST({col_ref} AS nvarchar(4000)))) AS max_length_text
                FROM {table_ref};
                """,
            ).iloc[0].to_dict()
            examples = read_sql(
                conn,
                f"""
                SELECT DISTINCT TOP ({sample_size})
                    CAST({col_ref} AS nvarchar(4000)) AS example_value
                FROM {table_ref}
                WHERE {col_ref} IS NOT NULL
                ORDER BY CAST({col_ref} AS nvarchar(4000));
                """,
            )["example_value"].dropna().astype(str).tolist()
            total = int(stats.get("total_rows") or 0)
            nulls = int(stats.get("null_rows") or 0)
            stats["filled_rows"] = total - nulls
            stats["filled_percent"] = round(((total - nulls) / total) * 100, 2) if total else 0
            stats["examples"] = ", ".join(examples[:5])
            stats["profile_error"] = ""
        except Exception as exc:
            stats = {
                "total_rows": None,
                "null_rows": None,
                "filled_rows": None,
                "filled_percent": None,
                "distinct_values": None,
                "min_value": None,
                "max_value": None,
                "min_length": None,
                "max_length_text": None,
                "examples": "",
                "profile_error": str(exc),
            }
        rows.append({**column, **stats})

    return mark_sensitive_columns(pd.DataFrame(rows))
