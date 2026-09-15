from __future__ import annotations

import re
from contextlib import contextmanager
from typing import Iterable

import pandas as pd
import pyodbc

from .config import ConnectionConfig


FORBIDDEN_SQL = re.compile(
    r"\b(DELETE|DROP|TRUNCATE|ALTER|UPDATE|INSERT|MERGE|CREATE|EXEC|EXECUTE|GRANT|REVOKE|DENY|BACKUP|RESTORE|DBCC|USE)\b|(?:\bsp_)|(?:\bxp_)",
    re.IGNORECASE,
)


def assert_read_only_sql(sql: str) -> None:
    if FORBIDDEN_SQL.search(sql):
        raise ValueError("SQL bloqueado: somente consultas SELECT sao permitidas.")
    stripped = sql.strip().lstrip("(").strip()
    if not stripped.upper().startswith(("SELECT", "WITH")):
        raise ValueError("SQL bloqueado: a consulta deve iniciar com SELECT ou WITH.")


def quote_name(identifier: str) -> str:
    if identifier is None or identifier == "" or "\x00" in identifier:
        raise ValueError("Identificador invalido.")
    return "[" + identifier.replace("]", "]]") + "]"


def qualified_name(schema_name: str, table_name: str) -> str:
    return f"{quote_name(schema_name)}.{quote_name(table_name)}"


@contextmanager
def connect(config: ConnectionConfig):
    conn = pyodbc.connect(config.connection_string(), autocommit=True)
    try:
        yield conn
    finally:
        conn.close()


def read_sql(conn, sql: str, params: Iterable | None = None) -> pd.DataFrame:
    assert_read_only_sql(sql)
    return pd.read_sql(sql, conn, params=list(params or []))
