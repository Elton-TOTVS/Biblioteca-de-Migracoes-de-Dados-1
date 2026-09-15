IF OBJECT_ID('ZMIGRA_SETAPAS') IS NOT NULL
    DROP TABLE ZMIGRA_SETAPAS
;

DECLARE @ANOLETIVO AS INT = 2026

SELECT DISTINCT
    13                                          AS CODCOLIGADA,
    ZMIGRA_BASE.CODCURSO                        AS CODCURSO,
    ZMIGRA_BASE.CODHABILITACAO                  AS CODHABILITACAO,
    ZMIGRA_BASE.CODGRADE_PARA                   AS CODGRADE,
    ZMIGRA_BASE.TURNO_PARA                      AS TURNO,
    ZMIGRA_BASE.CODFILIAL                       AS CODFILIAL,
    ZMIGRA_BASE.CODTIPOCURSO                    AS CODTIPOCURSO,
    ZMIGRA_BASE.CODPERLET                       AS CODPERLET,
    ZMIGRA_BASE.CODTURMA                        AS CODTURMA,
    ZDEPARA_SDISCIPLINAS.CODIGO_PARA            AS CODDISC,
    TB_PADDIS_TIPNOT.TNP_ORDEM                  AS CODETAPA,
    'N'                                         AS TIPOETAPA,
    TB_PADDIS_TIPNOT.TNP_DESCRI                 AS DESCRICAO,
    NULL                                        AS PONTDIST,
    TB_PADDIS_TIPNOT.TNP_NOTMINAPR              AS MEDIA,
    NULL                                        AS FREQMIN,
    NULL                                        AS DTINICIO,
    NULL                                        AS DTFIM,
    NULL                                        AS DTINICIODIGITACAO,
    NULL                                        AS DTLIMITEDIGITACAO,
    'S'                                         AS DIGAULASDADAS,
    'S'                                         AS EXIBENAWEB,
    'N'                                         AS ETAPAFINAL,
    NULL                                        AS TITULO,
    NULL                                        AS AULASDADAS,
    NULL                                        AS AULASPREVISTAS,
    NULL                                        AS CONCEITOGRAFICO,
    NULL                                        AS EXIBENOGRAFICO,
    NULL                                        AS DTLIMITECONTPREVISTO,
    NULL                                        AS DTLIMITECONTEFETIVO,
    NULL                                        AS DISPONIVELALUNOS,
    NULL                                        AS ETAPAENCERRADA
    INTO ZMIGRA_SETAPAS
FROM ZMIGRA_BASE
LEFT JOIN TB_TURMA
  ON TB_TURMA.TUR_ID = ZMIGRA_BASE.CODTURMA_DE
  AND TB_TURMA.TUR_CURID = ZMIGRA_BASE.CURSO_DE
  AND TB_TURMA.UNIDON = ZMIGRA_BASE.CODFILIAL_DE
  AND UPPER(TB_TURMA.TUR_TURNO) = UPPER(LEFT(ZMIGRA_BASE.CODTURNO_DE, 1))
  AND TB_TURMA.TUR_FASE = ZMIGRA_BASE.CODHABILITACAO_DE
  AND TB_TURMA.TUR_PERID = (SELECT TOP 1 CODIGO_DE FROM ZDEPARA_SPLETIVO WHERE DESCRICAO = @ANOLETIVO)
JOIN TB_TURMA_DISCIP
  ON TB_TURMA_DISCIP.TDI_TURID = TB_TURMA.TUR_ID
JOIN ZDEPARA_SDISCIPLINAS
  ON ZDEPARA_SDISCIPLINAS.CODIGO = TB_TURMA_DISCIP.TDI_DISCID
JOIN TB_PADRONIZACAO_DIS 
  ON TB_TURMA_DISCIP.TDI_PDIID = TB_PADRONIZACAO_DIS.PDI_ID
JOIN TB_PADDIS_TIPNOT
  ON TB_PADRONIZACAO_DIS.PDI_ID = TB_PADDIS_TIPNOT.TNP_PDIID
ORDER BY 1,2,3,4,5,6,7,8,9,10,11

SELECT * FROM ZMIGRA_SETAPAS