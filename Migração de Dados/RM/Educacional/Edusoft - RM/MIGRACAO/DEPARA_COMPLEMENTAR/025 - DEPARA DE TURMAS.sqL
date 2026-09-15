IF OBJECT_ID ('ZDEPARA_TURMAS_COMPL') IS NOT NULL
   DROP TABLE ZDEPARA_TURMAS_COMPL
;

SELECT 
      SOPHIA.TURMAS.CODIGO                         AS CODIGO_DE,
      SOPHIA.TURMAS.NOME                           AS NOME_DE,
      SOPHIA.TURMAS.PERIODO                        AS PERIODO_DE,
      SOPHIA.TURMAS.CURSO                          AS CURSO_DE,
      SOPHIA.TURMAS.SERIE                          AS SERIE_DE,
      SOPHIA.TURMAS.TURMA                          AS IDENTIFICACAO_DE,
      SOPHIA.TURMAS.UNIDADE                        AS FILIAL_DE,
      SOPHIA.PERIODOS.DESCRICAO                    AS PERIODO_LETIVO_DE,
      14                                           AS CODCOLIGADA,
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
      INTO ZDEPARA_TURMAS_COMPL
  FROM 
      SOPHIA.TURMAS 
      JOIN SOPHIA.PERIODOS
        ON SOPHIA.PERIODOS.CODIGO = SOPHIA.TURMAS.PERIODO
 WHERE 
       YEAR(SOPHIA.PERIODOS.INICIO) = '2026'
   AND NOT EXISTS (SELECT 1 FROM ZDEPARA_TURMAS AS Z WHERE Z.CODIGO_DE = SOPHIA.TURMAS.CODIGO AND Z.PERIODO_DE = SOPHIA.TURMAS.PERIODO AND Z.CURSO_DE = SOPHIA.TURMAS.CURSO AND Z.SERIE_DE = SOPHIA.TURMAS.SERIE AND Z.IDENTIFICACAO_DE = SOPHIA.TURMAS.TURMA AND Z.FILIAL_DE = SOPHIA.TURMAS.UNIDADE)       
ORDER BY 
     CURSO_DE, FILIAL_DE, IDENTIFICACAO_DE
;

SELECT * FROM ZDEPARA_TURMAS_COMPL ;

