IF OBJECT_ID('ZMIGRA_SHABILITACAOFILIALPL') IS NOT NULL
   DROP TABLE ZMIGRA_SHABILITACAOFILIALPL ;

DECLARE @ANOLETIVO AS INTEGER = 2026

SELECT DISTINCT
      CAST(ZDEPARA_SHABILITACAOFILIAL.CODCOLIGADA AS VARCHAR)                 AS CODCOLIGADA,
      CAST(ZDEPARA_SPLETIVO.CODIGO_PARA AS VARCHAR)                           AS CODPERLET,
      ZDEPARA_SHABILITACAOFILIAL.CODCURSO_PARA                                AS CODCURSO,
      ZDEPARA_SHABILITACAOFILIAL.CODHABILITACAO_PARA                          AS CODHABILITACAO,
      ZDEPARA_SHABILITACAOFILIAL.CODGRADE_PARA                                AS CODGRADE,
      CAST(ZDADOSORI_STURNO.NOME AS VARCHAR)                                  AS TURNO,
      CAST(ZDEPARA_SHABILITACAOFILIAL.CODFILIAL_PARA AS VARCHAR)                   AS CODFILIAL,
      CAST(ZDEPARA_SHABILITACAOFILIAL.NIVELENSINO AS VARCHAR)                 AS CODTIPOCURSO,
      NULL                                                                    AS DTNUMAUTOMATICA,
      NULL                                                                    AS DTINICIOMATRICULA,
      NULL                                                                    AS DTFINMATRICULA,
      NULL                                                                    AS HRINICIOMATRICULA,
      NULL                                                                    AS HRFINMATRICULA,
      NULL                                                                    AS PONTUACAOMINIMA,
      NULL                                                                    AS MAXIMOAULAS,
      NULL                                                                    AS [PLANO PAGAMENTO],
      NULL                                                                    AS [PLANO PAGAMENTO POR SERVIÇO],
      NULL                                                                    AS DTINICIOALTERACAOPROGRAMA,
      NULL                                                                    AS DTFIMALTERACAOPROGRAMA,
      NULL                                                                    AS HRINICIOALTERACAOPROGRAMA,
      NULL                                                                    AS HRFIMALTERACAOPROGRAMA,
      NULL                                                                    AS DTINICIOAUTESPECIAL,
      NULL                                                                    AS DTFIMAUTESPECIAL,
      NULL                                                                    AS HRINICIOAUTESPECIAL,
      NULL                                                                    AS HRFIMAUTESPECIAL,
      NULL                                                                    AS DTLIMITETRANCAMENTO,
      NULL                                                                    AS CODCOLCXA,
      NULL                                                                    AS CODCXA,
      NULL                                                                    AS DTCOMPETENCIAINICIAL,
      NULL                                                                    AS DTCOMPETENCIAFINAL,
      NULL                                                                    AS DTCOMPETENCIAINICIALMOV,
      NULL                                                                    AS DTCOMPETENCIAFINALMOV,
      NULL                                                                    AS PERMITEMATFILIALDIF,
      NULL                                                                    AS USASUGESTAODISCIPLINACURSO,
      NULL                                                                    AS SUGESTTURMADIF,
      NULL                                                                    AS SUGESTTURNODIF,
      NULL                                                                    AS SUGESTGRADEDIF,
      NULL                                                                    AS SUGESTHABILITACAODIF,
      NULL                                                                    AS SUGESTCURSODIF,
      NULL                                                                    AS SELECTURMASLIVRES,
      NULL                                                                    AS MOSTRARDISCOPTELESDD,
      NULL                                                                    AS DESCONSIDERARREQDISC,
      NULL                                                                    AS FILIALDIFPRESENCIAL,
      NULL                                                                    AS FILIALDIFPORTAL,
      NULL                                                                    AS EXIBIRTURDISCEMCURSO,
      NULL                                                                    AS EXIBIREQUIVALENTE,
      NULL                                                                    AS EQUIVTURNOS,
      NULL                                                                    AS EQUIVMATRIZES,
      NULL                                                                    AS EQUIVCURSOS,
      NULL                                                                    AS EQUIVHABILITACOES
      INTO ZMIGRA_SHABILITACAOFILIALPL
  FROM 
      ZDEPARA_SHABILITACAOFILIAL
  JOIN ZDEPARA_SPLETIVO
    ON ZDEPARA_SPLETIVO.CODCOLIGADA             = ZDEPARA_SHABILITACAOFILIAL.CODCOLIGADA
    AND ZDEPARA_SPLETIVO.CODFILIAL_PARA         = ZDEPARA_SHABILITACAOFILIAL.CODFILIAL_PARA
    AND ZDEPARA_SPLETIVO.NIVELENSINO            = ZDEPARA_SHABILITACAOFILIAL.NIVELENSINO
    AND ZDEPARA_SPLETIVO.DESCRICAO              = ZDEPARA_SHABILITACAOFILIAL.ANO
  JOIN ZDADOSORI_STURNO
    ON ZDADOSORI_STURNO.CODCOLIGADA             = ZDEPARA_SHABILITACAOFILIAL.CODCOLIGADA
    AND ZDADOSORI_STURNO.CODFILIAL              = ZDEPARA_SHABILITACAOFILIAL.CODFILIAL_PARA
    AND ZDADOSORI_STURNO.CODTIPOCURSO           = ZDEPARA_SHABILITACAOFILIAL.NIVELENSINO
    AND ZDADOSORI_STURNO.CODTURNO               = ZDEPARA_SHABILITACAOFILIAL.CODTURNO_PARA
  WHERE
    ZDEPARA_SHABILITACAOFILIAL.ANO LIKE @ANOLETIVO
    AND ZDEPARA_SHABILITACAOFILIAL.CODCURSO_PARA NOT LIKE 'NÃO IMPORTAR' 

SELECT * FROM ZMIGRA_SHABILITACAOFILIALPL ;