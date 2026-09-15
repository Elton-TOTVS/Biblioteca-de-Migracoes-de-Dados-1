----------------------------------------------------------------------------------------------------      
-- Script:					ZMIGRA_PFDEPEND
-- Última Alteração:		14/08/2024     
-- Versão:					1 
-- Origem:					FORTES
-- Autor Alteração:			Rafael Stroppa
----------------------------------------------------------------------------------------------------

IF OBJECT_ID('ZMIGRA_PFDEPEND') IS NOT NULL 
   DROP TABLE ZMIGRA_PFDEPEND;

SELECT DADOS.CODCOLIGADA, --NÃO SERÁ USADO NO LAYOUT
	   
	   DADOS."Chapa do Funcionário" AS CHAPA,
       ROW_NUMBER() OVER (PARTITION BY DADOS.CODCOLIGADA, DADOS."Chapa do Funcionário" ORDER BY DADOS."Nº do Dependente") AS "Nº do Dependente",
       DADOS."Nome do Dependente",
       DADOS."CPF do Dependente",
       DADOS."Data de Nasc. Do Dependente" AS "Data de Nasc. Do Dependente",
       DADOS."Sexo do Dependente (M/F)",
       DADOS."Estado Civil do Dependente",
       DADOS."Local de Nascimento do Dependente",
       DADOS."Nome do Cartório",
       DADOS."Nº do Registro",
       DADOS."Nº do Livro de Registro",
       DADOS."Nº da Folha de Registro",
       DADOS."Incidência de IRRF (0-Não/1-Sim)",
       DADOS."Incidência de INSS (0-Não/1-Sim)",
       DADOS."Incidência de Assistência Médica (0-Não/1-Sim)",
       DADOS."Incidência de Pensão (0-Não/1-Sim)",
       DADOS."Incidências Definíveis",
       DADOS."Grau de Parentesco do Dependente",
       DADOS."Dependentes possui cartão vacina?",
       DADOS."Percentual da Pensão",
       DADOS."Tipo da Pensão",
       DADOS."Banco de pagamento pensão",
       DADOS."Agencia de pagamento da Pensão",
       DADOS."Conta de Pagamento Pensão",
       DADOS."Nome responsável",
       DADOS."Fórmula cálculo",
       DADOS."Cálculo da Pensão é sobre o bruto",
       FORMAT(CAST(DADOS."Data de entrega da certidão de nascimento" AS DATE), 'ddMMyyyy') AS "Data de entrega da certidão de nascimento",
       DADOS."Flag apresentou compr frequência escolar?",
       DADOS."Universitário/Escola técnica 2º grau",
       DADOS."Incidência Salário Família - (0-Não/ 1-Sim)",
       DADOS."Observação",
       DADOS."Fórmula Adicional Pensão",
       FORMAT(CAST(DADOS."Data de início do desconto da pensão" AS DATE), 'ddMMyyyy') AS "Data de início do desconto da pensão",
       DADOS."Coligada do fornecedor",
       DADOS."Código do fornecedor",
       DADOS."Operação Bancária",
       DADOS."Valor fixo",
       DADOS."Número do Cartão SUS",
       DADOS."Número da Declaração de Nascido Vivo",
	   FORMAT(CAST(DADOS."Data Fim do Desconto de Pensão" AS DATE), 'ddMMyyyy') AS "Data Fim do Desconto de Pensão",
	   DADOS."Informa se o dependente do beneficiário é pessoa com Doença Incapacitante (eSocial Órgão Público)",
	   DADOS."Descrição do parâmetro Outros da tela de dependente",
	   DADOS."Dependente possui Retenção FGTS",
	   DADOS."Incidência de Assistência Odontológica (0-Não/1-Sim)",
	   NULL AS CAMPOEXTRA
  INTO ZMIGRA_PFDEPEND
  FROM (
SELECT ZDEPARA_PFUNC.CODCOLIGADA,
       ZDEPARA_PFUNC.CHAPA AS "Chapa do Funcionário",
       CAST(DEP.SEQ AS INT) AS "Nº do Dependente",
       DEP.NOME AS "Nome do Dependente",
       CASE WHEN ROW_NUMBER() OVER(PARTITION BY CODCOLIGADA, CHAPA, DEP.CPF ORDER BY CODCOLIGADA) > 1 THEN NULL
	        ELSE CASE WHEN DEP.CPF = '' THEN NULL ELSE DEP.CPF END
		END AS "CPF do Dependente",
	   REPLACE(CONVERT(VARCHAR,DEP.NASCDATA,103),'/','') AS "Data de Nasc. Do Dependente",
       CASE WHEN DEP.SEXO = '' THEN 'M' 
			WHEN DEP.SEXO IS NULL THEN 'M' 
			ELSE DEP.SEXO
		END AS "Sexo do Dependente (M/F)",
       CASE WHEN DEP.TB_TIP_DEP_CODIGO IN ('01','02') THEN 'C' ELSE 'S' END AS "Estado Civil do Dependente",
       NASCIMENTO.NOME AS "Local de Nascimento do Dependente",
       CASE WHEN SUBSTRING(DEP.CERTIDAOCARTORIO,1,40) = '' THEN NULL ELSE SUBSTRING(REPLACE(DEP.CERTIDAOCARTORIO,';',''),1,40) END AS "Nome do Cartório",
       CASE WHEN SUBSTRING(REPLACE(DEP.CERTIDAONUMERO,'.',''),1,10) = '' THEN NULL ELSE SUBSTRING(REPLACE(DEP.CERTIDAONUMERO,'.',''),1,10) END AS "Nº do Registro",
       CASE WHEN SUBSTRING(REPLACE(DEP.CERTIDAOLIVRO,' ',''),1,8) = '' THEN NULL ELSE SUBSTRING(REPLACE(DEP.CERTIDAOLIVRO,' ',''),1,8) END AS "Nº do Livro de Registro",
       CASE WHEN SUBSTRING(REPLACE(DEP.CERTIDAOFOLHA,' ',''),1,5) = '' THEN NULL ELSE SUBSTRING(REPLACE(DEP.CERTIDAOFOLHA,' ',''),1,5) END AS "Nº da Folha de Registro",
       CASE WHEN DEP.TB_TIP_DEP_CODIGO IN ('01', '09') AND DEPENDDTFINAL IS NULL THEN 1 
			WHEN DEP.TB_TIP_DEP_CODIGO IN ('03','04','10','11') AND GETDATE() <= DEPENDDTFINAL THEN 1
			ELSE 0 END AS "Incidência de IRRF (0-Não/1-Sim)",
       0 AS "Incidência de INSS (0-Não/1-Sim)",
       0 AS "Incidência de Assistência Médica (0-Não/1-Sim)",
       0 AS "Incidência de Pensão (0-Não/1-Sim)",
       NULL AS "Incidências Definíveis",
       CASE WHEN DEP.TB_TIP_DEP_CODIGO = '01' THEN '5' --Cônjuge
            WHEN DEP.TB_TIP_DEP_CODIGO = '02' THEN 'C' --Companheiro(a) com o(a) qual tenha filho ou viva há mais de 5 (cinco) anos ou possua Declaração de União Estável
            WHEN DEP.TB_TIP_DEP_CODIGO = '03' THEN '1' --Filho(a) ou enteado(a)
            WHEN DEP.TB_TIP_DEP_CODIGO = '04' THEN '1' --Filho(a) ou enteado(a), universitário(a) ou cursando escola técnica de 2º grau
            WHEN DEP.TB_TIP_DEP_CODIGO = '06' THEN 'I' --Irmão(ã), neto(a) ou bisneto(a) sem arrimo dos pais, do(a) qual detenha a guarda judicial
            WHEN DEP.TB_TIP_DEP_CODIGO = '09' THEN 'A' --Pais, avós e bisavós
            WHEN DEP.TB_TIP_DEP_CODIGO = '10' THEN 'M' --Menor pobre do qual detenha a guarda judicial
            WHEN DEP.TB_TIP_DEP_CODIGO = '11' THEN 'B' --A pessoa absolutamente incapaz, da qual seja tutor ou curador
            WHEN DEP.TB_TIP_DEP_CODIGO = '12' THEN 'G' --Ex-cônjuge
            WHEN DEP.TB_TIP_DEP_CODIGO = '99' THEN '9' --Agregado/Outros
            WHEN DEP.TB_TIP_DEP_CODIGO = '07' THEN 'I' --Irmão(ã), neto(a) ou bisneto(a) sem arrimo dos pais, universitário(a) ou cursando escola técnica de 2º grau, do(a) qual detenha a guarda judicial
		    ELSE '9' END AS "Grau de Parentesco do Dependente",
       CASE WHEN DEP.SALARIOFAMILIA = 'S' AND GETDATE() <= SALARIOFAMILIADTFINAL THEN 1 ELSE 0 END AS "Dependentes possui cartão vacina?",
       NULL AS "Percentual da Pensão",
       NULL AS "Tipo da Pensão",
       NULL AS "Banco de pagamento pensão",
       NULL AS "Agencia de pagamento da Pensão",
       NULL AS "Conta de Pagamento Pensão",
       NULL AS "Nome responsável",
       NULL AS "Fórmula cálculo",
       NULL AS "Cálculo da Pensão é sobre o bruto",
       NULL AS "Data de entrega da certidão de nascimento",
       CASE WHEN DEP.SALARIOFAMILIA = 'S' AND CAST(GETDATE() AS DATE) <= CAST(SALARIOFAMILIADTFINAL AS DATE) THEN 1 ELSE 0 END AS "Flag apresentou compr frequência escolar?",
       CASE WHEN DEP.TB_TIP_DEP_CODIGO = '04' THEN 1 ELSE 0 END AS "Universitário/Escola técnica 2º grau",
       0 AS "Incidência Salário Família - (0-Não/ 1-Sim)",
       NULL AS "Observação",
       NULL AS "Fórmula Adicional Pensão",
       NULL AS "Data de início do desconto da pensão",
       NULL AS "Coligada do fornecedor",
       NULL AS "Código do fornecedor",
       NULL AS "Operação Bancária",
       NULL AS "Valor fixo",
       NULL AS "Número do Cartão SUS",
       NULL AS "Número da Declaração de Nascido Vivo",
	   NULL AS "Data Fim do Desconto de Pensão",
	   NULL AS "Informa se o dependente do beneficiário é pessoa com Doença Incapacitante (eSocial Órgão Público)",
	   NULL AS "Descrição do parâmetro Outros da tela de dependente",
	   NULL AS "Dependente possui Retenção FGTS",
	   0 AS "Incidência de Assistência Odontológica (0-Não/1-Sim)"
  FROM DEP
       INNER JOIN ZDEPARA_PFUNC
               ON ZDEPARA_PFUNC.EMP_CODIGO = DEP.EMP_CODIGO
              AND ZDEPARA_PFUNC.EPG_CODIGO = DEP.EPG_CODIGO
	   LEFT  JOIN MUN AS NASCIMENTO
	           ON NASCIMENTO.UFD_SIGLA = DEP.MUN_UFD_SIGLA_NASC
			  AND NASCIMENTO.CODIGO    = DEP.MUN_CODIGO_NASC
   
   		UNION 
		--MAE
	   (SELECT ZDEPARA_PFUNC.CODCOLIGADA,
			   ZDEPARA_PFUNC.CHAPA AS "Chapa do Funcionário",
			   CASE 
					WHEN MAX_NRODEPEND.NRO_DEPENDENTES IS NULL THEN 1
					ELSE CAST(MAX_NRODEPEND.NRO_DEPENDENTES AS INT) + 1
			   END AS "Nº do Dependente",
			   EPG.MAENOME AS "Nome do Dependente",
			   NULL AS "CPF do Dependente",
			   NULL  AS "Data de Nasc. Do Dependente",
			   'F' AS "Sexo do Dependente (M/F)",
			   'O' AS "Estado Civil do Dependente",
				NULL AS "LOCAL DE NASCIMENTO DO DEPENDENTE",
				NULL AS "Nome do Cartório",
				NULL AS "Nº do Registro",
				NULL AS "Nº do Livro de Registro",
				NULL AS "Nº da Folha de Registro",
				0 AS "Incidência de IRRF (0-Não/1-Sim)",
				0 AS "Incidência de INSS (0-Não/1-Sim)",
				0 AS "Incidência de Assistência Médica (0-Não/1-Sim)",
				0 AS "Incidência de Pensão (0-Não/1-Sim)",
				NULL AS "Incidências Definíveis",
				'7' AS "Grau de Parentesco do Dependente",
				0 AS "Dependentes possui cartão vacina?",
				NULL AS "Percentual da Pensão",
				NULL AS "Tipo da Pensão",
				NULL AS "Banco de pagamento pensão",
				NULL AS "Agencia de pagamento da Pensão",
				NULL AS "Conta de Pagamento Pensão",
				NULL AS "Nome responsável",
				NULL AS "Fórmula cálculo",
				NULL AS "Cálculo da Pensão é sobre o bruto",
				NULL AS "Data de entrega da certidão de nascimento",
				NULL AS "Flag apresentou compr frequência escolar?",
				NULL AS "Universitário/Escola técnica 2º grau",
				0 AS "Incidência Salário Família - (0-Não/ 1-Sim)",
				NULL AS "Observação",
				NULL AS "Fórmula Adicional Pensão",
				NULL AS "Data de início do desconto da pensão",
				NULL AS "Coligada do fornecedor",
				NULL AS "Código do fornecedor",
				NULL AS "Operação Bancária",
				NULL AS "Valor fixo",
				NULL AS "Número do Cartão SUS",
				NULL AS "Número da Declaração de Nascido Vivo",
				NULL AS "Data Fim do Desconto de Pensão",
				NULL AS "Informa se o dependente do beneficiário é pessoa com Doença Incapacitante (eSocial Órgão Público)",
				NULL AS "Descrição do parâmetro Outros da tela de dependente",
				NULL AS "Dependente possui Retenção FGTS",
				0 AS "Incidência de Assistência Odontológica (0-Não/1-Sim)"
		FROM EPG
				INNER JOIN ZDEPARA_PFUNC
				        ON ZDEPARA_PFUNC.EMP_CODIGO = EPG.EMP_CODIGO
					   AND ZDEPARA_PFUNC.EPG_CODIGO = EPG.CODIGO
				LEFT JOIN (
					SELECT DEP.EMP_CODIGO, 
						   DEP.EPG_CODIGO, 
						   MAX(DEP.SEQ) AS NRO_DEPENDENTES
					FROM DEP
					GROUP BY EMP_CODIGO, EPG_CODIGO
				) MAX_NRODEPEND
					ON MAX_NRODEPEND.EMP_CODIGO = EPG.EMP_CODIGO
				   AND MAX_NRODEPEND.EPG_CODIGO = EPG.CODIGO
			  WHERE NOT EXISTS (SELECT 1
					  FROM DEP
				 WHERE DEP.EMP_CODIGO = EPG.EMP_CODIGO
				AND DEP.EPG_CODIGO = EPG.CODIGO
				AND DEP.TB_TIP_DEP_CODIGO = 'A')
				AND EPG.MAENOME <> '')

		UNION 
		--PAI
	   (SELECT ZDEPARA_PFUNC.CODCOLIGADA,
			   ZDEPARA_PFUNC.CHAPA AS "Chapa do Funcionário",
			   CASE 
					WHEN MAX_NRODEPEND.NRO_DEPENDENTES IS NULL THEN 2
					ELSE CAST(MAX_NRODEPEND.NRO_DEPENDENTES AS INT) + 2
			   END AS "Nº do Dependente",
			   EPG.PAINOME AS "Nome do Dependente",
			   NULL AS "CPF do Dependente",
			   NULL  AS "Data de Nasc. Do Dependente",
			   'M' AS "Sexo do Dependente (M/F)",
			   'O' AS "Estado Civil do Dependente",
				NULL AS "LOCAL DE NASCIMENTO DO DEPENDENTE",
				NULL AS "Nome do Cartório",
				NULL AS "Nº do Registro",
				NULL AS "Nº do Livro de Registro",
				NULL AS "Nº da Folha de Registro",
				0 AS "Incidência de IRRF (0-Não/1-Sim)",
				0 AS "Incidência de INSS (0-Não/1-Sim)",
				0 AS "Incidência de Assistência Médica (0-Não/1-Sim)",
				0 AS "Incidência de Pensão (0-Não/1-Sim)",
				NULL AS "Incidências Definíveis",
				'6' AS "Grau de Parentesco do Dependente",
				0 AS "Dependentes possui cartão vacina?",
				NULL AS "Percentual da Pensão",
				NULL AS "Tipo da Pensão",
				NULL AS "Banco de pagamento pensão",
				NULL AS "Agencia de pagamento da Pensão",
				NULL AS "Conta de Pagamento Pensão",
				NULL AS "Nome responsável",
				NULL AS "Fórmula cálculo",
				NULL AS "Cálculo da Pensão é sobre o bruto",
				NULL AS "Data de entrega da certidão de nascimento",
				NULL AS "Flag apresentou compr frequência escolar?",
				NULL AS "Universitário/Escola técnica 2º grau",
				0 AS "Incidência Salário Família - (0-Não/ 1-Sim)",
				NULL AS "Observação",
				NULL AS "Fórmula Adicional Pensão",
				NULL AS "Data de início do desconto da pensão",
				NULL AS "Coligada do fornecedor",
				NULL AS "Código do fornecedor",
				NULL AS "Operação Bancária",
				NULL AS "Valor fixo",
				NULL AS "Número do Cartão SUS",
				NULL AS "Número da Declaração de Nascido Vivo",
				NULL AS "Data Fim do Desconto de Pensão",
				NULL AS "Informa se o dependente do beneficiário é pessoa com Doença Incapacitante (eSocial Órgão Público)",
				NULL AS "Descrição do parâmetro Outros da tela de dependente",
				NULL AS "Dependente possui Retenção FGTS",
				0 AS "Incidência de Assistência Odontológica (0-Não/1-Sim)"
		FROM EPG
				INNER JOIN ZDEPARA_PFUNC
				        ON ZDEPARA_PFUNC.EMP_CODIGO = EPG.EMP_CODIGO
					   AND ZDEPARA_PFUNC.EPG_CODIGO = EPG.CODIGO
				LEFT JOIN (
					SELECT DEP.EMP_CODIGO, 
						   DEP.EPG_CODIGO, 
						   MAX(DEP.SEQ) AS NRO_DEPENDENTES
					FROM DEP
					GROUP BY EMP_CODIGO, EPG_CODIGO
				) MAX_NRODEPEND
					ON MAX_NRODEPEND.EMP_CODIGO = EPG.EMP_CODIGO
				   AND MAX_NRODEPEND.EPG_CODIGO = EPG.CODIGO
			  WHERE NOT EXISTS (SELECT 1
					  FROM DEP
				 WHERE DEP.EMP_CODIGO = EPG.EMP_CODIGO
				AND DEP.EPG_CODIGO = EPG.CODIGO
				AND DEP.TB_TIP_DEP_CODIGO = 'A')
				AND EPG.PAINOME <> '')
   
   ) DADOS 
