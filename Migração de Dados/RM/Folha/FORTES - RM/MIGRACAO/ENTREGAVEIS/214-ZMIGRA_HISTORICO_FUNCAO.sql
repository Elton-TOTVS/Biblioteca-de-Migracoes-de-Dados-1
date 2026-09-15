----------------------------------------------------------------------------------------------------      
-- Script:					ZMIGRA_PFHSTFCO
-- Última Alteração:		14/08/2024     
-- Versão:					1 
-- Origem:					FORTES
-- Autor Alteração:			Rafael Stroppa
----------------------------------------------------------------------------------------------------

IF OBJECT_ID('ZMIGRA_PFHSTFCO') IS NOT NULL 
   DROP TABLE ZMIGRA_PFHSTFCO;

WITH ORDENACAO_FUNCOES AS (
	SELECT EMP_CODIGO,
		   EPG_CODIGO,
		   DATA,
		   CAR_CODIGO,
		   DATEADD(MINUTE, ROW_NUMBER() OVER(PARTITION BY EMP_CODIGO, EPG_CODIGO, DATA ORDER BY EMP_CODIGO, EPG_CODIGO, DATA)-1, DATA) AS DATA_ALTERADA
      FROM SEP)

SELECT ZDEPARA_PFUNC.CODCOLIGADA, --NÃO SERÁ USADO NO LAYOUT

	   ZDEPARA_PFUNC.CHAPA,
	   CASE WHEN CAST(SEP.DATA AS DATE) <= ZDEPARA_PFUNC.DATAADMISSAO THEN REPLACE(CONVERT(VARCHAR,ZDEPARA_PFUNC.DATAADMISSAO,103),'/','') + ' 00:01:00'
			ELSE REPLACE(CONVERT(VARCHAR(10),ORDENACAO_FUNCOES.DATA_ALTERADA,103),'/','')+' '+CONVERT(VARCHAR(8),ORDENACAO_FUNCOES.DATA_ALTERADA,108) 
	   END AS "Data da Mudança (ddmmaaaa hh:mm:ss)",
	   CASE WHEN CAST(SEP.DATA AS DATE) <= ZDEPARA_PFUNC.DATAADMISSAO THEN '01' ELSE '05' END AS "Código do Motivo da Mud. De Função",
	   ZDEPARA_FUNCOES.CODIGO_PARA AS "Código da Função",
       NULL AS "Nível Salarial",
       NULL AS "Faixa Salarial",
	   NULL AS CAMPOEXTRA1

  INTO ZMIGRA_PFHSTFCO
  FROM SEP 
       INNER JOIN ( 
				  SELECT X.*
                    FROM (
							SELECT ZSEP.EMP_CODIGO,
                  	               ZSEP.EPG_CODIGO,
                  	               ZSEP.DATA,
                  	               ZSEP.CAR_CODIGO,
								   (SELECT MIN(S.DATA)
                  	                  FROM SEP S 
  									 WHERE S.EMP_CODIGO = ZSEP.EMP_CODIGO
                  	                   AND S.EPG_CODIGO = ZSEP.EPG_CODIGO
                  	                   AND S.CAR_CODIGO <> ZSEP.CAR_CODIGO 
                  	                   AND S.DATA       >= ZSEP.DATA) AS DATA_NOVA_FUNCAO,
								   ROW_NUMBER() OVER (PARTITION BY ZSEP.EMP_CODIGO, ZSEP.EPG_CODIGO,(SELECT MIN(S.DATA)
                  																					   FROM SEP S 
                  																					  WHERE S.EMP_CODIGO = ZSEP.EMP_CODIGO
                  																					    AND S.EPG_CODIGO = ZSEP.EPG_CODIGO
                  																					    AND S.CAR_CODIGO <> ZSEP.CAR_CODIGO 
                  																						AND S.DATA       >= ZSEP.DATA)
														  ORDER BY ZSEP.DATA ) AS ID		
														  
														  /*ORDER BY ISNULL((SELECT MIN(S.DATA)
                  															FROM SEP S 
                  															WHERE S.EMP_CODIGO = ZSEP.EMP_CODIGO
                  															AND S.EPG_CODIGO = ZSEP.EPG_CODIGO
                  															AND S.CAR_CODIGO <> ZSEP.CAR_CODIGO 
                  															AND S.DATA       >= ZSEP.DATA),ZSEP.DATA)) AS ID*/

									  FROM SEP ZSEP ) X 
				  WHERE X.ID = 1 ) MENOR_DATA
			   ON MENOR_DATA.EMP_CODIGO = SEP.EMP_CODIGO
			  AND MENOR_DATA.EPG_CODIGO = SEP.EPG_CODIGO
			  AND MENOR_DATA.DATA       = SEP.DATA
       INNER JOIN ZDEPARA_PFUNC
               ON ZDEPARA_PFUNC.EMP_CODIGO = SEP.EMP_CODIGO
              AND ZDEPARA_PFUNC.EPG_CODIGO = SEP.EPG_CODIGO
	   INNER JOIN ZDEPARA_FUNCOES 
               ON ZDEPARA_FUNCOES.EMPRESA_DE = SEP.EMP_CODIGO
			  AND ZDEPARA_FUNCOES.CODIGO_DE  = SEP.CAR_CODIGO
	   INNER JOIN ORDENACAO_FUNCOES
	           ON ORDENACAO_FUNCOES.EMP_CODIGO = SEP.EMP_CODIGO
			  AND ORDENACAO_FUNCOES.EPG_CODIGO = SEP.EPG_CODIGO
			  AND ORDENACAO_FUNCOES.DATA = SEP.DATA
			  AND ORDENACAO_FUNCOES.CAR_CODIGO = SEP.CAR_CODIGO
