----------------------------------------------------------------------------------------------------      
-- Script:					ZMIGRA_PFHSTSEC
-- Última Alteração:		14/08/2024     
-- Versão:					1 
-- Origem:					FORTES
-- Autor Alteração:			Rafael Stroppa
----------------------------------------------------------------------------------------------------

IF OBJECT_ID('ZMIGRA_PFHSTSEC') IS NOT NULL 
   DROP TABLE ZMIGRA_PFHSTSEC;

SELECT ZDEPARA_PFUNC.CODCOLIGADA, --NÃO SERÁ USADO NO LAYOUT

       ZDEPARA_PFUNC.CHAPA AS "Chapa",
       REPLACE(CONVERT(VARCHAR,SEP.DATA,103),'/','') + ' 00:00:00' AS "Data da Mudança (ddmmaaaa hh:mm:ss)",
       CASE WHEN SEP.DATA <= ZDEPARA_PFUNC.DATAADMISSAO THEN '01' ELSE '04' END AS "Código do Motivo da Mud. De Seção",
	   ZDEPARA_SECOES.CODIGO_PARA AS "Código da Seção"
  INTO ZMIGRA_PFHSTSEC
  FROM SEP 
       INNER JOIN ZDEPARA_PFUNC 
	           ON ZDEPARA_PFUNC.EMP_CODIGO = SEP.EMP_CODIGO 
			  AND ZDEPARA_PFUNC.EPG_CODIGO = SEP.EPG_CODIGO
	   INNER JOIN ZDEPARA_SECOES 
	           ON ZDEPARA_SECOES.EMPRESA_DE = SEP.EMP_CODIGO 
			  AND ZDEPARA_SECOES.FILIAL_DE  = SEP.EST_CODIGO 
			  AND ZDEPARA_SECOES.CODIGO_DE  = SEP.LOT_CODIGO 
	   INNER JOIN (SELECT X.* 
	                 FROM ( SELECT ZSEP.EMP_CODIGO,
                            	   ZSEP.EPG_CODIGO,
                            	   ZSEP.EST_CODIGO,
                            	   ZSEP.LOT_CODIGO,
                            	   ZS.CODIGO_DE,
                            	   ZSEP.DATA,
                            	   (SELECT MIN(S.DATA)
                            	      FROM SEP S 
                            		       INNER JOIN ZDEPARA_SECOES Z
                            	                   ON Z.EMPRESA_DE = S.EMP_CODIGO 
                            			          AND Z.FILIAL_DE = S.EST_CODIGO 
                            			          AND Z.CODIGO_DE = S.LOT_CODIGO 
                            		 WHERE S.EMP_CODIGO = ZSEP.EMP_CODIGO
                            		   AND S.EPG_CODIGO = ZSEP.EPG_CODIGO
                            		   AND Z.CODIGO_DE  <> ZS.CODIGO_DE
                            		   AND S.DATA       > ZSEP.DATA) AS PROX_MUDANCA_SECAO,
                            	   ROW_NUMBER() OVER (PARTITION BY ZSEP.EMP_CODIGO, ZSEP.EPG_CODIGO, (SELECT MIN(S.DATA)
                            	                                                                        FROM SEP S 
                            		                                                                   INNER JOIN ZDEPARA_SECOES Z
                            	                                                                               ON Z.EMPRESA_DE = S.EMP_CODIGO
                            		                                                                          AND Z.FILIAL_DE  = S.EST_CODIGO
                            		                                                                          AND Z.CODIGO_DE  = S.LOT_CODIGO
                            		                                                                   WHERE S.EMP_CODIGO = ZSEP.EMP_CODIGO
                            		                                                                     AND S.EPG_CODIGO = ZSEP.EPG_CODIGO
                            		                                                                     AND Z.CODIGO_DE  <> ZS.CODIGO_DE
                            		                                                                     AND S.DATA       >= ZSEP.DATA)
                            							  ORDER BY ZSEP.DATA
														  
														  /*ISNULL((SELECT MIN(S.DATA)
                            												 FROM SEP S 
                            												INNER JOIN ZDEPARA_SECOES Z
                            												   ON Z.EMPRESA_DE = S.EMP_CODIGO 
                            												  AND Z.FILIAL_DE  = S.EST_CODIGO 
                            												  AND Z.CODIGO_DE  = S.LOT_CODIGO 
                            											    WHERE S.EMP_CODIGO = ZSEP.EMP_CODIGO
                            												  AND S.EPG_CODIGO = ZSEP.EPG_CODIGO
                            												  AND Z.CODIGO_DE  <> ZS.CODIGO_DE
                            												  AND S.DATA       > ZSEP.DATA),ZSEP.DATA)*/
																) AS ID 
                              FROM SEP ZSEP
  						     INNER JOIN ZDEPARA_PFUNC ZP
                                ON ZP.EMP_CODIGO = ZSEP.EMP_CODIGO 
                               AND ZP.EPG_CODIGO = ZSEP.EPG_CODIGO
                             INNER JOIN ZDEPARA_SECOES ZS
                   	            ON ZS.EMPRESA_DE = ZSEP.EMP_CODIGO 
                               AND ZS.FILIAL_DE = ZSEP.EST_CODIGO 
							   AND ZS.CODIGO_DE = ZSEP.LOT_CODIGO 
                             ) X 
					WHERE X.ID = 1
                ) MAX_SECAO 
			   ON MAX_SECAO.EMP_CODIGO = SEP.EMP_CODIGO 
			  AND MAX_SECAO.EPG_CODIGO = SEP.EPG_CODIGO
			  AND MAX_SECAO.DATA       = SEP.DATA