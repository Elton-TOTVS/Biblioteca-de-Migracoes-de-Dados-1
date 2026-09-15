----------------------------------------------------------------------------------------------------      
-- Script:					ZMIGRA_PFPERFF (Período da Ficha)
-- Última Alteração:		14/08/2024     
-- Versão:					1 
-- Origem:					FORTES
-- Autor Alteração:			Rafael Stroppa
----------------------------------------------------------------------------------------------------

IF OBJECT_ID('ZMIGRA_PFPERFF') IS NOT NULL 
   DROP TABLE ZMIGRA_PFPERFF;

DECLARE @ANOMESCOMP VARCHAR(6) = '202608' --#Ver: AAAAMM

SELECT ZDEPARA_PFUNC.CODCOLIGADA, --NÃO SERÁ USADO NO LAYOUT

	   ZDEPARA_PFUNC.CHAPA,
       ZFICHA.ANOCOMP,
       ZFICHA.MESCOMP,
       CAST(ZFICHA.NROPERIODO AS INT) AS NROPERIODO,
       ZFICHA.MESCOMP AS MESCAIXACOMUM,
       0 AS VALORESFORCADOS,
       1 AS MOVIMPORTADO,
       0 AS EDITADO,
       0 AS ALTERADO,
       0 AS SALCOMISSAO,
       0 AS FERIASMES,
       (SELECT 
              SUM(Z.VALOR)
          FROM 
              ZFICHA AS Z 
              JOIN EVE
                ON EVE.EMP_CODIGO = Z.EMP_CODIGO
               AND EVE.CODIGO     = Z.EVE_CODIGO
         WHERE 
              Z.EMP_CODIGO = ZFICHA.EMP_CODIGO
          AND Z.FOL_SEQ    = ZFICHA.FOL_SEQ
          AND Z.ANOCOMP    = ZFICHA.ANOCOMP
          AND Z.MESCOMP    = ZFICHA.MESCOMP
          AND Z.NROPERIODO = ZFICHA.NROPERIODO
          AND Z.FOLHA      = ZFICHA.FOLHA
          AND Z.EPG_CODIGO = ZFICHA.EPG_CODIGO
          AND (EVE.IndicativoCPMensalFerias = 11
           OR EVE.INDICATIVOCPRPMENSALFERIAS = 11)) AS BASEINSS,
       0 AS BASEINSSOUTROEMP,
       0 AS INSS,
       0 AS INSSFERIAS,
       0 AS INSSOUTROEMP,
       (SELECT 
              SUM(Z.VALOR)
          FROM 
              ZFICHA AS Z 
              JOIN EVE
                ON EVE.EMP_CODIGO = Z.EMP_CODIGO
               AND EVE.CODIGO     = Z.EVE_CODIGO
         WHERE 
              Z.EMP_CODIGO = ZFICHA.EMP_CODIGO
          AND Z.FOL_SEQ    = ZFICHA.FOL_SEQ
          AND Z.ANOCOMP    = ZFICHA.ANOCOMP
          AND Z.MESCOMP    = ZFICHA.MESCOMP
          AND Z.NROPERIODO = ZFICHA.NROPERIODO
          AND Z.FOLHA      = ZFICHA.FOLHA
          AND Z.EPG_CODIGO = ZFICHA.EPG_CODIGO
          AND (EVE.IndicativoCPDTS = 12
           OR EVE.INDICATIVOCPRPDTS = 12)) AS BASEINSS13,
       0 AS BASEINSS13OUTRO,
       0 AS INSS13,
       0 AS BASESALFAMILIA,
       0 AS SALFAMILIA,
       0 AS BASEVALETRANSP,
       0 AS VALETRANSPENTR,
       0 AS VALETRANSPDESC,
       (SELECT 
              SUM(Z.VALOR)
          FROM 
              ZFICHA AS Z 
              JOIN EVE
                ON EVE.EMP_CODIGO = Z.EMP_CODIGO
               AND EVE.CODIGO     = Z.EVE_CODIGO
         WHERE 
              Z.EMP_CODIGO = ZFICHA.EMP_CODIGO
          AND Z.FOL_SEQ    = ZFICHA.FOL_SEQ
          AND Z.ANOCOMP    = ZFICHA.ANOCOMP
          AND Z.MESCOMP    = ZFICHA.MESCOMP
          AND Z.NROPERIODO = ZFICHA.NROPERIODO
          AND Z.FOLHA      = ZFICHA.FOLHA
          AND Z.EPG_CODIGO = ZFICHA.EPG_CODIGO
          AND (EVE.IndicativoIRRFMensal = 11
           OR EVE.INDICATIVOIRRFRESCISAO = 11)) AS BASEIRRF,
       0 AS IRRF,
       0 AS INSSCAIXA,
       0 AS DEDUTIVELIRRF,
       0 AS BASEIRRFPART,
       0 AS IRRFPART,
       0 AS BASEIRRFFERIAS,
       0 AS IRRFFERIAS,
       0 AS INSSCOMCPMF,
       'IMPORTACAO DE FICHA FINANCEIRA - ' + RIGHT('00' + CAST(ZFICHA.MESCOMP AS VARCHAR(2)),2) +'/'+ CAST(ZFICHA.ANOCOMP AS VARCHAR(4)) AS DESCRICAO, 
       (SELECT 
              SUM(Z.VALOR)
          FROM 
              ZFICHA AS Z 
              JOIN EVE
                ON EVE.EMP_CODIGO = Z.EMP_CODIGO
               AND EVE.CODIGO     = Z.EVE_CODIGO
         WHERE 
              Z.EMP_CODIGO = ZFICHA.EMP_CODIGO
          AND Z.FOL_SEQ    = ZFICHA.FOL_SEQ
          AND Z.ANOCOMP    = ZFICHA.ANOCOMP
          AND Z.MESCOMP    = ZFICHA.MESCOMP
          AND Z.NROPERIODO = ZFICHA.NROPERIODO
          AND Z.FOLHA      = ZFICHA.FOLHA
          AND Z.EPG_CODIGO = ZFICHA.EPG_CODIGO
          AND (EVE.IndicativoFGTSMensalFerias = 11
           OR EVE.INDICATIVOCPRPMENSALFERIAS = 11)) AS BASEFGTS,
       (SELECT 
              SUM(Z.VALOR)
          FROM 
              ZFICHA AS Z 
              JOIN EVE
                ON EVE.EMP_CODIGO = Z.EMP_CODIGO
               AND EVE.CODIGO     = Z.EVE_CODIGO
         WHERE 
              Z.EMP_CODIGO = ZFICHA.EMP_CODIGO
          AND Z.FOL_SEQ    = ZFICHA.FOL_SEQ
          AND Z.ANOCOMP    = ZFICHA.ANOCOMP
          AND Z.MESCOMP    = ZFICHA.MESCOMP
          AND Z.NROPERIODO = ZFICHA.NROPERIODO
          AND Z.FOLHA      = ZFICHA.FOLHA
          AND Z.EPG_CODIGO = ZFICHA.EPG_CODIGO
          AND EVE.IndicativoIRRFDTS = 12) AS BASEFGTS13,
       0 AS SALARIOPAGO,
       0 AS STATUSCCUSTO,
       (SELECT 
              SUM(Z.VALOR)
          FROM 
              ZFICHA AS Z 
              JOIN EVE
                ON EVE.EMP_CODIGO = Z.EMP_CODIGO
               AND EVE.CODIGO     = Z.EVE_CODIGO
         WHERE 
              Z.EMP_CODIGO = ZFICHA.EMP_CODIGO
          AND Z.FOL_SEQ    = ZFICHA.FOL_SEQ
          AND Z.ANOCOMP    = ZFICHA.ANOCOMP
          AND Z.MESCOMP    = ZFICHA.MESCOMP
          AND Z.NROPERIODO = ZFICHA.NROPERIODO
          AND Z.FOLHA      = ZFICHA.FOLHA
          AND Z.EPG_CODIGO = ZFICHA.EPG_CODIGO
          AND EVE.IndicativoIRRFDTS = 12) AS BASEIRRF13,
       0 AS SALARIODECALCULO,
       0 AS IRRF13,
       0 AS INSSFERIASCOMCPMF,
       0 AS INSSCALCUSUARIO,
       0 AS BASEFGTSDIFSAL,
       0 AS INSSDIFSAL,
       0 AS INSSDIFSAL13,
       0 AS INSSDIFSALFER,
       ' ' AS EXECID,
       0 AS NRODEPENDIRRF,
       0 AS LIQUIDO,
       0 AS NRODEPENDSALFAMILIA,
       NULL AS IDDADOSRESID,
       NULL AS RETIFICACAO,
       NULL AS "Mês onde foi realizado o pagamento da retificação",
       NULL AS "Ano onde foi realizado o pagamento da retificação",
       NULL AS "Período onde foi realizado o pagamento da retificação",
       NULL AS "Ano Caixa Comum",
       NULL AS "Ordem de cálculo de funcionários com múltiplos vínculos",
       NULL AS "Pagamento de dissídio na competência da demissão após envio do evento S-2299",
       NULL AS "Número do benefício que se refere o pagamento",
       NULL AS "Base anual de IRRF PLR",
	   NULL AS IRRFSIMPLIFICADO,
	   NULL AS IRRF13SIMPLIFICADO,
	   NULL AS IRRFFERSIMPLIFICADO,
	   NULL AS CAMPOEXTRA1,
	   NULL AS CAMPOEXTRA2,
	   NULL AS CAMPOEXTRA3,
	   NULL AS CAMPOEXTRA4,
	   NULL AS CAMPOEXTRA5,
	   NULL AS CAMPOEXTRA6,
	   NULL AS CAMPOEXTRA7
  INTO ZMIGRA_PFPERFF
  FROM ZFICHA 
       INNER JOIN ZDEPARA_PFUNC
               ON ZDEPARA_PFUNC.EMP_CODIGO = ZFICHA.EMP_CODIGO
              AND ZDEPARA_PFUNC.EPG_CODIGO = ZFICHA.EPG_CODIGO
       INNER JOIN ZDEPARA_EVENTOS 
               ON ZDEPARA_EVENTOS.EMPRESA_DE = ZFICHA.EMP_CODIGO
			  AND ZDEPARA_EVENTOS.CODIGO_DE  = RIGHT('0000' + ZFICHA.EVE_CODIGO,4)
  WHERE CAST(ANOCOMP AS VARCHAR(4)) + RIGHT('00' + CAST(MESCOMP AS VARCHAR(2)),2) < @ANOMESCOMP --#Ver
    AND ZDEPARA_EVENTOS.CODIGO_PARA LIKE '%[0-9]%'

 GROUP BY ZDEPARA_PFUNC.CODCOLIGADA,
		  ZDEPARA_PFUNC.CHAPA,
          ZFICHA.ANOCOMP,
          ZFICHA.MESCOMP,
          ZFICHA.NROPERIODO,
          ZFICHA.MESCOMP,
          ZFICHA.EMP_CODIGO,
          ZFICHA.FOL_SEQ,
          ZFICHA.FOLHA,
          ZFICHA.EPG_CODIGO,
          'IMPORTACAO DE FICHA FINANCEIRA - ' + RIGHT('00' + CAST(ZFICHA.MESCOMP AS VARCHAR(2)),2) +'/'+ CAST(ZFICHA.ANOCOMP AS VARCHAR(4))