----------------------------------------------------------------------------------------------------      
-- Script:					ZMIGRA_PFHSTSAL
-- Última Alteração:		14/08/2024     
-- Versão:					1 
-- Origem:					FORTES
-- Autor Alteração:			Rafael Stroppa
----------------------------------------------------------------------------------------------------

IF OBJECT_ID('ZMIGRA_PFHSTSAL') IS NOT NULL 
   DROP TABLE ZMIGRA_PFHSTSAL;

WITH ORDENACAO_SALARIOS AS (
	SELECT EMP_CODIGO,
		   EPG_CODIGO,
		   DATA,
		   VALOR,
		   DATEADD(MINUTE, ROW_NUMBER() OVER(PARTITION BY EMP_CODIGO, EPG_CODIGO, CAST(DATA AS DATE) ORDER BY EMP_CODIGO, EPG_CODIGO, DATA)-1, CONVERT(DATETIME,DATA,103)) AS DATA_ALTERADA
      FROM SEP)

-- SELECT TABELA.CODCOLIGADA, --NÃO SERÁ USADO NO LAYOUT
-- 	   TABELA.Chapa,
--        TABELA.[Data de mudança (ddmmaaaa hh:mm:ss)],
-- 	   TABELA.[Motivo de alteração salarial],
-- 	   TABELA.[Número do salário],
-- 	   TABELA.[Valor atual do salário],
-- 	   TABELA."Jornada de Trabalho",
-- 	   TABELA."Data de referência da alteração salarial (ddmmaaaa hh:mm:ss)",
-- 	   TABELA."Código do evento de salário",
--        TABELA."Data da inclusão do aumento salarial",
--        TABELA."Alteração de Jornada?",
--        TABELA."Percentual Aplicado",
--        TABELA."Historico Tabela Salarial",
--        TABELA."Historico Faixa",
--        TABELA."Historico Nivel",
--        TABELA."Identificador de executação da Alteração Global de Salário.",
-- 	   TABELA."Referência",
-- 	   TABELA.CAMPOEXTRA
--      INTO ZMIGRA_PFHSTSAL
-- 	 FROM (
			 SELECT ZDEPARA_PFUNC.CODCOLIGADA,
					ZDEPARA_PFUNC.CHAPA AS "Chapa",
					ROW_NUMBER ()OVER(PARTITION BY ZDEPARA_PFUNC.CODCOLIGADA, ZDEPARA_PFUNC.CHAPA,CASE WHEN CAST(SEP.VALOR AS DECIMAL(15,2)) <> 0 THEN REPLACE(CAST(CAST(REPLACE(SEP.VALOR,',','.') AS NUMERIC(15,2)) AS VARCHAR(20)),'.',',')
																									   WHEN CAST(SEP.VALOR AS DECIMAL(15,2)) = 0  THEN REPLACE(CAST(CAST(REPLACE(CAST((SELECT MAX(REPLACE(VALOR,',','.')) 
																																							 FROM VID 
																																							WHERE VID.IND_CODIGO = SEP.IND_CODIGO_SALARIO
																																							  AND VID.DATA       <= SEP.DATA) AS NUMERIC(15,2)) * SEP.INDQTDE,',','.') AS NUMERIC(15,2)) AS VARCHAR(20)),'.',',')
																								  END ORDER BY MIN(SEP.DATA)) AS ID,
					CASE WHEN MIN(SEP.DATA) < ZDEPARA_PFUNC.DATAADMISSAO THEN REPLACE(CONVERT(VARCHAR,ZDEPARA_PFUNC.DATAADMISSAO,103),'/','') + ' 00:01:00' 
						 ELSE REPLACE(CONVERT(VARCHAR(10),ORDENACAO_SALARIOS.DATA_ALTERADA,103),'/','')+' '+CONVERT(VARCHAR(8),ORDENACAO_SALARIOS.DATA_ALTERADA,108) 
					END AS "Data de mudança (ddmmaaaa hh:mm:ss)",
					CASE WHEN CAST(MIN(SEP.DATA) AS DATE) = ZDEPARA_PFUNC.DATAADMISSAO THEN '01' /*Admissão*/
						 ELSE '15' /*Acordo Coletivo*/
					END AS "Motivo de alteração salarial",
					1 AS "Número do salário",
					CASE WHEN CAST(SEP.VALOR AS DECIMAL(15,2)) <> 0 THEN REPLACE(CAST(CAST(REPLACE(SEP.VALOR,',','.') AS NUMERIC(15,2)) AS VARCHAR(20)),'.',',')
						 WHEN CAST(SEP.VALOR AS DECIMAL(15,2)) = 0  THEN REPLACE(CAST(CAST(REPLACE(CAST((SELECT MAX(REPLACE(VALOR,',','.')) 
																			   FROM VID 
																			  WHERE VID.IND_CODIGO  = SEP.IND_CODIGO_SALARIO
																			    AND VID.DATA       <= SEP.DATA) AS NUMERIC(15,2)) * SEP.INDQTDE,',','.') AS NUMERIC(15,2)) AS VARCHAR(20)),'.',',')
					END AS "Valor atual do salário",
					CASE WHEN ZDEPARA_PFUNC.HORASMES = '22500' THEN '220:00' --#Ver
					 	 WHEN RIGHT('000' + REPLACE(CAST(CAST(REPLACE(ZDEPARA_PFUNC.HORASMES,',','.') AS NUMERIC(5,2)) AS VARCHAR(20)),'.',':'),6) = '000:00' THEN '000:01'
				         WHEN RIGHT('000' + REPLACE(CAST(CAST(REPLACE(ZDEPARA_PFUNC.HORASMES,',','.') AS NUMERIC(5,2)) AS VARCHAR(20)),'.',':'),6) > '546:07' THEN '220:00'
						 ELSE RIGHT('000' + REPLACE(CAST(CAST(REPLACE(ZDEPARA_PFUNC.HORASMES,',','.') AS NUMERIC(5,2)) AS VARCHAR(20)),'.',':'),6) 
					 END AS "Jornada de Trabalho",
					CASE WHEN MIN(SEP.DATA) < ZDEPARA_PFUNC.DATAADMISSAO THEN REPLACE(CONVERT(VARCHAR,ZDEPARA_PFUNC.DATAADMISSAO,103),'/','') + ' 00:01:00' 
						 ELSE REPLACE(CONVERT(VARCHAR(10),ORDENACAO_SALARIOS.DATA_ALTERADA,103),'/','')+' '+CONVERT(VARCHAR(8),ORDENACAO_SALARIOS.DATA_ALTERADA,108) 
					END AS  "Data de referência da alteração salarial (ddmmaaaa hh:mm:ss)",
					NULL AS "Código do evento de salário",
					NULL AS "Data da inclusão do aumento salarial",
					NULL AS "Alteração de Jornada?",
					NULL AS "Percentual Aplicado",
					NULL AS "Historico Tabela Salarial",
					NULL AS "Historico Faixa",
					NULL AS "Historico Nivel",
					NULL AS "Identificador de executação da Alteração Global de Salário.",
					NULL AS "Referência",
					NULL AS CAMPOEXTRA
				FROM SEP
			    JOIN ZDEPARA_PFUNC
			      ON ZDEPARA_PFUNC.EMP_CODIGO = SEP.EMP_CODIGO
				 AND ZDEPARA_PFUNC.EPG_CODIGO = SEP.EPG_CODIGO
                JOIN ORDENACAO_SALARIOS
				  ON ORDENACAO_SALARIOS.EMP_CODIGO = SEP.EMP_CODIGO
				 AND ORDENACAO_SALARIOS.EPG_CODIGO = SEP.EPG_CODIGO
				 AND ORDENACAO_SALARIOS.DATA = SEP.DATA
				 AND ORDENACAO_SALARIOS.VALOR = SEP.VALOR

		       GROUP BY ZDEPARA_PFUNC.CODCOLIGADA,
						ZDEPARA_PFUNC.CHAPA,
						ZDEPARA_PFUNC.DATAADMISSAO,
						SEP.VALOR,
						ZDEPARA_PFUNC.HORASMES,
						SEP.DATA,
						SEP.IND_CODIGO_SALARIO,
						SEP.INDQTDE,	
						ORDENACAO_SALARIOS.DATA_ALTERADA

			UNION ALL

			/* CRIA HISTÓRICO DE ADMISSÃO PARA QUEM NÃO POSSUI */
			SELECT ZDEPARA_PFUNC.CODCOLIGADA,
				   ZDEPARA_PFUNC.CHAPA AS "Chapa",
				   1 AS ID,
				   REPLACE(CONVERT(VARCHAR,ZDEPARA_PFUNC.DATAADMISSAO,103),'/','') + ' 00:01:00' AS "Data de mudança (ddmmaaaa hh:mm:ss)",
				   '01' /* Admissão */ AS "Motivo de alteração salarial",
				   1 AS "Número do salário",
				   '0,00' AS "Valor atual do salário",
				   CASE WHEN ZDEPARA_PFUNC.HORASMES = '22500' THEN '220:00' --#Ver
					 	WHEN RIGHT('000' + REPLACE(CAST(CAST(REPLACE(ZDEPARA_PFUNC.HORASMES,',','.') AS NUMERIC(5,2)) AS VARCHAR(20)),'.',':'),6) = '000:00' THEN '000:01'
				        WHEN RIGHT('000' + REPLACE(CAST(CAST(REPLACE(ZDEPARA_PFUNC.HORASMES,',','.') AS NUMERIC(5,2)) AS VARCHAR(20)),'.',':'),6) > '546:07' THEN '220:00'
						ELSE RIGHT('000' + REPLACE(CAST(CAST(REPLACE(ZDEPARA_PFUNC.HORASMES,',','.') AS NUMERIC(5,2)) AS VARCHAR(20)),'.',':'),6) 
				   END AS "Jornada de Trabalho",
				   REPLACE(CONVERT(VARCHAR,ZDEPARA_PFUNC.DATAADMISSAO,103),'/','') + ' 00:01:00' AS "Data de referência da alteração salarial (ddmmaaaa hh:mm:ss)",
				   NULL AS "Código do evento de salário",
				   NULL AS "Data da inclusão do aumento salarial",
				   NULL AS "Alteração de Jornada?",
				   NULL AS "Percentual Aplicado",
				   NULL AS "Historico Tabela Salarial",
				   NULL AS "Historico Faixa",
				   NULL AS "Historico Nivel",
				   NULL AS "Identificador de executação da Alteração Global de Salário.",
				   NULL AS "Referência",
				   NULL AS CAMPOEXTRA
			  FROM ZDEPARA_PFUNC
			  JOIN SEP
			    ON SEP.EMP_CODIGO = ZDEPARA_PFUNC.EMP_CODIGO
			   AND SEP.EPG_CODIGO = ZDEPARA_PFUNC.EPG_CODIGO
			 WHERE NOT EXISTS (SELECT 1
			                     FROM SEP
								WHERE SEP.EMP_CODIGO = ZDEPARA_PFUNC.EMP_CODIGO
								  AND SEP.EPG_CODIGO = ZDEPARA_PFUNC.EPG_CODIGO
								  AND CONVERT(DATE,SEP.DATA,103) = ZDEPARA_PFUNC.DATAADMISSAO)
		  GROUP BY ZDEPARA_PFUNC.CODCOLIGADA,
		           ZDEPARA_PFUNC.CHAPA,
				   ZDEPARA_PFUNC.DATAADMISSAO,
				   ZDEPARA_PFUNC.HORASMES

					) TABELA
 WHERE TABELA.ID = 1
   AND TABELA.[VALOR ATUAL DO SALÁRIO] IS NOT NULL