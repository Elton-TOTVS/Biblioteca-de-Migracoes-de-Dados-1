----------------------------------------------------------------------------------------------------      
-- Script:					ZMIGRA_PFHSTCSD
-- Última Alteração:		14/08/2024     
-- Versão:					1 
-- Origem:					FORTES
-- Autor Alteração:			Rafael Stroppa
----------------------------------------------------------------------------------------------------

IF OBJECT_ID('ZMIGRA_PFHSTCSD') IS NOT NULL 
   DROP TABLE ZMIGRA_PFHSTCSD;

SELECT ZDEPARA_PFUNC.CODCOLIGADA, --NÃO SERÁ USADO NO LAYOUT 

	   ZDEPARA_PFUNC.CHAPA,
       REPLACE(CONVERT(VARCHAR,FOL.DTCALCULO,103),'/','') AS "Data de contribuição",
       ZDEPARA_SINDICATOS.CODIGO_PARA AS "Código do sindicato",
       REPLACE(CAST(CAST(SUM(CAST(EFP.VALOR AS DECIMAL(15,2))) AS NUMERIC(15,2)) AS VARCHAR(20)),'.',',') AS "Valor da contribuição",
	   0 AS CAMPOEXTRA,
	   NULL AS CAMPOEXTRA2
  INTO ZMIGRA_PFHSTCSD
  FROM EFP 
       INNER JOIN ZDEPARA_PFUNC 
	           ON ZDEPARA_PFUNC.EMP_CODIGO = EFP.EMP_CODIGO
			  AND ZDEPARA_PFUNC.EPG_CODIGO = EFP.EFO_EPG_CODIGO
	   INNER JOIN EFO
	              INNER JOIN FOL 
				          ON FOL.EMP_CODIGO = EFO.EMP_CODIGO
						 AND FOL.SEQ        = EFO.FOL_SEQ
	              INNER JOIN SEP 
				             INNER JOIN ZDEPARA_SINDICATOS
							         ON ZDEPARA_SINDICATOS.CODIGO_DE = SEP.SIN_CODIGO
				          ON SEP.EMP_CODIGO = EFO.EMP_CODIGO
						 AND SEP.EPG_CODIGO = EFO.EPG_CODIGO
						 AND SEP.DATA       = EFO.SEP_DATA
	           ON EFO.EMP_CODIGO = EFP.EMP_CODIGO
			  AND EFO.EPG_CODIGO = EFP.EFO_EPG_CODIGO
			  AND EFO.FOL_SEQ    = EFP.EFO_FOL_SEQ
 WHERE EFP.EVE_CODIGO IN ('312')
 GROUP BY ZDEPARA_PFUNC.CODCOLIGADA,
	      ZDEPARA_PFUNC.CHAPA,
          FOL.DTCALCULO,
		  ZDEPARA_SINDICATOS.CODIGO_PARA 
