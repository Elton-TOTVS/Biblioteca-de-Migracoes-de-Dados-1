IF OBJECT_ID('ZMIGRA_SNOTAETAPAS_FALTAS') IS NOT NULL
   DROP TABLE ZMIGRA_SNOTAETAPAS_FALTAS ;

SELECT
      DADOS.*
	  INTO ZMIGRA_SNOTAETAPAS_FALTAS
  FROM (
SELECT DISTINCT
	  ZMIGRA_BASE.CODCOLIGADA                                                               AS CODCOLIGADA,
      ZMIGRA_BASE.CODCURSO                                                                  AS CODCURSO,
      ZMIGRA_BASE.CODHABILITACAO                                                            AS CODHABILITACAO,
      ZMIGRA_BASE.CODGRADE_PARA                                                             AS CODGRADE,
      ZMIGRA_BASE.TURNO                                                                     AS TURNO,
      ZMIGRA_BASE.CODFILIAL                                                                 AS CODFILIAL,
      ZMIGRA_BASE.CODTIPOCURSO                                                              AS CODTIPOCURSO,
      ZMIGRA_BASE.RA                                                                        AS RA,
      ZMIGRA_BASE.CODTURMA                                                                  AS CODTURMA,
      ZMIGRA_BASE.CODPERLET                                                                 AS CODPERLET,
      ZDEPARA_SDISCIPLINAS.CODIGO_PARA                                                      AS CODDISC,
      '100'+CAST(SOPHIA.ETAPAS.NUMERO AS VARCHAR)                                           AS CODETAPA,
      'F'                                                                                   AS TIPOETAPA,
      NULL                                                                                  AS CONCEITO,
      NULL                                                                                  AS NOTA,
      NULL                                                                                  AS NUMACERTOS
  FROM 
      SOPHIA.TURMAS
      JOIN ZMIGRA_BASE
           JOIN SOPHIA.MATRICULA
		        JOIN SOPHIA.ACADEMIC
				  ON SOPHIA.ACADEMIC.MATRICULA = SOPHIA.MATRICULA.CODIGO
	  	     ON SOPHIA.MATRICULA.CODIGO = ZMIGRA_BASE.MATRICULA
        ON ZMIGRA_BASE.CODTURMA_DE    = SOPHIA.TURMAS.CODIGO 
       AND ZMIGRA_BASE.SOPHIA_PERIODO = SOPHIA.TURMAS.PERIODO
       AND ZMIGRA_BASE.CODTURNO_DE    = SOPHIA.TURMAS.TURNO
       AND ZMIGRA_BASE.CURSO_DE       = SOPHIA.TURMAS.CURSO
       AND ZMIGRA_BASE.RA IS NOT NULL 
      JOIN SOPHIA.QC 
	       JOIN ZDEPARA_SDISCIPLINAS
	         ON ZDEPARA_SDISCIPLINAS.CODIGO = QC.DISCIPLINA
	    ON SOPHIA.QC.TURMA = SOPHIA.TURMAS.CODIGO
      JOIN SOPHIA.CFG_ACAD
	       JOIN SOPHIA.ETAPAS
             ON SOPHIA.ETAPAS.CFG_ACAD = SOPHIA.CFG_ACAD.CODIGO
	    ON SOPHIA.CFG_ACAD.CODIGO  = SOPHIA.TURMAS.CFG_ACAD
       AND SOPHIA.ACADEMIC.DISCIPLINA = SOPHIA.QC.DISCIPLINA
 WHERE 
      SOPHIA.QC.TIPO_NOTA = 0
  AND SOPHIA.TURMAS.CURSO IS NOT NULL
  AND SOPHIA.TURMAS.SERIE IS NOT NULL
GROUP BY 
      ZMIGRA_BASE.CODCOLIGADA,          
      ZMIGRA_BASE.CODCURSO,             
      ZMIGRA_BASE.CODHABILITACAO,       
      ZMIGRA_BASE.CODGRADE_PARA,        
      ZMIGRA_BASE.TURNO,                
      ZMIGRA_BASE.CODFILIAL,            
      ZMIGRA_BASE.CODTIPOCURSO,         
      ZMIGRA_BASE.RA,                   
      ZMIGRA_BASE.CODTURMA,                   
      ZMIGRA_BASE.CODPERLET,            
      ZDEPARA_SDISCIPLINAS.CODIGO_PARA,
      SOPHIA.ETAPAS.NUMERO,
	  SOPHIA.CFG_ACAD.CODIGO,
	  SOPHIA.ACADEMIC.MEDIA1,
	  SOPHIA.ACADEMIC.MEDIA2,
	  SOPHIA.ACADEMIC.MEDIA3,
	  SOPHIA.ACADEMIC.MEDIA4,
	  SOPHIA.ACADEMIC.MEDIA5,
	  SOPHIA.ACADEMIC.MEDIA6,
	  SOPHIA.ACADEMIC.MEDIA7,
	  SOPHIA.ACADEMIC.MEDIA8,
	  SOPHIA.ACADEMIC.MEDIA9,
	  SOPHIA.ACADEMIC.MEDIA_ANUAL,
	  SOPHIA.ACADEMIC.REC_FINAL,
	  SOPHIA.ACADEMIC.MEDIA_FINAL,
	  ZDEPARA_SDISCIPLINAS.CODIGO,
	  SOPHIA.MATRICULA.CODIGO
/* 
-- UNION
 
-- SELECT DISTINCT
-- 	  ZMIGRA_BASE.CODCOLIGADA                                                               AS CODCOLIGADA,
--       ZMIGRA_BASE.CODCURSO                                                                  AS CODCURSO,
--       ZMIGRA_BASE.CODHABILITACAO                                                            AS CODHABILITACAO,
--       ZMIGRA_BASE.CODGRADE_PARA                                                             AS CODGRADE,
--       ZMIGRA_BASE.TURNO                                                                     AS TURNO,
--       ZMIGRA_BASE.CODFILIAL                                                                 AS CODFILIAL,
--       ZMIGRA_BASE.CODTIPOCURSO                                                              AS CODTIPOCURSO,
--       ZMIGRA_BASE.RA                                                                        AS RA,
--       TURMAS.CODIGO                                                                         AS CODTURMA,
--       ZMIGRA_BASE.CODPERLET                                                                 AS CODPERLET,
--       ZDEPARA_SDISCIPLINAS.CODIGO_PARA                                                      AS CODDISC,
--       SOPHIA.ETAPAS.NUMERO                                                                  AS CODETAPA,
--       'F'                                                                                   AS TIPOETAPA,
--       NULL                                                                                  AS CONCEITO,
--       NULL                                                                                  AS NOTA,
--       NULL                                                                                  AS NUMACERTOS
--   FROM 
--       SOPHIA.TURMAS (NOLOCK)
--       JOIN ZMIGRA_BASE
--            JOIN SOPHIA.MATRICULA
-- 		        JOIN SOPHIA.ACADEMIC
-- 				  ON SOPHIA.ACADEMIC.MATRICULA = SOPHIA.MATRICULA.CODIGO
-- 	  	     ON SOPHIA.MATRICULA.CODIGO = ZMIGRA_BASE.MATRICULA
--         ON ZMIGRA_BASE.CODTURMA       = SOPHIA.TURMAS.CODIGO 
--        AND ZMIGRA_BASE.SOPHIA_PERIODO = SOPHIA.TURMAS.PERIODO
--        AND ZMIGRA_BASE.CODTURNO_DE    = SOPHIA.TURMAS.TURNO
--        AND ZMIGRA_BASE.CURSO_DE       = SOPHIA.TURMAS.CURSO
--        AND ZMIGRA_BASE.RA IS NOT NULL 
--       JOIN SOPHIA.QC 
-- 	       JOIN ZDEPARA_SDISCIPLINAS (NOLOCK) 
-- 	         ON ZDEPARA_SDISCIPLINAS.CODIGO = QC.DISCIPLINA
-- 	    ON SOPHIA.QC.TURMA = SOPHIA.TURMAS.CODIGO
--       JOIN SOPHIA.CFG_ACAD (NOLOCK) 
-- 	       JOIN SOPHIA.ETAPAS (NOLOCK)
--              ON SOPHIA.ETAPAS.CFG_ACAD = SOPHIA.CFG_ACAD.CODIGO
-- 	    ON SOPHIA.CFG_ACAD.CODIGO  = SOPHIA.TURMAS.CFG_ACAD
-- 	   AND SOPHIA.ACADEMIC.DISCIPLINA = SOPHIA.QC.DISCIPLINA
--  WHERE 
--       SOPHIA.QC.TIPO_NOTA = 1
--   AND SOPHIA.TURMAS.CURSO IS NOT NULL
--   AND SOPHIA.TURMAS.SERIE IS NOT NULL
-- GROUP BY 
--       ZMIGRA_BASE.CODCOLIGADA,          
--       ZMIGRA_BASE.CODCURSO,             
--       ZMIGRA_BASE.CODHABILITACAO,       
--       ZMIGRA_BASE.CODGRADE_PARA,        
--       ZMIGRA_BASE.TURNO,                
--       ZMIGRA_BASE.CODFILIAL,            
--       ZMIGRA_BASE.CODTIPOCURSO,         
--       ZMIGRA_BASE.RA,                   
--       TURMAS.CODIGO,                   
--       ZMIGRA_BASE.CODPERLET,            
--       ZDEPARA_SDISCIPLINAS.CODIGO_PARA,
--       SOPHIA.ETAPAS.NUMERO,
-- 	  SOPHIA.CFG_ACAD.CODIGO,
-- 	  SOPHIA.ACADEMIC.MEDIA1,
-- 	  SOPHIA.ACADEMIC.MEDIA2,
-- 	  SOPHIA.ACADEMIC.MEDIA3,
-- 	  SOPHIA.ACADEMIC.MEDIA4,
-- 	  SOPHIA.ACADEMIC.MEDIA5,
-- 	  SOPHIA.ACADEMIC.MEDIA6,
-- 	  SOPHIA.ACADEMIC.MEDIA7,
-- 	  SOPHIA.ACADEMIC.MEDIA8,
-- 	  SOPHIA.ACADEMIC.MEDIA9,
-- 	  SOPHIA.ACADEMIC.MEDIA_ANUAL,
-- 	  SOPHIA.ACADEMIC.REC_FINAL,
-- 	  SOPHIA.ACADEMIC.MEDIA_FINAL
--     */
) AS DADOS
WHERE EXISTS (SELECT 1 
                FROM ZMIGRA_SNOTAETAPA AS Z 
               WHERE Z.CODCOLIGADA = DADOS.CODCOLIGADA 
                 AND Z.CODCURSO = DADOS.CODCURSO 
                 AND Z.CODDISC = DADOS.CODDISC 
                 AND Z.CODETAPA = DADOS.CODETAPA 
                 AND Z.CODFILIAL = DADOS.CODFILIAL 
                 AND Z.CODGRADE = DADOS.CODGRADE 
                 AND Z.CODHABILITACAO = DADOS.CODHABILITACAO 
                 AND Z.CODPERLET = DADOS.CODPERLET 
                 AND Z.CODTIPOCURSO = DADOS.CODTIPOCURSO 
                 AND Z.CODTURMA = DADOS.CODTURMA 
                 AND Z.RA = DADOS.RA) ; 

SELECT * FROM ZMIGRA_SNOTAETAPAS_FALTAS ;
