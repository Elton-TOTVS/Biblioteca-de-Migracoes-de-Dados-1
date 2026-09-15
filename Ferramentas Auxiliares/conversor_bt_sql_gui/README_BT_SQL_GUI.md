# Conversor BT -> SQL Server

Aplicação desktop para Windows que lê arquivos `.bt` e envia os blocos/tabelas para SQL Server.

## Instalação

1. Instale Python 3.11+ no Windows.
2. Instale o **Microsoft ODBC Driver 18 for SQL Server** (ou Driver 17).
3. Na pasta do aplicativo, execute:



```bat
py -m pip install -r requirements_bt_sql_gui.txt
```

## Execução

```bat
py app_bt_sql_gui.py
```

Ou use `executar_app.bat`.

## Uso do DE -> PARA

Exemplo:

| Arquivo | Banco de destino |
|---|---|
| `TESLA.bt` | `EST` |
| `SIST.bt` | `EST` |
| `ALFA.bt` | `MIGRA_ALFA` |

Resultado:

- dados de `TESLA.bt -> EPG` entram em `EST.dbo.EPG`;
- dados de `SIST.bt -> EPG` são acrescentados em `EST.dbo.EPG`;
- as demais tabelas seguem a mesma lógica;
- `ALFA.bt` vai para o banco `MIGRA_ALFA`.

O merge é por **append de linhas**. O aplicativo não remove duplicidades automaticamente.

## Opção "Recriar bancos"

Marcada: se o banco já existir, ele é apagado e criado novamente antes da importação.

Desmarcada: o aplicativo usa o banco existente e acrescenta os dados nas tabelas já existentes. Para uma migração limpa, mantenha essa opção marcada.
