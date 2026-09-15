IF OBJECT_ID('ZDEPARA_GRUPO_OCORRENCIA') IS NOT NULL
  DROP TABLE ZDEPARA_GRUPO_OCORRENCIA ; 

SELECT DISTINCT
      TOX_ID                                    AS CODIGO,
      TOX_ID                                    AS COD_EXT,
      CAST(TOX_DESCRI AS VARCHAR(MAX))          AS DESCICAO,
      1                                         AS NOTIFICAR,
      1                                         AS FREQUENCIA,
      0                                         AS INTERNA,
      ''                                        AS CODIGO_PARA,
      ''                                        AS DESCRICAO_PARA
      INTO ZDEPARA_GRUPO_OCORRENCIA
  FROM 
      TB_TIPO_OCORRENCIA;

SELECT * FROM ZDEPARA_GRUPO_OCORRENCIA ORDER BY 1;