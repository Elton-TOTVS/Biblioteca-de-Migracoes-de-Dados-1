from __future__ import annotations

import re


BLOCKED_KEYWORDS = (
    "DELETE",
    "DROP",
    "UPDATE",
    "INSERT",
    "ALTER",
    "TRUNCATE",
    "MERGE",
    "CREATE",
    "EXEC",
    "EXECUTE",
    "GRANT",
    "REVOKE",
    "DENY",
    "BACKUP",
    "RESTORE",
    "DBCC",
    "USE",
)

BLOCKED_PATTERN = re.compile(
    r"\b("
    + "|".join(re.escape(keyword) for keyword in BLOCKED_KEYWORDS)
    + r")\b|(?:\bsp_)|(?:\bxp_)",
    re.IGNORECASE,
)
COMMENT_PATTERN = re.compile(r"(--[^\n]*|/\*.*?\*/)", re.IGNORECASE | re.DOTALL)


def detect_blocked_keywords(query: str) -> list[str]:
    matches = []
    for match in BLOCKED_PATTERN.finditer(query or ""):
        matches.append(match.group(0).upper())
    return sorted(set(matches))


def _strip_trailing_semicolon(query: str) -> str:
    return query.strip().rstrip(";").strip()


def _has_multiple_statements(query: str) -> bool:
    stripped = query.strip()
    if not stripped:
        return False
    without_trailing = stripped[:-1] if stripped.endswith(";") else stripped
    return ";" in without_trailing


def _comments_have_blocked_keywords(query: str) -> bool:
    for comment in COMMENT_PATTERN.findall(query or ""):
        if detect_blocked_keywords(comment):
            return True
    return False


def ensure_select_only(query: str) -> None:
    stripped = _strip_trailing_semicolon(query)
    if not stripped:
        raise ValueError("Informe uma consulta SELECT.")
    if not stripped.upper().startswith(("SELECT", "WITH")):
        raise ValueError("Somente consultas iniciadas por SELECT ou WITH sao permitidas.")


def validate_readonly_sql(query: str) -> tuple[bool, list[str]]:
    errors: list[str] = []
    if not (query or "").strip():
        return False, ["Informe uma consulta SQL."]

    if _has_multiple_statements(query):
        errors.append("Multiplos comandos separados por ponto e virgula nao sao permitidos.")

    blocked = detect_blocked_keywords(query)
    if blocked:
        errors.append("Comando bloqueado encontrado: " + ", ".join(blocked))

    if _comments_have_blocked_keywords(query):
        errors.append("Comentario contem comando bloqueado ou suspeito.")

    try:
        ensure_select_only(query)
    except ValueError as exc:
        errors.append(str(exc))

    return not errors, errors


def apply_row_limit(query: str, limit: int) -> str:
    limit = max(1, min(int(limit), 5000))
    stripped = _strip_trailing_semicolon(query)
    upper = stripped.upper()

    if upper.startswith("WITH"):
        return stripped
    if re.match(r"^\s*SELECT\s+(DISTINCT\s+)?TOP\s*\(", stripped, re.IGNORECASE):
        return stripped
    if re.match(r"^\s*SELECT\s+(DISTINCT\s+)?TOP\s+\d+", stripped, re.IGNORECASE):
        return stripped
    if re.match(r"^\s*SELECT\s+DISTINCT\b", stripped, re.IGNORECASE):
        return re.sub(r"^\s*SELECT\s+DISTINCT\b", f"SELECT DISTINCT TOP ({limit})", stripped, count=1, flags=re.IGNORECASE)
    return re.sub(r"^\s*SELECT\b", f"SELECT TOP ({limit})", stripped, count=1, flags=re.IGNORECASE)
