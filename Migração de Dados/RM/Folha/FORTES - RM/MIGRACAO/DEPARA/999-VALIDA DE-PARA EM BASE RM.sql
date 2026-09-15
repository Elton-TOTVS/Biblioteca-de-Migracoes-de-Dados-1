-- ZDEPARA_FUNCAO

WITH CTE AS (
  SELECT 
  'SELECT X.* FROM (' AS SQL_GERADO, 1 AS ORDERM
  UNION ALL
  SELECT DISTINCT
      'SELECT ' 
      + Y.CODCOLIGADA 
      + ' AS CODCOLIGADA, ''' 
      + CAST(X.CODIGO_PARA AS VARCHAR(100))
      + ''' AS CODIGO FROM DUAL'
      + CASE 
          WHEN ROW_NUMBER() OVER (
              ORDER BY Y.CODCOLIGADA, X.CODIGO_PARA
          ) < COUNT(*) OVER ()
          THEN ' UNION'
          ELSE ''
        END AS SQL_GERADO,
        2 AS ORDERM
  FROM (SELECT DISTINCT CODIGO_PARA FROM ZDEPARA_FUNCOES) X
  CROSS JOIN (
      SELECT CAST(CODCOLIGADA AS VARCHAR(5)) AS CODCOLIGADA
      FROM ZDEPARA_COLIGADAS
  ) Y
  UNION ALL
  SELECT') X WHERE NOT EXISTS (SELECT 1 FROM PFUNCAO WHERE PFUNCAO.CODCOLIGADA = X.CODCOLIGADA AND PFUNCAO.CODIGO = X.CODIGO)' AS SQL_GERADO, 3 AS ORDERM
)
SELECT SQL_GERADO FROM CTE ORDER BY ORDERM;

--ORIGINAL=========================================================================================================
-- SELECT DISTINCT 'SELECT ' + Y.CODCOLIGADA + ' AS CODCOLIGADA, ''' + CODIGO_PARA + ''' AS CODIGO FROM DUAL UNION ' FROM ZDEPARA_FUNCOES, (SELECT CAST(CODCOLIGADA AS VARCHAR(5)) AS CODCOLIGADA FROM ZDEPARA_COLIGADAS) Y
-- SELECT X.*
--   FROM (  
    
--   ) X
--  WHERE NOT EXISTS (SELECT 1 
--                      FROM PFUNCAO
--                     WHERE PFUNCAO.CODCOLIGADA = X.CODCOLIGADA
--                       AND PFUNCAO.CODIGO      = X.CODIGO)
--=================================================================================================================
--=================================================================================================================

-- ZDEPARA_SECAO
WITH CTE AS (
  SELECT 
  'SELECT X.* FROM (' AS SQL_GERADO, 1 AS ORDERM
  UNION ALL
  SELECT DISTINCT 
      'SELECT ' 
      + COLIGADA_PARA 
      + ' AS CODCOLIGADA, ' 
      + FILIAL_PARA 
      + ' AS FILIAL, ''' 
      + CODIGO_PARA 
      + ''' AS CODIGO FROM DUAL ' 
      + CASE 
          WHEN ROW_NUMBER() OVER (
              ORDER BY COLIGADA_PARA, FILIAL_PARA, CODIGO_PARA
          ) < COUNT(*) OVER ()
          THEN 'UNION'
          ELSE ''
        END AS SQL_GERADO,
        2 AS ORDERM 
    FROM (SELECT DISTINCT COLIGADA_PARA, FILIAL_PARA, CODIGO_PARA FROM ZDEPARA_SECOES) ZDEPARA_SECOES
    UNION ALL
    SELECT') X WHERE NOT EXISTS (SELECT 1 FROM PSECAO WHERE PSECAO.CODCOLIGADA = X.CODCOLIGADA AND PSECAO.CODFILIAL   = X.FILIAL AND PSECAO.CODIGO = X.CODIGO)' AS SQL_GERADO, 3 AS ORDERM
  )
  SELECT SQL_GERADO FROM CTE ORDER BY ORDERM;

--ORIGINAL=========================================================================================================
-- SELECT DISTINCT 'SELECT ' + COLIGADA_PARA + ' AS CODCOLIGADA, ' + FILIAL_PARA + ' AS FILIAL, ''' + CODIGO_PARA + ''' AS CODIGO FROM DUAL UNION ' FROM ZDEPARA_SECOES	
-- SELECT X.*
--   FROM (  
           
--  ) X
--  WHERE NOT EXISTS (SELECT 1 
--                      FROM PSECAO
--                     WHERE PSECAO.CODCOLIGADA = X.CODCOLIGADA
-- 					  AND PSECAO.CODFILIAL   = X.FILIAL
--                       AND PSECAO.CODIGO      = X.CODIGO)
--=================================================================================================================
--=================================================================================================================

--ZDEPARA_EVENTOS
WITH CTE AS (
  SELECT 
  'SELECT X.* FROM (' AS SQL_GERADO, 1 AS ORDERM
  UNION ALL
  SELECT
      'SELECT '
      + Y.CODCOLIGADA
      + ' AS CODCOLIGADA, '''
      + X.CODIGO_PARA
      + ''' AS CODIGO FROM DUAL'
      + CASE
          WHEN ROW_NUMBER() OVER (
              ORDER BY Y.CODCOLIGADA, X.CODIGO_PARA
          ) < COUNT(*) OVER ()
          THEN ' UNION'
          ELSE ''
        END AS SQL_GERADO,
        2 AS ORDERM
  FROM (
      SELECT DISTINCT
          CODIGO_PARA
      FROM ZDEPARA_EVENTOS
  ) X
  CROSS JOIN (
      SELECT DISTINCT
          CAST(CODCOLIGADA AS VARCHAR(5)) AS CODCOLIGADA
      FROM ZDEPARA_COLIGADAS
  ) Y
    UNION ALL
    SELECT' ) X WHERE NOT EXISTS (SELECT 1 FROM PEVENTO WHERE PEVENTO.CODCOLIGADA = X.CODCOLIGADA AND PEVENTO.CODIGO = X.CODIGO)' AS SQL_GERADO, 3 AS ORDERM
  )
  SELECT SQL_GERADO FROM CTE ORDER BY ORDERM;

--ORIGINAL=========================================================================================================
-- SELECT DISTINCT 'SELECT ' + Y.CODCOLIGADA + ' AS CODCOLIGADA, ''' + CODIGO_PARA + ''' AS CODIGO FROM DUAL UNION ' FROM ZDEPARA_EVENTOS, (SELECT CAST(CODCOLIGADA AS VARCHAR(5)) AS CODCOLIGADA FROM ZDEPARA_COLIGADAS) Y	
-- SELECT X.*
--   FROM (
   
--   ) X
--  WHERE NOT EXISTS (SELECT 1 
--                      FROM PEVENTO
--                     WHERE PEVENTO.CODCOLIGADA = X.CODCOLIGADA
--                       AND PEVENTO.CODIGO      = X.CODIGO)
--=================================================================================================================
--=================================================================================================================

-- ZDEPARA_SINDICATO
WITH DADOS AS (
    SELECT DISTINCT
        Y.CODCOLIGADA,
        X.CODIGO_PARA
    FROM (
        SELECT DISTINCT
            COLIGADA_PARA,
            CODIGO_PARA
        FROM ZDEPARA_SINDICATOS
    ) AS X
    CROSS JOIN (
        SELECT CAST(CODCOLIGADA AS VARCHAR(5)) AS CODCOLIGADA
        FROM ZDEPARA_COLIGADAS
    ) AS Y
),
CTE AS (
    SELECT 
        'SELECT X.* FROM (' AS SQL_GERADO,
        1 AS ORDERM
    UNION ALL
    SELECT
        'SELECT '
        + CODCOLIGADA
        + ' AS CODCOLIGADA, '''
        + CODIGO_PARA
        + ''' AS CODIGO FROM DUAL'
        + CASE
            WHEN ROW_NUMBER() OVER (
                ORDER BY CODCOLIGADA, CODIGO_PARA
            ) < COUNT(*) OVER ()
            THEN ' UNION'
            ELSE ''
          END AS SQL_GERADO,
        2 AS ORDERM
    FROM DADOS
    UNION ALL
    SELECT ') X WHERE NOT EXISTS ( SELECT 1 FROM PSINDIC WHERE PSINDIC.CODCOLIGADA = X.CODCOLIGADA AND PSINDIC.CODIGO = X.CODIGO )' AS SQL_GERADO,
    3 AS ORDERM
)
SELECT SQL_GERADO FROM CTE WHERE SQL_GERADO IS NOT NULL ORDER BY ORDERM;

--ORIGINAL=========================================================================================================
-- SELECT DISTINCT 'SELECT ' + Y.CODCOLIGADA + ' AS CODCOLIGADA, ''' + CODIGO_PARA + ''' AS CODIGO FROM DUAL UNION ' FROM ZDEPARA_SINDICATOS, (SELECT CAST(CODCOLIGADA AS VARCHAR(5)) AS CODCOLIGADA FROM ZDEPARA_COLIGADAS) Y				  
-- SELECT X.*
--   FROM (
 
-- ) X
--  WHERE NOT EXISTS (SELECT 1 
--                      FROM PSINDIC
--                     WHERE PSINDIC.CODCOLIGADA = X.CODCOLIGADA
--                       AND PSINDIC.CODIGO      = X.CODIGO)
--=================================================================================================================
--================================================================================================================

--ZDEPARA_SITUACAO
WITH CTE AS (
  SELECT 
    'SELECT X.* FROM (' AS SQL_GERADO, 1 AS ORDERM
    UNION ALL
    SELECT DISTINCT 
      'SELECT ''' 
      + CODSITUACAO_PARA 
      + ''' AS CODIGO FROM DUAL' 
      + CASE 
        WHEN ROW_NUMBER() OVER (
            ORDER BY CODSITUACAO_PARA
          ) < COUNT(*) OVER () 
        THEN ' UNION' 
        ELSE '' 
      END,
      2 AS ORDERM
    FROM ZDEPARA_SITUACAO
    UNION ALL
    SELECT ' ) X WHERE NOT EXISTS (SELECT 1 FROM PCODSITUACAO WHERE PCODSITUACAO.CODCLIENTE = X.CODIGO)' AS SQL_GERADO, 
    3 AS ORDERM
  )
  SELECT SQL_GERADO FROM CTE ORDER BY ORDERM;

--ORIGINAL=========================================================================================================
-- SELECT DISTINCT 'SELECT ''' + CODSITUACAO_PARA + ''' AS CODIGO FROM DUAL UNION' FROM ZDEPARA_SITUACAO
-- SELECT X.*
--   FROM (    

--  ) X 
--  WHERE NOT EXISTS (SELECT 1 
--                      FROM PCODSITUACAO 
-- 					WHERE PCODSITUACAO.CODCLIENTE = X.CODIGO)

WITH DADOS AS (
  SELECT DISTINCT 
    'SELECT ''' 
    + CODMOTIVO_PARA 
    + ''' AS CODIGO FROM DUAL UNION' AS SQL_GERADO,
    1 AS ORG
  FROM ZDEPARA_SITUACAO
  UNION ALL
  SELECT 
    'SELECT ''' 
    + CODMOTIVO_RETORNO_PARA 
    + ''' AS CODIGO FROM DUAL' 
    + CASE 
      WHEN ROW_NUMBER() OVER (
          ORDER BY CODMOTIVO_RETORNO_PARA
        ) < COUNT(*) OVER () 
      THEN ' UNION' 
      ELSE '' 
    END AS SQL_GERADO,
    2 AS ORG
  FROM ZDEPARA_SITUACAO
),
CTE AS (
  SELECT 
    'SELECT X.* FROM (' AS SQL_GERADO, 1 AS ORDERM
    UNION ALL
    SELECT SQL_GERADO, 2 AS ORDERM FROM DADOS
    UNION ALL
    SELECT ' ) X WHERE NOT EXISTS (SELECT 1 FROM PMUDSITUACAO WHERE PMUDSITUACAO.CODCLIENTE = X.CODIGO)' AS SQL_GERADO, 3 AS ORDERM
)
SELECT SQL_GERADO FROM CTE WHERE SQL_GERADO IS NOT NULL ORDER BY ORDERM;

--ORIGINAL=========================================================================================================
-- SELECT DISTINCT 'SELECT ''' + CODMOTIVO_PARA + ''' AS CODIGO FROM DUAL UNION' FROM ZDEPARA_SITUACAO UNION
-- SELECT DISTINCT 'SELECT ''' + CODMOTIVO_RETORNO_PARA + ''' AS CODIGO FROM DUAL UNION' FROM ZDEPARA_SITUACAO
-- SELECT X.*
--   FROM (    

--  ) X 
--  WHERE NOT EXISTS (SELECT 1 
--                      FROM PMUDSITUACAO 
-- 					WHERE PMUDSITUACAO.CODCLIENTE = X.CODIGO)
--=================================================================================================================
--=================================================================================================================

-- ZDEPARA_BANCO
--BANCO
WITH CTE AS (
  SELECT 
    'SELECT X.* FROM (' AS SQL_GERADO, 1 AS ORDERM
    UNION ALL
    SELECT DISTINCT 
      'SELECT ''' 
      + CODIGO_BANCO_PARA 
      + ''' AS CODBANCO FROM DUAL' 
      + CASE
        WHEN ROW_NUMBER() OVER (
            ORDER BY CODIGO_BANCO_PARA
          ) < COUNT(*) OVER ()
        THEN ' UNION'
        ELSE ''
      END AS SQL_GERADO,
      2 AS ORDEM
    FROM ZDEPARA_BANCOS
    UNION ALL
    SELECT ' ) X WHERE NOT EXISTS (SELECT 1 FROM GBANCO WHERE GBANCO.NUMBANCO = X.CODBANCO)' AS SQL_GERADO, 
    3 AS ORDERM
)
SELECT SQL_GERADO FROM CTE ORDER BY ORDERM;

--=================================================================================================================
--=================================================================================================================

--BANCO + AGENCIA
WITH CTE AS (
  SELECT 
    'SELECT X.* FROM (' AS SQL_GERADO, 1 AS ORDERM
    UNION ALL
    SELECT DISTINCT 
      'SELECT ''' 
      + CODIGO_BANCO_PARA 
      + ''' AS CODBANCO, ''' 
      + CODIGO_AGENCIA_PARA 
      + ''' AS CODAGENCIA FROM DUAL' 
      + CASE
        WHEN ROW_NUMBER() OVER (
            ORDER BY CODIGO_BANCO_PARA, CODIGO_AGENCIA_PARA
          ) < COUNT(*) OVER ()
        THEN ' UNION'
        ELSE ''
      END AS SQL_GERADO,
      2 AS ORDEM
    FROM ZDEPARA_BANCOS
    UNION ALL
    SELECT ' ) X WHERE NOT EXISTS (SELECT 1 FROM GAGENCIA WHERE GAGENCIA.NUMBANCO = X.CODBANCO AND GAGENCIA.NUMAGENCIA = X.CODAGENCIA)' AS SQL_GERADO, 
    3 AS ORDERM
  )
  SELECT SQL_GERADO FROM CTE ORDER BY ORDERM; 

--ORIGINAL=========================================================================================================
-- SELECT DISTINCT 'SELECT ''' + CODIGO_BANCO_PARA + ''' AS CODBANCO, ''' + CODIGO_AGENCIA_PARA + ''' AS CODAGENCIA FROM DUAL UNION ' FROM ZDEPARA_BANCOS
-- SELECT X.*
--   FROM (  

--  ) X
--  WHERE NOT EXISTS (SELECT 1 
--                      FROM GAGENCIA
--                     WHERE GAGENCIA.NUMBANCO   = X.CODBANCO
--                       AND GAGENCIA.NUMAGENCIA = X.CODAGENCIA)
--=================================================================================================================
--=================================================================================================================

-- ZDEPARA_HORARIOS
WITH CTE AS (
  SELECT 
    'SELECT X.* FROM (' AS SQL_GERADO, 1 AS ORDERM
    UNION ALL
    SELECT
      'SELECT ' + Y.CODCOLIGADA 
      + ' AS CODCOLIGADA, ''' 
      + X.CODIGO_PARA 
      + ''' AS CODIGO FROM DUAL'
      + CASE
        WHEN ROW_NUMBER() OVER(
          ORDER BY Y.CODCOLIGADA, X.CODIGO_PARA
        ) < COUNT(*) OVER ()
        THEN ' UNION'
        ELSE ''
      END AS SQL_GERADO,
      2 AS ORDEM
    FROM (
      SELECT DISTINCT
        CODIGO_PARA 
      FROM ZDEPARA_HORARIOS
    ) X
    CROSS JOIN (
      SELECT DISTINCT CAST(CODCOLIGADA AS VARCHAR(5)) AS CODCOLIGADA 
      FROM ZDEPARA_COLIGADAS
    ) Y
    UNION ALL
    SELECT ' ) X WHERE NOT EXISTS (SELECT 1 FROM AHORARIO WHERE AHORARIO.CODCOLIGADA = X.CODCOLIGADA AND AHORARIO.CODIGO = X.CODIGO)' AS SQL_GERADO, 
    3 AS ORDERM
  )
  SELECT SQL_GERADO FROM CTE ORDER BY ORDERM;

--ORIGINAL=========================================================================================================
-- SELECT DISTINCT 'SELECT ' + Y.CODCOLIGADA + ' AS CODCOLIGADA, ''' + CODIGO_PARA + ''' AS CODIGO FROM DUAL UNION '  FROM ZDEPARA_HORARIOS, (SELECT CAST(CODCOLIGADA AS VARCHAR(5)) AS CODCOLIGADA FROM ZDEPARA_COLIGADAS) Y
-- SELECT X.*
--   FROM (
  
--  ) X
--  WHERE NOT EXISTS (SELECT 1 
--                      FROM AHORARIO 
--                     WHERE AHORARIO.CODCOLIGADA = X.CODCOLIGADA
--                       AND AHORARIO.CODIGO      = X.CODIGO)
--=============================================================== Dá pra ter presenciais seleciona o próprio BT já tem padrão aqui mas pode vir aqui por exemplo Zigra Protest do Arquivo já faz padrão é isso que colocar tudo com nome só por exemplo ele vai juntar aqui tudinho todos aqueles==================================================
--=================================================================================================================