----------------------------------------------------------------------------------------------------      
-- Script:					ZMIGRA_PFUFERIASRECIBO (Recibo de Férias)
-- Última Alteração:		14/08/2024     
-- Versão:					1 
-- Origem:					FORTES
-- Autor Alteração:			Rafael Stroppa
----------------------------------------------------------------------------------------------------

IF OBJECT_ID ('ZMIGRA_PFUFERIASRECIBO') IS NOT NULL
	DROP TABLE ZMIGRA_PFUFERIASRECIBO;

;WITH DADOS AS (
      SELECT
        PAF.*,
        ROW_NUMBER() OVER (
            PARTITION BY
                PAF.PAE_EMP_CODIGO,
                PAF.FER_EFO_EPG_CODIGO,
                PAF.FER_EFO_FOL_SEQ
            ORDER BY
                PAF.PAE_DTINICIAL DESC
        ) AS ORDEM
    FROM PAF
),
PAF AS (
  SELECT * FROM DADOS WHERE ORDEM = 1
)

SELECT ZDEPARA_PFUNC.CODCOLIGADA, --NÃO SERÁ USADO NO LAYOUT

	   ZDEPARA_PFUNC.CHAPA, 
 	   REPLACE(CONVERT(VARCHAR,PAE.DTFINAL,103),'/','') AS "Data final do período aquisitivo",
	   --GERAR DATA FINAL PERÍODO AQUISITIVO PARA PAE.DTFINAL IS NULL ACORDADO COM O CLIENTE
	   /*
	   CASE WHEN PAE.DTFINAL IS NULL THEN REPLACE(CONVERT(VARCHAR,DATEADD(DAY,365,DATEADD(DAY,-1,PAE.DTINICIAL)),103),'/','') 
			ELSE REPLACE(CONVERT(VARCHAR,PAE.DTFINAL,103),'/','') 
		END AS "Data final do período aquisitivo",      
	   */
	   REPLACE(CONVERT(VARCHAR,FOL.DTCALCULO,103),'/','') AS "Data de pagamento das férias",  
       NULL AS "Desconto de Inss ref. ao primeiro mês",  
       NULL AS "Desconto de Inss ref. ao segundo mês",  
       REPLACE(CAST(CAST(SUM(CASE WHEN EFP.EVE_CODIGO IN ('311','506','507') THEN CAST(EFP.VALOR AS DECIMAL(15,2)) ELSE 0 END) AS NUMERIC(15,2)) AS VARCHAR(20)),'.',',') AS "Desconto de Irrf",   
       NULL AS "Base de Inss referente ao primeiro mês",  
       NULL AS "Base de Inss referente ao segundo mês",  
       REPLACE(CAST(CAST(SUM(CASE WHEN EFP.EVE_CODIGO = '603' THEN CAST(EFP.VALOR AS DECIMAL(15,2)) ELSE 0 END) AS NUMERIC(15,2)) AS VARCHAR(20)),'.',',') AS "Base de Irrf",   
       REPLACE(CAST(CAST(SUM(CASE WHEN EVE.INFPROVDESC = 1 THEN CAST(EFP.VALOR AS DECIMAL(15,2))   
                                  WHEN EVE.INFPROVDESC = 2 THEN CAST(EFP.VALOR AS DECIMAL(15,2)) * (-1)  
                      ELSE 0  
                  END) AS NUMERIC(15,2)) AS VARCHAR(20)),'.',',') AS "Valor Líquido do Recibo de Férias",  
       'Férias referente ao Per. Aquisitivo de ' + CONVERT(VARCHAR,PAE.DTINICIAL,103) + ' a ' + CONVERT(VARCHAR,PAE.DTFINAL,103) + '.' AS "Observação referente ao Recibo de Férias",  
       NULL AS "GUID da execução do processo de cálculo",  
       NULL AS "Pensão",  
       NULL AS "Base da Pensão",  
       NULL AS "Valores forçados manualmente",  
       NULL AS "Média do período aquisitivo atual",  
       NULL AS "Média do próximo período aquisitivo",  
       NULL AS "Salário do func. no momento do cálculo",  
       NULL AS "Número de dependentes de IRRF",  
       NULL AS "Número dependentes de Salário Familia",
	   NULL AS CAMPOEXTRA1,
	   NULL AS CAMPOEXTRA2,
	   NULL AS CAMPOEXTRA3
  INTO ZMIGRA_PFUFERIASRECIBO
  FROM PAE
       INNER JOIN ZDEPARA_PFUNC 
	           ON ZDEPARA_PFUNC.EMP_CODIGO = PAE.EMP_CODIGO
			  AND ZDEPARA_PFUNC.EPG_CODIGO = PAE.EPG_CODIGO
	   INNER JOIN PAF 
	              INNER JOIN EFO 
				             INNER JOIN FOL 
							         ON FOL.EMP_CODIGO = EFO.EMP_CODIGO
									AND FOL.SEQ        = EFO.FOL_SEQ
						     INNER JOIN EFP 
							            INNER JOIN EVE 
										        ON EVE.EMP_CODIGO = EFP.EMP_CODIGO
											   AND EVE.CODIGO     = EFP.EVE_CODIGO
							         ON EFP.EMP_CODIGO     = EFO.EMP_CODIGO
									AND EFP.EFO_EPG_CODIGO = EFO.EPG_CODIGO
									AND EFP.EFO_FOL_SEQ    = EFO.FOL_SEQ
				          ON EFO.EMP_Codigo = PAF.FER_EMP_Codigo
						 AND EFO.EPG_Codigo = PAF.FER_EFO_EPG_Codigo
						 AND EFO.FOL_Seq    = PAF.FER_EFO_FOL_Seq
	           ON PAF.PAE_EMP_Codigo = PAE.EMP_Codigo
			  AND PAF.PAE_EPG_Codigo = PAE.EPG_Codigo
			  AND PAF.PAE_DTINICIAL  = PAE.DTINICIAL
 WHERE FOL.FOLHA IN (4, 5)
   --AND FOL.ENCERRADA <> 'S' --#Ver
   AND (ZDEPARA_PFUNC.DATADEMISSAO IS NULL OR FOL.DTCALCULO < ZDEPARA_PFUNC.DATADEMISSAO)
   AND PAE.DTFINAL IS NOT NULL
 GROUP BY ZDEPARA_PFUNC.CODCOLIGADA,
		  ZDEPARA_PFUNC.CHAPA,
          PAE.DTFINAL,
		  PAE.DTINICIAL,
		  FOL.DTCALCULO