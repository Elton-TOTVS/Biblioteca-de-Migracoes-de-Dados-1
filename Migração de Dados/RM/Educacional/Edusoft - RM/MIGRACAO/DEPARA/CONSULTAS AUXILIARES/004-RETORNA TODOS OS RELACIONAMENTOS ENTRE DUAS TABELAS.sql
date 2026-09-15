DECLARE @SchemaOrigem  SYSNAME = 'dbo';
DECLARE @TabelaOrigem  SYSNAME = 'TB_PESSOA';

DECLARE @SchemaDestino SYSNAME = 'dbo';
DECLARE @TabelaDestino SYSNAME = 'TB_TURMA';

DECLARE @ProfundidadeMaxima INT = 3;

;WITH Relacionamentos AS (
    SELECT
        fk.name AS fk_name,

        ps.name AS schema_origem,
        pt.name AS tabela_origem,
        pc.name AS coluna_origem,

        rs.name AS schema_destino,
        rt.name AS tabela_destino,
        rc.name AS coluna_destino
    FROM sys.foreign_keys fk
    INNER JOIN sys.foreign_key_columns fkc
        ON fkc.constraint_object_id = fk.object_id

    INNER JOIN sys.tables pt
        ON pt.object_id = fkc.parent_object_id
    INNER JOIN sys.schemas ps
        ON ps.schema_id = pt.schema_id
    INNER JOIN sys.columns pc
        ON pc.object_id = pt.object_id
       AND pc.column_id = fkc.parent_column_id

    INNER JOIN sys.tables rt
        ON rt.object_id = fkc.referenced_object_id
    INNER JOIN sys.schemas rs
        ON rs.schema_id = rt.schema_id
    INNER JOIN sys.columns rc
        ON rc.object_id = rt.object_id
       AND rc.column_id = fkc.referenced_column_id
),
Grafo AS (
    -- sentido normal da FK
    SELECT
        fk_name,
        schema_origem,
        tabela_origem,
        coluna_origem,
        schema_destino,
        tabela_destino,
        coluna_destino,
        CAST(
            schema_origem + '.' + tabela_origem + '.' + coluna_origem
            + ' -> ' +
            schema_destino + '.' + tabela_destino + '.' + coluna_destino
            AS VARCHAR(MAX)
        ) AS descricao_ligacao
    FROM Relacionamentos

    UNION ALL

    -- sentido inverso da FK, para permitir navegar de volta
    SELECT
        fk_name,
        schema_destino AS schema_origem,
        tabela_destino AS tabela_origem,
        coluna_destino AS coluna_origem,
        schema_origem AS schema_destino,
        tabela_origem AS tabela_destino,
        coluna_origem AS coluna_destino,
        CAST(
            schema_destino + '.' + tabela_destino + '.' + coluna_destino
            + ' <- ' +
            schema_origem + '.' + tabela_origem + '.' + coluna_origem
            AS VARCHAR(MAX)
        ) AS descricao_ligacao
    FROM Relacionamentos
),
Busca AS (
    SELECT
        1 AS nivel,

        g.schema_origem,
        g.tabela_origem,
        g.schema_destino,
        g.tabela_destino,

        CAST(g.schema_origem + '.' + g.tabela_origem AS VARCHAR(MAX)) AS caminho_tabelas,

        CAST(g.descricao_ligacao AS VARCHAR(MAX)) AS caminho_relacionamentos,

        CAST(
            '|' + g.schema_origem + '.' + g.tabela_origem + '|'
            + g.schema_destino + '.' + g.tabela_destino + '|'
            AS VARCHAR(MAX)
        ) AS visitados
    FROM Grafo g
    WHERE g.schema_origem = @SchemaOrigem
      AND g.tabela_origem = @TabelaOrigem

    UNION ALL

    SELECT
        b.nivel + 1,

        g.schema_origem,
        g.tabela_origem,
        g.schema_destino,
        g.tabela_destino,

        CAST(
            b.caminho_tabelas + ' -> ' + g.schema_destino + '.' + g.tabela_destino
            AS VARCHAR(MAX)
        ) AS caminho_tabelas,

        CAST(
            b.caminho_relacionamentos + CHAR(13) + CHAR(10)
            + g.descricao_ligacao
            AS VARCHAR(MAX)
        ) AS caminho_relacionamentos,

        CAST(
            b.visitados + g.schema_destino + '.' + g.tabela_destino + '|'
            AS VARCHAR(MAX)
        ) AS visitados
    FROM Busca b
    INNER JOIN Grafo g
        ON g.schema_origem = b.schema_destino
       AND g.tabela_origem = b.tabela_destino
    WHERE b.nivel < @ProfundidadeMaxima
      AND b.visitados NOT LIKE '%|' + g.schema_destino + '.' + g.tabela_destino + '|%'
)
SELECT
    nivel AS quantidade_de_passos,
    caminho_tabelas,
    caminho_relacionamentos
FROM Busca
WHERE schema_destino = @SchemaDestino
  AND tabela_destino = @TabelaDestino
ORDER BY nivel, caminho_tabelas
OPTION (MAXRECURSION 100);