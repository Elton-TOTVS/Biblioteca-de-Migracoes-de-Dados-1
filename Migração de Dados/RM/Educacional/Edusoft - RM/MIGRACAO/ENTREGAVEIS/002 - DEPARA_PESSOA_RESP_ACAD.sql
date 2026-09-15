IF OBJECT_ID('ZDEPARA_PESSOA_RESP_ACAD', 'U') IS NOT NULL
    DROP TABLE ZDEPARA_PESSOA_RESP_ACAD;

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

DECLARE @ANOLETIVO AS INTEGER = 2026

SELECT DISTINCT
    'RESP_ACAD'                                                             AS TIPO,
    TB_RESPONSAVEL_FIN.RFI_PESID                                            AS CODIGO,
    TB_CONTRATO_FIN.CFI_PESID                                               AS MATRICULA,
    dbo.fn_RemoveAcentos(TB_PESSOA.PES_NOME)                                AS NOME,
    ''                                                                      AS APELIDO,
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
    ELSE ''   
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
    ''                                                                      AS CODTIPORUA,
    dbo.fn_RemoveAcentos(TB_PESSOA.PES_ENDERE)                              AS RUA,
    TB_PESSOA.PES_NUMERO                                                    AS NUMERO,
    dbo.fn_RemoveAcentos(TB_PESSOA.PES_COMEND)                              AS COMPLEMENTO,
    1                                                                       AS CODTIPOBAIRRO,
    dbo.fn_RemoveAcentos(TB_PESSOA.PES_BAIRRO)                              AS BAIRRO,
    TB_UNIDADE_FEDERACAO.UFE_SIGUF                                          AS ESTADO,
    TB_MUNICIPIO.MUN_NOME                                                   AS CIDADE,
    TB_PESSOA.PES_CEP                                                       AS CEP,
    TB_PESSOA.PES_TIPNAC                                                    AS PAIS,
    ''                                                                      AS REGPROFISSIONAL,
    CASE
        WHEN LEN(dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC1)) = 11 
        THEN dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC1)
        ELSE dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC2)
    END                                                                     AS CPF,
    dbo.fn_SomenteNumeros(TB_PESSOA.PES_FONCEL)                             AS TELEFONE1,
    dbo.fn_SomenteNumeros(TB_PESSOA.PES_FONCEL)                             AS TELEFONE2,
    dbo.fn_SomenteNumeros(TB_PESSOA.PES_FONCEL)                             AS TELEFONE3,
    ''                                                                      AS FAX,
    TB_PESSOA.PES_EMAIL                                                     AS EMAIL,
    CASE
        WHEN LEN(dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC1)) <> 11 
        THEN dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC1)
        ELSE dbo.fn_SomenteNumeros(TB_PESSOA.PES_NRODOC2)
    END                                                                     AS CARTIDENTIDADE,
    ''                                                                      AS UFCARTIDENT,
    ''                                                                      AS ORGEMISSORIDENT,
    NULL                                                                    AS DTEMISSAOIDENT,
    ''                                                                      AS TITULOELEITOR,
    ''                                                                      AS ZONATITELEITOR,
    ''                                                                      AS SECAOTITELEITOR,
    NULL                                                                    AS DTTITELEITOR,
    ''                                                                      AS ESTELEIT,
    ''                                                                      AS CARTEIRATRAB,
    ''                                                                      AS SERIECARTTRAB,
    ''                                                                      AS UFCARTTRAB,
    NULL                                                                    AS DTCARTTRAB,
    ''                                                                      AS NIT,
    ''                                                                      AS CARTMOTORISTA,
    ''                                                                      AS TIPOCARTHABILIT,
    NULL                                                                    AS DTVENCHABILIT,
    ''                                                                      AS SITMILITAR,
    ''                                                                      AS CERTIFRESERV,
    ''                                                                      AS CATEGMILITAR,
    ''                                                                      AS CSM,
    NULL                                                                    AS DTEXPCML,
    ''                                                                      AS EXPED,
    ''                                                                      AS RM,
    ''                                                                      AS NROREGGERAL,
    ''                                                                      AS NPASSAPORTE,
    ''                                                                      AS PAISORIGEM,
    NULL                                                                    AS DTEMISSPASSAPORTE,
    NULL                                                                    AS DTVALPASSAPORTE,
    dbo.fn_RemoveAcentos(TB_RACA.RAC_DESCRI)                                AS CORRACA,
    0                                                                       AS DEFICIENTEFISICO,
    0                                                                       AS DEFICIENTEAUDITIVO,
    0                                                                       AS DEFICIENTEFALA,
    0                                                                       AS DEFICIENTEVISUAL,
    0                                                                       AS DEFICIENTEMENTAL,
    ''                                                                      AS RECURSOREALIZACAOTRAB,
    ''                                                                      AS RECURSOACESSIBILIDADE,
    ''                                                                      AS PROFISSAO,
    ''                                                                      AS EMPRESA,
    ''                                                                      AS OCUPACAO,
    ''                                                                      AS TIPOSANG,
    0                                                                       AS ALUNO,
    0                                                                       AS PROFESSOR,
    0                                                                       AS USUARIOBIBLIOS,
    0                                                                       AS FUNCIONARIO,
    0                                                                       AS EXFUNCIONARIO,
    0                                                                       AS CANDIDATO,
    0                                                                       AS FALECIDO,
    NULL                                                                    AS DATAOBITO,
    ''                                                                      AS MATRICULAOBITO,
    ''                                                                      AS NOMESOCIAL,
    NULL                                                                    AS OBSERVACOES
    INTO ZDEPARA_PESSOA_RESP_ACAD
FROM TB_RESPONSAVEL_FIN
INNER JOIN TB_CONTRATO_FIN
  ON TB_CONTRATO_FIN.CFI_ID = TB_RESPONSAVEL_FIN.RFI_CFIID
  AND TB_CONTRATO_FIN.GRUPO_UNIDON = TB_RESPONSAVEL_FIN.GRUPO_UNIDON
  AND TB_CONTRATO_FIN.UNIDON = TB_RESPONSAVEL_FIN.UNIDON
  AND TB_CONTRATO_FIN.CFI_PERID <> (SELECT TOP 1 PEL_PERID FROM TB_PERIODO_LETIVO WHERE PEL_ANOREF = @ANOLETIVO)
INNER JOIN TB_PESSOA
  ON TB_RESPONSAVEL_FIN.RFI_PESID = TB_PESSOA.PES_ID
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

SELECT * FROM ZDEPARA_PESSOA_RESP_ACAD ;