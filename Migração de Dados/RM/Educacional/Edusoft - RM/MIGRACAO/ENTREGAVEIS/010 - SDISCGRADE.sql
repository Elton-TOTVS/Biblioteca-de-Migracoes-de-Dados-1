/*
IMPORTAR TABELA PARA VERIFICACAO DE DADOS QUE JÁ EXISTEM => SUBIR COMO ZDADOSORI_SDISCGRADE
SELECT
	CODCOLIGADA,
	CODCURSO,
	CODHABILITACAO,
	CODGRADE,
	CODPERIODO,
	CODDISC
FROM SDISCGRADE
WHERE CODCOLIGADA = :CODCOLIGADA
*/

IF OBJECT_ID('ZMIGRA_SDISCGRADE') IS NOT NULL
  DROP TABLE ZMIGRA_SDISCGRADE
;

DECLARE @CODCOLIGADA AS INTEGER = 13
DECLARE @ANOLETIVO AS INTEGER = 2026

  SELECT DISTINCT
    @CODCOLIGADA                                                AS CODCOLIGADA,
    ZDEPARA_SDISCGRADE.CODCURSO_PARA                            AS CODCURSO,
    ZDEPARA_SDISCGRADE.CODHABILITACAO_PARA                      AS CODHABILITACAO,
    ZDEPARA_SDISCGRADE.CODGRADE_PARA                            AS CODGRADE,
    CAST(ZDEPARA_SDISCGRADE.CODPERIODO_PARA AS INT)             AS CODPERIODO,
    ZDEPARA_SDISCGRADE.CODDISC_PARA                             AS CODDISC,
    NULL                                                        AS CODGRPDISC,
    NULL                                                        AS PREREQCRED,
    NULL                                                        AS DESCRICAO,
    1                                                           AS POSHIST,
    FORMAT(ISNULL(TB_TURMA_DISCIP.TDI_CHORTH, 0), '0.00')       AS CH,
    NULL                                                        AS NUMCREDITOSCOB,
    NULL                                                        AS VALORCREDITO,
    NULL                                                        AS OBJETIVO,
    NULL                                                        AS PERCAULASNAOPRES,
    NULL                                                        AS PRIORIDADEMATRICULA,
    2                                                           AS DECIMAIS,
    '1'                                                         AS ATIVIDADE,
    'S'                                                         AS CALCMEDIAGLOBAL,
    'S'                                                         AS DESEMPENHOALUNO,
    'S'                                                         AS IMPBOLETIM,
    'C'                                                         AS TIPONOTA,
    NULL                                                        AS NUMMINDISC,
    NULL                                                        AS CHDISC,
    'B'                                                         AS TIPODISC,
    NULL                                                        AS APLICACAO,
    NULL                                                        AS CODFORMULACO,
    NULL                                                        AS CODFORMULAPRE,
    NULL                                                        AS CHPRESENCIAL,
    NULL                                                        AS CHDISTANCIA,
    NULL                                                        AS CHSINCRONA,
    NULL                                                        AS CHSINCRONAMEDIADA,
    NULL                                                        AS CHASSINCRONA
    INTO ZMIGRA_SDISCGRADE
  FROM ZDEPARA_SDISCGRADE
  LEFT JOIN TB_TURMA
    ON TB_TURMA.TUR_CURID = ZDEPARA_SDISCGRADE.COD_CURSO
    AND TB_TURMA.TUR_FASE = ZDEPARA_SDISCGRADE.COD_MATRIZ
    AND TB_TURMA.TUR_CURID = ZDEPARA_SDISCGRADE.COD_CURSO
    AND TB_TURMA.TUR_PERID = (SELECT TOP 1 PEL_PERID FROM TB_PERIODO_LETIVO WHERE PEL_ANOREF = @ANOLETIVO)
  LEFT JOIN TB_TURMA_DISCIP
    ON TB_TURMA_DISCIP.TDI_TURID = TB_TURMA.TUR_ID
    AND TB_TURMA_DISCIP.TDI_FASDIS = TB_TURMA.TUR_FASE
    AND TB_TURMA_DISCIP.TDI_DISCID = ZDEPARA_SDISCGRADE.DISCIPLINA
  -- WHERE
  --   NOT EXISTS (
  --     SELECT 1
  --     FROM ZDADOSORI_SDISCGRADE X
  --     WHERE 
  --       X.CODCOLIGADA           = ZDEPARA_SDISCGRADE.CODCOLIGADA
  --       AND X.CODCURSO          = ZDEPARA_SDISCGRADE.CODCURSO_PARA
  --       AND X.CODHABILITACAO    = ZDEPARA_SDISCGRADE.CODHABILITACAO_PARA
  --       AND X.CODGRADE          = ZDEPARA_SDISCGRADE.CODGRADE_PARA
  --       AND X.CODPERIODO        = ZDEPARA_SDISCGRADE.ANO
  --       AND X.CODDISC           = ZDEPARA_SDISCGRADE.CODDISC_PARA
  --   )

SELECT * FROM ZMIGRA_SDISCGRADE ORDER BY 4, 6 ;
