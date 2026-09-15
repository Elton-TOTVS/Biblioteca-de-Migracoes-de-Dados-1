import os
import re
import queue
import threading
import traceback
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
import tkinter as tk
from tkinter import filedialog, messagebox, simpledialog, ttk

import pandas as pd
import pyodbc
from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import URL
from sqlalchemy.types import NVARCHAR

load_dotenv()

APP_TITLE = "Conversor BT -> SQL Server"

REQUIRED_TABLES = {
    "EVE", "EPG", "SEP", "DEP", "CAR", "CBA", "EMP", "SIN", "AVI", "PAE",
    "PVE", "AGE", "MUN", "UFD", "BAN", "DRM", "EBC", "EED", "EFP", "EPR",
    "ERF", "EST", "FOL", "FPG", "GPS", "HOR", "LOT", "TLI", "LIC", "REC",
    "EFO", "TRC", "TFO", "VID", "TB_MOT_DES", "PAF", "FER", "IND", "EPC",
    "ASO", "ESO", "PRS"
}

DECODE_RE = re.compile(r"\$([A-Fa-f0-9]{2})")
SYSTEM_DATABASES = {"master", "model", "msdb", "tempdb"}


def decode_special_characters(value):
    if isinstance(value, str) and "$" in value:
        return DECODE_RE.sub(
            lambda match: bytes.fromhex(match.group(1)).decode("latin-1"),
            value,
        )
    return value


def quote_identifier(name: str) -> str:
    """Escapa identificadores para uso entre colchetes no SQL Server."""
    return "[" + str(name).replace("]", "]]") + "]"


def odbc_value(value: str) -> str:
    """Protege valores de connection string que possam conter ';' ou '}'."""
    return "{" + str(value).replace("}", "}}") + "}"


def validate_database_name(name: str) -> str:
    name = (name or "").strip()
    if not name:
        raise ValueError("Há arquivo sem banco de destino informado.")
    if len(name) > 128:
        raise ValueError(f"Nome de banco maior que 128 caracteres: {name}")
    if any(ord(ch) < 32 for ch in name):
        raise ValueError(f"Nome de banco contém caractere inválido: {name!r}")
    if name.lower() in SYSTEM_DATABASES:
        raise ValueError(f"O banco de sistema '{name}' não pode ser usado como destino.")
    return name


def make_default_database_name(bt_path: str) -> str:
    base = Path(bt_path).stem.upper()
    base = re.sub(r"[^A-Z0-9_]+", "_", base).strip("_") or "BT"
    return f"MIGRA_{base}"[:128]


def make_unique_fields(fields):
    """Garante nomes não vazios e únicos, inclusive ignorando caixa."""
    result = []
    used = set()

    for index, field in enumerate(fields, start=1):
        base = (field or "").strip() or f"COLUNA_{index}"
        candidate = base
        suffix = 2
        while candidate.lower() in used:
            candidate = f"{base}_{suffix}"
            suffix += 1
        used.add(candidate.lower())
        result.append(candidate)

    return result


@dataclass(frozen=True)
class SqlConfig:
    server: str
    auth_mode: str  # "windows" ou "sql"
    driver: str
    username: str = ""
    password: str = ""

    def connection_string(self, database="master"):
        server = self.server.strip()
        if not server:
            raise ValueError("Servidor SQL Server não informado.")
        if not self.driver.strip():
            raise ValueError("Driver ODBC não informado.")

        parts = [
            f"DRIVER={odbc_value(self.driver)}",
            f"SERVER={odbc_value(server)}",
            f"DATABASE={odbc_value(database)}",
        ]

        if self.auth_mode == "windows":
            parts.append("Trusted_Connection=yes")
        else:
            if not self.username:
                raise ValueError("Usuário SQL Server não informado.")
            parts.extend([
                f"UID={odbc_value(self.username)}",
                f"PWD={odbc_value(self.password)}",
            ])

        parts.extend([
            "Encrypt=no",
            "TrustServerCertificate=yes",
            "LoginTimeout=30",
        ])
        return ";".join(parts) + ";"


class SqlServerManager:
    def __init__(self, config: SqlConfig, log_callback=None):
        self.config = config
        self.log = log_callback or (lambda _msg: None)
        self.engines = {}
        self.schema_cache = {}

    def connect(self, database="master", autocommit=False):
        return pyodbc.connect(
            self.config.connection_string(database),
            autocommit=autocommit,
        )

    def test_connection(self):
        with self.connect("master") as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT @@SERVERNAME, SUSER_SNAME(), DB_NAME()")
            return cursor.fetchone()

    def database_exists(self, database):
        with self.connect("master") as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM sys.databases WHERE name = ?", database)
            return cursor.fetchone()[0] > 0

    def create_database(self, database):
        database = validate_database_name(database)
        with self.connect("master", autocommit=True) as conn:
            conn.cursor().execute(f"CREATE DATABASE {quote_identifier(database)}")

    def recreate_database(self, database):
        database = validate_database_name(database)
        db = quote_identifier(database)
        self.dispose_engine(database)
        with self.connect("master", autocommit=True) as conn:
            cursor = conn.cursor()
            cursor.execute(f"ALTER DATABASE {db} SET SINGLE_USER WITH ROLLBACK IMMEDIATE")
            cursor.execute(f"DROP DATABASE {db}")
            cursor.execute(f"CREATE DATABASE {db}")

    def prepare_database(self, database, recreate=False):
        database = validate_database_name(database)
        exists = self.database_exists(database)

        if recreate and exists:
            self.log(f"[DB] Recriando banco {database}...")
            self.recreate_database(database)
            self.clear_schema_cache(database)
        elif not exists:
            self.log(f"[DB] Criando banco {database}...")
            self.create_database(database)
            self.clear_schema_cache(database)
        else:
            self.log(f"[DB] Usando banco existente {database} e acrescentando dados.")

    def get_engine(self, database):
        if database not in self.engines:
            url = URL.create(
                "mssql+pyodbc",
                query={"odbc_connect": self.config.connection_string(database)},
            )
            self.engines[database] = create_engine(
                url,
                fast_executemany=True,
                pool_pre_ping=True,
            )
        return self.engines[database]

    def dispose_engine(self, database):
        engine = self.engines.pop(database, None)
        if engine is not None:
            engine.dispose()

    def dispose_all(self):
        for engine in self.engines.values():
            engine.dispose()
        self.engines.clear()

    def clear_schema_cache(self, database):
        for key in [key for key in self.schema_cache if key[0] == database]:
            self.schema_cache.pop(key, None)

    def _load_table_columns(self, database, table):
        key = (database, table)
        if key in self.schema_cache:
            return self.schema_cache[key]

        engine = self.get_engine(database)
        inspector = inspect(engine)
        if not inspector.has_table(table, schema="dbo"):
            self.schema_cache[key] = None
            return None

        columns = [col["name"] for col in inspector.get_columns(table, schema="dbo")]
        self.schema_cache[key] = columns
        return columns

    def _add_missing_columns(self, database, table, missing_columns):
        if not missing_columns:
            return

        engine = self.get_engine(database)
        table_sql = f"dbo.{quote_identifier(table)}"
        with engine.begin() as conn:
            for column in missing_columns:
                conn.execute(text(
                    f"ALTER TABLE {table_sql} ADD {quote_identifier(column)} NVARCHAR(MAX) NULL"
                ))

    def append_dataframe(self, database, table, df, sql_chunksize=1000):
        if df.empty:
            return 0

        engine = self.get_engine(database)
        key = (database, table)
        existing_columns = self._load_table_columns(database, table)

        # Primeira ocorrência da tabela: cria com todas as colunas como NVARCHAR(MAX).
        if existing_columns is None:
            dtype_map = {column: NVARCHAR(length=None) for column in df.columns}
            df.to_sql(
                table,
                engine,
                schema="dbo",
                if_exists="fail",
                index=False,
                chunksize=sql_chunksize,
                dtype=dtype_map,
            )
            self.schema_cache[key] = list(df.columns)
            return len(df)

        # Alinha diferenças de maiúsculas/minúsculas e acrescenta novas colunas.
        canonical = {column.lower(): column for column in existing_columns}
        rename_map = {
            column: canonical[column.lower()]
            for column in df.columns
            if column.lower() in canonical and column != canonical[column.lower()]
        }
        if rename_map:
            df = df.rename(columns=rename_map)

        missing = [
            column for column in df.columns
            if column.lower() not in canonical
        ]
        if missing:
            self.log(
                f"[SCHEMA] {database}.dbo.{table}: adicionando colunas "
                + ", ".join(missing)
            )
            self._add_missing_columns(database, table, missing)
            existing_columns = existing_columns + missing
            self.schema_cache[key] = existing_columns

        df.to_sql(
            table,
            engine,
            schema="dbo",
            if_exists="append",
            index=False,
            chunksize=sql_chunksize,
        )
        return len(df)


class BtFileImporter:
    def __init__(
        self,
        sql_manager: SqlServerManager,
        database: str,
        batch_size=5000,
        only_required_tables=True,
        stop_event=None,
        log_callback=None,
    ):
        self.sql = sql_manager
        self.database = database
        self.batch_size = max(100, int(batch_size))
        self.sql_chunksize = min(1000, self.batch_size)
        self.only_required_tables = only_required_tables
        self.stop_event = stop_event or threading.Event()
        self.log = log_callback or (lambda _msg: None)

    def table_is_allowed(self, table):
        return (not self.only_required_tables) or table in REQUIRED_TABLES

    @staticmethod
    def normalize_row(parts, field_count):
        # Muitos exports terminam a linha com '|'. Remove apenas excedentes vazios finais.
        while len(parts) > field_count and parts and parts[-1] == "":
            parts.pop()

        if len(parts) < field_count:
            parts.extend([None] * (field_count - len(parts)))
            return parts, True

        if len(parts) > field_count:
            return parts[:field_count], True

        return parts, False

    @staticmethod
    def build_dataframe(fields, rows):
        df = pd.DataFrame(rows, columns=fields, dtype=object)

        for column in df.columns:
            df[column] = df[column].map(decode_special_characters)

        # Mantém '@' e string vazia como NULL, sem remover linhas ou colunas.
        # Linhas integralmente nulas continuam no DataFrame e são enviadas ao SQL Server.
        df = df.replace({"@": None, "": None})
        return df

    def import_file(self, bt_file_path):
        file_name = Path(bt_file_path).name
        table_totals = defaultdict(int)
        encountered = set()
        malformed_rows = 0

        current_table = None
        current_fields = None
        batch = []

        def flush_batch():
            nonlocal batch
            if not current_table or not current_fields or not batch:
                batch = []
                return
            if not self.table_is_allowed(current_table):
                batch = []
                return

            df = self.build_dataframe(current_fields, batch)
            batch = []
            if df.empty:
                return

            inserted = self.sql.append_dataframe(
                self.database,
                current_table,
                df,
                sql_chunksize=self.sql_chunksize,
            )
            table_totals[current_table] += inserted

        with open(bt_file_path, "r", encoding="ISO-8859-1", errors="replace") as bt_file:
            for line_number, raw_line in enumerate(bt_file, start=1):
                if self.stop_event.is_set():
                    flush_batch()
                    raise InterruptedError("Processamento cancelado pelo usuário.")

                line = raw_line.rstrip("\r\n")
                marker = line.strip()
                if not marker:
                    continue

                if marker.startswith("[") and marker.endswith("]"):
                    content = marker[1:-1]

                    # Linha de definição dos campos: [CODIGO:s;NOME:s;...]
                    if current_table and current_fields is None and (":" in content or ";" in content):
                        raw_fields = content.split(";")
                        current_fields = make_unique_fields([
                            field.split(":", 1)[0] for field in raw_fields
                        ])
                        continue

                    # Novo bloco/tabela: [EPG], [EMP], etc.
                    flush_batch()
                    current_table = content.strip()
                    current_fields = None
                    batch = []
                    if current_table:
                        encountered.add(current_table)
                    continue

                if not current_table or not current_fields or not self.table_is_allowed(current_table):
                    continue

                parts, malformed = self.normalize_row(line.split("|"), len(current_fields))
                malformed_rows += int(malformed)
                batch.append(parts)

                if len(batch) >= self.batch_size:
                    flush_batch()

        flush_batch()

        if malformed_rows:
            self.log(
                f"[AVISO] {file_name}: {malformed_rows} linha(s) tinham quantidade de campos "
                "diferente do cabeçalho e foram ajustadas."
            )

        return dict(table_totals), encountered


class BtSqlApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title(APP_TITLE)
        self.geometry("1180x800")
        self.minsize(980, 680)

        self.ui_queue = queue.Queue()
        self.stop_event = threading.Event()
        self.worker_thread = None
        self.bt_files = []

        self._create_variables()
        self._create_widgets()
        self._apply_auth_state()
        self.after(100, self._process_ui_queue)

    def _create_variables(self):
        drivers = pyodbc.drivers()
        sql_drivers = [driver for driver in drivers if "SQL Server" in driver]
        preferred = next(
            (d for d in ["ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server"] if d in sql_drivers),
            sql_drivers[-1] if sql_drivers else "ODBC Driver 18 for SQL Server",
        )

        self.server_var = tk.StringVar(value=os.getenv("DB_SERVER", "localhost"))
        self.auth_var = tk.StringVar(value="Windows")
        self.user_var = tk.StringVar(value=os.getenv("DB_USER", ""))
        self.password_var = tk.StringVar(value=os.getenv("DB_PASSWORD", ""))
        self.driver_var = tk.StringVar(value=preferred)
        self.folder_var = tk.StringVar()
        self.recursive_var = tk.BooleanVar(value=False)
        self.recreate_var = tk.BooleanVar(value=True)
        self.only_required_var = tk.BooleanVar(value=True)
        self.batch_size_var = tk.IntVar(value=5000)
        self.status_var = tk.StringVar(value="Pronto")
        self.progress_var = tk.DoubleVar(value=0)

    def _create_widgets(self):
        root = ttk.Frame(self, padding=10)
        root.pack(fill="both", expand=True)
        root.columnconfigure(0, weight=1)
        root.rowconfigure(2, weight=1)
        root.rowconfigure(4, weight=1)

        connection = ttk.LabelFrame(root, text="1. Conexão SQL Server", padding=10)
        connection.grid(row=0, column=0, sticky="ew")
        for col in range(8):
            connection.columnconfigure(col, weight=1 if col in (1, 3, 5) else 0)

        ttk.Label(connection, text="Servidor:").grid(row=0, column=0, sticky="w")
        ttk.Entry(connection, textvariable=self.server_var).grid(row=0, column=1, sticky="ew", padx=(5, 12))

        ttk.Label(connection, text="Autenticação:").grid(row=0, column=2, sticky="w")
        auth_combo = ttk.Combobox(
            connection,
            textvariable=self.auth_var,
            values=["Windows", "SQL Server"],
            state="readonly",
            width=15,
        )
        auth_combo.grid(row=0, column=3, sticky="ew", padx=(5, 12))
        auth_combo.bind("<<ComboboxSelected>>", lambda _e: self._apply_auth_state())

        ttk.Label(connection, text="Driver:").grid(row=0, column=4, sticky="w")
        self.driver_combo = ttk.Combobox(
            connection,
            textvariable=self.driver_var,
            values=[driver for driver in pyodbc.drivers() if "SQL Server" in driver],
            state="readonly" if any("SQL Server" in driver for driver in pyodbc.drivers()) else "normal",
        )
        self.driver_combo.grid(row=0, column=5, sticky="ew", padx=(5, 12))

        self.test_button = ttk.Button(connection, text="Testar conexão", command=self._test_connection)
        self.test_button.grid(row=0, column=6, columnspan=2, sticky="ew")

        ttk.Label(connection, text="Usuário:").grid(row=1, column=0, sticky="w", pady=(8, 0))
        self.user_entry = ttk.Entry(connection, textvariable=self.user_var)
        self.user_entry.grid(row=1, column=1, sticky="ew", padx=(5, 12), pady=(8, 0))

        ttk.Label(connection, text="Senha:").grid(row=1, column=2, sticky="w", pady=(8, 0))
        self.password_entry = ttk.Entry(connection, textvariable=self.password_var, show="*")
        self.password_entry.grid(row=1, column=3, sticky="ew", padx=(5, 12), pady=(8, 0))

        ttk.Label(
            connection,
            text="Windows: use localhost, .\\SQLEXPRESS ou outro servidor com autenticação integrada.",
        ).grid(row=1, column=4, columnspan=4, sticky="w", pady=(8, 0))

        files_frame = ttk.LabelFrame(root, text="2. Arquivos .bt e DE -> PARA", padding=10)
        files_frame.grid(row=1, column=0, sticky="ew", pady=(10, 0))
        files_frame.columnconfigure(1, weight=1)

        ttk.Label(files_frame, text="Pasta:").grid(row=0, column=0, sticky="w")
        ttk.Entry(files_frame, textvariable=self.folder_var).grid(row=0, column=1, sticky="ew", padx=5)
        ttk.Button(files_frame, text="Selecionar...", command=self._choose_folder).grid(row=0, column=2, padx=(0, 5))
        ttk.Button(files_frame, text="Ler .bt", command=self._scan_files).grid(row=0, column=3)
        ttk.Checkbutton(files_frame, text="Incluir subpastas", variable=self.recursive_var).grid(row=0, column=4, padx=(10, 0))

        mapping_frame = ttk.Frame(root)
        mapping_frame.grid(row=2, column=0, sticky="nsew", pady=(8, 0))
        mapping_frame.columnconfigure(0, weight=1)
        mapping_frame.rowconfigure(0, weight=1)

        self.tree = ttk.Treeview(
            mapping_frame,
            columns=("arquivo", "destino", "status"),
            show="headings",
            selectmode="extended",
        )
        self.tree.heading("arquivo", text="Arquivo .bt")
        self.tree.heading("destino", text="Banco de destino")
        self.tree.heading("status", text="Status")
        self.tree.column("arquivo", width=430, anchor="w")
        self.tree.column("destino", width=300, anchor="w")
        self.tree.column("status", width=180, anchor="w")
        self.tree.grid(row=0, column=0, sticky="nsew")
        self.tree.bind("<Double-1>", self._edit_mapping_double_click)

        scrollbar = ttk.Scrollbar(mapping_frame, orient="vertical", command=self.tree.yview)
        scrollbar.grid(row=0, column=1, sticky="ns")
        self.tree.configure(yscrollcommand=scrollbar.set)

        mapping_actions = ttk.Frame(root)
        mapping_actions.grid(row=3, column=0, sticky="ew", pady=(8, 0))

        ttk.Button(mapping_actions, text="AUTO", command=self._auto_map).grid(row=0, column=0, padx=(0, 5))
        ttk.Button(mapping_actions, text="Limpar DE -> PARA", command=self._clear_map).grid(row=0, column=1)

        options_log = ttk.Panedwindow(root, orient="vertical")
        options_log.grid(row=4, column=0, sticky="nsew", pady=(10, 0))

        options = ttk.LabelFrame(options_log, text="3. Processamento", padding=10)
        options.columnconfigure(5, weight=1)
        options_log.add(options, weight=0)

        ttk.Checkbutton(
            options,
            text="Recriar bancos de destino antes de importar",
            variable=self.recreate_var,
        ).grid(row=0, column=0, columnspan=2, sticky="w")
        ttk.Checkbutton(
            options,
            text="Somente tabelas configuradas no layout atual",
            variable=self.only_required_var,
        ).grid(row=0, column=2, columnspan=2, sticky="w", padx=(20, 0))

        ttk.Label(options, text="Linhas por lote:").grid(row=0, column=4, sticky="e", padx=(20, 5))
        ttk.Spinbox(options, from_=500, to=50000, increment=500, textvariable=self.batch_size_var, width=10).grid(row=0, column=5, sticky="w")

        ttk.Label(
            options,
            text=(
                "Quando vários arquivos apontarem para o mesmo banco, as tabelas de mesmo nome serão acrescentadas "
                "na mesma tabela de destino. Ex.: TESLA.bt + SIST.bt -> EST => EPG + EPG -> EST.dbo.EPG."
            ),
            wraplength=1050,
        ).grid(row=1, column=0, columnspan=6, sticky="w", pady=(8, 0))

        log_frame = ttk.LabelFrame(options_log, text="Log", padding=6)
        log_frame.columnconfigure(0, weight=1)
        log_frame.rowconfigure(0, weight=1)
        options_log.add(log_frame, weight=1)

        self.log_text = tk.Text(log_frame, height=12, wrap="none", state="disabled")
        self.log_text.grid(row=0, column=0, sticky="nsew")
        log_scroll = ttk.Scrollbar(log_frame, orient="vertical", command=self.log_text.yview)
        log_scroll.grid(row=0, column=1, sticky="ns")
        self.log_text.configure(yscrollcommand=log_scroll.set)

        footer = ttk.Frame(root)
        footer.grid(row=5, column=0, sticky="ew", pady=(10, 0))
        footer.columnconfigure(0, weight=1)

        self.progress = ttk.Progressbar(footer, variable=self.progress_var, maximum=100)
        self.progress.grid(row=0, column=0, sticky="ew", padx=(0, 10))
        ttk.Label(footer, textvariable=self.status_var, width=32).grid(row=0, column=1, sticky="w")

        self.start_button = ttk.Button(footer, text="INICIAR CONVERSÃO", command=self._start_processing)
        self.start_button.grid(row=0, column=2, padx=(10, 5))
        self.stop_button = ttk.Button(footer, text="Cancelar", command=self._cancel_processing, state="disabled")
        self.stop_button.grid(row=0, column=3)

    def _apply_auth_state(self):
        sql_auth = self.auth_var.get() == "SQL Server"
        state = "normal" if sql_auth else "disabled"
        self.user_entry.configure(state=state)
        self.password_entry.configure(state=state)

    def _get_sql_config(self):
        return SqlConfig(
            server=self.server_var.get().strip(),
            auth_mode="sql" if self.auth_var.get() == "SQL Server" else "windows",
            driver=self.driver_var.get().strip(),
            username=self.user_var.get(),
            password=self.password_var.get(),
        )

    def _choose_folder(self):
        folder = filedialog.askdirectory(title="Selecione a pasta com os arquivos .bt")
        if folder:
            self.folder_var.set(folder)
            self._scan_files()

    def _scan_files(self):
        folder = self.folder_var.get().strip()
        if not folder or not os.path.isdir(folder):
            messagebox.showwarning(APP_TITLE, "Informe uma pasta válida.")
            return

        candidates = Path(folder).rglob("*") if self.recursive_var.get() else Path(folder).iterdir()
        self.bt_files = sorted(
            str(path) for path in candidates
            if path.is_file() and path.suffix.lower() == ".bt"
        )

        for item in self.tree.get_children():
            self.tree.delete(item)

        for path in self.bt_files:
            relative = os.path.relpath(path, folder)
            self.tree.insert(
                "",
                "end",
                iid=path,
                values=(relative, make_default_database_name(path), "Pendente"),
            )

        self.status_var.set(f"{len(self.bt_files)} arquivo(s) encontrado(s)")
        self._append_log(f"[ARQUIVOS] Encontrados {len(self.bt_files)} arquivo(s) .bt em {folder}")

        if not self.bt_files:
            messagebox.showinfo(APP_TITLE, "Nenhum arquivo .bt foi encontrado na pasta informada.")

    def _edit_mapping_double_click(self, event):
        region = self.tree.identify("region", event.x, event.y)
        column = self.tree.identify_column(event.x)
        item = self.tree.identify_row(event.y)
        if region != "cell" or column != "#2" or not item:
            return

        current = self.tree.set(item, "destino")
        new_value = simpledialog.askstring(
            APP_TITLE,
            f"Banco de destino para {Path(item).name}:",
            initialvalue=current,
            parent=self,
        )
        if new_value is not None:
            try:
                new_value = validate_database_name(new_value)
            except ValueError as exc:
                messagebox.showerror(APP_TITLE, str(exc))
                return
            self.tree.set(item, "destino", new_value)

    def _auto_map(self):
        if not self.tree.get_children():
            messagebox.showinfo(APP_TITLE, "Leia uma pasta com arquivos .bt antes de usar o AUTO.")
            return

        pattern = simpledialog.askstring(
            APP_TITLE,
            "Informe o padrão do banco de destino.\n\n"
            "Use [ARQUIVO] onde deseja inserir o nome do arquivo sem a extensão .bt.\n"
            "Se não usar [ARQUIVO], todos os arquivos serão enviados para o mesmo banco.\n\n"
            "Exemplo individual: ZMIGRA_TESTE_[ARQUIVO]_PRD2\n"
            "Exemplo único: ZMIGRA_TESTE_PRD2",
            initialvalue="MIGRA_[ARQUIVO]",
            parent=self,
        )
        if pattern is None:
            return

        pattern = pattern.strip()
        if not pattern:
            messagebox.showwarning(
                APP_TITLE,
                "Informe um nome ou padrão para o banco de destino.",
            )
            return

        for item in self.tree.get_children():
            file_base = Path(item).stem.upper()
            file_base = re.sub(r"[^A-Z0-9_]+", "_", file_base).strip("_") or "BT"
            destination = pattern.replace("[ARQUIVO]", file_base) if "[ARQUIVO]" in pattern else pattern
            try:
                destination = validate_database_name(destination)
            except ValueError as exc:
                messagebox.showerror(
                    APP_TITLE,
                    f"Padrão inválido para o arquivo {Path(item).name}:\n\n{exc}",
                )
                return
            self.tree.set(item, "destino", destination)

    def _clear_map(self):
        for item in self.tree.get_children():
            self.tree.set(item, "destino", "")

    def _get_mappings(self):
        mappings = []
        for item in self.tree.get_children():
            destination = validate_database_name(self.tree.set(item, "destino"))
            mappings.append((item, destination))
        return mappings

    def _test_connection(self):
        try:
            config = self._get_sql_config()
            config.connection_string("master")
        except Exception as exc:
            messagebox.showerror(APP_TITLE, str(exc))
            return

        self.test_button.configure(state="disabled")
        self.status_var.set("Testando conexão...")

        def worker():
            try:
                manager = SqlServerManager(config)
                row = manager.test_connection()
                self.ui_queue.put(("test_ok", tuple(row)))
            except Exception as exc:
                self.ui_queue.put(("test_error", str(exc)))

        threading.Thread(target=worker, daemon=True).start()

    def _start_processing(self):
        if self.worker_thread and self.worker_thread.is_alive():
            return

        try:
            config = self._get_sql_config()
            config.connection_string("master")
            mappings = self._get_mappings()
            batch_size = int(self.batch_size_var.get())
            if batch_size < 100:
                raise ValueError("O lote deve ter pelo menos 100 linhas.")
        except Exception as exc:
            messagebox.showerror(APP_TITLE, str(exc))
            return

        if not mappings:
            messagebox.showwarning(APP_TITLE, "Leia uma pasta com arquivos .bt antes de iniciar.")
            return

        if self.recreate_var.get():
            if not messagebox.askyesno(
                APP_TITLE,
                "A opção de recriar bancos está ativa. Se um banco de destino já existir, TODO o conteúdo dele será apagado. Deseja continuar?",
                icon="warning",
            ):
                return

        self.stop_event.clear()
        self.progress_var.set(0)
        self.status_var.set("Iniciando...")
        self.start_button.configure(state="disabled")
        self.stop_button.configure(state="normal")
        self.test_button.configure(state="disabled")

        for item, _db in mappings:
            self.tree.set(item, "status", "Aguardando")

        worker_args = {
            "config": config,
            "mappings": mappings,
            "recreate": self.recreate_var.get(),
            "only_required": self.only_required_var.get(),
            "batch_size": batch_size,
        }
        self.worker_thread = threading.Thread(
            target=self._processing_worker,
            kwargs=worker_args,
            daemon=True,
        )
        self.worker_thread.start()

    def _processing_worker(self, config, mappings, recreate, only_required, batch_size):
        started_at = datetime.now()
        manager = SqlServerManager(config, log_callback=self._queue_log)
        grand_totals = defaultdict(lambda: defaultdict(int))
        file_errors = []

        try:
            server_info = manager.test_connection()
            self._queue_log(
                f"[CONEXÃO] Servidor={server_info[0]} | Login={server_info[1]} | Banco={server_info[2]}"
            )

            databases = []
            canonical_databases = {}
            normalized_mappings = []
            for path, database in mappings:
                key = database.lower()
                canonical = canonical_databases.setdefault(key, database)
                if canonical not in databases:
                    databases.append(canonical)
                normalized_mappings.append((path, canonical))
            mappings = normalized_mappings

            self._queue_log(f"[MAPEAMENTO] {len(mappings)} arquivo(s) -> {len(databases)} banco(s) de destino.")
            for database in databases:
                if self.stop_event.is_set():
                    raise InterruptedError("Processamento cancelado pelo usuário.")
                manager.prepare_database(database, recreate=recreate)

            total_files = len(mappings)
            for index, (bt_path, database) in enumerate(mappings, start=1):
                if self.stop_event.is_set():
                    raise InterruptedError("Processamento cancelado pelo usuário.")

                file_name = Path(bt_path).name
                self.ui_queue.put(("file_status", bt_path, "Processando"))
                self.ui_queue.put(("status", f"{index}/{total_files} - {file_name}"))
                self._queue_log(f"\n[ARQUIVO] {file_name} -> {database}")

                try:
                    importer = BtFileImporter(
                        manager,
                        database,
                        batch_size=batch_size,
                        only_required_tables=only_required,
                        stop_event=self.stop_event,
                        log_callback=self._queue_log,
                    )
                    totals, encountered = importer.import_file(bt_path)

                    if totals:
                        for table, rows in totals.items():
                            grand_totals[database][table] += rows
                            self._queue_log(f"  [OK] {table}: +{rows} linha(s)")
                    else:
                        self._queue_log("  [AVISO] Nenhuma tabela com dados foi importada deste arquivo.")

                    if only_required:
                        missing = sorted(REQUIRED_TABLES - encountered)
                        if missing:
                            self._queue_log(f"  [INFO] {len(missing)} tabela(s) configurada(s) não apareceram no arquivo.")

                    self.ui_queue.put(("file_status", bt_path, "Concluído"))
                except InterruptedError:
                    self.ui_queue.put(("file_status", bt_path, "Cancelado"))
                    raise
                except Exception as exc:
                    file_errors.append((file_name, str(exc)))
                    self.ui_queue.put(("file_status", bt_path, "Erro"))
                    self._queue_log(f"  [ERRO] {exc}")
                    self._queue_log(traceback.format_exc())

                self.ui_queue.put(("progress", (index / total_files) * 100.0))

            elapsed = datetime.now() - started_at
            self._queue_log("\n[RESUMO FINAL]")
            for database in sorted(grand_totals):
                total_db = sum(grand_totals[database].values())
                self._queue_log(f"  Banco {database}: {total_db} linha(s) importada(s)")
                for table in sorted(grand_totals[database]):
                    self._queue_log(f"    - {table}: {grand_totals[database][table]} linha(s)")

            if file_errors:
                self._queue_log(f"\n[ATENÇÃO] {len(file_errors)} arquivo(s) terminaram com erro.")
                for file_name, error in file_errors:
                    self._queue_log(f"  - {file_name}: {error}")

            self._queue_log(f"[FIM] Duração total: {elapsed}")
            self.ui_queue.put(("done", len(file_errors)))

        except InterruptedError as exc:
            self._queue_log(f"\n[CANCELADO] {exc}")
            self.ui_queue.put(("cancelled",))
        except Exception as exc:
            self._queue_log(f"\n[ERRO FATAL] {exc}")
            self._queue_log(traceback.format_exc())
            self.ui_queue.put(("fatal", str(exc)))
        finally:
            manager.dispose_all()

    def _cancel_processing(self):
        if self.worker_thread and self.worker_thread.is_alive():
            self.stop_event.set()
            self.stop_button.configure(state="disabled")
            self.status_var.set("Cancelamento solicitado...")
            self._append_log("[AÇÃO] Cancelamento solicitado. O lote SQL atual será concluído antes de parar.")

    def _queue_log(self, message):
        self.ui_queue.put(("log", message))

    def _append_log(self, message):
        timestamp = datetime.now().strftime("%H:%M:%S")
        self.log_text.configure(state="normal")
        self.log_text.insert("end", f"{timestamp} {message}\n")
        self.log_text.see("end")
        self.log_text.configure(state="disabled")

    def _finish_ui_state(self):
        self.start_button.configure(state="normal")
        self.stop_button.configure(state="disabled")
        self.test_button.configure(state="normal")

    def _process_ui_queue(self):
        try:
            while True:
                event = self.ui_queue.get_nowait()
                kind = event[0]

                if kind == "log":
                    self._append_log(event[1])
                elif kind == "progress":
                    self.progress_var.set(event[1])
                elif kind == "status":
                    self.status_var.set(event[1])
                elif kind == "file_status":
                    path, status = event[1], event[2]
                    if self.tree.exists(path):
                        self.tree.set(path, "status", status)
                elif kind == "test_ok":
                    server, login, database = event[1]
                    self.test_button.configure(state="normal")
                    self.status_var.set("Conexão OK")
                    messagebox.showinfo(
                        APP_TITLE,
                        f"Conexão realizada.\n\nServidor: {server}\nLogin: {login}\nBanco: {database}",
                    )
                elif kind == "test_error":
                    self.test_button.configure(state="normal")
                    self.status_var.set("Falha na conexão")
                    messagebox.showerror(APP_TITLE, f"Falha ao conectar:\n\n{event[1]}")
                elif kind == "done":
                    errors = event[1]
                    self._finish_ui_state()
                    self.status_var.set("Concluído" if not errors else f"Concluído com {errors} erro(s)")
                    self.progress_var.set(100)
                    if errors:
                        messagebox.showwarning(APP_TITLE, f"Processamento finalizado com {errors} arquivo(s) com erro. Consulte o log.")
                    else:
                        messagebox.showinfo(APP_TITLE, "Processamento finalizado com sucesso.")
                elif kind == "cancelled":
                    self._finish_ui_state()
                    self.status_var.set("Cancelado")
                    messagebox.showinfo(APP_TITLE, "Processamento cancelado.")
                elif kind == "fatal":
                    self._finish_ui_state()
                    self.status_var.set("Erro fatal")
                    messagebox.showerror(APP_TITLE, f"Erro fatal:\n\n{event[1]}\n\nConsulte o log.")
        except queue.Empty:
            pass
        finally:
            self.after(100, self._process_ui_queue)


if __name__ == "__main__":
    app = BtSqlApp()
    app.mainloop()