-- Consulta complementar: retorna somente situacoes ainda nao existentes no DE-PARA anterior.
;WITH NOVO_DEPARA AS
(
    SELECT TLI.CODIGO AS CODIGO_DE,
           TLI.NOME AS NOME_DE,
           CAST('' AS VARCHAR(5)) AS CODSITUACAO_PARA,
           CAST('' AS VARCHAR(5)) AS CODMOTIVO_PARA,
           CAST('' AS VARCHAR(5)) AS CODSITUACAO_RETORNO_PARA,
           CAST('' AS VARCHAR(5)) AS CODMOTIVO_RETORNO_PARA
      FROM TLI
     WHERE EXISTS
           (
               SELECT 1
                 FROM LIC
                 JOIN ZDEPARA_COLIGADAS AS COLIGADA
                   ON LIC.EMP_CODIGO = COLIGADA.EMPRESA_DE
                WHERE LIC.TLI_CODIGO = TLI.CODIGO
           )
)
SELECT NOVO_DEPARA.*
  FROM NOVO_DEPARA
 WHERE NOT EXISTS
       (
           SELECT 1
             FROM ZDEPARA_SITUACAO AS ANTERIOR
            WHERE ANTERIOR.CODIGO_DE = NOVO_DEPARA.CODIGO_DE
       )
 ORDER BY NOVO_DEPARA.CODIGO_DE;
