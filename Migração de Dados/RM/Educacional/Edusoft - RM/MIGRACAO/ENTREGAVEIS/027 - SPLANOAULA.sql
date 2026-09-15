IF OBJECT_ID('ZMIGRA_SPLANOAULA') IS NOT NULL
	DROP TABLE ZMIGRA_SPLANOAULA
;

SELECT
	CAST(ZMIGRA_SHORARIOBASE.CODCOLIGADA AS INT)                                   	AS CODCOLIGADA,
	CAST(ZMIGRA_SHORARIOBASE.CODFILIAL AS INT)                                     	AS CODFILIAL,
	CAST(ZMIGRA_SHORARIOBASE.NIVELENSINO AS INT)                                  	AS CODTIPOCURSO,
	ZMIGRA_SHORARIOBASE.CODTURMA_PARA 	                                			AS CODTURMA,
    ZMIGRA_SHORARIOBASE.HORARIO_INICIAL						 						AS HORAINICIAL,
    ZMIGRA_SHORARIOBASE.HORARIO_FINAL						 						AS HORAFINAL,
	ZMIGRA_SHORARIOBASE.TURNO_PARA				                        			AS NOMETURNO,
	CAST(ZMIGRA_SHORARIOBASE.CODPERLET_PARA AS INT)                                 AS CODPERLET,
	ZDEPARA_SDISCIPLINAS.CODIGO_PARA                          						AS CODDISC,
	CAST(ZMIGRA_SHORARIOBASE.AULA AS INT)                                           AS AULA,
	CAST(ZMIGRA_SHORARIOBASE.DIA_SEMANA_PARA AS INT)                      			AS DIASEMANA,
	NULL							                               	    			AS IDHORARIOTURMA,
	NULL                                                      						AS CODPREDIO,
	NULL                                                      						AS CODSALA,
	ZMIGRA_SHORARIOBASE.CODPROF   		                  							AS CODPROF,
	CAST(ZMIGRA_SHORARIOBASE.DIA AS DATE)						              		AS DATA,
	REPLACE(
		REPLACE(
			REPLACE(
				REPLACE(
					LTRIM(RTRIM(REPLACE(REPLACE(TB_CONTEUDO_MINISTRADO.CMI_CONTEUDO, CHAR(13), ' '), CHAR(10), ' '))),
				'  ','!$'),
			'!$ ',''),
		'!$',' '),
		';',''
	) AS CONTEUDO,
	NULL                                                      						AS LOCACAO,
	REPLACE(
		REPLACE(
			REPLACE(
				REPLACE(
					LTRIM(RTRIM(REPLACE(REPLACE(TB_CONTEUDO_MINISTRADO.CMI_CONTEUDO, CHAR(13), ' '), CHAR(10), ' '))),
				'  ','!$'),
			'!$ ',''),
		'!$',' '),
		';',''
	) AS CONTEUDOEFETIVO,
	ZMIGRA_SHORARIOBASE.DIA							           						AS DATAEFETIVA,
	NULL                                                      						AS REPOSICAO,
	NULL                                                      						AS SUBSTITUTO,
	NULL                                                      						AS PAGAMENTOPROF,
	NULL                                                      						AS TIPOFALTA,
	NULL                                                      						AS CODBLOCO,
	NULL                                                      						AS FREQUENCIADISPWEB,
	NULL                                                      						AS LICAOCASA,
	NULL                                                      						AS OBSERVACAO,
	NULL                                                      						AS CONFIRMADO,
	NULL                                                      						AS TIPOAULA
	INTO ZMIGRA_SPLANOAULA
FROM ZMIGRA_SHORARIOBASE

INNER JOIN TB_TURMA_DISCIP
    ON TB_TURMA_DISCIP.UNIDON = ZMIGRA_SHORARIOBASE.CODFILIAL_DE
    AND TB_TURMA_DISCIP.TDI_TURID = ZMIGRA_SHORARIOBASE.CODIGO_TURMA
    AND TB_TURMA_DISCIP.TDI_DISCID = ZMIGRA_SHORARIOBASE.CODDISC_DE

INNER JOIN ZDEPARA_SDISCIPLINAS
    ON ZDEPARA_SDISCIPLINAS.CODIGO = TB_TURMA_DISCIP.TDI_DISCID
   AND ZDEPARA_SDISCIPLINAS.CODIGO_PARA <> 'NÃO IMPORTAR'

INNER JOIN TB_CRONOGRAMA_AULA_DATA
    ON TB_CRONOGRAMA_AULA_DATA.CAD_TDIID = TB_TURMA_DISCIP.TDI_TURDISID
    AND CAST(TB_CRONOGRAMA_AULA_DATA.CAD_DATA AS DATE) = ZMIGRA_SHORARIOBASE.DIA

INNER JOIN TB_CONTEUDO_MINISTRADO
    ON TB_CONTEUDO_MINISTRADO.CMI_CADID = TB_CRONOGRAMA_AULA_DATA.CAD_ID
   AND TB_CONTEUDO_MINISTRADO.CMI_CONTEUDO IS NOT NULL

SELECT * FROM ZMIGRA_SPLANOAULA ORDER BY CODFILIAL, CODTURMA, DATA, AULA ;