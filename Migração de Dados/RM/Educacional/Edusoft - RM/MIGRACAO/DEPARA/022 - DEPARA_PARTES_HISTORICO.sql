IF OBJECT_ID('ZDEPARA_PARTES_HISTORICO') IS NOT NULL
   DROP TABLE ZDEPARA_PARTES_HISTORICO;

SELECT 
      ''                                  AS CODIGO, 
      ''                                  AS QDTE,
      ''                                  AS DESCRICAO,
      ''                                  AS CODIGO_PARA,
      ''                                  AS DESCRICAO_PARA
      INTO ZDEPARA_PARTES_HISTORICO
;

SELECT * FROM ZDEPARA_PARTES_HISTORICO;
