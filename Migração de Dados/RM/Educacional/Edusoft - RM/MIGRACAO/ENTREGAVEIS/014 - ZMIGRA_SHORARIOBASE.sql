IF OBJECT_ID('ZMIGRA_SHORARIOBASE') IS NOT NULL
    DROP TABLE ZMIGRA_SHORARIOBASE
;

DECLARE @ANOLETIVO AS INTEGER = 2026

SELECT DISTINCT
  ZMIGRA_BASE.CODCOLIGADA                                                 AS CODCOLIGADA,
  ZMIGRA_BASE.CODFILIAL_DE                                                AS CODFILIAL_DE,
  ZMIGRA_BASE.CURSO_DE                                                    AS CODCURSO_DE,
  ZMIGRA_BASE.CODCURSO                                                    AS CODCURSO,
  ZMIGRA_BASE.CODHABILITACAO_DE                                           AS CODHABILITACAO_DE,
  ZMIGRA_BASE.CODHABILITACAO                                              AS CODHABILITACAO,
  ZMIGRA_BASE.CODGRADE_DE                                                 AS CODGRADE_DE,
  ZMIGRA_BASE.CODGRADE_PARA                                               AS CODGRADE,
  ZMIGRA_BASE.CODTURMA_DE                                                 AS CODIGO_TURMA,
  ZMIGRA_BASE.CODTURMA                                                    AS CODTURMA_PARA,
  ZMIGRA_BASE.NOME                                                        AS NOMETURMA,
  ZMIGRA_BASE.CODPERLET                                                   AS PERIODO_DE,
  ZMIGRA_BASE.CODPERLET                                                   AS CODPERLET_DE,
  ZMIGRA_BASE.CODPERLET                                                   AS PERIODO_PARA,
  ZMIGRA_BASE.CODPERLET                                                   AS CODPERLET_PARA,
  TB_CRONOGRAMA_AULA_DATA.CAD_DIASEM                                      AS SEMANA,
  NULL                                                                    AS DIA_SEMANA_DE,
  NULL                                                                    AS DIA_SEMANA_PARA,
  CONVERT(VARCHAR(5), ZDADOS_TURNOS.HORAINICIAL, 108)                     AS HORARIO_INICIAL,
  CONVERT(VARCHAR(5), ZDADOS_TURNOS.HORAFINAL, 108)                       AS HORARIO_FINAL,
  CAST(TB_CRONOGRAMA_AULA_DATA.CAD_DATA AS DATE)                          AS DIA,
  CAST(ZDADOS_TURNOS.AULA AS INT)                                         AS AULA,
  NULL                                                                    AS CODDISC_HORARIO,
  ZDEPARA_SDISCIPLINAS.CODIGO                                             AS CODDISC_DE,
  ZDEPARA_SDISCIPLINAS.CODIGO_PARA                                        AS CODDISC_PARA,
  ZDEPARA_SDISCIPLINAS.NOME                                               AS DISCIPLINAS,
  (
    SELECT TOP 1 TB_TURMADISCIP_PROF.TDP_PESID
    FROM TB_TURMADISCIP_PROF
    WHERE TB_TURMADISCIP_PROF.TDP_TDIID = TB_TURMA_DISCIP.TDI_TURDISID  
      AND EXISTS(SELECT 1 FROM ZMIGRA_SPESSOA_SPROFESSOR
        WHERE TB_TURMADISCIP_PROF.TDP_PESID = ZMIGRA_SPESSOA_SPROFESSOR.CODPROF
      )
    ORDER BY 1
  )                                                                       AS CODPROF,
  NULL                                                                    AS CODPROF1,
  ZMIGRA_BASE.CODTURNO_DE                                                 AS CODTURNO,
  ZMIGRA_BASE.TURNO_DE                                                    AS TURNO_DE,
  ZDADOSORI_STURNO.NOME                                                   AS TURNO_PARA,
  ZMIGRA_BASE.CODFILIAL                                                   AS CODFILIAL,
  ZMIGRA_BASE.CODTIPOCURSO                                                AS NIVELENSINO,
  NULL                                                                    AS cod_qh,
  NULL                                                                    AS cod_ha
  INTO ZMIGRA_SHORARIOBASE
FROM ZMIGRA_BASE
LEFT JOIN TB_TURMA
  ON TB_TURMA.TUR_ID = ZMIGRA_BASE.CODTURMA_DE
  AND TB_TURMA.TUR_CURID = ZMIGRA_BASE.CURSO_DE
  AND TB_TURMA.UNIDON = ZMIGRA_BASE.CODFILIAL_DE
  AND TB_TURMA.TUR_TURNO = LEFT(ZMIGRA_BASE.CODTURNO_DE, 1)
  AND TB_TURMA.TUR_FASE = ZMIGRA_BASE.CODHABILITACAO_DE
  AND TB_TURMA.TUR_PERID = (SELECT TOP 1 CODIGO_DE FROM ZDEPARA_SPLETIVO WHERE DESCRICAO = @ANOLETIVO)
JOIN TB_TURMA_DISCIP
  ON TB_TURMA_DISCIP.TDI_TURID = TB_TURMA.TUR_ID
JOIN ZDEPARA_SDISCIPLINAS
  ON ZDEPARA_SDISCIPLINAS.CODIGO = TB_TURMA_DISCIP.TDI_DISCID
JOIN TB_CRONOGRAMA_AULA_DATA
  ON TB_CRONOGRAMA_AULA_DATA.CAD_TDIID = TB_TURMA_DISCIP.TDI_TURDISID
JOIN TB_CRONOGRAMA_AULA
  ON TB_CRONOGRAMA_AULA.CAU_CADID = TB_CRONOGRAMA_AULA_DATA.CAD_ID
JOIN TB_HORARIO
  ON TB_HORARIO.HOR_ID = TB_CRONOGRAMA_AULA.CAU_HORID
JOIN ZDADOS_TURNOS
  ON ZDADOS_TURNOS.CODCOLIGADA =  ZMIGRA_BASE.CODCOLIGADA
  AND ZDADOS_TURNOS.CODTURNO =  ZMIGRA_BASE.CODTURNO_PARA
  AND ZDADOS_TURNOS.DIASEMANA = TB_CRONOGRAMA_AULA_DATA.CAD_DIASEM
  AND ZDADOS_TURNOS.HORAINICIAL = FORMAT(TB_HORARIO.HOR_HORINI, 'HH:mm')
JOIN ZDADOSORI_STURNO
  ON ZDADOSORI_STURNO.CODCOLIGADA = ZMIGRA_BASE.CODCOLIGADA
  AND ZDADOSORI_STURNO.CODTURNO = ZMIGRA_BASE.CODTURNO_PARA
WHERE ZDEPARA_SDISCIPLINAS.CODIGO_PARA NOT LIKE 'NÃO IMPORTAR'

SELECT * FROM ZMIGRA_SHORARIOBASE ORDER BY CODFILIAL, CODTURMA_PARA, DIA, AULA ;