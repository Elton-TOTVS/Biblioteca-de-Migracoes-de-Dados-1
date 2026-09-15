IF OBJECT_ID('ZMIGRA_SGRADE') IS NOT NULL
      DROP TABLE ZMIGRA_SGRADE
;

DECLARE @CODCOLIGADA AS INTEGER = 13

SELECT
      @CODCOLIGADA                                                AS CODCOLIGADA,
      ZDEPARA_SGRADE.CODCURSO                                     AS CODCURSO,
      ZDEPARA_SGRADE.CODHABILITACAO                               AS CODHABILITACAO,
      ZDEPARA_SGRADE.CODGRADE                                     AS CODGRADE,
      'MATRIZ ' + ZDEPARA_SGRADE.NOME_MATRIZ                      AS DESCRICAO,
      NULL                                                        AS DTINICIO,
      NULL                                                        AS DTFIM,
      NULL                                                        AS CARGAHORARIA,
      NULL                                                        AS CONTROLEVAGAS,
      0                                                           AS STATUS,
      NULL                                                        AS CODCURSOPROX,
      NULL                                                        AS CODHABILITACAOPROX,
      NULL                                                        AS CODGRADEPROX,
      NULL                                                        AS MAXCREDPERIODO,
      NULL                                                        AS MINCREDPERIODO,
      'S'                                                         AS REGIME,
      'H'                                                         AS TIPOATIVIDADECURRICULAR,
      'H'                                                         AS TIPOELETIVA,
      'H'                                                         AS TIPOOPTATIVA,
      NULL                                                        AS DTDOU,
      NULL                                                        AS TOTALCREDITOS
      INTO ZMIGRA_SGRADE
FROM ZDEPARA_SGRADE;

SELECT * FROM ZMIGRA_SGRADE ;