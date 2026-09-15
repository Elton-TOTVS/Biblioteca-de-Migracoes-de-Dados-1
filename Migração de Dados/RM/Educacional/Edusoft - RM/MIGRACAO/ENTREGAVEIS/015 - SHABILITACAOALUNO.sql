-- CODCOLIGADA, CODCURSO, CODHABILITACAO, CODGRADE, CODFILIAL, CODTURNO: recuperar IdHabilitacaoFilial		

IF OBJECT_ID('ZMIGRA_SHABILITACAOALUNO') IS NOT NULL
    DROP TABLE ZMIGRA_SHABILITACAOALUNO
;

SELECT DISTINCT
    ZMIGRA_BASE.CODCOLIGADA                                              AS CODCOLIGADA,
    ZDEPARA_SHABILITACAOFILIAL.CODCURSO_PARA                             AS CODCURSO,
    ZDEPARA_SHABILITACAOFILIAL.CODHABILITACAO_PARA                       AS CODHABILITACAO,
    ZDEPARA_SHABILITACAOFILIAL.CODGRADE_PARA                             AS CODGRADE,
    ZMIGRA_BASE.TURNO_PARA                                               AS TURNO,
    CAST(ZDEPARA_SHABILITACAOFILIAL.CODFILIAL_PARA AS INT)               AS CODFILIAL,
    CAST(ZDEPARA_SHABILITACAOFILIAL.NIVELENSINO AS INT)                  AS CODTIPOCURSO,
    ZMIGRA_BASE.RA                                                       AS RA,
    NULL                                                                 AS INGRESSO,
    NULL                                                                 AS INSTITUICAO,
    CASE
		WHEN ZMIGRA_BASE.CODTIPOCURSO = 2 THEN 'Cursando'
		ELSE ZMIGRA_BASE.STATUS
	END AS STATUS,
    ( SELECT TOP 1 MATRICULA.DTMATRICULA 
        FROM (
            SELECT RA, DTMATRICULA FROM ZMIGRA_BASE
        ) MATRICULA
        WHERE MATRICULA.RA = ZMIGRA_BASE.RA ORDER BY 1 DESC
    ) AS DTINGRESSO,
    NULL                                                                 AS PONTOSVESTIBULAR,
    NULL                                                                 AS CLASSIFICACAOVESTIBULAR,
    NULL                                                                 AS MEDIAVESTIBULAR,
    NULL                                                                 AS DTCOLACAOGRAU,
    NULL                                                                 AS DTEMISDIPLOMA,
    NULL                                                                 AS REGISTROCONCLUSAO,
    NULL                                                                 AS LIVROREGISTRO,
    NULL                                                                 AS PAGINAREGISTRO,
    NULL                                                                 AS DTCONCLUSAOCURSO,
    NULL                                                                 AS CR,
    NULL                                                                 AS MEDIAGLOBAL,
    NULL                                                                 AS DTPROVAO,
    NULL                                                                 AS PROCESSOREGISTRO,
    NULL                                                                 AS INSTITUICAODIPLOMA,
    NULL                                                                 AS REALIZOUPROVAO,
    NULL                                                                 AS CODCURSOTRANSF,
    NULL                                                                 AS CODHABILITACAOTRANSF,
    NULL                                                                 AS CODGRADETRANSF,
    NULL                                                                 AS TURNOTRANSF,
    NULL                                                                 AS CODTIPOCURSOTRANSF,
    NULL                                                                 AS CODFILIALTRANSF,
    NULL                                                                 AS MOTIVOTRANSF,
    NULL                                                                 AS INDICECARENCIA,
    NULL                                                                 AS OBSERVACAO,
    NULL                                                                 AS CODINSTITUICAO,
    NULL                                                                 AS CODINSTTITUICAODIPLOMA,
    NULL                                                                 AS CAMPUS,
    NULL                                                                 AS LOCALIZACAOFISICA
    INTO ZMIGRA_SHABILITACAOALUNO
FROM ZMIGRA_BASE
JOIN ZDEPARA_SHABILITACAOFILIAL
  ON ZDEPARA_SHABILITACAOFILIAL.COD_CURSO = ZMIGRA_BASE.CURSO_DE
  AND ZDEPARA_SHABILITACAOFILIAL.COD_MATRIZ = ZMIGRA_BASE.COD_MATRIZ_DE
  AND ZDEPARA_SHABILITACAOFILIAL.ANO = ZMIGRA_BASE.CODPERLET
  AND ZDEPARA_SHABILITACAOFILIAL.COD_TURNO = UPPER(LEFT(ZMIGRA_BASE.CODTURNO_DE, 1))
  AND ZDEPARA_SHABILITACAOFILIAL.CODFILIAL = ZMIGRA_BASE.CODFILIAL_DE

SELECT * FROM ZMIGRA_SHABILITACAOALUNO ;