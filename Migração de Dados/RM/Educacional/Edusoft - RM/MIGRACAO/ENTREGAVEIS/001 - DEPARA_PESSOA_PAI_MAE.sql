IF OBJECT_ID('ZDEPARA_PPESSOA_PAI_MAE') IS NOT NULL
    DROP TABLE ZDEPARA_PPESSOA_PAI_MAE
;

IF OBJECT_ID('PAI_ALUNO') IS NOT NULL
    DROP TABLE PAI_ALUNO

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

/*--------/* CONSULTA PRINCIPAL */--------*/

/*--------/* CRIA TABELA AUXILIAR PAI_ALUNO */--------*/

SELECT DISTINCT
    TB_PESSOA_FILIACAO.PFL_PESID,
    TB_PESSOA_FILIACAO.PFL_FILID,
    CASE
        WHEN TB_PESSOA.PES_SEXO LIKE 'M' THEN 'PAI'
        WHEN TB_PESSOA.PES_SEXO LIKE 'F' THEN 'MAE'
        ELSE 'INDEFINIDO'
    END AS TIPO,
    dbo.fn_RemoveAcentos(TB_PESSOA.PES_NOME) AS NOME,
    CAST(TB_PESSOA.PES_DATNAS AS DATE) AS DTNASCIMENTO,
    TB_PESSOA.PES_ESTCIV AS ESTADOCIVIL,
    TB_PESSOA.PES_SEXO AS SEXO,
    TB_PESSOA.PES_ENDERE AS RUA,
    TB_PESSOA.PES_NUMERO AS NUMERO,
    TB_PESSOA.PES_COMEND AS COMPLEMENTO,
    TB_PESSOA.PES_BAIRRO AS BAIRRO,
    dbo.fn_RemoveAcentos(TB_MUNICIPIO.MUN_NOME) AS CIDADE,
    dbo.fn_RemoveAcentos(TB_UNIDADE_FEDERACAO.UFE_SIGUF) AS ESTADO,
    TB_PESSOA.PES_CEP AS CEP,
    TB_PESSOA.PES_TIPNAC AS PAIS,
    TB_PESSOA.GRUPO_UNIDON,
    TB_PESSOA.UNIDON,
    TB_PESSOA.PES_MUNNASID,
    CASE
        WHEN LEN(dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC1)) = 11 
        THEN dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC1)
        ELSE dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC2)
    END CPF,
    TB_PESSOA.PES_FONCEL AS FONE,
    CASE
        WHEN LEN(dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC1)) <> 11 
        THEN dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC1)
        ELSE dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC2)
    END RG
    INTO PAI_ALUNO
FROM TB_PESSOA_FILIACAO
INNER JOIN TB_PESSOA
    ON TB_PESSOA.PES_ID = TB_PESSOA_FILIACAO.PFL_FILID
LEFT JOIN TB_MUNICIPIO
    ON TB_MUNICIPIO.MUN_ID = TB_PESSOA.PES_CODMUN
LEFT JOIN TB_UNIDADE_FEDERACAO
    ON TB_UNIDADE_FEDERACAO.UFE_ID = TB_MUNICIPIO.MUN_UFID
;

SELECT DISTINCT
     PAI_ALUNO.PFL_PESID                               AS COD_ALUNO,
     dbo.fn_RemoveAcentos(TB_PESSOA.PES_NOME)          AS NOME,
     CASE
        WHEN UPPER(TB_PESSOA.PES_SEXO) = 'F' THEN 'MAE'
        WHEN UPPER(TB_PESSOA.PES_SEXO) = 'M' THEN 'PAI'
        ELSE 'NAO INFORMADO'
     END                                               AS TIPO,
     (
        SELECT PES_NOME FROM TB_PESSOA WHERE PES_ID = PAI_ALUNO.PFL_PESID
     ) AS NOME_ALUNO,
     ''                                                AS APELIDO,
     PAI_ALUNO.DTNASCIMENTO                            AS DTNASCIMENTO,
     PAI_ALUNO.ESTADOCIVIL                             AS ESTADOCIVIL,
     PAI_ALUNO.SEXO                                    AS SEXO,
    CASE WHEN EXISTS (
        SELECT 1 
        FROM TB_MUNICIPIO 
        WHERE TB_MUNICIPIO.MUN_ID = PAI_ALUNO.PES_MUNNASID
        ) 
    THEN (
        SELECT dbo.fn_RemoveAcentos(TB_MUNICIPIO.MUN_NOME)
        FROM TB_MUNICIPIO 
        WHERE TB_MUNICIPIO.MUN_ID = PAI_ALUNO.PES_MUNNASID
        )
    ELSE ''
    END                                                             AS NATURALIDADE,
    CASE WHEN EXISTS (
        SELECT 1 
        FROM TB_MUNICIPIO 
        LEFT JOIN TB_UNIDADE_FEDERACAO 
            ON TB_UNIDADE_FEDERACAO.UFE_ID = TB_MUNICIPIO.MUN_UFID 
        WHERE TB_MUNICIPIO.MUN_ID = PAI_ALUNO.PES_MUNNASID
        ) 
    THEN (
        SELECT TB_UNIDADE_FEDERACAO.UFE_SIGUF
        FROM TB_MUNICIPIO 
        LEFT JOIN TB_UNIDADE_FEDERACAO 
            ON TB_UNIDADE_FEDERACAO.UFE_ID = TB_MUNICIPIO.MUN_UFID 
        WHERE TB_MUNICIPIO.MUN_ID = PAI_ALUNO.PES_MUNNASID
        )  
    ELSE '' 
    END                                                             AS ESTADONATAL,

     10                                                AS NACIONALIDADE,
     NULL                                              AS GRAUINSTRUCAO,
     1                                                 AS CODTIPORUA,
     PAI_ALUNO.RUA                                     AS RUA,
     PAI_ALUNO.NUMERO                                  AS NUMERO,
     PAI_ALUNO.COMPLEMENTO                             AS COMPLEMENTO,
     1                                                 AS CODTIPOBAIRRO,
     PAI_ALUNO.BAIRRO                                  AS BAIRRO,
     PAI_ALUNO.ESTADO                                  AS ESTADO,
     PAI_ALUNO.CIDADE                                  AS CIDADE,
     PAI_ALUNO.CEP                                     AS CEP,
     PAI_ALUNO.PAIS                                    AS PAIS,
     ''                                                AS REGPROFISSIONAL,
     PAI_ALUNO.CPF                                     AS CPF,
     dbo.fn_SomenteNumeros(PAI_ALUNO.FONE)             AS TELEFONE1,
     dbo.fn_SomenteNumeros(PAI_ALUNO.FONE)             AS TELEFONE2,
     dbo.fn_SomenteNumeros(PAI_ALUNO.FONE)             AS TELEFONE3,
     ''                                                AS FAX,
     TB_PESSOA.PES_EMAIL                               AS EMAIL,
     PAI_ALUNO.RG                                      AS CARTIDENTIDADE,
     ''                                                AS UFCARTIDENT,
     ''                                                AS ORGEMISSORIDENT,
     NULL                                              AS DTEMISSAOIDENT,
     ''                                                AS TITULOELEITOR,
     ''                                                AS ZONATITELEITOR,
     ''                                                AS SECAOTITELEITOR,
     NULL                                              AS DTTITELEITOR,
     ''                                                AS ESTELEIT,
     ''                                                AS CARTEIRATRAB,
     ''                                                AS SERIECARTTRAB,
     ''                                                AS UFCARTTRAB,
     NULL                                              AS DTCARTTRAB,
     ''                                                AS NIT,
     ''                                                AS CARTMOTORISTA,
     ''                                                AS TIPOCARTHABILIT,
     NULL                                              AS DTVENCHABILIT,
     ''                                                AS SITMILITAR,
     ''                                                AS CERTIFRESERV,
     ''                                                AS CATEGMILITAR,
     ''                                                AS CSM,
     NULL                                              AS DTEXPCML,
     ''                                                AS EXPED,
     ''                                                AS RM,
     ''                                                AS NROREGGERAL,
     ''                                                AS NPASSAPORTE,
     ''                                                AS PAISORIGEM,
     NULL                                              AS DTEMISSPASSAPORTE,
     NULL                                              AS DTVALPASSAPORTE,
     dbo.fn_RemoveAcentos(TB_RACA.RAC_DESCRI)          AS CORRACA,
     0                                                 AS DEFICIENTEFISICO,
     0                                                 AS DEFICIENTEAUDITIVO,
     0                                                 AS DEFICIENTEFALA,
     0                                                 AS DEFICIENTEVISUAL,
     0                                                 AS DEFICIENTEMENTAL,
     ''                                                AS RECURSOREALIZACAOTRAB,
     ''                                                AS RECURSOACESSIBILIDADE,
     ''                                                AS PROFISSAO,
     ''                                                AS EMPRESA,
     ''                                                AS OCUPACAO,
     ''                                                AS TIPOSANG,
     0                                                 AS ALUNO,
     0                                                 AS PROFESSOR,
     0                                                 AS USUARIOBIBLIOS,
     0                                                 AS FUNCIONARIO,
     0                                                 AS EXFUNCIONARIO,
     0                                                 AS CANDIDATO,
     0                                                 AS FALECIDO,
     NULL                                              AS DATAOBITO,
     ''                                                AS MATRICULAOBITO,
     ''                                                AS NOMESOCIAL
     INTO ZDEPARA_PPESSOA_PAI_MAE
FROM TB_PESSOA
LEFT JOIN PAI_ALUNO
  ON PAI_ALUNO.PFL_FILID = TB_PESSOA.PES_ID
INNER JOIN (
	SELECT DISTINCT CFI_PESID, CFI_PERID, GRUPO_UNIDON, UNIDON
	FROM TB_CONTRATO_FIN 
) TB_CONTRATO_FIN
  ON TB_CONTRATO_FIN.CFI_PESID = PAI_ALUNO.PFL_PESID
  AND TB_CONTRATO_FIN.CFI_PERID <> (SELECT TOP 1 PEL_PERID FROM TB_PERIODO_LETIVO WHERE PEL_ANOREF = 2026)
LEFT JOIN TB_RACA
  ON TB_RACA.RAC_ID = TB_PESSOA.PES_RACID
ORDER BY
     PAI_ALUNO.PFL_PESID
;

DROP FUNCTION dbo.fn_SomenteNumeros;
DROP FUNCTION dbo.fn_RemoveAcentos;
GO

SELECT * FROM ZDEPARA_PPESSOA_PAI_MAE ;