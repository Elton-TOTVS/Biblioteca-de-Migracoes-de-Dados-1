----------------------------------------------------------------------------------------------------      
-- Script:					ZMIGRA_FUNCOES
-- Última Alteração:		19/01/2026     
-- Versão:					1 
-- Origem:					FORTES
-- Autor Alteração:			Reno Neto
----------------------------------------------------------------------------------------------------
IF OBJECT_ID ('ZMIGRA_FUNCOES') IS NOT NULL
    DROP TABLE ZMIGRA_FUNCOES;

--CRIAR LAYOUT DE IMPORTAÇÃO
SELECT DISTINCT
       COLIGADA_PARA AS CODCOLIGADA,
       CAST(CODIGO_PARA AS VARCHAR(6)) AS "Código",
       CAST(UPPER(NOME_DE) AS VARCHAR(100)) AS "Nome da Função",         
       NULL AS "Numero de Pontos (Formato 99999,99)",
       NULL AS "CBO",
       NULL AS "Código do Cargo",
       0 AS "Indicativo de Inatividade (0-Não/1-Sim)",
       0 AS "Atividade de Transporte (0-Não/1-Sim)", 
       NULL AS "Descrição (começa com /@ e termina com @/)",
       NULL AS "Faixa Salarial",               
       NULL AS "Limite de Funcionários",
       NULL AS "Valor Verba Q.Vagas",    
       NULL AS "Percentual Verba Q.Vagas",
       ISNULL(CBO_2002,CBO) AS "CBO 2002",
       NULL AS "Código da tabela",
       NULL AS "Nro pontos disponíveis para a função",
       NULL AS "Objetivo da função",
       NULL AS "Descrição para o PPP",
       NULL AS "Exibição no Organograma",
       NULL AS "Cód. função chefia",        
       NULL AS "Jornada de referência da função",
       NULL AS "Tipo de Função PPE",
       NULL AS "Sigla da função/cargo",   
       NULL AS "Definir se o cargo é de confiança ou não",
       NULL AS "Integração GUPY: ´de para´ do nome da função utilizado para enviar CSV com dados da entidade"
	   --NULL AS CAMPOEXTRA1
 INTO ZMIGRA_FUNCOES
 FROM ZDEPARA_FUNCOES_NOVAS;

 SELECT * FROM ZMIGRA_FUNCOES;


--  IF OBJECT_ID ('ZMIGRA_FUNCOES') IS NOT NULL
--     DROP TABLE ZMIGRA_FUNCOES; 

-- SELECT DISTINCT
--        CODIGO_PARA AS "Código",
--        CAST(UPPER(NOME_DE) AS VARCHAR(100)) AS "Nome da Função",         
--        NULL AS "Numero de Pontos (Formato 99999,99)",
--        NULL AS "CBO",
--        NULL AS "Código do Cargo",
--        0 AS "Indicativo de Inatividade (0-Não/1-Sim)",
--        0 AS "Atividade de Transporte (0-Não/1-Sim)", 
--        NULL AS "Descrição (começa com /@ e termina com @/)",
--        NULL AS "Faixa Salarial",                
--        NULL AS "Limite de Funcionários",
--        NULL AS "Valor Verba Q.Vagas",    
--        NULL AS "Percentual Verba Q.Vagas",
--        ISNULL(CBO_2002, CBO) AS "CBO 2002",
--        NULL AS "Código da tabela",
--        NULL AS "Nro pontos disponíveis para a função",
--        NULL AS "Objetivo da função",
--        NULL AS "Descrição para o PPP",
--        NULL AS "Exibição no Organograma",
--        NULL AS "Cód. função chefia",        
--        NULL AS "Jornada de referência da função",
--        NULL AS "Tipo de Função PPE",
--        NULL AS "Sigla da função/cargo",   
--        NULL AS "Definir se o cargo é de confiança ou não",
--        NULL AS "Integração GUPY: de para do nome da função utilizado para enviar CSV com dados da entidade"
--   INTO ZMIGRA_FUNCOES
--   FROM ZDEPARA_FUNCOES; 

-- SELECT * FROM ZMIGRA_FUNCOES;