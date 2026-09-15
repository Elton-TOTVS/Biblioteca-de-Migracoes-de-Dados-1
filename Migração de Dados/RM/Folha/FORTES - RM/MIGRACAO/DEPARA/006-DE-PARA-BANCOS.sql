-------------------------------------------------------------------------
-- SCRIPT PARA DE-PARA --------------------------------------------------
-------------------------------------------------------------------------

IF OBJECT_ID ('ZDEPARA_BANCOS') IS NOT NULL
DROP TABLE ZDEPARA_BANCOS ; 

WITH AGE_FORMAT AS (
    SELECT *, 
        REPLACE(
        REPLACE(
        REPLACE(
        AGE.NUMERO
        ,'-','')
        ,' ','')
        ,'/','') AS NUMAGENCIA_FORMAT
    FROM AGE
)

SELECT DISTINCT 

       EPG.EMP_CODIGO AS EMPRESA_DE,
	   EPG.AGE_BAN_CODIGO AS CODIGO_BANCO_DE, --UTILIZAR ESSE código PARA MAPEAMENTO DO SCRIPT ZMIGRA_PFUNC
	   EPG.AGE_CODIGO AS CODIGO_AGENCIA_DE, --UTILIZAR ESSE código PARA MAPEAMENTO DO SCRIPT ZMIGRA_PFUNC

	   --BANCOS
	   BAN.NUMERO AS NUMBANCO_DE,
	   BAN.NOME AS NOME_BANCO_DE,

	   --AGÊNCIAS
	   AGE_FORMAT.NUMERO AS NUMAGENCIA_DE, 
	   AGE_FORMAT.NOME AS NOME_AGENCIA_DE,

	   --SUGESTÃO CODIGO_PARA
	   	CASE WHEN BAN.NUMERO = '122' THEN '104' ELSE CAST(BAN.NUMERO AS VARCHAR(5)) END AS CODIGO_BANCO_PARA, 
		
		CASE 
			-- Valida se a Agencia possui até 4 caracteres e "-", assim sendo, formata o número e aplica os zeros a esquerda
			WHEN LEN(AGE_FORMAT.NUMERO) <= 4 AND AGE_FORMAT.NUMERO NOT LIKE '%-%' THEN RIGHT('0000' + CAST(AGE_FORMAT.NUMAGENCIA_FORMAT AS VARCHAR(4)), 4) 
			-- Se não tiver, aplica a formatação
			ELSE RIGHT('0000' + 
				LEFT( 
					CAST(
						(LEFT(
								AGE_FORMAT.NUMAGENCIA_FORMAT,
								(
									LEN(AGE_FORMAT.NUMAGENCIA_FORMAT
								)-1) -- Retorna o valor sem o último caractere (Necessário para remover o "X" de alguns tipos de agência)
								) * 1) -- Converte em Inteiro e remove os zeros a esquerda  
					AS VARCHAR), 4
				), 4 -- Pega os 4 Primeiros Dígitos
			) -- Completa com até 4 Zeros
		END AS CODIGO_AGENCIA_PARA,
		
		CASE 
			WHEN BAN.NOME LIKE '%CAIXA%' OR BAN.NOME LIKE '%CEF%' THEN '' -- Banco CEF não possui dígito
			WHEN LEN(AGE_FORMAT.NUMAGENCIA_FORMAT) <= 4 THEN '' --Se AGE_FORMAT.NUMERO menor que ou igual a 4 dígitos, deixar vazio
			ELSE RIGHT('0' + CAST(REPLACE(RIGHT(AGE_FORMAT.NUMERO,1),'-','') AS VARCHAR(1)),1) 
		END AS DIGITO_AGENCIA_PARA

INTO ZDEPARA_BANCOS
  FROM EPG 
  JOIN ZDEPARA_COLIGADAS 
    ON EPG.EMP_CODIGO = ZDEPARA_COLIGADAS.EMP_CODIGO
  JOIN BAN
	ON BAN.CODIGO = EPG.AGE_BAN_CODIGO
  JOIN AGE_FORMAT
    ON AGE_FORMAT.BAN_CODIGO = EPG.AGE_BAN_CODIGO
   AND AGE_FORMAT.CODIGO     = EPG.AGE_CODIGO ;

SELECT * FROM ZDEPARA_BANCOS;

---------------------------------------------------------------------------------------------------
-- SCRIPT ANTERIOR COM A CORRECAO DAS AGENCIAS-----------------------------------------------------
---------------------------------------------------------------------------------------------------

-- IF OBJECT_ID ('ZDEPARA_BANCOS') IS NOT NULL
-- DROP TABLE ZDEPARA_BANCOS ; 

-- SELECT DISTINCT 
--        EPG.EMP_CODIGO AS EMPRESA_DE,
-- 	   EPG.AGE_BAN_CODIGO AS CODIGO_BANCO_DE, --UTILIZAR ESSE código PARA MAPEAMENTO DO SCRIPT ZMIGRA_PFUNC
-- 	   EPG.AGE_CODIGO AS CODIGO_AGENCIA_DE, --UTILIZAR ESSE código PARA MAPEAMENTO DO SCRIPT ZMIGRA_PFUNC

-- 	   --BANCOS
-- 	   BAN.NUMERO AS NUMBANCO_DE,
-- 	   BAN.NOME AS NOME_BANCO_DE,

-- 	   --AGÊNCIAS
-- 	   AGE.NUMERO AS NUMAGENCIA_DE, 
-- 	   AGE.NOME AS NOME_AGENCIA_DE,

-- 	   --SUGESTÃO CODIGO_PARA
-- 	   	CASE WHEN BAN.NUMERO = '122' THEN '104' ELSE CAST(BAN.NUMERO AS VARCHAR(5)) END AS CODIGO_BANCO_PARA, 
		
-- 		CASE 
-- 			-- Valida se a Agencia possui até 4 caracteres e "-", assim sendo, formata o número e aplica os zeros a esquerda
-- 			WHEN LEN(AGE.NUMERO) <= 4 AND AGE.NUMERO NOT LIKE '%-%' THEN RIGHT('0000' + CAST(REPLACE(REPLACE(REPLACE(AGE.NUMERO,'-',''),' ',''),'/','') AS VARCHAR(4)), 4) 
-- 			-- Se não tiver, aplica a formatação
-- 			ELSE RIGHT('0000' + 
-- 				LEFT( 
-- 					CAST(
-- 						(LEFT(
-- 								REPLACE(REPLACE(REPLACE(AGE.NUMERO,'-',''),' ',''),'/',''),
-- 								(
-- 									LEN(REPLACE(REPLACE(REPLACE(AGE.NUMERO,'-',''),' ',''),'/','')
-- 								)-1) -- Retorna o valor sem o último caractere (Necessário para remover o "X" de alguns tipos de agência)
-- 								) * 1) -- Converte em Inteiro e remove os zeros a esquerda  
-- 					AS VARCHAR), 4
-- 				), 4 -- Pega os 4 Primeiros Dígitos
-- 			) -- Completa com até 4 Zeros
-- 		END AS CODIGO_AGENCIA_PARA,
		
-- 		CASE 
-- 			WHEN BAN.NOME LIKE '%CAIXA%' OR BAN.NOME LIKE '%CEF%' THEN '' 
-- 			WHEN LEN(REPLACE(REPLACE(REPLACE(AGE.NUMERO,'-',''),' ',''),'/','')) <= 4 THEN '' --Se AGE.NUMERO menor que ou igual a 4 dígitos, deixar vazio 
-- 			ELSE RIGHT('0' + CAST(REPLACE(RIGHT(AGE.NUMERO,1),'-','') AS VARCHAR(1)),1) 
-- 		END AS DIGITO_AGENCIA_PARA --#Ver: Banco CEF n�o possui d�gito.
  
-- INTO ZDEPARA_BANCOS
--   FROM EPG 
--   JOIN ZDEPARA_COLIGADAS 
--     ON EPG.EMP_CODIGO = ZDEPARA_COLIGADAS.CODCOLIGADA
--   JOIN BAN
-- 	ON BAN.CODIGO = EPG.AGE_BAN_CODIGO
--   JOIN AGE
--     ON AGE.BAN_CODIGO = EPG.AGE_BAN_CODIGO
--    AND AGE.CODIGO     = EPG.AGE_CODIGO
--  ORDER BY CODIGO_BANCO_DE, CODIGO_AGENCIA_DE ;

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

--SELECT * FROM ZDEPARA_BANCOS ; 

--VERIFICA��O
--BANCO > 3 POSI��ES OU AG�NCIA > 5 POSI��ES

--SELECT SUGESTAO_NUMBANCO_PARA, SUGESTAO_NUMAGENCIA_PARA FROM ZMIGRA_BANCOS WHERE LEN(SUGESTAO_NUMBANCO_PARA) > 3
--SELECT SUGESTAO_NUMBANCO_PARA, SUGESTAO_NUMAGENCIA_PARA FROM ZMIGRA_BANCOS WHERE LEN(SUGESTAO_NUMAGENCIA_PARA) > 5

--VERIFICAR códigoS DOS BANCOS
--SELECT DISTINCT BAN.NUMERO
--  FROM EPG 
--  JOIN ZDEPARA_COLIGADAS 
--    ON EPG.EMP_CODIGO = ZDEPARA_COLIGADAS.EMP_CODIGO
--  JOIN BAN
--	ON BAN.CODIGO = EPG.AGE_BAN_CODIGO
--  JOIN AGE
--    ON AGE.BAN_CODIGO = EPG.AGE_BAN_CODIGO
--   AND AGE.CODIGO     = EPG.AGE_CODIGO



--GERANDO INSERT
--EXECUTAR APENAS SE N�O HOUVER OS BANCOS CADASTRADOS



--SELECT DISTINCT 
--       NUMBANCO_DE, 
--	   NOME_BANCO_DE, 
--	   NOME_BANCO_DE, 
--	   SUGESTAO_NUMBANCO_PARA,
--       'INSERT INTO GBANCO (NUMBANCO, NOME_BANCO_DE, NOME_BANCO_DE, NUMEROOFICIAL, MASCCONTA) VALUES (''' + SUGESTAO_NUMBANCO_PARA + ''',''' + NOME_BANCO_DE + ''',''' + NOME_BANCO_DE + ''',''' + SUGESTAO_NUMBANCO_PARA + ''',''###########'' )' AS COMANDO_INSERT
--  FROM ZMIGRA_BANCOS

--SELECT DISTINCT 
--	   EMPRESA_DE,
--	   CODIGO_BANCO_DE,
--	   CODIGO_AGENCIA_DE,
--	   NUMBANCO_DE,
--	   NOME_BANCO_DE,
--	   NUMAGENCIA_DE,
--	   NOME_AGENCIA_DE,
--	   CODIGO_BANCO_PARA,
--	   CODIGO_AGENCIA_PARA,
--	   DIGITO_AGENCIA_PARA,
--	   'INSERT INTO GAGENCIA (NUMBANCO, NUMAGENCIA, DIGAG, NOME, TIPOAGENCIA) VALUES (''' + CODIGO_BANCO_PARA + ''',''' + CODIGO_AGENCIA_PARA + ''',''' + DIGITO_AGENCIA_PARA + ''',''' + UPPER(NOME_AGENCIA_DE) + ''', 1 );' AS COMANDO_INSERT
--  INTO ZDEPARA_BANCOS
--  FROM ZMIGRA_BANCOS ;

--COMANDO INSERT

--SELECT EMPRESA_DE,
--	   NUMBANCO_DE,
--	   NOME_BANCO_DE,
--	   NUMAGENCIA_DE,
--	   NOME_AGENCIA_DE,
--	   CODIGO_BANCO_PARA,
--	   CODIGO_AGENCIA_PARA
--  FROM ZDEPARA_BANCOS ;

--SELECT COMANDO_INSERT FROM ZDEPARA_BANCOS ;

--IF OBJECT_ID ('ZMIGRA_BANCOS') IS NOT NULL
--   DROP TABLE ZMIGRA_BANCOS
--GO 

--IF OBJECT_ID ('ZDEPARA_BANCOS') IS NOT NULL
--   DROP TABLE ZDEPARA_BANCOS
--GO 



--SELECT X.*,
--	   'INSERT INTO GAGENCIA (NUMBANCO, NUMAGENCIA, DIGAG, NOME, TIPOAGENCIA) VALUES (''' + BANCO_PARA + ''',''' + AGENCIA_PARA + ''',''' + DIGITO_AGENCIA_DE + ''',''' + UPPER(NOME_AGENCIA_DE) + ''', 1 )' AS COMANDO_INSERT
--  INTO ZDEPARA_BANCOS
--  FROM (
--		SELECT DISTINCT 
--			   CODIGO_DE,
--			   BANCO_DE,
--			   NOME_BANCO_DE,
--			   AGENCIA_DE,
--			   NOME_AGENCIA_DE,
--			   BANCO_PARA,
--			   AGENCIA_PARA,
--			   COALESCE(DIGITO_AGENCIA_DE,'') AS DIGITO_AGENCIA_DE,
--			   ROW_NUMBER() OVER (PARTITION BY BANCO_PARA, AGENCIA_PARA ORDER BY BANCO_PARA, AGENCIA_PARA DESC) AS ID_DUP_AGENCIA
--		  FROM ZMIGRA_BANCOS
--	) X 
--WHERE ID_DUP_AGENCIA = 1

--SELECT * 
--  FROM ZDEPARA_BANCOS
--#Ver 
--Condi��o para n�o levar BANCO 12 - MIGRA��O (Inv�lido).
--Foi informado ao cliente que esses funcion�rios foram carrregados em homologa��o sem informa��o de banco e ag�ncia.
 --WHERE CODIGO_DE <> '990' 


