DECLARE @NomeTabela SYSNAME = '%TURMA%',
        @Query NVARCHAR(MAX) = 'SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ';

SELECT *,
        @Query + '''' + table_name + ''' AND TABLE_NAME NOT LIKE ''ZDEPARA_%'' UNION ' AS QUERY
FROM (
    SELECT 
        s.name AS schema_name,
        t.name AS table_name,
        SUM(p.rows) AS total_linhas
    FROM sys.tables t
    JOIN sys.schemas s 
        ON t.schema_id = s.schema_id
    JOIN sys.partitions p 
        ON t.object_id = p.object_id
    WHERE p.index_id IN (0,1) -- heap ou clustered index
    GROUP BY s.name, t.name
) DADOS
WHERE DADOS.total_linhas > 0
  AND DADOS.table_name NOT LIKE 'ZMIGRA%'
  AND DADOS.table_name LIKE '%' + @NomeTabela + '%'
ORDER BY 3 DESC