----------------------------------------------------------------------------------------------------      
-- Script:					ZDEPARA_PFUNC
-- Última Alteração:		14/08/2024     
-- Versão:					1 
-- Origem:					FORTES
-- Autor Alteração:			Rafael Stroppa
----------------------------------------------------------------------------------------------------

IF OBJECT_ID('ZDEPARA_PFUNC') IS NOT NULL 
   DROP TABLE ZDEPARA_PFUNC;

SELECT SEP.EMP_CODIGO,
       SEP.EPG_CODIGO,
	   EPG.CPF,
	   ZDEPARA_COLIGADAS.CODCOLIGADA AS COLIGADA,
	   ZDEPARA_COLIGADAS.NOME AS EMP_NOME,
	   > INSERIR SCRIPT DE CHAPA AQUI <
	   SEP.DATA,
	   EPG.NOME,
	   CASE WHEN EPG.DTRESCISAO IS NOT NULL THEN 'D' --DEMITIDO
	       
		    WHEN EXISTS (SELECT 1 
			               FROM LIC
						  WHERE LIC.EMP_CODIGO = SEP.EMP_CODIGO
						    AND LIC.EPG_CODIGO = SEP.EPG_CODIGO
							AND LIC.TLI_CODIGO = '01'
							AND CAST(GETDATE() AS DATE) BETWEEN CAST(LIC.DTINICIAL AS DATE) AND ISNULL(CAST(LIC.DTFINAL AS DATE), DATEADD(DAY,1,CAST(GETDATE() AS DATE)))
							AND SUBSTRING(CONVERT(VARCHAR,LIC.DTINICIAL,112),1,6) < SUBSTRING(CONVERT(VARCHAR,GETDATE(),112),1,6))
			THEN 'F' --FÉRIAS

			WHEN EXISTS (SELECT 1 
			               FROM LIC
						  WHERE LIC.EMP_CODIGO = SEP.EMP_CODIGO
						    AND LIC.EPG_CODIGO = SEP.EPG_CODIGO
							AND LIC.TLI_CODIGO = '01'
							AND CAST(GETDATE() AS DATE) BETWEEN CAST(LIC.DTINICIAL AS DATE) AND ISNULL(CAST(LIC.DTFINAL AS DATE), DATEADD(DAY,1,CAST(GETDATE() AS DATE)))
							AND SUBSTRING(CONVERT(VARCHAR,LIC.DTINICIAL,112),1,6) = SUBSTRING(CONVERT(VARCHAR,GETDATE(),112),1,6))
			THEN 'A' --ATIVO

			WHEN EXISTS (SELECT 1 
			               FROM LIC
						  WHERE LIC.EMP_CODIGO = SEP.EMP_CODIGO
						    AND LIC.EPG_CODIGO = SEP.EPG_CODIGO
							AND CAST(GETDATE() AS DATE) BETWEEN CAST(LIC.DTINICIAL AS DATE) AND ISNULL(CAST(LIC.DTFINAL AS DATE), DATEADD(DAY,1,CAST(GETDATE() AS DATE))))
			
			--SELECT * FROM TLI
			
			--01	Férias
			--02	Licença-maternidade
			--03	Licença por motivo de doença superior a 15 dias
			--04	Licença por motivo de acidente de trabalho
			--05	Licença para prestação de serviço militar
			--06	Licença não remunerada
			--07	Prorrogação de Licença-Maternidade
			--08	Licença por motivo de aborto não criminoso
			--09	Licença-Maternidade adoção/guarda até 1 ano(120 dias)
			--10	Licença maternidade do empregado do MEI
			--11	Prorrogação de Licença maternidade do empregado do MEI
			--12	Licença em decorrencia do mesmo acidente de trabalho    
			--13	Licença em decorrencia da mesma doença (até 60 dias após)
			--14	Licença por motivo de doença inferior a 15 dias
			--15	Licença por motivo de acidente de trabalho inf. a 15 dias
			--16	Licença por motivo de doença - superior a 15 dias
			--17	Licença por motivo de doença igual ou inferior 15 dias
			--18	Licença por motivo de doença
			--19	Aposentadoria por Invalidez
			--20	Suspensão temporária do contrato de trabalho MP 936/2020
			--21	(BKP 21) Licença por motivo de doença - superior a 15 dias
			--22	(BKP 22) Licença por motivo de doença igual ou inferior 15 d
			--23	(BKP 23) Licença por motivo de doença
			--24	(BKP 24) Licença por motivo de doença inferior a 15 dias
			--73	(BKP 73) Suspensão temporária do contrato de trabalho MP 936
			--74	(BKP 74) Licença por motivo de doença
			--75	Cárcere

			THEN (SELECT CASE WHEN LIC.TLI_CODIGO = '01' THEN 'F' -- Férias
                              WHEN LIC.TLI_CODIGO = '02' THEN 'E' -- Licença-maternidade
                              WHEN LIC.TLI_CODIGO = '03' THEN 'P' -- Licença por motivo de doença > que 15 dias
                              WHEN LIC.TLI_CODIGO = '04' THEN 'T' -- Licença por motivo de acidente de trabalho  > que 15 dias
							  WHEN LIC.TLI_CODIGO = '05' THEN 'M'  --Licença para prestação de serviço militar
                              WHEN LIC.TLI_CODIGO = '06' THEN 'L' -- Licença não remunerada
							  WHEN LIC.TLI_CODIGO = '08' THEN 'E' -- Licença por motivo de aborto não criminoso
                              WHEN LIC.TLI_CODIGO = '12' THEN 'T' -- Licença em decorrencia do mesmo acidente de trabalho    
                              WHEN LIC.TLI_CODIGO = '13' THEN 'P' -- Licença em decorrencia da mesma doença (até 60 dias após)
                              WHEN LIC.TLI_CODIGO = '14' THEN 'P' -- Licença por motivo de doença inferior a 15 dias
                              WHEN LIC.TLI_CODIGO = '15' THEN 'T' -- Licença por motivo de acidente de trabalho inf. a 15 dias
                              WHEN LIC.TLI_CODIGO = '16' THEN 'A' -- Transferencia para empresa do mesmo grupo
							  WHEN LIC.TLI_CODIGO = '17' THEN 'C'  --Suspensão temporária do contrato de trabalho MP 936/2020
							  WHEN LIC.TLI_CODIGO = '19' THEN 'I'  --Aposentadoria por Invalidez
							  WHEN LIC.TLI_CODIGO = '21' THEN 'P'  --(BKP 21) Licença por motivo de doença - superior a 15 dias
							  WHEN LIC.TLI_CODIGO = '75' THEN 'Q'  --Cárcere
						  END
			        FROM LIC 
				   WHERE LIC.EMP_CODIGO = SEP.EMP_CODIGO
					 AND LIC.EPG_CODIGO = SEP.EPG_CODIGO
					 AND CAST(GETDATE() AS DATE) BETWEEN CAST(LIC.DTINICIAL AS DATE) AND ISNULL(CAST(LIC.DTFINAL AS DATE), DATEADD(DAY,1,CAST(GETDATE() AS DATE))))
			ELSE 'A' -- ATIVO
		END AS CODSITUACAO,
	   CASE WHEN SEP.CATEGORIAESOCIAL = '101' THEN 'N' -- NORMAL      -- Empregado - Geral, inclusive o empregado público da administração direta ou indireta contratado pela CLT
	        WHEN SEP.CATEGORIAESOCIAL = '103' THEN 'Z' -- APRENDIZ    -- Empregado - Aprendiz
			WHEN SEP.CATEGORIAESOCIAL = '722' THEN 'D' -- DIRETOR     -- Contribuinte individual - Diretor não empregado, sem FGTS
	        WHEN SEP.CATEGORIAESOCIAL = '723' THEN 'D' -- DIRETOR     -- Contribuinte individual - Diretor não empregado, sem FGTS
            WHEN SEP.CATEGORIAESOCIAL = '901' THEN 'T' -- ESTAGIÁRIO  -- Estagiário
            ELSE 'N'
		END AS CODTIPO, 
	   CAST(EPG.ADMISSAODATA AS DATE) AS DATAADMISSAO,
	   CAST(EPG.DTRESCISAO AS DATE) AS DATADEMISSAO,
	   CAST(EPG.DTTRANSFERENCIA AS DATE) AS DTTRANSFERENCIA,
	   SEP.CAR_CODIGO,
	   SEP.IND_CODIGO_SALARIO,
	   IND.NOME AS IND_CODIGO,
	   SEP.EST_CODIGO,
	   SEP.HOR_CODIGO,
	   SEP.LOT_CODIGO,
	   SEP.SIN_CODIGO,
	   SEP.AIN_CODIGO,
	   SEP.EDU_CODIGO,
	   SEP.SALTIPO,
	   CASE WHEN SEP.SALTIPO = 'I' AND ( SELECT REPLACE(CAST(MAX(VID.VALOR) AS NUMERIC(15,2)),'.',',')
	                                       FROM VID 
										  WHERE VID.IND_CODIGO = SEP.IND_CODIGO_SALARIO
											AND VID.DATA BETWEEN CAST(EPG.ADMISSAODATA AS DATE) AND CAST(ISNULL(EPG.DTRESCISAO, GETDATE()) AS DATE)) IS NULL
			THEN (SELECT REPLACE(CAST(MAX(VID.VALOR) AS NUMERIC(15,2)),'.',',')
	                                       FROM VID 
										  WHERE VID.IND_CODIGO = SEP.IND_CODIGO_SALARIO)
			WHEN SEP.SALTIPO = 'I' THEN (SELECT REPLACE(CAST(MAX(VID.VALOR) AS NUMERIC(15,2)),'.',',')
	                                       FROM VID 
										  WHERE VID.IND_CODIGO = SEP.IND_CODIGO_SALARIO
											AND VID.DATA BETWEEN CAST(EPG.ADMISSAODATA AS DATE) AND CAST(ISNULL(EPG.DTRESCISAO, GETDATE()) AS DATE))
            ELSE REPLACE(CAST(CAST(REPLACE(SEP.VALOR,',','.') AS NUMERIC(15,2)) AS VARCHAR(20)),'.',',') 
	    END AS SALARIO,
	   SEP.HORASMES,
	   SEP.TIPOSALARIO,
	   SEP.COMISSIONADO,
	   SEP.TIPOPAGAMENTO,
	   SEP.VALETRANSPORTE,
	   RESCISAO.DIASTRABALHADOS,
       RESCISAO.SALDO_FGTS,
       RESCISAO.DATA_PGTO_RESCISAO,
       RESCISAO.DESCONTA_AVISO_PREV,
	   RESCISAO.MOTIVO_DEMISSAO,
	   RESCISAO.TIPO_DEMISSAO,
	   RESCISAO.DATAAVISO,
       RESCISAO.TIPOAVISO,
       RESCISAO.DIASAVISO,
       RESCISAO.CODIGOFGTS,
	   ZDEPARA_COLIGADAS.CODCOLIGADA,

	   --Verificar:
	   ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	   CASE WHEN MAX_SAL.DATA IS NULL OR MAX_SAL.DATA <	EPG.ADMISSAODATA THEN CAST(EPG.ADMISSAODATA AS DATE) ELSE MAX_SAL.DATA					END AS HST_SAL,    -- "Data da Mudança de Salário",    
	   CASE WHEN MAX_SAL.DATA <= CAST(EPG.ADMISSAODATA AS DATE)          THEN '01'	/*Admissão*/			 ELSE '15'	/*Acordo Coletivo*/		END AS MOTIVO_SAL, -- "Motivo da Mudança de Salário",

	   CASE WHEN MAX_FCO.DATA IS NULL OR MAX_FCO.DATA <	EPG.ADMISSAODATA THEN CAST(EPG.ADMISSAODATA AS DATE) ELSE MAX_FCO.DATA					END AS HST_FCO,	   -- "Data da Mudança de Função",   
	   CASE WHEN MAX_FCO.DATA <= CAST(EPG.ADMISSAODATA AS DATE)          THEN '01' /*Admissão*/			     ELSE '05'	/*Promoção*/     		END AS MOTIVO_FCO, -- "Motivo da Mudança de Função",
																     
	   CASE WHEN CAST(EPG.DTRESCISAO AS DATE) IS NULL					 THEN CAST(EPG.ADMISSAODATA AS DATE) ELSE CAST(EPG.DTRESCISAO AS DATE)  END AS HST_SIT,	   -- "Data da Mudança de Situação",    
	   CASE WHEN CAST(EPG.DTRESCISAO AS DATE) IS NULL			         THEN '01'	/*Admissão*/			 ELSE '08'	/*Demissão*/			END AS MOTIVO_SIT, -- "Motivo da Mudança de Situação",  
																     
	   CASE WHEN MAX_SEC.DATA IS NULL OR MAX_SEC.DATA <	EPG.ADMISSAODATA THEN CAST(EPG.ADMISSAODATA AS DATE) ELSE MAX_SEC.DATA					END AS HST_SEC,	   -- "Data da Mudança de Seção",    
	   CASE WHEN MAX_SEC.DATA <= CAST(EPG.ADMISSAODATA AS DATE)	         THEN '01'	/*Admissão*/			 ELSE '04'	/*Remanejamento*/		END AS MOTIVO_SEC, -- "Motivo da Mudança de Seção",    
	   ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	   
	   CASE WHEN TRIM(EPG.AGE_BAN_CODIGO) = '' THEN NULL ELSE TRIM(EPG.AGE_BAN_CODIGO) END AS AGE_BAN_CODIGO, 
	   CASE WHEN TRIM(EPG.AGE_CODIGO) = '' THEN NULL ELSE TRIM(EPG.AGE_CODIGO) END AS AGE_CODIGO,
	   CASE WHEN TRIM(EPG.CONTACORRENTENUMERO) = '' THEN NULL ELSE TRIM(EPG.CONTACORRENTENUMERO) END AS CONTACORRENTENUMERO,

	   GETDATE() AS CRIADO_EM,
	   EPG.CNPJEMPREGADORANTERIOR,
	   EPG.MATRICULAANTERIOR
  INTO ZDEPARA_PFUNC
  FROM EPG 
       INNER JOIN ZDEPARA_COLIGADAS 
	           ON ZDEPARA_COLIGADAS.EMP_CODIGO = EPG.EMP_CODIGO
       INNER JOIN SEP
	              INNER JOIN (SELECT EMP_CODIGO, EPG_CODIGO, MAX(DATA) AS DATA 
				                FROM SEP 
							   GROUP BY EMP_CODIGO, EPG_CODIGO) MAX_SEP
						  ON MAX_SEP.EMP_CODIGO = SEP.EMP_CODIGO
						 AND MAX_SEP.EPG_CODIGO = SEP.EPG_CODIGO
						 AND MAX_SEP.DATA       = SEP.DATA
				  LEFT  JOIN IND 
				          ON IND.CODIGO = SEP.IND_CODIGO_SALARIO
				  LEFT  JOIN (SELECT S.EPG_CODIGO,
                                     S.EMP_CODIGO,
	                                 CAST(MIN(S.DATA) AS DATE) AS DATA
                                FROM SEP S
                               WHERE S.VALOR = (SELECT MAX(SS.VALOR)
                                                  FROM SEP SS
                              					 WHERE SS.EMP_CODIGO = S.EMP_CODIGO
                              					   AND SS.EPG_CODIGO = S.EPG_CODIGO)
				               GROUP BY S.EPG_CODIGO,
                                        S.EMP_CODIGO) AS MAX_SAL
			              ON MAX_SAL.EMP_CODIGO = SEP.EMP_CODIGO
			             AND MAX_SAL.EPG_CODIGO = SEP.EPG_CODIGO
				  LEFT  JOIN (SELECT S.EPG_CODIGO,
                                     S.EMP_CODIGO,
									 S.CAR_CODIGO,
	                                 CAST(MIN(S.DATA) AS DATE) AS DATA
                                FROM SEP S
				               GROUP BY S.EPG_CODIGO,
                                        S.EMP_CODIGO,
										S.CAR_CODIGO) AS MAX_FCO
			              ON MAX_FCO.EMP_CODIGO = SEP.EMP_CODIGO
			             AND MAX_FCO.EPG_CODIGO = SEP.EPG_CODIGO
						 AND MAX_FCO.CAR_CODIGO = SEP.CAR_CODIGO
				  LEFT  JOIN (SELECT S.EPG_CODIGO,
                                     S.EMP_CODIGO,
									 S.EST_CODIGO,
									 S.LOT_CODIGO,
	                                 CAST(MIN(S.DATA) AS DATE) AS DATA
                                FROM SEP S
				               GROUP BY S.EPG_CODIGO,
                                        S.EMP_CODIGO,
										S.EST_CODIGO,
									    S.LOT_CODIGO) AS MAX_SEC
			              ON MAX_SEC.EMP_CODIGO = SEP.EMP_CODIGO
			             AND MAX_SEC.EPG_CODIGO = SEP.EPG_CODIGO
						 AND MAX_SEC.EST_CODIGO = SEP.EST_CODIGO
						 AND MAX_SEC.LOT_CODIGO = SEP.LOT_CODIGO
	           ON SEP.EMP_CODIGO = EPG.EMP_CODIGO
			  AND SEP.EPG_CODIGO = EPG.CODIGO
	   LEFT  JOIN (  
					 SELECT ROW_NUMBER() OVER (PARTITION BY EFO.EMP_CODIGO, EFO.EPG_CODIGO ORDER BY REC.FOL_SEQ DESC) AS ID,
	                        EFO.EMP_CODIGO,
                            EFO.EPG_CODIGO,
                    		REC.FOL_SEQ,
                    		EFO.SEP_DATA,
                    		REC.TRC_CODIGO,
                    		TRC.DESCRICAO,
                    		FOL.ENCERRADA,
                    		FOL.DTCALCULO,
                    		EFO.DIASTRABALHADOS,
                    		REC.SALDOCEF AS SALDO_FGTS,
                    		REC.DATAPAGAMENTO AS DATA_PGTO_RESCISAO,
							REC.DATAAVISO,
							REC.TIPOAVISO,
							REC.DIASAVISO,
							TRC.CODIGOFGTS,
							CASE WHEN REC.DISPINDAVISO = 'S'	   THEN 1 ELSE 0 END AS DESCONTA_AVISO_PREV,
                    		CASE WHEN TRC.TB_MOT_DES_CODIGO = '01' THEN '1' --	RESCISÃO COM JUSTA CAUSA, POR INICIATIVA DO EMPREGADOR
                                 WHEN TRC.TB_MOT_DES_CODIGO = '02' THEN '2' --	RESCISÃO SEM JUSTA CAUSA, POR INICIATIVA DO EMPREGADOR
                                 WHEN TRC.TB_MOT_DES_CODIGO = '03' THEN 'T' --	RESCISÃO ANTECIPADA DO CONTRATO A TERMO POR INICIATIVA DO EMPREGADOR
                                 WHEN TRC.TB_MOT_DES_CODIGO = '04' THEN 'T' --	RESCISÃO ANTECIPADA DO CONTRATO A TERMO POR INICIATIVA DO EMPREGADO
                                 WHEN TRC.TB_MOT_DES_CODIGO = '05' THEN 'C' --	RESCISÃO POR CULPA RECÍPROCA
                                 WHEN TRC.TB_MOT_DES_CODIGO = '06' THEN 'T' --	RESCISÃO POR TÉRMINO DO CONTRATO A TERMO
                                 WHEN TRC.TB_MOT_DES_CODIGO = '07' THEN '4' --	RESCISÃO DO CONTRATO DE TRABALHO POR INICIATIVA DO EMPREGADO
                                 WHEN TRC.TB_MOT_DES_CODIGO = '10' THEN '8' --	RESCISÃO POR FALECIMENTO DO EMPREGADO
                                 WHEN TRC.TB_MOT_DES_CODIGO = '11' THEN '5' --	TRANSFERÊNCIA DE EMPREGADO PARA EMPRESA DO MESMO GRUPO EMPRESARIAL QUE TENHA ASSUMIDO OS ENCARGOS TRABALHISTAS, SEM QUE TENHA HAVIDO RESCISÃO DO CONTRATO DE TRABALHO
                                 WHEN TRC.TB_MOT_DES_CODIGO = '14' THEN 'G' --	RESCISÃO DO CONTRATO DE TRABALHO POR ENCERRAMENTO DA EMPRESA, DE SEUS ESTABELECIMENTOS OU SUPRESSÃO DE PARTE DE SUAS ATIVIDADES OU FALECIMENTO DO EMPREGADOR INDIVIDUAL OU EMPREGADOR DOMÉSTICO SEM CONTINUAÇÃO DA ATIVIDADE
                                 WHEN TRC.TB_MOT_DES_CODIGO = '17' THEN 'N' --	RESCISÃO INDIRETA DO CONTRATO DE TRABALHO
                                 WHEN TRC.TB_MOT_DES_CODIGO = '19' THEN 'I' --	APOSENTADORIA POR IDADE (SOMENTE PARA CATEGORIAS DE TRABALHADORES 301 A 309)
                                 WHEN TRC.TB_MOT_DES_CODIGO = '26' THEN 'G' --	RESCISÃO DO CONTRATO DE TRABALHO POR PARALISAÇÃO TEMPORÁRIA OU DEFINITIVA DA EMPRESA, ESTABELECIMENTO OU PARTE DAS ATIVIDADES MOTIVADA POR ATOS DE AUTORIDADE MUNICIPAL, ESTADUAL OU FEDERAL
                                 WHEN TRC.TB_MOT_DES_CODIGO = '33' THEN 'V' --	RESCISÃO POR ACORDO ENTRE AS PARTES (ART. 484-A DA CLT)
                    			 ELSE '99'-- IMPLANTAÇÃO ERP
                             END AS TIPO_DEMISSAO,
							CASE WHEN TRC.TB_MOT_DES_CODIGO = '01'				THEN '04' -- REDUCAO DE QUADRO
                                 WHEN TRC.TB_MOT_DES_CODIGO = '02'				THEN '04' -- REDUCAO DE QUADRO
                                 WHEN TRC.TB_MOT_DES_CODIGO = '07'				THEN '05' -- PEDIDO DE DEMISSAO
                                 WHEN TRC.TB_MOT_DES_CODIGO = '11'				THEN '07' -- TRANSFERÂNCIA ENTRE FILIAIS
                                 WHEN TRC.TB_MOT_DES_CODIGO = '10'				THEN '04' -- REDUCAO DE QUADRO
                                 WHEN TRC.TB_MOT_DES_CODIGO IN ('03','04','06') THEN '04' -- REDUCAO DE QUADRO
                                 WHEN TRC.TB_MOT_DES_CODIGO = '33'				THEN '03' -- NEGOCIAÇÃO HABITUAL                             
                    			 ELSE '99'-- IMPLANTAÇÃO ERP
                             END AS MOTIVO_DEMISSAO
                       FROM REC 
                            INNER JOIN EFO 
                    		           INNER JOIN FOL 
                    				           ON FOL.EMP_CODIGO = EFO.EMP_CODIGO
                    						  AND FOL.SEQ        = EFO.FOL_SEQ
                    		        ON EFO.EMP_CODIGO = REC.EMP_CODIGO 
                    			   AND EFO.FOL_SEQ    = REC.FOL_SEQ
                    	    INNER JOIN TRC 
                    		        ON TRC.CODIGO = REC.TRC_CODIGO
									
									) RESCISAO 
	           ON RESCISAO.EMP_CODIGO = EPG.EMP_CODIGO 
			  AND RESCISAO.EPG_CODIGO = EPG.CODIGO
			  AND RESCISAO.ID         = 1

