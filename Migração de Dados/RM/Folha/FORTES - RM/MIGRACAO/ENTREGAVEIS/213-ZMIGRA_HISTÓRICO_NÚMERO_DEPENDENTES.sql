----------------------------------------------------------------------------------------------------      
-- Script:					ZMIGRA_PFHSTNDEP
-- Última Alteração:		14/08/2024     
-- Versão:					1 
-- Origem:					FORTES
-- Autor Alteração:			Rafael Stroppa
----------------------------------------------------------------------------------------------------

IF OBJECT_ID('ZMIGRA_PFHSTNDEP') IS NOT NULL 
   DROP TABLE ZMIGRA_PFHSTNDEP;

WITH NUMEROS (N) AS   
(  
 SELECT 0 AS N 
 UNION ALL  
 SELECT N + 1 
   FROM NUMEROS 
  WHERE N < 100  
)  

SELECT DISTINCT   
       DADOS.CODCOLIGADA, --NÃO SERÁ USADO NO LAYOUT 

	   DADOS.CHAPA,
       REPLACE(CONVERT(VARCHAR,DADOS.DATAMUDANCA,103),'/','') + ' 00:00:00' AS "Data de mudança (ddmmaaaa hh:mm:ss)",  
       DADOS.IRRF AS "Número de dep. que incidem no IRRF",  
       DADOS.SALFAM AS "Número de dependentes de salário família"  
  INTO ZMIGRA_PFHSTNDEP
  FROM (  
        SELECT ZDEPARA_PFUNC.CODCOLIGADA,  
               ZDEPARA_PFUNC.CHAPA,  
               ZDEPARA_PFUNC.NOME,  
               ZDEPARA_PFUNC.DATAADMISSAO,  
               ZDEPARA_PFUNC.DATADEMISSAO,  
               (SELECT MAX(FOL.DTCALCULO)  
                  FROM EFO   
                       INNER JOIN FOL   
                               ON FOL.EMP_CODIGO = EFO.EMP_CODIGO  
                              AND FOL.SEQ        = EFO.FOL_SEQ  
                 WHERE EFO.EMP_CODIGO = ZDEPARA_PFUNC.EMP_CODIGO   
                   AND EFO.EPG_CODIGO = ZDEPARA_PFUNC.EPG_CODIGO  
                   AND FOL.Folha      = 2  
                   AND SUBSTRING(CONVERT(VARCHAR,FOL.DTCALCULO,120),1,7) <= SUBSTRING(CONVERT(VARCHAR,DATEADD(MONTH,NUMEROS.N,ZDEPARA_PFUNC.DATAADMISSAO),120),1,7)) AS DATAMUDANCA,
               DATEADD(MONTH,NUMEROS.N,ZDEPARA_PFUNC.DATAADMISSAO) AS DATALIMITE,  
               (SELECT COUNT(*)  
                  FROM DEP   
                 WHERE DEP.EMP_Codigo = ZDEPARA_PFUNC.EMP_CODIGO  
                   AND DEP.EPG_Codigo = ZDEPARA_PFUNC.EPG_CODIGO  
                   AND DEP.TB_TIP_DEP_CODIGO = '03'  
                   AND (   ISNULL(DEPENDDTINICIAL,'2099-01-01') <> ISNULL(DEPENDDTFINAL,'2099-01-01')  
                        OR ISNULL(SALARIOFAMILIADTINICIAL,'2099-01-01') <> ISNULL(SALARIOFAMILIADTFINAL,'2099-01-01'))  
                   --AND FLOOR(DATEDIFF(DAY,DEP.NascData,DATEADD(MONTH,NUMEROS.N,ZDEPARA_PFUNC.DATAADMISSAO)) / 365.20) <= 14  
                   AND DATEADD(MONTH,NUMEROS.N,ZDEPARA_PFUNC.DATAADMISSAO) BETWEEN DEP.SALARIOFAMILIADTINICIAL AND DEP.SALARIOFAMILIADTFINAL) AS IRRF,  
               (SELECT COUNT(*)  
                  FROM DEP   
                 WHERE DEP.EMP_Codigo = ZDEPARA_PFUNC.EMP_CODIGO  
                   AND DEP.EPG_Codigo = ZDEPARA_PFUNC.EPG_CODIGO  
                   AND DEP.TB_TIP_DEP_CODIGO = '03'  
                   AND (   ISNULL(DEPENDDTINICIAL,'2099-01-01') <> ISNULL(DEPENDDTFINAL,'2099-01-01')  
                        OR ISNULL(SALARIOFAMILIADTINICIAL,'2099-01-01') <> ISNULL(SALARIOFAMILIADTFINAL,'2099-01-01'))  
                   AND DATEADD(MONTH,NUMEROS.N,ZDEPARA_PFUNC.DATAADMISSAO) BETWEEN DEP.SALARIOFAMILIADTINICIAL AND DEP.SALARIOFAMILIADTFINAL) AS SALFAM  
             FROM NUMEROS  
                  INNER JOIN ZDEPARA_PFUNC   
                          ON SUBSTRING(CONVERT(VARCHAR,DATEADD(MONTH,NUMEROS.N,ZDEPARA_PFUNC.DATAADMISSAO),120),1,7) BETWEEN SUBSTRING(CONVERT(VARCHAR,ZDEPARA_PFUNC.DATAADMISSAO,120),1,7)  
                                                                                                                         AND SUBSTRING(CONVERT(VARCHAR,ISNULL(ZDEPARA_PFUNC.DATADEMISSAO,CONVERT(DATE,GETDATE())),120),1,7)  
            WHERE ZDEPARA_PFUNC.CODSITUACAO<>'D'			
               ) DADOS  
  WHERE DADOS.DATAMUDANCA IS NOT NULL  