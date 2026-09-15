from __future__ import annotations

import re

import pandas as pd


SENSITIVE_NAME = re.compile(
    r"(senha|password|cpf|cnpj|rg|email|e_mail|telefone|celular|endereco|cep|token|secret|chave)",
    re.IGNORECASE,
)


def is_sensitive_column(column_name: str) -> bool:
    return bool(SENSITIVE_NAME.search(column_name or ""))


def mask_value(value):
    if pd.isna(value):
        return value
    text = str(value)
    if len(text) <= 4:
        return "*" * len(text)
    return text[:2] + "*" * max(len(text) - 4, 1) + text[-2:]


def mask_sensitive_dataframe(df: pd.DataFrame, enabled: bool = True) -> pd.DataFrame:
    if not enabled or df.empty:
        return df
    masked = df.copy()
    for column in masked.columns:
        if is_sensitive_column(str(column)):
            masked[column] = masked[column].map(mask_value)
    return masked


def mark_sensitive_columns(columns: pd.DataFrame) -> pd.DataFrame:
    if columns.empty:
        return columns
    output = columns.copy()
    output["is_potentially_sensitive"] = output["column_name"].map(is_sensitive_column)
    return output
