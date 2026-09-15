from __future__ import annotations

from collections import Counter

import pandas as pd

from .db import quote_name
from .relationships import find_paths


def table_parts(table_key: str) -> tuple[str, str]:
    schema_name, table_name = table_key.split(".", 1)
    return schema_name, table_name


def path_table_sequence(path: list[dict]) -> list[str]:
    if not path:
        return []
    tables = [path[0]["from_table"]]
    tables.extend(step["to_table"] for step in path)
    return tables


def _alias(index: int) -> str:
    return f"t{index}"


def path_validation_sql(path: list[dict]) -> str:
    tables = path_table_sequence(path)
    if not tables:
        return ""

    base_schema, base_table = table_parts(tables[0])
    lines = [
        "SELECT TOP 100",
        "    *",
        f"FROM {quote_name(base_schema)}.{quote_name(base_table)} AS {_alias(0)}",
    ]

    aliases = {tables[0]: _alias(0)}
    for index, step in enumerate(path, start=1):
        to_table = step["to_table"]
        aliases[to_table] = _alias(index)
        to_schema, to_name = table_parts(to_table)

        from_alias = aliases[step["from_table"]]
        to_alias = aliases[to_table]
        source_table = f"{step.get('source_schema')}.{step.get('source_table')}"
        target_table = f"{step.get('target_schema')}.{step.get('target_table')}"

        if source_table == step["from_table"] and target_table == step["to_table"]:
            left_alias = from_alias
            left_column = step["source_column"]
            right_alias = to_alias
            right_column = step["target_column"]
        elif target_table == step["from_table"] and source_table == step["to_table"]:
            left_alias = from_alias
            left_column = step["target_column"]
            right_alias = to_alias
            right_column = step["source_column"]
        else:
            left_alias = from_alias
            left_column = step["source_column"]
            right_alias = to_alias
            right_column = step["target_column"]

        lines.append(
            f"JOIN {quote_name(to_schema)}.{quote_name(to_name)} AS {to_alias}"
            f" ON {left_alias}.{quote_name(left_column)} = {right_alias}.{quote_name(right_column)}"
        )
    return "\n".join(lines) + ";"


def describe_paths(
    real: pd.DataFrame,
    inferred: pd.DataFrame,
    source_table: str,
    target_table: str,
    max_depth: int,
    include_inferred: bool,
) -> list[dict]:
    raw_paths = find_paths(
        real,
        inferred,
        source_table,
        target_table,
        max_depth=max_depth,
        include_inferred=include_inferred,
    )
    described = []
    for index, path in enumerate(raw_paths, start=1):
        relationship_types = Counter(step["relationship_type"] for step in path)
        min_score = min((int(step.get("confidence_score") or 0) for step in path), default=0)
        described.append(
            {
                "path_id": index,
                "tables": " -> ".join(path_table_sequence(path)),
                "intermediate_tables": " -> ".join(path_table_sequence(path)[1:-1]),
                "steps": path,
                "relationship_types": ", ".join(f"{key}: {value}" for key, value in relationship_types.items()),
                "confidence_score": min_score,
                "confidence_label": "alta" if min_score >= 80 else "media" if min_score >= 55 else "baixa",
                "validation_sql": path_validation_sql(path),
            }
        )
    return described
