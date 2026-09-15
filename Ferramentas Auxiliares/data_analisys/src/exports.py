from __future__ import annotations

from io import BytesIO

import pandas as pd


def to_excel_bytes(sheets: dict[str, pd.DataFrame]) -> bytes:
    output = BytesIO()
    with pd.ExcelWriter(output, engine="openpyxl") as writer:
        for sheet_name, df in sheets.items():
            safe_name = sheet_name[:31] or "dados"
            df.to_excel(writer, index=False, sheet_name=safe_name)
    return output.getvalue()


def to_json_bytes(df: pd.DataFrame) -> bytes:
    return df.to_json(orient="records", force_ascii=False, indent=2).encode("utf-8")


def to_markdown_bytes(df: pd.DataFrame) -> bytes:
    return df.to_markdown(index=False).encode("utf-8")
