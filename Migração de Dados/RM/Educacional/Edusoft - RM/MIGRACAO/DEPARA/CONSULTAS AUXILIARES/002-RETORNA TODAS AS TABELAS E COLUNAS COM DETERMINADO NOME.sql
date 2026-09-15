DECLARE @Valor NVARCHAR(4000) = N'6.00';

DROP TABLE IF EXISTS #Resultados;

CREATE TABLE #Resultados
(
    SchemaName SYSNAME,
    TableName  SYSNAME,
    ColumnName SYSNAME
);

DECLARE
    @Schema SYSNAME,
    @Tabela SYSNAME,
    @Coluna SYSNAME,
    @SQL    NVARCHAR(MAX);

DECLARE colunas CURSOR LOCAL FAST_FORWARD FOR
SELECT
    s.name,
    t.name,
    c.name
FROM sys.tables t
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
INNER JOIN sys.columns c
    ON c.object_id = t.object_id
INNER JOIN sys.types ty
    ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND ty.system_type_id IN
      (
          35,  -- text
          99,  -- ntext
          167, -- varchar
          175, -- char
          231, -- nvarchar
          239  -- nchar
      );

OPEN colunas;

FETCH NEXT FROM colunas
INTO @Schema, @Tabela, @Coluna;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = N'
        IF EXISTS
        (
            SELECT 1
            FROM ' + QUOTENAME(@Schema) + N'.' + QUOTENAME(@Tabela) + N'
            WHERE TRY_CONVERT(NVARCHAR(MAX), '
                + QUOTENAME(@Coluna) + N') LIKE @Valor
        )
        BEGIN
            INSERT INTO #Resultados
            (
                SchemaName,
                TableName,
                ColumnName
            )
            VALUES
            (
                @Schema,
                @Tabela,
                @Coluna
            );
        END;';

    EXEC sys.sp_executesql
        @SQL,
        N'@Valor NVARCHAR(4000),
          @Schema SYSNAME,
          @Tabela SYSNAME,
          @Coluna SYSNAME',
        @Valor  = @Valor,
        @Schema = @Schema,
        @Tabela = @Tabela,
        @Coluna = @Coluna;

    FETCH NEXT FROM colunas
    INTO @Schema, @Tabela, @Coluna;
END;

CLOSE colunas;
DEALLOCATE colunas;

SELECT
    SchemaName AS schema_name,
    TableName  AS table_name,
    ColumnName AS column_name
FROM #Resultados
ORDER BY
    SchemaName,
    TableName,
    ColumnName;

SELECT * , 'SELECT ' + ColumnName + ' FROM ' + SchemaName + '.' + TableName FROM #Resultados;
