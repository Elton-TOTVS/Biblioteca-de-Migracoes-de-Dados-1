import os
import re
import sys
import pyodbc
import pandas as pd
from glob import glob
from datetime import datetime
from sqlalchemy import create_engine, inspect
from sqlalchemy.types import NVARCHAR
from dotenv import load_dotenv

load_dotenv()

REQUIRED_TABLES = {
    "EVE", "EPG", "SEP", "DEP", "CAR", "CBA", "EMP", "SIN", "AVI", "PAE",
    "PVE", "AGE", "MUN", "UFD", "BAN", "DRM", "EBC", "EED", "EFP", "EPR",
    "ERF", "EST", "FOL", "FPG", "GPS", "HOR", "LOT", "TLI", "LIC", "REC",
    "EFO", "TRC", "TFO", "VID", "TB_MOT_DES", "PAF", "FER", "IND", "EPC",
    "ASO", "ESO", "PRS"
}

DECODE_RE = re.compile(r'\$([A-Fa-f0-9]{2})')

db_server = os.getenv('DB_SERVER')
db_user = os.getenv('DB_USER')
db_password = os.getenv('DB_PASSWORD')
odbc_driver = 'ODBC Driver 18 for SQL Server'

engine_db = None


def decode_special_characters(text):
    if isinstance(text, str) and "$" in text:
        return DECODE_RE.sub(lambda m: bytes.fromhex(m.group(1)).decode('latin-1'), text)
    return text


def _conn_str_base(banco="master"):
    return (
        f"DRIVER={{{odbc_driver}}};"
        f"SERVER={db_server};"
        f"DATABASE={banco};"
        f"UID={db_user};"
        f"PWD={db_password};"
        f"Encrypt=no;"
        f"TrustServerCertificate=yes;"
        f"LoginTimeout=30;"
    )


def banco_existe(nome_banco):
    conn = pyodbc.connect(_conn_str_base("master"), autocommit=True)
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM sys.databases WHERE name = ?", nome_banco)
    existe = cursor.fetchone()[0] > 0
    cursor.close()
    conn.close()
    return existe


def criar_banco(nome_banco):
    conn = pyodbc.connect(_conn_str_base("master"), autocommit=True)
    cursor = conn.cursor()
    cursor.execute(f"CREATE DATABASE [{nome_banco}]")
    cursor.close()
    conn.close()


def recriar_banco(nome_banco):
    conn = pyodbc.connect(_conn_str_base("master"), autocommit=True)
    cursor = conn.cursor()
    cursor.execute(f"ALTER DATABASE [{nome_banco}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE")
    cursor.execute(f"DROP DATABASE [{nome_banco}]")
    cursor.execute(f"CREATE DATABASE [{nome_banco}]")
    cursor.close()
    conn.close()


def selecionar_banco():
    while True:
        nome_banco = input("Informe o nome do banco de dados de destino: ").strip()

        if not banco_existe(nome_banco):
            print(f"   [+] Banco '{nome_banco}' não existe. Criando...")
            criar_banco(nome_banco)
            print(f"   [OK] Banco '{nome_banco}' criado.")
            return nome_banco

        resposta = input(f"   O banco '{nome_banco}' já existe. Sobrescrever (apaga tudo) ou escolher outro nome? (s = sobrescrever / n = outro nome): ").strip().lower()
        if resposta in ('s', 'sim', 'y', 'yes'):
            print(f"   [!] Apagando e recriando o banco '{nome_banco}'...")
            recriar_banco(nome_banco)
            print(f"   [OK] Banco '{nome_banco}' recriado.")
            return nome_banco

        print("   Ok, escolha outro nome.")


def configurar_engine(nome_banco):
    global engine_db
    conn_str = _conn_str_base(nome_banco)
    engine_db = create_engine(f"mssql+pyodbc:///?odbc_connect={conn_str}", fast_executemany=True)


def tabela_existe(nome_tabela):
    return nome_tabela in inspect(engine_db).get_table_names()


def enviar_para_sql(nome_tabela, df):
    if tabela_existe(nome_tabela):
        resposta = input(f"   A tabela '{nome_tabela}' já existe. Substituir? (s/n): ").strip().lower()
        if resposta not in ('s', 'sim', 'y', 'yes'):
            return "mantida (não substituída)"

    df = df.replace('', None)
    dtype_map = {col: NVARCHAR(length=None) for col in df.columns}
    df.to_sql(nome_tabela, engine_db, if_exists='replace', index=False, chunksize=5000, dtype=dtype_map)
    return len(df)


def processar_tabela(nome_tabela, fields, data):
    if not fields or not data:
        return False, "sem dados"

    df = pd.DataFrame(data, columns=fields)
    obj_cols = df.columns[df.dtypes == object]
    for col in obj_cols:
        df[col] = df[col].map(decode_special_characters)

    df = df.replace("@", "")
    df = df.dropna(how="all")
    df = df.dropna(axis=1, how="all")

    if df.empty:
        return False, "sem dados"

    resultado = enviar_para_sql(nome_tabela, df)
    if isinstance(resultado, str):
        return False, resultado
    return True, resultado


def parse_e_importar(bt_file_path):
    geradas = []
    nao_geradas = []
    encontradas = set()

    current_table = None
    current_fields = None
    current_data = []

    def flush():
        if not current_table or current_table not in REQUIRED_TABLES:
            return
        ok, info = processar_tabela(current_table, current_fields, current_data)
        (geradas if ok else nao_geradas).append((current_table, info))

    with open(bt_file_path, 'r', encoding='ISO-8859-1') as bt_file:
        for raw_line in bt_file:
            line = raw_line.strip()
            if not line:
                continue
            if line.startswith("[") and line.endswith("]") and ":" not in line:
                flush()
                current_table = line[1:-1]
                current_fields = None
                current_data = []
                if current_table in REQUIRED_TABLES:
                    encontradas.add(current_table)
            elif current_table and current_table in REQUIRED_TABLES:
                if line.startswith("[") and line.endswith("]"):
                    fields = line[1:-1].split(";")
                    current_fields = [f.split(":")[0] for f in fields]
                else:
                    current_data.append(line.split("|"))
        flush()

    for tabela in sorted(REQUIRED_TABLES - encontradas):
        nao_geradas.append((tabela, "não encontrada no arquivo .bt"))

    return geradas, nao_geradas


def main():
    inicio = datetime.now()
    print(f"Servidor: {db_server}")

    nome_banco = selecionar_banco()
    configurar_engine(nome_banco)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = sys.argv[1] if len(sys.argv) > 1 else script_dir
    bt_files = sorted(glob(os.path.join(base_dir, "*.bt")))

    if not bt_files:
        print("Nenhum arquivo .bt encontrado.")
        return

    print(f"Encontrados {len(bt_files)} arquivo(s) .bt.")

    for bt_path in bt_files:
        base_name = os.path.splitext(os.path.basename(bt_path))[0]
        print(f"\n=== Processando arquivo '{base_name}' ===")

        geradas, nao_geradas = parse_e_importar(bt_path)

        print(f"✔ Tabelas importadas ({len(geradas)}):")
        for t, n in geradas:
            print(f"   - {t} ({n} linhas)")

        print(f"✘ Tabelas não importadas ({len(nao_geradas)}):")
        for t, motivo in nao_geradas:
            print(f"   - {t} ({motivo})")

    print(f"\nDuração total: {datetime.now() - inicio}")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\nERRO FATAL: {e}")
        import traceback
        traceback.print_exc()
    finally:
        input("\nPressione ENTER para sair...")