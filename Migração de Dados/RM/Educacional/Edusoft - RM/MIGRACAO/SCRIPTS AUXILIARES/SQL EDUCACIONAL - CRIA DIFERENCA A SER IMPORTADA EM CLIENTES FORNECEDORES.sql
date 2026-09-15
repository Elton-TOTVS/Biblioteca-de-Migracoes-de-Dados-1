USE SESC_EDUSOFT_MS
GO

IF OBJECT_ID('dbo.fn_RemoveAcentos', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_RemoveAcentos;
GO

IF OBJECT_ID('dbo.fn_SomenteNumeros', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_SomenteNumeros;
GO

CREATE FUNCTION dbo.fn_RemoveAcentos (
    @Texto NVARCHAR(MAX)
) RETURNS NVARCHAR(MAX)
WITH SCHEMABINDING
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

CREATE FUNCTION dbo.fn_SomenteNumeros (
    @Texto VARCHAR(MAX)
) RETURNS VARCHAR(MAX) AS
BEGIN
    DECLARE @Resultado VARCHAR(MAX) = '';
    DECLARE @I INT = 1;
    DECLARE @C CHAR(1);

    IF @Texto IS NULL
        RETURN NULL;

    WHILE @I <= LEN(@Texto)
    BEGIN
        SET @C = SUBSTRING(@Texto, @I, 1);

        IF @C LIKE '[0-9]'
            SET @Resultado += @C;

        SET @I += 1;
    END

    RETURN NULLIF(@Resultado, '');
END;
GO

DECLARE @PerId INT = (SELECT TOP 1 PEL_PERID FROM TB_PERIODO_LETIVO WHERE PEL_ANOREF = 2026);

-- 1) Só os responsáveis financeiros do período alvo, com nome já normalizado
IF OBJECT_ID('tempdb..#Responsaveis') IS NOT NULL DROP TABLE #Responsaveis;
IF OBJECT_ID('FCFO_DIF') IS NOT NULL DROP TABLE FCFO_DIF;

SELECT
    TCF.CFI_PESID                                                             AS MATRICULA_ALUNO,
    TCF.UNIDON,
    CAST(dbo.fn_RemoveAcentos(TP.PES_NOME) AS NVARCHAR(200))                  AS NOME_NORMALIZADO,
        CASE
        WHEN LEN(dbo.fn_SomenteNumeros(TP.PES_NRODOC1)) = 11 
        THEN dbo.fn_SomenteNumeros(TP.PES_NRODOC1)
        ELSE dbo.fn_SomenteNumeros(TP.PES_NRODOC2)
    END                                                                       AS CPF,
    dbo.fn_RemoveAcentos(TP.PES_ENDERE)                                       AS RUA,
    TP.PES_NUMERO                                                             AS NUMERO,
    dbo.fn_RemoveAcentos(TP.PES_COMEND)                                       AS COMPLEMENTO,
    dbo.fn_RemoveAcentos(TP.PES_BAIRRO)                                       AS BAIRRO,
    dbo.fn_RemoveAcentos(TB_MUNICIPIO.MUN_NOME)                               AS CIDADE,
    TP.PES_CEP                                                                AS CEP,
    dbo.fn_SomenteNumeros(TP.PES_FONCEL)                                      AS TELEFONE,
    TB_UNIDADE_FEDERACAO.UFE_SIGUF                                            AS ESTADO,
    TP.PES_EMAIL                                                              AS EMAIL,
    CAST(TP.PES_DATNAS AS DATE)                                               AS DTNASCIMENTO
INTO #Responsaveis
FROM TB_RESPONSAVEL_FIN TRF
JOIN TB_CONTRATO_FIN TCF
  ON TCF.CFI_ID = TRF.RFI_CFIID
 AND TCF.GRUPO_UNIDON = TRF.GRUPO_UNIDON
 AND TCF.UNIDON = TRF.UNIDON
 AND TCF.CFI_PERID = @PerId
JOIN TB_PESSOA TP
  ON TP.PES_ID = TRF.RFI_PESID
 AND TP.GRUPO_UNIDON = TRF.GRUPO_UNIDON
 AND TP.UNIDON = TRF.UNIDON
LEFT JOIN TB_MUNICIPIO
  ON TB_MUNICIPIO.MUN_ID = TP.PES_CODMUN
LEFT JOIN TB_UNIDADE_FEDERACAO
  ON TB_UNIDADE_FEDERACAO.UFE_ID = TB_MUNICIPIO.MUN_UFID;

CREATE INDEX IX_Resp_Nome ON #Responsaveis (NOME_NORMALIZADO);

-- 2) FCFO com nome normalizado uma única vez
IF OBJECT_ID('tempdb..#FCFO_Norm') IS NOT NULL DROP TABLE #FCFO_Norm;

SELECT
    CAST(FCFO.NOME AS NVARCHAR(200)) COLLATE SQL_Latin1_General_CP1_CI_AS AS NOME_NORMALIZADO,
    FCFO.CODCFO
INTO #FCFO_Norm
FROM FCFO;

CREATE INDEX IX_FCFO_Nome ON #FCFO_Norm (NOME_NORMALIZADO);

-- 3) Join final, agora sobre conjuntos pequenos e indexados
SELECT DISTINCT
    13 AS CODCOLIGADA,
    CAST((DENSE_RANK() OVER (ORDER BY R.NOME_NORMALIZADO) + 16728 ) AS VARCHAR) AS ID,
    R.NOME_NORMALIZADO AS NOMEFANTASIA,
    R.NOME_NORMALIZADO AS NOME,
    CPF AS CGCCFO,
    1 AS PAGREC,
    ISNULL(ESTADO,'MS') AS CODETD,
    'F' AS PESSOAFISOUJUR,
    0 AS NACIONALIDADE,
    ISNULL(RUA,'') AS RUA,
    ISNULL(NUMERO,0) AS NUMERO,
    ISNULL(COMPLEMENTO,'') AS COMPLEMENTO,
    ISNULL(BAIRRO,'') AS BAIRRO,
    ISNULL(
    ( 
		SELECT TOP 1
			GMUNICIPIO.NOMEMUNICIPIO 
		FROM CorporeRM.dbo.GMUNICIPIO
		WHERE GMUNICIPIO.CODETDMUNICIPIO COLLATE SQL_Latin1_General_CP1_CI_AI = ESTADO
		  AND dbo.fn_RemoveAcentos(UPPER(GMUNICIPIO.NOMEMUNICIPIO)) COLLATE Latin1_General_CI_AI = CIDADE
	), ''
	) AS CIDADE,
    ISNULL(CEP,'') AS CEP,
    CASE WHEN LEN(TELEFONE) <> 11 THEN '' ELSE ISNULL(RIGHT(TELEFONE, 11),'') END AS TELEFONE,
    ISNULL(
		RIGHT('00000' + 
			(
				SELECT TOP 1
					GMUNICIPIO.CODMUNICIPIO 
				FROM CorporeRM.dbo.GMUNICIPIO
				WHERE GMUNICIPIO.CODETDMUNICIPIO COLLATE SQL_Latin1_General_CP1_CI_AI = ESTADO
				AND dbo.fn_RemoveAcentos(UPPER(GMUNICIPIO.NOMEMUNICIPIO)) COLLATE Latin1_General_CI_AI = CIDADE
			),
		5), '' 
	) AS CODMUNICIPIO,
    1 AS IDPAIS,
    '' AS INSCRESTADUAL,
    '' AS INSCRMUNICIPAL,
    '' AS TELEX,
    ISNULL(FORMAT(DTNASCIMENTO, 'dd/MM/yyyy'),'') AS DTNASCIMENTO,
    ISNULL(EMAIL,'') AS EMAIL
    INTO FCFO_DIF
FROM #Responsaveis R
LEFT JOIN #FCFO_Norm F
  ON F.NOME_NORMALIZADO = R.NOME_NORMALIZADO COLLATE SQL_Latin1_General_CP1_CI_AS
JOIN ZMIGRA_BASE ZB
  ON ZB.MATRICULA = R.MATRICULA_ALUNO
 AND ZB.CODFILIAL_DE = R.UNIDON
WHERE F.CODCFO IS NULL;

DROP TABLE #Responsaveis;
DROP TABLE #FCFO_Norm;

DROP FUNCTION dbo.fn_SomenteNumeros;
DROP FUNCTION dbo.fn_RemoveAcentos;
GO