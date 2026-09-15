DECLARE @NomeColuna SYSNAME = '%NOTA%';

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
    
FROM sys.tables t
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
INNER JOIN sys.columns c
    ON c.object_id = t.object_id
WHERE c.name LIKE @NomeColuna
  AND t.is_ms_shipped = 0
ORDER BY
    s.name,
    t.name,
    c.name;