IF OBJECT_ID ('ZDEPARA_TURMAS') IS NOT NULL
   DROP TABLE ZDEPARA_TURMAS
;

DECLARE @CODCOLIGADA INT
SET @CODCOLIGADA = 13

SELECT 
      TB_TURMA.TUR_ID                         AS CODIGO_DE,
      TB_TURMA.TUR_DESCRI                     AS NOME_DE,
      TB_TURMA.TUR_PERID                      AS PERIODO_DE,
      TB_TURMA.TUR_CURID                      AS CURSO_DE,
      TB_TURMA.TUR_FASE                       AS SERIE_DE,
      TB_TURMA.TUR_SEQTUR                     AS IDENTIFICACAO_DE,
      TB_TURMA.UNIDON                         AS FILIAL_DE,
      TB_PERIODO_LETIVO.PEL_DESCRI            AS PERIODO_LETIVO_DE,
      @CODCOLIGADA                                AS CODCOLIGADA,
      ''                                           AS FILIAL_PARA,
      ''                                           AS NIVEL_ENSINO,
      ''                                           AS CODCURSO_PARA,
      ''                                           AS NOMECURSO_PARA,
      ''                                           AS CODHABILITACAO_PARA,
      ''                                           AS NOMEHABILITACAO_PARA,
      ''                                           AS CODGRADE_PARA,
      ''                                           AS NOMEGRADE_PARA,
      ''                                           AS CODTURNO_PARA,
      ''                                           AS NOMETURNO_PARA,
      ''                                           AS IDHABILITACAOFILIAL_PARA,
      ''                                           AS CODIGOTURMA_PARA,
      ''                                           AS NOMETURMA_PARA
      INTO ZDEPARA_TURMAS
  FROM 
      TB_TURMA 
      JOIN TB_PERIODO_LETIVO
        ON TB_PERIODO_LETIVO.PEL_PERID = TB_TURMA.TUR_PERID
WHERE 
    TB_PERIODO_LETIVO.PEL_DESCRI LIKE '%2026%'
ORDER BY 
     1, 2, 3, 4, 5 DESC
;

SELECT * FROM ZDEPARA_TURMAS ;

