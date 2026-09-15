IF OBJECT_ID('ZMIGRA_STURMADISC') IS NOT NULL
	DROP TABLE ZMIGRA_STURMADISC
;

IF OBJECT_ID('dbo.fn_RemoveAcentos', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_RemoveAcentos;
GO

CREATE FUNCTION dbo.fn_RemoveAcentos
(
    @Texto NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN TRANSLATE
    (
        @Texto,
        N'ÁÀÃÂÄáàãâäÉÈÊËéèêëÍÌÎÏíìîïÓÒÕÔÖóòõôöÚÙÛÜúùûüÇçÑñÝŸýÿ',
        N'AAAAAaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCcNnYYyy'
    );
END;
GO

DECLARE @ANOLETIVO AS INTEGER = 2026

SELECT DISTINCT
	ZMIGRA_BASE.CODCOLIGADA			                        	AS CODCOLIGADA,
	ZMIGRA_BASE.CODCURSO                             			AS CODCURSO,
	ZMIGRA_BASE.CODHABILITACAO                           		AS CODHABILITACAO,
	ZMIGRA_BASE.CODGRADE_PARA                              		AS CODGRADE,
	ZMIGRA_BASE.TURNO_PARA                               		AS TURNO,
	CAST(ZMIGRA_BASE.CODFILIAL AS INT)                      	AS CODFILIAL,
	CAST(ZMIGRA_BASE.CODTIPOCURSO AS INT)                       AS CODTIPOCURSO,
	CAST(ZMIGRA_BASE.CODPERLET AS INT)                          AS CODPERLET,
	ZDEPARA_SDISCIPLINAS.CODIGO_PARA	                		AS CODDISC,
	ZMIGRA_BASE.CODTURMA		                				AS CODTURMA,
	NULL                                  						AS CODPREDIO,
	NULL                                  						AS CODSALA,
	NULL                                  						AS CODCCUSTO,
	CAST(ZMIGRA_STURMA.MAXALUNOS AS INT)                   		AS MAXALUNOS,
	NULL                                  						AS MINALUNOS,
	NULL                                  						AS DTINICIAL,
	NULL                                  						AS DTFINAL,
	NULL                                  						AS NUMAULASEM,
	NULL                                  						AS DURACAOAULA,
	NULL                                  						AS CUSTOMEDIO,
	dbo.fn_RemoveAcentos(ZDEPARA_SDISCIPLINAS.NOME)                 AS NOME,
	NULL                                  						AS TIPO,
	NULL                                  						AS CODCAMPUS,
	NULL                                  						AS CODBLOCO,
	'N'                                   						AS ADICIONALNOTURNO,
	'N'                                   						AS ADICIONALEXTRA,
	NULL                                  						AS VAGASCALOUROS,
	NULL                                  						AS NUMMAXALUNOOUTROSCURSOS,
	'N'                                   						AS DISPONIVELMATRICULA,
	NULL                                  						AS NUMCREDITOSCOB,
	NULL                                  						AS VAGASLISTAESPERA,
	NULL                                  						AS VALORCREDITO,
	NULL                                  						AS DTINICIOMATPRES,
	NULL                                  						AS DTFIMMATPRES,
	NULL                                  						AS DTINICIOMATPORTAL,
	NULL                                  						AS DTFIMMATPORTAL,
	'S'                                   						AS ATIVA,
	'N'                                   						AS GERENCIAL,
	NULL                                  						AS TURNOTURMADISC,
	NULL                                  						AS CODITINERARIOFORMATIVO
	INTO ZMIGRA_STURMADISC
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
JOIN ZMIGRA_STURMA
  ON ZMIGRA_STURMA.CODCOLIGADA = ZMIGRA_BASE.CODCOLIGADA
  AND ZMIGRA_STURMA.CODCURSO = ZMIGRA_BASE.CODCURSO
  AND ZMIGRA_STURMA.CODHABILITACAO = ZMIGRA_BASE.CODHABILITACAO
  AND ZMIGRA_STURMA.CODGRADE = ZMIGRA_BASE.CODGRADE_PARA
  AND ZMIGRA_STURMA.TURNO = ZMIGRA_BASE.TURNO_PARA
  AND ZMIGRA_STURMA.CODFILIAL = ZMIGRA_BASE.CODFILIAL
  AND ZMIGRA_STURMA.CODPERLET = ZMIGRA_BASE.CODPERLET
  AND ZMIGRA_STURMA.CODTURMA = ZMIGRA_BASE.CODTURMA
WHERE ZDEPARA_SDISCIPLINAS.CODIGO_PARA NOT LIKE 'NÃO IMPORTAR' ;

DROP FUNCTION dbo.fn_RemoveAcentos
GO

SELECT * FROM ZMIGRA_STURMADISC ;