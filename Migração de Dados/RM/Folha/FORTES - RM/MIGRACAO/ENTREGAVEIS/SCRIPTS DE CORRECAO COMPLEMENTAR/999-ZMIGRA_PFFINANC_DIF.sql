--MIGRA AS LINHAS DE PFFINANC COM DATA DE PAGAMENTO MAIOR QUE COMPETENCIA

IF OBJECT_ID('ZMIGRA_PFFINANC_DIF') IS NOT NULL
    DROP TABLE ZMIGRA_PFFINANC_DIF
;

SELECT 
    * ,
    FORMAT(EOMONTH(DATEFROMPARTS([Ano de Competência], [Mês de Competência], 1)), 'ddMMyyyy') AS DTPAGTOFIMMES,
    'UPDATE PFFINANC '
    + 'SET DTPAGTO = '
    + 'TO_DATE(''' + CAST(STUFF(STUFF([Data de Pagamento],3,0,'/'),6,0,'/') AS VARCHAR) + ''', ''DD/MM/YYYY'')' +
    + ' WHERE'
    + ' CODCOLIGADA = ' + CODCOLIGADA + ' AND' +
    + ' CHAPA = ' + '''' + CHAPA + '''' + ' AND' +
    + ' ANOCOMP = ' + CAST([Ano de Competência] AS VARCHAR) + ' AND' +
    + ' MESCOMP = ' + CAST([Mês de Competência] AS VARCHAR) + ' AND' +
    + ' NROPERIODO = ' + CAST([Número do Período] AS VARCHAR) + ' AND' +
    + ' CODEVENTO = ''' + [Código do Evento] + '''; '
    AS UPDATE_DTPAGTO
    INTO ZMIGRA_PFFINANC_DIF
FROM ZMIGRA_PFFINANC 
WHERE SUBSTRING([Data de Pagamento], 3, 2) <> [Mês de Competência]

SELECT * FROM ZMIGRA_PFFINANC_DIF;