IF OBJECT_ID('EDUSOFT_FCFO') IS NOT NULL
	DROP TABLE EDUSOFT_FCFO;

IF OBJECT_ID('dbo.fn_RemoveAcentos', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_RemoveAcentos;
GO

CREATE FUNCTION dbo.fn_RemoveAcentos (
    @Texto NVARCHAR(MAX)
) RETURNS NVARCHAR(MAX) AS
BEGIN
    RETURN TRANSLATE
    (
        @Texto,
        N'ÁÀÃÂÄáàãâäÉÈÊËéèêëÍÌÎÏíìîïÓÒÕÔÖóòõôöÚÙÛÜúùûüÇçÑñÝŸýÿ',
        N'AAAAAaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCcNnYYyy'
    );
END;
GO

DECLARE @CODCOLIGADA AS INT = 13

SELECT DISTINCT
	@CODCOLIGADA                                                                        AS CODCOLIGADA,
	RIGHT('0000'+CAST(DENSE_RANK() OVER (ORDER BY ZPESSOA_REG.CPF) AS VARCHAR),4)       AS ID,
	ZPESSOA_REG.NOME                                                                    AS NOMEFANTASIA,
	ZPESSOA_REG.NOME                                                                    AS NOME,
	ZPESSOA_REG.CPF                                                                     AS CGCCFO,
	1                                                                              		AS PAGREC,
	CASE 
		WHEN ZPESSOA_REG.ESTADO LIKE 'NA' THEN ''
		ELSE ZPESSOA_REG.ESTADO
	END AS CODETD,
	'F'                                                                                 AS PESSOAFISOUJUR,
	0                                                                              		AS NACIONALIDADE,
	ISNULL(UPPER(ZPESSOA_REG.RUA),'')                                     		        AS RUA,
	ISNULL(ZPESSOA_REG.NUMERO,0)                                                        AS NUMERO,
	ISNULL(ZPESSOA_REG.COMPLEMENTO,'') 			                                        AS COMPLEMENTO,
	ISNULL(UPPER(ZPESSOA_REG.BAIRRO),'')                                        		AS BAIRRO,
	ISNULL(
	(
		SELECT TOP 1
			GMUNICIPIO.NOMEMUNICIPIO 
		FROM CorporeRM.dbo.GMUNICIPIO
		WHERE GMUNICIPIO.CODETDMUNICIPIO COLLATE SQL_Latin1_General_CP1_CI_AI = ZPESSOA_REG.ESTADO
		  AND dbo.fn_RemoveAcentos(UPPER(GMUNICIPIO.NOMEMUNICIPIO)) COLLATE Latin1_General_CI_AI = ZPESSOA_REG.CIDADE
	), ''
	) AS CIDADE,
	ISNULL(ZPESSOA_REG.CEP,'')                                                                     AS CEP,
	ISNULL(CASE
		WHEN ZPESSOA_REG.TELEFONE1 IS NOT NULL THEN RIGHT(ZPESSOA_REG.TELEFONE1, 11)
		WHEN ZPESSOA_REG.TELEFONE2 IS NOT NULL THEN RIGHT(ZPESSOA_REG.TELEFONE2, 11)
		WHEN ZPESSOA_REG.TELEFONE3 IS NOT NULL THEN RIGHT(ZPESSOA_REG.TELEFONE3, 11)
		ELSE NULL
	END, '99999999999') AS TELEFONE,
	ISNULL(ZPESSOA_REG.ESTADO,'')                                                                  AS ESTADO,
	ISNULL(
		RIGHT('00000' + 
			(
				SELECT TOP 1
					GMUNICIPIO.CODMUNICIPIO 
				FROM CorporeRM.dbo.GMUNICIPIO
				WHERE GMUNICIPIO.CODETDMUNICIPIO COLLATE SQL_Latin1_General_CP1_CI_AI = ZPESSOA_REG.ESTADO
				AND dbo.fn_RemoveAcentos(UPPER(GMUNICIPIO.NOMEMUNICIPIO)) COLLATE Latin1_General_CI_AI = ZPESSOA_REG.CIDADE
			),
		5), '' 
	) AS CODMUNICIPIO,
	1                                                                              		AS IDPAIS,
	''                                                                           		AS INSCRESTADUAL,
	''                                                                           		AS INSCRMUNICIPAL,
	''                                                                           		AS TELEX,
	FORMAT(ZPESSOA_REG.DTNASCIMENTO, 'dd/MM/yyyy')                                      AS DTNASCIMENTO,
	ISNULL(ZPESSOA_REG.EMAIL, '')                                                       AS EMAIL,
	''                                                                           		AS PLT_COD,
	ZPESSOA_REG.MATRICULA                                                               AS MATRICULA
	INTO EDUSOFT_FCFO
FROM ZPESSOA_REG
WHERE ZPESSOA_REG.TIPO = 'RESP_ACAD'
  AND DATEDIFF(YEAR, ZPESSOA_REG.DTNASCIMENTO, GETDATE()) > 18
;

DROP FUNCTION dbo.fn_RemoveAcentos;
GO

--EXCLUI DUPLICIDADES
IF OBJECT_ID('ZDADOS_FCFO') IS NOT NULL
	DROP TABLE ZDADOS_FCFO;

SELECT ROW_NUMBER() OVER (PARTITION BY ID ORDER BY ID, DTNASCIMENTO) AS RN, * INTO ZDADOS_FCFO FROM EDUSOFT_FCFO;
GO

DELETE FROM ZDADOS_FCFO WHERE RN <> 1 OR LEN(REPLACE(REPLACE(TRIM(CGCCFO),'.',''),'-','')) <> 11;

ALTER TABLE ZDADOS_FCFO DROP COLUMN RN;

IF OBJECT_ID('FCFO_RM') IS NOT NULL
	DROP TABLE FCFO_RM;

SELECT CODCOLIGADA,
	   ID,
	   NOMEFANTASIA,
	   NOME,
	   CGCCFO,
	   PAGREC,
	   CODETD,
	   PESSOAFISOUJUR,
	   NACIONALIDADE,
	   RUA,
	   NUMERO,
	   COMPLEMENTO,
	   BAIRRO,
	   CIDADE,
	   CEP,
	   TELEFONE,
	   CODMUNICIPIO,
	   IDPAIS,
	   INSCRESTADUAL,
	   INSCRMUNICIPAL,
	   TELEX,
	   DTNASCIMENTO,
	   EMAIL
  INTO FCFO_RM
  FROM ZDADOS_FCFO;

SELECT * FROM FCFO_RM ORDER BY ID;