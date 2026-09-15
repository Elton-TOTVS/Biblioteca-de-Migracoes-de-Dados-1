----------------------------------------------------------------------------------------------------      
-- Script:					ZMIGRA_PFHSTAFT
-- Última Alteração:		14/08/2024     
-- Versão:					1 
-- Origem:					FORTES
-- Autor Alteração:			Rafael Stroppa
----------------------------------------------------------------------------------------------------

IF OBJECT_ID('ZMIGRA_PFHSTAFT') IS NOT NULL 
   DROP TABLE ZMIGRA_PFHSTAFT;

SELECT ZDEPARA_PFUNC.CODCOLIGADA, --NÃO SERÁ USADO NO LAYOUT

	   ZDEPARA_PFUNC.CHAPA AS "Chapa",
       REPLACE(CONVERT(VARCHAR,LIC.DTINICIAL,103),'/','') AS "Data de início",
       REPLACE(CONVERT(VARCHAR,LIC.DTFINAL,103),'/','') AS "Data final",      
       ZDEPARA_SITUACAO.CODSITUACAO_PARA AS "Tipo",
       ZDEPARA_SITUACAO.CODMOTIVO_PARA "Motivo do afastamento", 
       REPLACE(REPLACE(CASE WHEN LIC.OBSERVACAO = '' THEN NULL ELSE REPLACE(REPLACE(CONVERT(VARCHAR(MAX),LIC.OBSERVACAO), CHAR(13),' '), CHAR(10),' ') END,';',':'),'.','') AS "Observações",
       NULL AS "Estorna tempo de serviço",
       NULL AS "Código da Coligada do Tomador",
       NULL AS "Código do Tomador",
       NULL AS "Tipo do Tomador",
       NULL AS "Data de Requerimento",
       NULL AS "CEI",
       /*AFAST.CID */ NULL AS "Codigo da Tabela CID",
       NULL AS "Ônus da Cessão",
       NULL AS "Código do Médico",
       NULL AS "Tipo de Acidente de Trânsito",
       NULL AS "Flag Acidente de Trânsito",
       NULL AS "CNPJ do sindicato",
       NULL AS "Informação onus da Remuneração",
       NULL AS "Código da estabilidade",
       NULL AS "Doença ou agravo de notificação compulsória",
       NULL AS "Cnpj do orgão a qual o funcionário foi cedido",
       NULL AS "Dt. Inicial da Continuidade de Aft.",
	   NULL AS "Afastamento pela Previdência",
	   NULL AS CAMPOEXTRA1
  INTO ZMIGRA_PFHSTAFT
  FROM LIC
       INNER JOIN ZDEPARA_PFUNC 
               ON ZDEPARA_PFUNC.EMP_CODIGO = LIC.EMP_CODIGO
              AND ZDEPARA_PFUNC.EPG_CODIGO = LIC.EPG_CODIGO
	   INNER JOIN ZDEPARA_SITUACAO 
	           ON ZDEPARA_SITUACAO.CODIGO_DE = LIC.TLI_CODIGO
 WHERE LIC.TLI_CODIGO <> '01' --FÉRIAS
