DECLARE @NomeTabela SYSNAME = '%PLANO%';

SELECT
    s.name AS schema_name,
    t.name AS table_name
FROM sys.tables t
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id    
WHERE t.name LIKE @NomeTabela
ORDER BY
    s.name,
    t.name;
