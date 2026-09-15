----------------------------------------------------------------------------------------------------      
-- Script:					ZMIGRA_PFUFERIAS (Período Aquisitivo)
-- Última Alteração:		14/08/2024     
-- Versão:					1 
-- Origem:					FORTES
-- Autor Alteração:			Rafael Stroppa
----------------------------------------------------------------------------------------------------

IF OBJECT_ID('ZMIGRA_PFUFERIAS') IS NOT NULL 
   DROP TABLE ZMIGRA_PFUFERIAS;

DECLARE @COMPETENCIA VARCHAR(8) = '202608' --#Ver: Ajustar competência para férias (AAAAMM)

SELECT DADOS.CODCOLIGADA, --NÃO SERÁ USADO NO LAYOUT
	   DADOS.CHAPA,
       DADOS."Data final do período aquisitivo",
       DADOS."Data inicial do período aquisitivo",
       CAST(DADOS."Saldo do período de férias" AS INT) "Saldo do período de férias",
	   CASE WHEN ROW_NUMBER() OVER (PARTITION BY DADOS.CODCOLIGADA, DADOS.CHAPA 
	                                    ORDER BY SUBSTRING(DADOS."DATA FINAL DO PERÍODO AQUISITIVO",5,4) DESC, 
										         SUBSTRING(DADOS."DATA FINAL DO PERÍODO AQUISITIVO",5,4) + '-' + 
												 SUBSTRING(DADOS."DATA FINAL DO PERÍODO AQUISITIVO",3,2) + '-' + 
												 SUBSTRING(DADOS."DATA FINAL DO PERÍODO AQUISITIVO",1,2) DESC) > 1 
		    THEN 0 
			ELSE 1 
	   END AS "Indicativo de período aquisitivo aberto",
       DADOS."Indicativo de período aquisitivo perdido",
       DADOS."Motivo da perda do período aquisitivo",
       DADOS."Faltas ocorridas no período aquisitivo",
       DADOS."Bônus",
       DADOS.CAMPOEXTRA
  INTO ZMIGRA_PFUFERIAS
  FROM (
        
		/* PERIODOS EXISTENTES */
        
		SELECT 1 AS ID, 
		       ZDEPARA_PFUNC.CODCOLIGADA,
               ZDEPARA_PFUNC.CHAPA,
               ZDEPARA_PFUNC.CODSITUACAO,
			   PAE.DTINICIAL,
			   --REPLACE(CONVERT(VARCHAR,PAE.DTFINAL,103),'/','') AS "Data final do período aquisitivo",
		       
			   --GERAR DATA FINAL PERÍODO AQUISITIVO PARA PAE.DTFINAL IS NULL ACORDADO COM O CLIENTE
			   CASE WHEN PAE.DTFINAL IS NULL THEN REPLACE(CONVERT(VARCHAR,DATEADD(DAY,365,DATEADD(DAY,-1,PAE.DTINICIAL)),103),'/','') 
			        ELSE REPLACE(CONVERT(VARCHAR,PAE.DTFINAL,103),'/','') 
			   END AS "Data final do período aquisitivo", --PARTICULARIDADE DO PROJETO NOSSA FRUTA
			   
               REPLACE(CONVERT(VARCHAR,PAE.DTINICIAL,103),'/','') AS "Data inicial do período aquisitivo",
               CASE WHEN PAE.DTFINAL IS NULL THEN PAE.DIASDIREITO - SUM(ISNULL(CASE WHEN FOL.ENCERRADA = 'S' THEN CAST(PAE.DIASGOZADOS AS DECIMAL(10,2)) ELSE 0 END,0))
			        ELSE SUM(ISNULL(CASE WHEN FOL.ENCERRADA = 'S' THEN CAST(PAE.DIASDIREITO AS DECIMAL(10,2)) ELSE 0 END,0)) - 
			             SUM(ISNULL(CASE WHEN FOL.ENCERRADA = 'S' THEN CAST(PAE.DIASGOZADOS AS DECIMAL(10,2)) ELSE 0 END,0)) 
			   END AS "Saldo do período de férias",
               0 AS "Indicativo de período aquisitivo aberto",   
               0 AS "Indicativo de período aquisitivo perdido",
               NULL AS "Motivo da perda do período aquisitivo",
               SUM(ISNULL(CASE WHEN FOL.ENCERRADA = 'S' THEN PAF.FALTAS ELSE 0 END,0)) AS "Faltas ocorridas no período aquisitivo",
               '0,00' AS "Bônus",  
               NULL AS CAMPOEXTRA
          FROM PAE 
               INNER JOIN ZDEPARA_PFUNC 
	                   ON ZDEPARA_PFUNC.EMP_CODIGO = PAE.EMP_CODIGO 
		        	  AND ZDEPARA_PFUNC.EPG_CODIGO = PAE.EPG_CODIGO
	           LEFT JOIN PAF 
			             LEFT  JOIN FOL 
							     ON FOL.EMP_Codigo = PAF.FER_EMP_Codigo
							    AND FOL.SEQ        = PAF.FER_EFO_FOL_SEQ
								--AND FOL.ENCERRADA  = 'S' --#Ver
	                   ON PAF.FER_EMP_CODIGO     = PAE.EMP_CODIGO 
			          AND PAF.FER_EFO_EPG_CODIGO = PAE.EPG_CODIGO
			          AND PAF.PAE_DTINICIAL      = PAE.DTINICIAL

		 GROUP BY ZDEPARA_PFUNC.CODCOLIGADA,
                  ZDEPARA_PFUNC.CHAPA,
                  ZDEPARA_PFUNC.CODSITUACAO,
				  PAE.DTINICIAL,
				  PAE.DTFINAL,
				  PAE.DIASDIREITO --PARTICULARIDADE DO PROJETO BOA LOCACAO

         UNION
		 
		/* CRIA NOVO PERIODO PARA FUNCIONÁRIOS ATIVOS */

		SELECT 2 AS ID,
		       ZDEPARA_PFUNC.CODCOLIGADA,
               ZDEPARA_PFUNC.CHAPA,
               ZDEPARA_PFUNC.CODSITUACAO,
			   DATEADD(YEAR,1,MAX(DTFINAL)) AS DTFINAL,
			   REPLACE(CONVERT(VARCHAR,DATEADD(YEAR,1,MAX(PAE.DTFINAL)),103),'/','') AS "Data final do período aquisitivo",
			   /*
			   --GERAR DATA FINAL PERÍODO AQUISITIVO PARA PAE.DTFINAL IS NULL ACORDADO COM O CLIENTE
			   CASE WHEN MAX(DTFINAL) IS NULL THEN REPLACE(CONVERT(VARCHAR,DATEADD(DAY,365,DATEADD(DAY,-1,DATEADD(YEAR,1,MAX(PAE.DTINICIAL)))),103),'/','') 
			        WHEN DATEADD(YEAR,1,DATEADD(DAY,1,MAX(DTFINAL))) = DATEADD(YEAR,1,MAX(PAE.DTINICIAL)) THEN REPLACE(CONVERT(VARCHAR,DATEADD(YEAR,1,DATEADD(YEAR,1,MAX(PAE.DTINICIAL))),103),'/','') --Exceção a Regra
					ELSE REPLACE(CONVERT(VARCHAR,DATEADD(YEAR,1,MAX(PAE.DTFINAL)),103),'/','')
			   END AS "Data final do período aquisitivo",	
			   */
               REPLACE(CONVERT(VARCHAR,DATEADD(YEAR,1,MAX(PAE.DTINICIAL)),103),'/','') AS "Data inicial do período aquisitivo",
               NULL AS "Saldo do período de férias",
               1 AS "Indicativo de período aquisitivo aberto",   
               0 AS "Indicativo de período aquisitivo perdido",
               NULL AS "Motivo da perda do período aquisitivo",
               0 AS "Faltas ocorridas no período aquisitivo",
               '0,00' AS "Bônus",  
               NULL AS CAMPOEXTRA
          FROM PAE 
               INNER JOIN ZDEPARA_PFUNC 
        	           ON ZDEPARA_PFUNC.EMP_CODIGO = PAE.EMP_CODIGO
        			  AND ZDEPARA_PFUNC.EPG_CODIGO = PAE.EPG_CODIGO
         WHERE ZDEPARA_PFUNC.CODSITUACAO <> 'D'
		   AND PAE.DTFINAL IS NOT NULL
		   AND NOT EXISTS (	SELECT 1
							  FROM ZFERIAS
							 WHERE ZFERIAS.EMP_CODIGO = ZDEPARA_PFUNC.EMP_CODIGO
							   AND ZFERIAS.EPG_CODIGO = ZDEPARA_PFUNC.EPG_CODIGO
							   AND ZFERIAS.ANOMESGOZO >= '202604')

         GROUP BY ZDEPARA_PFUNC.CODCOLIGADA,
                  ZDEPARA_PFUNC.CHAPA,
                  ZDEPARA_PFUNC.CODSITUACAO,
			      PAE.EMP_CODIGO,
                  PAE.EPG_CODIGO
		 HAVING SUM(CAST(DIASDIREITO AS DECIMAL(10,2))) = SUM(CAST(DIASGOZADOS AS DECIMAL(10,2)))
		 
		 UNION 

        /* FUNCIONARIOS SEM PERIODO AQUISITIVO */
		SELECT 3 AS ID, 
		       ZDEPARA_PFUNC.CODCOLIGADA,
               ZDEPARA_PFUNC.CHAPA,
               ZDEPARA_PFUNC.CODSITUACAO,
			   DATEADD(DAY,-1,DATEADD(YEAR,1,ZDEPARA_PFUNC.DATAADMISSAO)) AS DTFINAL,
               REPLACE(CONVERT(VARCHAR,DATEADD(DAY,-1,DATEADD(YEAR,1,ZDEPARA_PFUNC.DATAADMISSAO)),103),'/','') AS "Data final do período aquisitivo",
               REPLACE(CONVERT(VARCHAR,ZDEPARA_PFUNC.DATAADMISSAO,103),'/','') AS "Data inicial do período aquisitivo",
               NULL AS "Saldo do período de férias",
               1 AS "Indicativo de período aquisitivo aberto",   
               0 AS "Indicativo de período aquisitivo perdido",
               NULL AS "Motivo da perda do período aquisitivo",
               NULL AS "Faltas ocorridas no período aquisitivo",
               '0,00' AS "Bônus",  
               NULL AS CAMPOEXTRA
	      FROM ZDEPARA_PFUNC
		 WHERE CASE WHEN ZDEPARA_PFUNC.CODSITUACAO = 'D' AND ZDEPARA_PFUNC.DATADEMISSAO > DATEADD(DAY,-1,DATEADD(YEAR,1,ZDEPARA_PFUNC.DATAADMISSAO)) THEN 0
		            WHEN ZDEPARA_PFUNC.CODSITUACAO <> 'D' THEN 1
					ELSE 1 
				END = 1 
		   AND NOT EXISTS (SELECT 1 
		                     FROM PAE
							WHERE PAE.EMP_CODIGO = ZDEPARA_PFUNC.EMP_CODIGO
                              AND PAE.EPG_CODIGO = ZDEPARA_PFUNC.EPG_CODIGO)
          
		  ) DADOS 
 WHERE DADOS."Data final do período aquisitivo" IS NOT NULL
