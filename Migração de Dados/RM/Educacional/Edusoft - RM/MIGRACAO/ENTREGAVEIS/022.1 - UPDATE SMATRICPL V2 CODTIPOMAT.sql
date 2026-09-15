----------------------------------------------------------------------------------------------------      
-- Script:					022.1 - SCRIPT SMATRICPL
-- Última Alteração:		23/05/2025
-- Versão:					3 
-- Origem:					Sistema Sophia
-- Autor Alteração:			Pedro Andresen
----------------------------------------------------------------------------------------------------      

/* RODAR NA BASE DE DADOS DO CLIENTE O COMANDO PARA INSERIR O VALOR DO CAMPO CODTIPOMAT DA SMATRICPL */

/*MG*/
UPDATE SMATRICPL 
   SET CODTIPOMAT = 7 
  FROM 
       SMATRICPL
	   JOIN SHABILITACAOFILIAL
	     ON SHABILITACAOFILIAL.CODCOLIGADA         = SMATRICPL.CODCOLIGADA
	    AND SHABILITACAOFILIAL.IDHABILITACAOFILIAL = SMATRICPL.IDHABILITACAOFILIAL
 WHERE
       SHABILITACAOFILIAL.CODTIPOCURSO = 1 
   AND SMATRICPL.CODCOLIGADA = 14 ; 
