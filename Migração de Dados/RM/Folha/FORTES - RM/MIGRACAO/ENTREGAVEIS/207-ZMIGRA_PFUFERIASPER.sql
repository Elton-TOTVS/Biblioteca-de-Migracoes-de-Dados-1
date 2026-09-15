----------------------------------------------------------------------------------------------------      
-- Script:					ZMIGRA_PFUFERIASPER (Período de Gozo)
-- Última Alteração:		14/08/2024     
-- Versão:					1 
-- Origem:					FORTES
-- Autor Alteração:			Rafael Stroppa
----------------------------------------------------------------------------------------------------

IF OBJECT_ID ('ZMIGRA_PFUFERIASPER') IS NOT NULL
	DROP TABLE ZMIGRA_PFUFERIASPER;

DECLARE @COMPETENCIA VARCHAR(8) = '202608' --#Ver: Ajustar competência para férias (AAAAMM)

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
	   --REPLACE(CONVERT(VARCHAR,PAE.DTFINAL,103),'/','') AS "Data final do período aquisitivo",  
	   
	   --GERAR DATA FINAL PERÍODO AQUISITIVO PARA PAE.DTFINAL IS NULL ACORDADO COM O CLIENTE
	   CASE WHEN PAE.DTFINAL IS NULL THEN REPLACE(CONVERT(VARCHAR,DATEADD(DAY,365,DATEADD(DAY,-1,PAE.DTINICIAL)),103),'/','') 
			ELSE REPLACE(CONVERT(VARCHAR,PAE.DTFINAL,103),'/','') 
		END AS "Data final do período aquisitivo", --PARTICULARIDADE DO PROJETO NOSSA FRUTA  
	   
       REPLACE(CONVERT(VARCHAR,FOL.DTCALCULO,103),'/','') AS "Data de pagamento das férias",    
       REPLACE(CONVERT(VARCHAR,FER.DTGOZOINICIAL,103),'/','') AS "Data de início das férias",    
       REPLACE(CONVERT(VARCHAR,FER.DTGOZOFINAL,103),'/','') AS "Data de fim das férias",    
       REPLACE(CONVERT(VARCHAR,DATEADD(MONTH,-1,FER.DTGOZOINICIAL),103),'/','') AS "Data de aviso das férias",    
       SUM(CAST(FER.DIASABONO AS DECIMAL(10,2))) AS "Número de dias de abono pecuniário",    
       NULL AS "Ind. de pagto. da 1ª parcela 13ºsalário",    
       NULL AS "Licença remunerada férias colet. 1ºmês",    
       NULL AS "Licença remunerada férias colet. 2ºmês",    
       0 AS "Indicativo de per.ref.à férias coletivas",    
       NULL AS "Dias de férias perdidos devido a faltas",    
       'Férias referente ao Per. Aquisitivo de ' + CONVERT(VARCHAR,PAE.DTINICIAL,103) + ' a ' + CONVERT(VARCHAR,PAE.DTFINAL,103) + '.' AS "Obs. a ser impressa no recibo de férias",    
	   
	   CASE WHEN SUBSTRING(CONVERT(VARCHAR,FER.DTGOZOINICIAL,112),1,6) >= @COMPETENCIA THEN 'M'  --Marcadas
	        WHEN SUBSTRING(CONVERT(VARCHAR,FER.DTGOZOINICIAL,112),1,6) < @COMPETENCIA 
			 AND SUBSTRING(CONVERT(VARCHAR,FER.DTGOZOFINAL,112),1,6) = @COMPETENCIA	THEN 'P'  --Paga /* Mês anterior */
	        ELSE 'F' --Finalizadas
		END AS [Situação das férias],
	   
	   NULL AS "Data Inicio Desconto Empréstimo Férias",    
       NULL AS "Nro Vezes Desconto Empréstimo Férias",    
       SUM(CAST(PAF.FALTAS AS DECIMAL(10,2))) AS "Faltas",    
       NULL AS "Nro.dias antecipados do próx.periodo",    
       NULL AS "Fim per.aquis.referente aos dias antec.",    
       NULL AS "Data pagto.referente aos dias antec.",    
       NULL AS "Indica se este periodo foi antecipado",    
       NULL AS "NRODIASFERIADO",    
       NULL AS "Número de dias de férias corridos",    
       NULL AS "Número de dias de abono corridos",    
       NULL AS "Abono antes ou depois das férias",    
       NULL AS "Indicativo de per.ref.à férias compulsórias	",
	   NULL AS CAMPOEXTRA  
  INTO ZMIGRA_PFUFERIASPER
  FROM PAE 
       INNER JOIN ZDEPARA_PFUNC   
               ON ZDEPARA_PFUNC.EMP_CODIGO = PAE.EMP_CODIGO  
              AND ZDEPARA_PFUNC.EPG_CODIGO = PAE.EPG_CODIGO
	   INNER JOIN PAF 
	              INNER JOIN FER 
				             INNER JOIN EFO 
							            INNER JOIN FOL 
										        ON FOL.EMP_CODIGO = EFO.EMP_CODIGO
											   AND FOL.SEQ        = EFO.FOL_SEQ
							         ON EFO.EMP_CODIGO = FER.EMP_CODIGO
									AND EFO.EPG_CODIGO = FER.EFO_EPG_CODIGO
									AND EFO.FOL_SEQ    = FER.EFO_FOL_SEQ
				          ON FER.EMP_CODIGO     = PAF.FER_EMP_CODIGO
						 AND FER.EFO_EPG_CODIGO = PAF.FER_EFO_EPG_CODIGO
						 AND FER.EFO_FOL_SEQ    = PAF.FER_EFO_FOL_SEQ
	           ON PAF.PAE_EMP_CODIGO     = PAE.EMP_CODIGO
			  AND PAF.FER_EFO_EPG_CODIGO = PAE.EPG_CODIGO
			  AND PAF.PAE_DTINICIAL      = PAE.DTINICIAL
 WHERE FOL.FOLHA IN (4, 5)
   --AND FOL.ENCERRADA <> 'S' --#Ver
   AND PAE.DTFINAL IS NOT NULL --PARTICULARIDADE DO PROJETO BOA LOCACAO
   AND (ZDEPARA_PFUNC.DATADEMISSAO IS NULL OR FOL.DTCALCULO < ZDEPARA_PFUNC.DATADEMISSAO)
 GROUP BY ZDEPARA_PFUNC.CODCOLIGADA,
		  ZDEPARA_PFUNC.CHAPA,    
          PAE.DTFINAL,
		  PAE.DTINICIAL,
          FOL.DTCALCULO,
          FER.DTGOZOINICIAL,
          FER.DTGOZOFINAL