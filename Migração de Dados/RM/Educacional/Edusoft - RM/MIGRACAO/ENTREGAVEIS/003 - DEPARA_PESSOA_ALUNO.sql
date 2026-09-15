IF OBJECT_ID('ZDEPARA_PESSOA_ALUNO') IS NOT NULL
    DROP TABLE ZDEPARA_PESSOA_ALUNO
;

/*--------/* FUNÇÕES AUXILIARES PARA LIMPEZA DE DADOS */--------*/

IF OBJECT_ID('dbo.fn_SomenteNumeros', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_SomenteNumeros;

IF OBJECT_ID('dbo.fn_RemoveAcentos', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_RemoveAcentos;
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

DECLARE @ANOLETIVO AS INT = 2026

/*--------/* CONSULTA PRINCIPAL */--------*/

SELECT DISTINCT
    'ALUNO'                                                                 AS TIPO,
    'MT'                                                                    AS BASE,
    CAST('' AS VARCHAR(1))                                                  AS QUALIFICADO,
    CAST('' AS VARCHAR(10))                                                 AS MOTIVO1,
    CAST('' AS VARCHAR(10))                                                 AS MOTIVO2,
    TB_PESSOA.PES_ID                                                        AS MATRICULA,
    TB_PESSOA.PES_ID                                                        AS CODIGO,
    dbo.fn_RemoveAcentos(TB_PESSOA.PES_NOME)                                AS NOME,
    ' '                                                                     AS APELIDO,
    CAST(TB_PESSOA.PES_DATNAS AS DATE)                                      AS DTNASCIMENTO,
    TB_PESSOA.PES_ESTCIV                                                    AS ESTADOCIVIL,
    TB_PESSOA.PES_SEXO                                                      AS SEXO,
    CASE WHEN EXISTS (
        SELECT 1 
        FROM TB_MUNICIPIO 
        WHERE TB_MUNICIPIO.MUN_ID = TB_PESSOA.PES_MUNNASID
            AND TB_MUNICIPIO.UNIDON = TB_PESSOA.UNIDON 
            AND TB_MUNICIPIO.GRUPO_UNIDON = TB_PESSOA.GRUPO_UNIDON
        ) 
    THEN (
        SELECT dbo.fn_RemoveAcentos(TB_MUNICIPIO.MUN_NOME)
        FROM TB_MUNICIPIO 
        WHERE TB_MUNICIPIO.MUN_ID = TB_PESSOA.PES_MUNNASID
            AND TB_MUNICIPIO.UNIDON = TB_PESSOA.UNIDON 
            AND TB_MUNICIPIO.GRUPO_UNIDON = TB_PESSOA.GRUPO_UNIDON
        )
    ELSE 'NAO IDENTIFICADO'  
    END                                                                     AS NATURALIDADE,
    CASE WHEN EXISTS (
        SELECT 1 
        FROM TB_MUNICIPIO 
        LEFT JOIN TB_UNIDADE_FEDERACAO 
            ON TB_UNIDADE_FEDERACAO.UFE_ID = TB_MUNICIPIO.MUN_UFID 
            AND TB_UNIDADE_FEDERACAO.UNIDON = TB_PESSOA.UNIDON 
            AND TB_UNIDADE_FEDERACAO.GRUPO_UNIDON = TB_PESSOA.GRUPO_UNIDON 
        WHERE TB_MUNICIPIO.MUN_ID = TB_PESSOA.PES_MUNNASID
            AND TB_MUNICIPIO.UNIDON = TB_PESSOA.UNIDON 
            AND TB_MUNICIPIO.GRUPO_UNIDON = TB_PESSOA.GRUPO_UNIDON
        ) 
    THEN (
        SELECT TB_UNIDADE_FEDERACAO.UFE_SIGUF
        FROM TB_MUNICIPIO 
        LEFT JOIN TB_UNIDADE_FEDERACAO 
            ON TB_UNIDADE_FEDERACAO.UFE_ID = TB_MUNICIPIO.MUN_UFID 
            AND TB_UNIDADE_FEDERACAO.UNIDON = TB_PESSOA.UNIDON 
            AND TB_UNIDADE_FEDERACAO.GRUPO_UNIDON = TB_PESSOA.GRUPO_UNIDON 
        WHERE TB_MUNICIPIO.MUN_ID = TB_PESSOA.PES_MUNNASID
            AND TB_MUNICIPIO.UNIDON = TB_PESSOA.UNIDON 
            AND TB_MUNICIPIO.GRUPO_UNIDON = TB_PESSOA.GRUPO_UNIDON
        )  
    ELSE '' 
    END                                                                     AS ESTADONATAL,
    10                                                                      AS NACIONALIDADE,
    NULL                                                                    AS GRAUINSTRUCAO,
    1                                                                       AS CODTIPORUA,
    dbo.fn_RemoveAcentos(TB_PESSOA.PES_ENDERE)                              AS RUA,
    TB_PESSOA.PES_NUMERO                                                    AS NUMERO,
    ' '                                                                     AS COMPLEMENTO,
    1                                                                       AS CODTIPOBAIRRO,
    dbo.fn_RemoveAcentos(TB_PESSOA.PES_BAIRRO)                              AS BAIRRO,
    dbo.fn_RemoveAcentos(TB_UNIDADE_FEDERACAO.UFE_SIGUF)                    AS ESTADO,
    dbo.fn_RemoveAcentos(TB_MUNICIPIO.MUN_NOME)                             AS CIDADE,
    TB_PESSOA.PES_CEP                                                       AS CEP,
    TB_PESSOA.PES_TIPNAC                                                    AS PAIS,
    ' '                                                                     AS REGPROFISSIONAL,
    CASE
        WHEN LEN(dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC1)) = 11 
        THEN dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC1)
        ELSE dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC2)
    END                                                                     AS CPF,
    dbo.fn_SomenteNumeros(TB_PESSOA.PES_FONCEL)                             AS TELEFONE1,
    dbo.fn_SomenteNumeros(TB_PESSOA.PES_FONCEL)                             AS TELEFONE2,
    dbo.fn_SomenteNumeros(TB_PESSOA.PES_FONCEL)                             AS TELEFONE3,
    ' '                                                                     AS FAX,
    TB_PESSOA.PES_EMAIL                                                     AS EMAIL,
    CASE
        WHEN LEN(dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC1)) <> 11 
        THEN dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC1)
        ELSE dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC2)
    END                                                                     AS CARTIDENTIDADE,
    ' '                                                                     AS UFCARTIDENT,
    ' '                                                                     AS ORGEMISSORIDENT,
    NULL                                                                    AS DTEMISSAOIDENT,
    ' '                                                                     AS TITULOELEITOR,
    ' '                                                                     AS ZONATITELEITOR,
    ' '                                                                     AS SECAOTITELEITOR,
    NULL                                                                    AS DTTITELEITOR,
    ' '                                                                     AS ESTELEIT,
    ' '                                                                     AS CARTEIRATRAB,
    ' '                                                                     AS SERIECARTTRAB,
    ' '                                                                     AS UFCARTTRAB,
    NULL                                                                    AS DTCARTTRAB,
    ' '                                                                     AS NIT,
    ' '                                                                     AS CARTMOTORISTA,
    ' '                                                                     AS TIPOCARTHABILIT,
    NULL                                                                    AS DTVENCHABILIT,
    ' '                                                                     AS SITMILITAR,
    ' '                                                                     AS CERTIFRESERV,
    ' '                                                                     AS CATEGMILITAR,
    ' '                                                                     AS CSM,
    NULL                                                                    AS DTEXPCML,
    ' '                                                                     AS EXPED,
    ' '                                                                     AS RM,
    ' '                                                                     AS NROREGGERAL,
    ' '                                                                     AS NPASSAPORTE,
    ' '                                                                     AS PAISORIGEM,
    NULL                                                                    AS DTEMISSPASSAPORTE,
    NULL                                                                    AS DTVALPASSAPORTE,
    dbo.fn_RemoveAcentos(TB_RACA.RAC_DESCRI)                                AS CORRACA,
    0                                                                       AS DEFICIENTEFISICO,
    0                                                                       AS DEFICIENTEAUDITIVO,
    0                                                                       AS DEFICIENTEFALA,
    0                                                                       AS DEFICIENTEVISUAL,
    0                                                                       AS DEFICIENTEMENTAL,
    ' '                                                                     AS RECURSOREALIZACAOTRAB,
    ' '                                                                     AS RECURSOACESSIBILIDADE,
    ' '                                                                     AS PROFISSAO,
    ' '                                                                     AS EMPRESA,
    ' '                                                                     AS OCUPACAO,
    ' '                                                                     AS TIPOSANG,
    0                                                                       AS ALUNO,
    0                                                                       AS PROFESSOR,
    0                                                                       AS USUARIOBIBLIOS,
    0                                                                       AS FUNCIONARIO,
    0                                                                       AS EXFUNCIONARIO,
    0                                                                       AS CANDIDATO,
    ' '                                                                     AS FALECIDO,
    NULL                                                                    AS DATAOBITO,
    ' '                                                                     AS MATRICULAOBITO,
    ' '                                                                     AS NOMESOCIAL,
    ' '                                                                     AS OBSERVACOES
    INTO ZDEPARA_PESSOA_ALUNO
FROM TB_PESSOA
INNER JOIN (
	SELECT DISTINCT CFI_PESID, CFI_PERID, GRUPO_UNIDON, UNIDON
	FROM TB_CONTRATO_FIN 
) TB_CONTRATO_FIN
  ON TB_CONTRATO_FIN.CFI_PESID = TB_PESSOA.PES_ID
  AND TB_CONTRATO_FIN.CFI_PERID = (SELECT TOP 1 PEL_PERID FROM TB_PERIODO_LETIVO WHERE PEL_ANOREF = @ANOLETIVO)
LEFT JOIN TB_MUNICIPIO  
    ON TB_MUNICIPIO.MUN_ID = TB_PESSOA.PES_CODMUN
LEFT JOIN TB_UNIDADE_FEDERACAO
    ON TB_UNIDADE_FEDERACAO.UFE_ID = TB_MUNICIPIO.MUN_UFID
LEFT JOIN TB_RACA
    ON TB_RACA.RAC_ID = TB_PESSOA.PES_RACID
;

DROP FUNCTION dbo.fn_SomenteNumeros;
DROP FUNCTION dbo.fn_RemoveAcentos;
GO  

UPDATE ZDEPARA_PESSOA_ALUNO 
       SET MOTIVO1     = CASE WHEN ISNULL(MATRICULA,'0') ='0' THEN 'SEM RA' ELSE 'COM RA' END
FROM ZDEPARA_PESSOA_ALUNO 
;

UPDATE ZDEPARA_PESSOA_ALUNO 
      SET MOTIVO2     = CASE WHEN ISNULL(CPF,'0') ='0' THEN 'SEM CPF' ELSE 'COM CPF' END
FROM ZDEPARA_PESSOA_ALUNO 
;

/* INSERIDO A PARTE DE AJUSTE DE QUALIFICADO */
UPDATE ZDEPARA_PESSOA_ALUNO 
       SET QUALIFICADO = CASE 
	                         WHEN MOTIVO1 = 'COM RA' 
							  AND MOTIVO2 = 'COM CPF'
							 THEN 'S' 
							 ELSE 'N' 
						  END 
;

SELECT * FROM ZDEPARA_PESSOA_ALUNO ORDER BY 6 ;
