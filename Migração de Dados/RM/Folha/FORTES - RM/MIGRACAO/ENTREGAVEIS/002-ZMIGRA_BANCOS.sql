----------------------------------------------------------------------------------------------------      
-- Script:					ZDEPARA_BANCOS
-- �ltima Altera��o:		20/08/2025     
-- Vers�o:					1 
-- Origem:					FORTES
-- Autor Altera��o:			Jos� Melo
----------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------
-- SCRIPT PARA INSERT ---------------------------------------------------
-------------------------------------------------------------------------

IF OBJECT_ID('ZMIGRA_BANCOS') IS NOT NULL
	DROP TABLE ZMIGRA_BANCOS;

SELECT DISTINCT 
	   CODIGO_BANCO_PARA,
	   CODIGO_AGENCIA_PARA,
	   'INSERT INTO GAGENCIA (NUMBANCO, NUMAGENCIA, DIGAG, NOME, TIPOAGENCIA) VALUES (''' + CODIGO_BANCO_PARA + ''',''' + CODIGO_AGENCIA_PARA + ''',''' + ISNULL(DIGITO_AGENCIA_PARA,'') + ''',''' + UPPER(CODIGO_AGENCIA_PARA) + ''', 1 );' AS COMANDO_INSERT
  INTO ZMIGRA_BANCOS
  FROM ZDEPARA_BANCO
  WHERE CODIGO_AGENCIA_PARA IS NOT NULL
    AND CODIGO_AGENCIA_PARA NOT LIKE '0000'
	  AND CODIGO_BANCO_PARA NOT LIKE '005'
  ORDER BY CODIGO_BANCO_PARA,
            CODIGO_AGENCIA_PARA;

SELECT * FROM ZMIGRA_BANCOS

--   SELECT
--   	   CODIGO_BANCO_PARA,
-- 	   CODIGO_AGENCIA_PARA,
--   COUNT(*) FROM ZMIGRA_BANCOS
--   GROUP BY CODIGO_BANCO_PARA,
-- 	   CODIGO_AGENCIA_PARA;
