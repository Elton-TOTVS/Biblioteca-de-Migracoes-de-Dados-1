----------------------------------------------------------------------------------------------------      
-- Script:					ZMIGRA_PFHSTASSMED
-- Última Alteração:		06/04/2026     
-- Versão:					1 
-- Origem:					FORTES
-- Autor Alteração:			Reno Neto
----------------------------------------------------------------------------------------------------

IF OBJECT_ID('ZMIGRA_PFHSTASSMED') IS NOT NULL
	DROP TABLE ZMIGRA_PFHSTASSMED;

SELECT ZDEPARA_PFUNC.CODCOLIGADA, --NÃO SERÁ USADO NO LAYOUT

       ZDEPARA_PFUNC.CHAPA,
       SUBSTRING(VMP_CPT.ANOMES,1,4) AS "Ano Competência",
       CAST(SUBSTRING(VMP_CPT.ANOMES,5,6) AS INT) AS "Mês Competência",
       VMP_CPT.ANOMES AS ANOMESCOMP,
       ZDEPARA_PERIODO_FOLHA.NROPERIODO_PARA AS "Período",
       CASE WHEN VMP_CPT.DEP_SEQ IS NULL THEN 0 ELSE CAST(VMP_CPT.DEP_SEQ AS INT) END AS "Número do dependente",
       ZDEPARA_EVENTOS.CODIGO_PARA AS "Código do evento",
       0 AS "Tipo do valor", --Movimento
       REPLACE(CONVERT(VARCHAR(10),FOL.DTCALCULO,103),'/','') AS "Data do desconto",
       YEAR(FOL.DTCALCULO) AS "Ano de referência do desconto",
	   MONTH(FOL.DTCALCULO) AS "Mês de referência do desconto",
       ZDEPARA_PERIODO_FOLHA.NROPERIODO_PARA AS "Período de referência do desconto",
       REPLACE(CAST(REPLACE(VMP_CPT.VALORPAGO,',','.') AS NUMERIC(15,2)),'.',',') AS "Valor efetivo",
       REPLACE(CAST(REPLACE(VMP_CPT.VALORPAGO,',','.') AS NUMERIC(15,2)),'.',',') AS "Valor original",
       0 AS "Indicativo alteração manual/importação",
       NULL AS "Código do evento de férias",
       NULL AS CAMPOEXTRA
  INTO ZMIGRA_PFHSTASSMED
  FROM VMP_CPT
  JOIN FOL
    ON FOL.EMP_CODIGO = VMP_CPT.EMP_CODIGO
   AND FOL.SEQ = VMP_CPT.EFP_EFO_FOL_SEQ
  JOIN ZDEPARA_PFUNC
    ON ZDEPARA_PFUNC.EMP_CODIGO = VMP_CPT.EMP_CODIGO
   AND ZDEPARA_PFUNC.EPG_CODIGO = VMP_CPT.EFP_EFO_EPG_CODIGO
  JOIN ZDEPARA_EVENTOS
    ON ZDEPARA_EVENTOS.EMPRESA_DE = VMP_CPT.EMP_CODIGO
   AND ZDEPARA_EVENTOS.CODIGO_DE = VMP_CPT.EFP_EVE_CODIGO
  JOIN ZDEPARA_PERIODO_FOLHA
    ON ZDEPARA_PERIODO_FOLHA.CODIGO_PERIODO_DE = FOL.FOLHA
 WHERE ZDEPARA_EVENTOS.CODIGO_PARA LIKE '%[0-9]%'
   AND ZDEPARA_PERIODO_FOLHA.NROPERIODO_PARA <> 'IGNORAR'
   --AND CAST(FOL.DTCALCULO AS DATE) > CONVERT(DATE,'01/'+SUBSTRING(VMP_CPT.ANOMES,5,6)+'/'+SUBSTRING(VMP_CPT.ANOMES,1,4),103)