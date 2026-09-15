IF OBJECT_ID ('ZDEPARA_FUNCOES') IS NOT NULL
DROP TABLE ZDEPARA_FUNCOES ; 

SELECT DISTINCT 
       CAR.EMP_CODIGO				    AS EMPRESA_DE,
	   CAR.CODIGO					    AS CODIGO_DE,
	   LTRIM(RTRIM(CAR.NOME))		    AS NOME_DE,
	   CBO_CODIGO					    AS CBO,
	   CBO2009_CODIGO				    AS CBO_2002,
	   ZDEPARA_COLIGADAS.CODCOLIGADA	AS CODCOLIGADA,
	   RIGHT('000000' + CAST(DENSE_RANK () OVER (ORDER BY TRIM(CAR.NOME), CBO2009_CODIGO) AS VARCHAR(6)) ,6) AS CODIGO_PARA
  INTO ZDEPARA_FUNCOES
  FROM CAR
  JOIN ZDEPARA_COLIGADAS
    ON CAR.EMP_CODIGO = ZDEPARA_COLIGADAS.EMPRESA_DE
   AND EXISTS (SELECT 1 
                 FROM SEP
	            WHERE SEP.EMP_CODIGO = CAR.EMP_CODIGO
			      AND SEP.CAR_CODIGO = CAR.CODIGO)
 ORDER BY CODIGO_PARA ;

--SELECT * FROM ZDEPARA_FUNCOES ORDER BY CODIGO_PARA;

-------------------------------------------------------------------------
-- SCRIPT PARA CRIA��O DE TABELA DE MIGRA��O DE FUN��O ------------------
-------------------------------------------------------------------------

--
--IF OBJECT_ID ('ZMIGRA_FUNCOES') IS NOT NULL
--DROP TABLE ZMIGRA_FUNCOES ;
--
--
----CRIAR LAYOUT DE IMPORTA��O
--SELECT DISTINCT
--       CAST(CODIGO_PARA AS VARCHAR(6)) AS "C�digo",
--       CAST(UPPER(NOME_DE) AS VARCHAR(100)) AS "Nome da Fun��o",         
--       NULL AS "Numero de Pontos (Formato 99999,99)",
--       NULL AS "CBO",
--       NULL AS "C�digo do Cargo",
--       0 AS "Indicativo de Inatividade (0-N�o/1-Sim)",
--       0 AS "Atividade de Transporte (0-N�o/1-Sim)", 
--       NULL AS "Descri��o (come�a com /@ e termina com @/)",
--       NULL AS "Faixa Salarial",               
--       NULL AS "Limite de Funcion�rios",
--       NULL AS "Valor Verba Q.Vagas",    
--       NULL AS "Percentual Verba Q.Vagas",
--       ISNULL(CBO_2002,CBO) AS "CBO 2002",
--       NULL AS "C�digo da tabela",
--       NULL AS "Nro pontos dispon�veis para a fun��o",
--       NULL AS "Objetivo da fun��o",
--       NULL AS "Descri��o para o PPP",
--       NULL AS "Exibi��o no Organograma",
--       NULL AS "C�d. fun��o chefia",        
--       NULL AS "Jornada de refer�ncia da fun��o",
--       NULL AS "Tipo de Fun��o PPE",
--       NULL AS "Sigla da fun��o/cargo",   
--       NULL AS "Definir se o cargo � de confian�a ou n�o",
--       NULL AS "Integra��o GUPY: �de para� do nome da fun��o utilizado para enviar CSV com dados da entidade"
--	   --NULL AS CAMPOEXTRA1
-- INTO ZMIGRA_FUNCOES
-- FROM ZDEPARA_FUNCOES ;

SELECT * FROM ZDEPARA_FUNCOES ;
