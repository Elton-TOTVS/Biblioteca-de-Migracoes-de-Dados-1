from __future__ import annotations

from dataclasses import dataclass
from time import perf_counter
from typing import Iterable

import pandas as pd

from .db import read_sql
from .sql_safety import apply_row_limit, validate_readonly_sql


@dataclass
class QueryResult:
    dataframe: pd.DataFrame
    elapsed_seconds: float
    row_count: int
    executed_sql: str


def execute_safe_query(conn, query: str, params: Iterable | None = None, limit: int = 500) -> QueryResult:
    ok, errors = validate_readonly_sql(query)
    if not ok:
        raise ValueError("\n".join(errors))

    limited_query = apply_row_limit(query, limit)
    start = perf_counter()
    df = read_sql(conn, limited_query, params=params)
    elapsed = perf_counter() - start
    if len(df) > limit:
        df = df.head(limit)
    return QueryResult(
        dataframe=df,
        elapsed_seconds=elapsed,
        row_count=len(df),
        executed_sql=limited_query,
    )
