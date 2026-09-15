-- Consulta complementar: retorna somente coligadas ainda nao existentes no DE-PARA anterior.
;WITH NOVO_DEPARA AS
(
    SELECT DISTINCT
           DENSE_RANK() OVER
           (
               ORDER BY CASE
                            WHEN EMP.CNPJBASE = '17851596' THEN '17.851.596/0001-36'
                        END
           ) AS ID,
           ISNULL(EPG.EMP_CODIGO, EMP.CODIGO) AS EMPRESA_DE,
           EMP.NOME AS NOME_DE,
           EMP.RAZAOSOCIAL,
           CASE
               WHEN EMP.CNPJBASE = '17851596' THEN '17.851.596/0001-36'
           END AS CNPJ,
           EMP.DESATIVADA,
           ISNULL(SUM(CASE WHEN EPG.DTRESCISAO IS NULL
                               AND EPG.NOME IS NOT NULL THEN 1 ELSE 0 END), 0) AS ATIVOS,
           ISNULL(SUM(CASE WHEN EPG.DTRESCISAO IS NOT NULL
                               AND EPG.NOME IS NOT NULL THEN 1 ELSE 0 END), 0) AS INATIVOS,
           ISNULL(SUM(CASE WHEN EPG.NOME IS NOT NULL THEN 1 ELSE 0 END), 0) AS TOTAL,
           CASE
               WHEN EMP.CNPJBASE = '17851596' THEN '1'
           END AS CODCOLIGADA,
           1 AS FILIAL_PARA
      FROM EMP
      LEFT JOIN EPG
        ON EMP.CODIGO = EPG.EMP_CODIGO
     GROUP BY EPG.EMP_CODIGO,
              EMP.CODIGO,
              EMP.NOME,
              EMP.RAZAOSOCIAL,
              EMP.NMFANTASIA,
              EMP.CNPJBASE,
              EMP.CPF,
              EMP.DESATIVADA
)
SELECT NOVO_DEPARA.*
  FROM NOVO_DEPARA
 WHERE NOT EXISTS
       (
           SELECT 1
             FROM ZDEPARA_COLIGADAS AS ANTERIOR
            WHERE ANTERIOR.EMPRESA_DE = NOVO_DEPARA.EMPRESA_DE
       )
 ORDER BY NOVO_DEPARA.CODCOLIGADA;
