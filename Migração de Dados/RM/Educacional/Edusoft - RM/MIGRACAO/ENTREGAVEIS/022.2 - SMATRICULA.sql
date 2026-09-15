IF OBJECT_ID('ZMIGRA_SMATRICULA') IS NOT NULL
	DROP TABLE ZMIGRA_SMATRICULA
;

DECLARE @ANOLETIVO AS INTEGER = 2026

SELECT DISTINCT
	CAST(ZMIGRA_BASE.CODCOLIGADA AS INT)                        			AS CODCOLIGADA,
	ZMIGRA_BASE.CODCURSO                                        			AS CODCURSO,
	ZMIGRA_BASE.CODHABILITACAO	                                			AS CODHABILITACAO,
	ZMIGRA_BASE.CODGRADE_PARA                                   			AS CODGRADE,
	ZDADOSORI_STURNO.NOME		                                			AS TURNO,
	CAST(ZMIGRA_BASE.CODFILIAL AS INT)                          			AS CODFILIAL,
	CAST(ZMIGRA_BASE.CODTIPOCURSO AS INT)                                   AS CODTIPOCURSO,
	ZMIGRA_BASE.CODTURMA                                        			AS CODTURMA,
	CAST(ZMIGRA_BASE.CODPERLET AS INT)                                      AS CODPERLET,
	ZDEPARA_SDISCIPLINAS.CODIGO_PARA                            			AS CODDISC,
	ZMIGRA_BASE.RA                                              			AS RA,
	NULL                                                        			AS STATUSRES,
	CASE
		WHEN ZMIGRA_BASE.CODTIPOCURSO = 2 THEN 'Cursando'
		ELSE ZMIGRA_BASE.STATUS
	END AS STATUS,
	NULL                                                        			AS NUMDIARIO,
	CAST(ZMIGRA_BASE.DTMATRICULA AS DATE)                                   AS DTMATRICULA,
	NULL                                                        			AS OBSHISTORICO,
	'1'                                                         			AS TIPOMAT,
	'N'	                                                        			AS TIPODISCIPLINA,
	NULL                                                        			AS DTALTERACAO,
	NULL                                                        			AS DTALTERACAOSIST,
	NULL                                                        			AS CODSUBTURMA,
	NULL                                                        			AS NUMCREDITOSCOB,
	NULL                                                        			AS COBPOSTERIORMATRIC,
	NULL                                                        			AS CODTURMAORIGEM,
	NULL                                                        			AS CODDISCORIGEM,
	NULL                                                        			AS CODTURMAPRINCIPAL,
	NULL                                                        			AS CODDISCPRINCIPAL
	INTO ZMIGRA_SMATRICULA
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
JOIN ZDADOSORI_STURNO
  ON ZDADOSORI_STURNO.CODCOLIGADA = ZMIGRA_BASE.CODCOLIGADA
  AND ZDADOSORI_STURNO.CODTURNO = ZMIGRA_BASE.CODTURNO_PARA
WHERE ZDEPARA_SDISCIPLINAS.CODIGO_PARA NOT LIKE 'NÃO IMPORTAR';

SELECT * FROM ZMIGRA_SMATRICULA ;