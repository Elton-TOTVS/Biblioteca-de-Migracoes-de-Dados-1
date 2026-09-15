----------------------------------------------------------------------------------------------------      
-- Script:					ZMIGRA_PFUNC
-- Última Alteração:		14/08/2024     
-- Versão:					1 
-- Origem:					FORTES
-- Autor Alteração:			Rafael Stroppa
----------------------------------------------------------------------------------------------------

IF OBJECT_ID('ZMIGRA_PFUNC') IS NOT NULL 
   DROP TABLE ZMIGRA_PFUNC;

SELECT DISTINCT
       ZDEPARA_PFUNC.CODCOLIGADA, --NÃO SERÁ USADO NO LAYOUT
	   
	   ZDEPARA_PFUNC.CHAPA, 

       SUBSTRING(LTRIM(RTRIM(EPG.NOME)),1,120) AS NOME,  
       SUBSTRING(LTRIM(RTRIM(EPG.NOME)),1,CHARINDEX(' ',LTRIM(RTRIM(EPG.NOME))) - 1) AS Apelido,  
       FORMAT(CAST(EPG.DTNASCIMENTO AS DATE), 'ddMMyyyy') AS "Data de Nascimento",  
       CASE WHEN EPG.ESTADOCIVIL = '01' THEN 'S' -- SOLTEIRO
            WHEN EPG.ESTADOCIVIL = '02' THEN 'C' -- CASADO (COMUNHAO UNIVERSAL)
            WHEN EPG.ESTADOCIVIL = '03' THEN 'C' -- CASADO (COMUNHAO PARCIAL)
            WHEN EPG.ESTADOCIVIL = '04' THEN 'C' -- CASADO (SEPARACAO)
            WHEN EPG.ESTADOCIVIL = '05' THEN 'V' -- VIUVO
            WHEN EPG.ESTADOCIVIL = '06' THEN 'O' -- OUTROS
            WHEN EPG.ESTADOCIVIL = '07' THEN 'I' -- DIVORCIADO
			WHEN EPG.ESTADOCIVIL = '08' THEN 'C' -- CASADO (REGIME TOTAL)
			WHEN EPG.ESTADOCIVIL = '09' THEN 'O' -- OUTROS
            WHEN EPG.ESTADOCIVIL = '10' THEN 'E' -- UNIAO ESTAVEL
		END AS "Estado Civil",   
       EPG.SEXO AS "Sexo (M F)",    
	   CASE WHEN EPG.PAISNACIONALIDADE = '105' THEN '10' 
	        WHEN EPG.PAISNACIONALIDADE = '199' THEN '052' 
			WHEN EPG.PAISNACIONALIDADE = '474' THEN '207' 
		END AS Nacionalidade,  --#EPG.NACIONALIDADE
       CASE WHEN EPG.GRAUINSTRUCAO = '01' THEN '1' -- ANALFABETO
            WHEN EPG.GRAUINSTRUCAO = '02' THEN '2' -- ATÉ O QUINTO ANO INCOMPLETO
            WHEN EPG.GRAUINSTRUCAO = '03' THEN '3' -- 5º COMPLETO FUNDAMENTAL
            WHEN EPG.GRAUINSTRUCAO = '04' THEN '4' -- DO 6º AO 9º ANO 
            WHEN EPG.GRAUINSTRUCAO = '05' THEN '5' -- ENSINO FUNDAMENTAL COMPLETO
            WHEN EPG.GRAUINSTRUCAO = '06' THEN '6' -- ENSINO MEDIO INCOMPLETO
            WHEN EPG.GRAUINSTRUCAO = '07' THEN '7' -- ENSINO MEDIO COMPLETO
            WHEN EPG.GRAUINSTRUCAO = '08' THEN '8' -- SUPERIOR INCOMPLETO
            WHEN EPG.GRAUINSTRUCAO = '09' THEN '9' -- SUPERIOR COMPLETO
            WHEN EPG.GRAUINSTRUCAO = '10' THEN 'B' -- PÓS-GRADUACAO COMPLETA
			WHEN EPG.GRAUINSTRUCAO = '11' THEN 'D' -- MESTRADO COMPLETO
			WHEN EPG.GRAUINSTRUCAO = '12' THEN 'F' -- DOUTORADO COMPLETO
			ELSE '5'
        END AS "Grau de Instrução",    
       CASE WHEN EPG.ENDLOGRADOURO = '' THEN NULL 
	        WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'AL ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'AL ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'ALAMEDA ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'ALAMEDA ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'AV ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'AV ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'AVENIDA ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'AVENIDA ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'Estrada ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'Estrada ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'Lagoa ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'Lagoa ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'LG ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'LG ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'Passeio ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'Passeio ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'PCA ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'PCA ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'Praça ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'Praça ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'R ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'R ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'RUA ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'RUA ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'SITIO ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'SITIO ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'St ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'St ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'TR ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'TR ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'TRAVESA ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'TRAVESA ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'TRAVESSA ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'TRAVESSA ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'VALE ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'VALE ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'VIA ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'VIA ' ,'')
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'VILA ' THEN REPLACE(REPLACE(EPG.ENDLOGRADOURO,';','-'),'VILA ' ,'')
	        ELSE REPLACE(EPG.ENDLOGRADOURO,';','-') 
		END AS Rua,
       CASE WHEN EPG.ENDNUMERO = '' THEN NULL ELSE SUBSTRING(EPG.ENDNUMERO,1,8) END AS Número,    
       CASE WHEN EPG.ENDCOMPLEMENTO = '' THEN NULL ELSE REPLACE(EPG.ENDCOMPLEMENTO,';','-') END AS Complemento,    
       CASE WHEN EPG.BAIRRO = '' THEN NULL ELSE SUBSTRING(EPG.BAIRRO,1,30) END AS Bairro,    
       ISNULL(EPG.MUN_UFD_SIGLA,'CE') AS "Unidade da Federação",    
       ISNULL(ENDERECO.NOME,'NÃO INFORMADO') AS Cidade,    
	   CASE WHEN EPG.CEP = '' THEN NULL ELSE EPG.CEP END AS CEP,    
       CASE WHEN EPG.PAISNACIONALIDADE = '105' THEN 'Brasil' 
	        WHEN EPG.PAISNACIONALIDADE = '199' THEN 'Cuba' 
			WHEN EPG.PAISNACIONALIDADE = '474' THEN 'Marrocos' 
		END AS "Nome do País",   --#EPG.PAISNASCIMENTO    EPG.PAISNACIONALIDADE
       NULL AS "Registro Profissional",  
	   REPLACE(REPLACE(REPLACE(EPG.CPF,'.',''),'-',''),'/','') AS CPF,
	   CASE WHEN EPG.FONE = '' THEN NULL ELSE ISNULL(EPG.DDD,'') + LTRIM(RTRIM(EPG.FONE)) END AS "Telefone 1", 
       CASE WHEN EPG.CELULAR = '' THEN NULL ELSE ISNULL(EPG.DDD,'') + LTRIM(RTRIM(EPG.CELULAR)) END AS "Telefone 2", 
       CASE WHEN EPG.IDENTIDADENUMERO <> '' THEN EPG.IDENTIDADENUMERO END AS "Nº da Carteira de Identidade",   
       CASE WHEN EPG.MUN_UFD_SIGLA_IDENTORGAOEXPED <> '' THEN EPG.MUN_UFD_SIGLA_IDENTORGAOEXPED END AS "UF - Carteira de Identidade",    
       CASE WHEN EPG.IDENTIDADEORGAOEXPEDIDOR <> '' THEN EPG.IDENTIDADEORGAOEXPEDIDOR END AS "Órgão Emissor - Carteira de Identidade",  
       FORMAT(CAST(EPG.IDENTIDADEDTEXPEDICAO AS DATE), 'ddMMyyyy') AS "Data de Emissão - Carteira de Identidade",    
       FORMAT(CAST(EPG.DTVALIDADERG AS DATE), 'ddMMyyyy') AS "Data de Vencimento- Carteira de Identidade",      
       CASE WHEN EPG.TITULO = '' THEN NULL ELSE EPG.TITULO END AS "Título de Eleitor",    
       CASE WHEN EPG.ZONA = '' THEN NULL ELSE EPG.ZONA END AS "Zona de Votação",    
       CASE WHEN EPG.SECAO = '' THEN NULL ELSE EPG.SECAO END AS "Seção de Votacão",    
	   RIGHT('0000000000' + ISNULL(EPG.CTPSNUMERO,'') + ISNULL(EPG.CTPSDV,''),10) AS "Nº da Carteira de Trabalho",  --# Ajustado 14.12.2022       
	   CASE WHEN EPG.CTPSSERIE <> '' THEN EPG.CTPSSERIE END AS "Série - Carteira de Trabalho",    
       EPG.UFD_SIGLA_CTPS AS "UF - Carteira de Trabalho",   
       FORMAT(CAST(EPG.CTPSDTEXPEDICAO AS DATE), 'ddMMyyyy') AS "Data da emissão - Carteira de Trabalho",    
       FORMAT(CAST(EPG.DTVALIDADECTPS AS DATE), 'ddMMyyyy') AS "Data de Vencimento - Carteira de Trabalho",    
       0 AS "NIT - Tipo de Carteira de Trabalho (0-Não 1-Sim)",  
       CASE WHEN EPG.HABILITACAONUMERO <> '' THEN EPG.HABILITACAONUMERO END AS "Nº da Carteira de Motorista",    
       CASE WHEN EPG.HABILITACAOCATEGORIA <> '' THEN EPG.HABILITACAOCATEGORIA END AS "Tipo da Carteira de Habilitação",    
       FORMAT(CAST(EPG.HABILITACAOVENCIMENTO AS DATE), 'ddMMyyyy') AS "Data de Venc. Da Habilitação",    
       NULL AS "Nº do Certificado Reservista",    
       NULL AS "Categoria Militar",    
       ISNULL(NATURALIDADE.NOME,'NÃO INFORMADO') AS "NATURALIDADE",    
	   ISNULL(EPG.MUN_UFD_SIGLA_NATURALIDADE,'--') AS "ESTADO NATAL",    
	   NULL AS "Data da Chegada ao Brasil",    
       NULL AS "Carta Modelo 19",    
       ISNULL(EPG.ESTRANGEIROCASADOBR,0) AS "Cônjuge Brasil (0-Não 1-Sim)",    
       0 AS "Naturalizado (0-Não 1-Sim)",    
       ISNULL(EPG.ESTRANGEIROFILHOSBR,0) AS "Filhos no Brasil (0-Não 1-Sim)",   
       0 AS "Nº de Filhos no Brasil",    
       NULL AS "Nº do Registro Geral",    
       NULL AS "Nº do Decreto",    
       NULL AS "Tipo de Visto",    
       REPLACE(CASE WHEN LOWER(EPG.EMAIL) NOT LIKE '%@%' THEN NULL ELSE LTRIM(RTRIM(LOWER(EPG.EMAIL))) END,';','') AS "E-Mail",    
       NULL AS "Senha",    

	   --#Verificar: Não pode gerar automático e enviar parte da informação (TUDO ou NADA)
	   ---------------------------------------------------------------------------------------------
	   NULL AS "Nº da Ficha de Registro", --CASE WHEN ZDEPARA_PFUNC.REGISTRONUMERO = '' THEN NULL ELSE REPLACE(ZDEPARA_PFUNC.REGISTRONUMERO,'''','') END ,  --#Ver
	   ---------------------------------------------------------------------------------------------
	   CASE WHEN CAST(REPLACE(ZDEPARA_PFUNC.SALARIO,',','.') AS NUMERIC(15,2)) <= 50 THEN 'H' ELSE 'M' END AS "Código de Recebimento", --#   
	   ZDEPARA_PFUNC.CODSITUACAO AS "Código de Situação",   --#
       ZDEPARA_PFUNC.CODTIPO AS "Código do Tipo do Funcionário",  

	   --#Verificar
	   ---------------------------------------------------------------------------------------------
	   ZDEPARA_SECOES.CODIGO_PARA AS "Código da Seção",   --#
       ZDEPARA_FUNCOES.CODIGO_PARA "Código da Função",   
       ISNULL(ZDEPARA_SINDICATOS.CODIGO_PARA,'99') AS "Código do Sindicato",
	   CASE WHEN ZDEPARA_PFUNC.HORASMES = '22500' THEN '220:00' --#Ver
		    WHEN RIGHT('000' + REPLACE(CAST(CAST(REPLACE(ZDEPARA_PFUNC.HORASMES,',','.') AS NUMERIC(5,2)) AS VARCHAR(20)),'.',':'),6) = '000:00' THEN '000:01'
	        WHEN RIGHT('000' + REPLACE(CAST(CAST(REPLACE(ZDEPARA_PFUNC.HORASMES,',','.') AS NUMERIC(5,2)) AS VARCHAR(20)),'.',':'),6) > '546:07' THEN '220:00'
	        ELSE RIGHT('000' + REPLACE(CAST(CAST(REPLACE(ZDEPARA_PFUNC.HORASMES,',','.') AS NUMERIC(5,2)) AS VARCHAR(20)),'.',':'),6) 
	    END AS "Jornada (Formato HHH MM)",
	   ZDEPARA_HORARIOS.CODIGO_PARA AS "Código do Horário", --Será realizada a carga com o código 0001 e posteriormente ajustado no RM na implantação do ponto
	   ---------------------------------------------------------------------------------------------
	   
	   ISNULL((SELECT COUNT(*)  
                 FROM DEP
				WHERE DEP.EMP_CODIGO = SEP.EMP_CODIGO
				  AND DEP.EPG_CODIGO = SEP.EPG_CODIGO
				  AND DATEDIFF(DAY,CAST(DEP.NASCDATA AS DATE), CAST(GETDATE() AS DATE)) / 365.20 < 18), 0) AS "Número de Dependentes de IRRF",    
       ISNULL((SELECT COUNT(*)  
                 FROM DEP
				WHERE DEP.EMP_CODIGO = SEP.EMP_CODIGO
				  AND DEP.EPG_CODIGO = SEP.EPG_CODIGO
				  AND DEP.SALARIOFAMILIA = 'S'), 0) AS "Número de Dependentes de Salário Família",   
       FORMAT(CAST(ZDEPARA_PFUNC.DATAADMISSAO AS DATE), 'ddMMyyyy') AS "Data Base",   
	   CASE WHEN CAST(REPLACE(ZDEPARA_PFUNC.SALARIO,',','.') AS NUMERIC(15,2)) <= 10 
	        THEN REPLACE(CAST(CAST(CAST(REPLACE(ZDEPARA_PFUNC.SALARIO,',','.') AS NUMERIC(15,2)) * ZDEPARA_PFUNC.HORASMES AS NUMERIC(15,2)) AS VARCHAR(20)),'.',',')
	        ELSE ZDEPARA_PFUNC.SALARIO 
		END AS "Salário (Formato 999999999999,99)",  
       CASE WHEN ZDEPARA_PFUNC.CODTIPO IN ('A','D','T') THEN 2 ELSE 1 END AS "Situação de FGTS (1-Optante   2-Não Optante)",  --#  
       FORMAT(CAST(ZDEPARA_PFUNC.DATAADMISSAO AS DATE), 'ddMMyyyy') AS "Data de Opção de FGTS",    
       NULL AS "Número da Conta de FGTS",    
       REPLACE(CAST(CAST(REPLACE(ZDEPARA_PFUNC.SALDO_FGTS,',','.') AS NUMERIC(15,2)) AS VARCHAR(20)),'.',',') AS "Saldo do FGTS no Banco (Formato 999999999999,99)",    
       NULL AS "Data do Saldo do FGTS",  
       EPG.PIS AS "PIS/PASEP",  --#  
       NULL AS "Data de Cadastro do PIS",  --#  
       NULL AS "Cód. Banco do PIS",   
	   'X' AS "Contribuição Sindical (J-Já Descontou/L-Liberal/N-Não Desc.)",    
	   CASE WHEN EPG.DTAPOSENTADORIA IS NULL THEN 0 ELSE 1 END AS "Aposentado (0-Não 1-Sim)",    
       '0' AS "Tem Mais de 65 Anos (0-Não 1-Sim)",    
       '0,00' AS "Ajuda de Custo (Formato 999999999999,99)",    
       '0,00' AS "Percentual de Adiantamento (Formato 999,99)",    
       '0,00' AS "Arredondamento (Formato 99999,99)",    
       FORMAT(CAST(ZDEPARA_PFUNC.DATAADMISSAO AS DATE), 'ddMMyyyy') AS "Data de Admissão",    
       CASE WHEN EPG.ADMISSAOTIPO = '00' THEN 'P' -- PRIMEIRO EMPREGO
	        WHEN EPG.ADMISSAOTIPO = '10' THEN 'P' -- PRIMEIRO EMPREGO
			WHEN EPG.ADMISSAOTIPO = '20' THEN 'R' -- REEMPREGO
			WHEN EPG.ADMISSAOTIPO = '35' AND EPG.MATRICULAESOCIAL IS NOT NULL THEN 'I' -- REINTEGRAÇÃO
			WHEN EPG.ADMISSAOTIPO = '40' AND EPG.DTTRANSFERENCIA IS NOT NULL THEN 'T' -- TRANSFERENCIA SEM ONUS
			WHEN EPG.ADMISSAOTIPO = '40' AND EPG.DTTRANSFERENCIA IS NULL THEN 'O' -- TRANSFERENCIA SEM ONUS
			ELSE 'O'
        END AS "Tipo de Admissão", --# TIPOADMISSAO 
       FORMAT(CAST(EPG.DTTRANSFERENCIA AS DATE), 'ddMMyyyy') AS "Data da Transferência",	   
       '01' AS "Motivo da Admissão",  --# 99-implantação  /* REFINAR NO FUTURO */
       CASE WHEN SEP.DTTERMINOPRAZO IS NOT NULL AND SEP.DTTERMINOPRAZO > '1900-01-01' THEN 1 ELSE 0 END AS "Contrato tem Prazo Determinado (0-Não 1-Sim)", --#   
       CASE WHEN SEP.DTTERMINOPRAZO IS NOT NULL AND SEP.DTTERMINOPRAZO > '1900-01-01' THEN FORMAT(CAST(SEP.DTTERMINOPRAZO AS DATE), 'ddMMyyyy') END AS "Fim do Prazo do Contrato",   
       FORMAT(CAST(ZDEPARA_PFUNC.DATADEMISSAO AS DATE), 'ddMMyyyy') AS "Data de Demissão",    
       ZDEPARA_PFUNC.TIPO_DEMISSAO AS "Tipo de Demissão",  --#  
       ZDEPARA_PFUNC.MOTIVO_DEMISSAO AS "Motivo de Demissão",  --#                                 
       FORMAT(CAST(ZDEPARA_PFUNC.DATADEMISSAO AS DATE), 'ddMMyyyy') AS "Data de Desligamento",    
       FORMAT(CAST(ZDEPARA_PFUNC.DATA_PGTO_RESCISAO AS DATE), 'ddMMyyyy') AS "Data da Última Movimentação",    
       FORMAT(CAST(ZDEPARA_PFUNC.DATA_PGTO_RESCISAO AS DATE), 'ddMMyyyy') AS "Data de Pagamento da Rescisão",    
	   CASE  
	       WHEN ZDEPARA_PFUNC.TIPO_DEMISSAO = '1' THEN '00'
		   WHEN ZDEPARA_PFUNC.TIPO_DEMISSAO = '2' THEN '01'
		   WHEN ZDEPARA_PFUNC.TIPO_DEMISSAO = '3' THEN '00'
		   WHEN ZDEPARA_PFUNC.TIPO_DEMISSAO = '4' THEN '00'
		   WHEN ZDEPARA_PFUNC.TIPO_DEMISSAO = '5' THEN '00'
		   WHEN ZDEPARA_PFUNC.TIPO_DEMISSAO = '6' THEN '00'
		   WHEN ZDEPARA_PFUNC.TIPO_DEMISSAO = '8' THEN '23'
		   WHEN ZDEPARA_PFUNC.TIPO_DEMISSAO = '9' THEN '00'
		   WHEN ZDEPARA_PFUNC.TIPO_DEMISSAO = 'A' THEN '05'
		   WHEN ZDEPARA_PFUNC.TIPO_DEMISSAO = 'I' THEN '05'
		   WHEN ZDEPARA_PFUNC.TIPO_DEMISSAO = 'J' THEN '05'
		   WHEN ZDEPARA_PFUNC.TIPO_DEMISSAO = 'F' THEN '23'
		   WHEN ZDEPARA_PFUNC.TIPO_DEMISSAO = 'G' THEN '02'
		   WHEN ZDEPARA_PFUNC.TIPO_DEMISSAO = 'N' THEN '01'
		   WHEN ZDEPARA_PFUNC.TIPO_DEMISSAO = 'V' THEN '07'
		   WHEN ZDEPARA_PFUNC.TIPO_DEMISSAO = 'T' THEN '04'		    
	    END AS "Código de Saque de FGTS",    
       CASE WHEN AVISO.EPG_CODIGO IS NULL THEN 0 ELSE 1 END AS "Tem Aviso Prévio (0-Não 1-Sim)",    
       FORMAT(CAST(ZDEPARA_PFUNC.DATAAVISO AS DATE), 'ddMMyyyy') AS "Data do Aviso Prévio",    
       ZDEPARA_PFUNC.DIASAVISO AS "Número de Dias de Aviso",    
       NULL AS "Data de Venc. De Férias",  --inicioperiodoaquisitivoferias  
       NULL AS "Início de Programação de Férias 1",    
       NULL AS "Fim de Programação de Férias 1",    
       0 AS "Quer Abono (0-Não 1-Sim)",    
       0 AS "Quer 1ª Parcela de 13º (0-Não 1-Sim)",    
       NULL AS "Nº de dias de Adiantamento de Férias",    
       NULL AS "Evento de Adiantamento de Férias",    
       0 AS "Férias Coletivas Globais (0-Não 1-Sim)",    
       '0,00' AS "Nº de dias de Férias (Formato 9999,99, onde 1º dígito é sinal. Se for positivo, 1º dígito é 0)",    
       '0,00' AS "Nº de dias de Abono (Formato 999,99)",    
       '0,00' AS "Saldo de Férias (Formato 999,99)",    
       '0,00' AS "Saldo de Férias Anterior (Formato 999,99)",    
       '0,00' AS "Saldo de Férias Auxiliar (Formato 999,99)",    
       NULL AS "Observação de Férias",    
       NULL AS "Data de Pagamento de Férias",    
       NULL AS "Data de Aviso de Férias",    
       '0,00' AS "Nº de Dias Licença Remunerada 1 (Formato 999,99)",    
       '0,00' AS "Nº de Dias Licença Remunerada 2 (Formato 999,99)",    
       NULL AS "Data de Início da Licença",    
       '0,00' AS "Média Salário Maternidade (Formato 999999999999,99)",    
       CASE WHEN ZDEPARA_PFUNC.CODTIPO = 'D' THEN 'N' --DIRETOR  
            WHEN ZDEPARA_PFUNC.CODTIPO = 'N' THEN '1' --EMPREGADO  
            WHEN ZDEPARA_PFUNC.CODTIPO = 'A' THEN 'N' --AUTONOMO  
            WHEN ZDEPARA_PFUNC.CODTIPO = 'T' THEN 'N' --ESTAGIARIO  
            WHEN ZDEPARA_PFUNC.CODTIPO = 'Z' THEN '1' --APRENDIZ  
            ELSE '1'  
        END AS "Situação RAIS", 
		
	   --#Verificar	
	   ---------------------------------------------------------------------------------------------
	   CASE WHEN (ZDEPARA_PFUNC.CONTACORRENTENUMERO IS NOT NULL OR ZDEPARA_PFUNC.CONTACORRENTENUMERO <> '') THEN ZDEPARA_BANCO.CODIGO_BANCO_PARA END AS "Cód  Banco de Pagamento",    
	   CASE WHEN (ZDEPARA_PFUNC.CONTACORRENTENUMERO IS NOT NULL OR ZDEPARA_PFUNC.CONTACORRENTENUMERO <> '') THEN ZDEPARA_BANCO.CODIGO_AGENCIA_PARA END AS "Cód  Agência Pagamento", 
	   CASE WHEN (ZDEPARA_PFUNC.AGE_BAN_CODIGO IS NOT NULL OR ZDEPARA_PFUNC.AGE_CODIGO IS NOT NULL) THEN ZDEPARA_PFUNC.CONTACORRENTENUMERO END AS "Conta de Pagamento",
       ---------------------------------------------------------------------------------------------

       '0' AS "Membro Sindical (0-Não 1-Sim)",    
       CASE WHEN ZDEPARA_PFUNC.CODTIPO = 'D' THEN NULL --DIRETOR  
            WHEN ZDEPARA_PFUNC.CODTIPO = 'N' THEN '1'  --EMPREGADO  
            WHEN ZDEPARA_PFUNC.CODTIPO = 'A' THEN '9'  --AUTONOMO  
            WHEN ZDEPARA_PFUNC.CODTIPO = 'T' THEN '3'  --ESTAGIARIO: ESTAGIÁRIO SERÁ NULL (Informação: Analista Denis)
            WHEN ZDEPARA_PFUNC.CODTIPO = 'Z' THEN '0'  --APRENDIZ  
            ELSE '1'  
        END AS "Vínculo RAIS",    
       0 AS "Usa Vale Transporte (0-Não 1-Sim)",    
       NULL AS "Dias Úteis no Mês",    
       NULL AS "Dias Úteis Meio Expediente",    
       NULL AS "Dias Úteis Próximo Mês",    
       NULL AS "Dias Úteis Próximo Mês Meio Expediente",    
       NULL AS "Dias Úteis Restantes",    
       NULL AS "Dias Úteis Restantes Meio",    
       0 AS "Mudou Endereço (0-Não 1-Sim)",    
       0 AS "Mudou Carteira de Trabalho (0-Não 1-Sim)",    
       NULL AS "Antiga Carteira de Trabalho",    
       NULL AS "Antiga Série - Carteira de Trabalho",    
       0 AS "Mudou Nome (0-Não 1-Sim)",    
       NULL AS "Antigo Nome",    
       0 AS "Mudou PIS (0-Não 1-Sim)",    
       NULL AS "Antigo PIS",    
       0 AS "Mudou Chapa (0-Não 1-Sim)",    
       NULL AS "Antiga Chapa",  --#  
       0 AS "Mudou Data de Admissão (0-Não 1-Sim)",    
       NULL AS "Antiga Data de Admissão",    
       NULL AS "Antigo Vínculo",    
       NULL AS "Antigo Tipo do Funcionário",    
       NULL AS "Antigo Tipo de Admissão",    
       0 AS "Mudou Data de Opção (0-Não 1-Sim)",    
       NULL AS "Antiga Data de Opção",    
       0 AS "Mudou Seção (0-Não 1-Sim)",    
       NULL AS "Antiga Seção",    
       0 AS "Mudou Data de Nascimento (0-Não 1-Sim)",    
       NULL AS "Antiga Data de Nascimento",    
       0 AS "Falta Alterar FGTS (0-Não 1-Sim)",    
       0 AS "Deduzir IRRF Mais 65 (0-Não 1-Sim)",    
       NULL AS "PIS para FGTS",    
       NULL AS "Cód. Banco de FGTS",    
       NULL AS "0",    
	   CAST(ZDEPARA_SECOES.FILIAL_PARA AS INT) AS "Código identificador da filial", --#  
       1 AS "Índice de Início de Horário",    
       0 AS "Usa Salário Composto (0-Não 1-Sim)",    
       CASE WHEN EPG.CIPA = 'S' THEN 1 ELSE 0 END AS "Funcionário é membro da CIPA (0-Não 1-Sim)",    
       NULL AS "Operação bancária1",    
       NULL AS "Nro vezes para desconto do empréstimo de férias",    
       NULL AS "Data de início para desconto do empréstimo de férias",    
       NULL AS "Grupo Salarial",    
       1 AS "Funcionário é o atual? (0-Não 1-Sim)",    
       NULL AS "BRANCO",   
       NULL AS "Código da Ocorrência",           
	   CASE WHEN ZDEPARA_PFUNC.CODTIPO = 'D' THEN 11 --DIRETOR  
            WHEN ZDEPARA_PFUNC.CODTIPO = 'N' THEN 1  --EMPREGADO  
            WHEN ZDEPARA_PFUNC.CODTIPO = 'A' THEN 13 --AUTONOMO  
            WHEN ZDEPARA_PFUNC.CODTIPO = 'T' THEN NULL --ESTAGIARIO: ESTAGIÁRIO SERÁ NULL (Informação: Analista Denis)
            WHEN ZDEPARA_PFUNC.CODTIPO = 'Z' THEN 7  --APRENDIZ  
            ELSE 1  
        END AS "Código da Categoria",    
       NULL AS "Classe de contribuição para o INSS",    
       NULL AS "Código da equipe do funcionário",    
       0 AS "Funcionário tem status de supervisor? (0-Não 1-Sim) ",    
       NULL AS "Integração Contábil",    
       NULL AS "Integração Gerencial",    
       0 AS "Usa Controle de Saldo de Verbas? (0-Não 1-Sim)",    
       CASE WHEN ZDEPARA_PFUNC.CODTIPO = 'D' THEN EPG.PIS ELSE NULL END AS "Código Contribuinte Individual",  
       0 AS "Mudou Código Contribuinte Individual (0-Não 1-Sim)",    
       NULL AS "Antigo Código Contribuinte Individual",    
       CASE WHEN ZDEPARA_PFUNC.DATADEMISSAO IS NOT NULL AND YEAR(ZDEPARA_PFUNC.DATADEMISSAO) > 1900 THEN 2 END AS "Período de Rescisão",    
       CASE WHEN EPG.RACACOR = 1 THEN 8 ELSE ISNULL(EPG.RACACOR,8) END AS "Cor / Raça ( 0 Indígena - 2 Branca - 4 Preta - 6 Amarela - 8 Parda)",  --#
       ISNULL(CASE WHEN EPG.DEFICIENTEFISICO IS NOT NULL THEN EPG.DEFICIENTEFISICO ELSE 0 END ,0) AS "Flag Deficiente físico?",   
       0 AS "FGTS mês anterior será recolhido na GRFC (0-Não 1-Sim)",    
       NULL AS "Código do Nível da Tabela Salarial",    
       NULL AS "Número de Dias de Férias para a Jornada Reduzida",    
       2 AS "Tem alvará judicial p/func menor 16 anos (1-Sim 2-Não)",                       
       CASE WHEN ZDEPARA_PFUNC.CODTIPO = 'T' THEN 0 ELSE 1 END AS "Situação do INSS",    
       REPLACE(CONVERT(VARCHAR,EPG.DTAPOSENTADORIA,103),'/','') AS "Data de aposentadoria",    
       0 AS "Quer adiantamento nas férias (0-Não 1-Sim)",    
       NULL AS "Data próximo período aquisitivo de férias",    
       NULL AS "Coligada do fornecedor",    
       NULL AS "Código do fornecedor",    
       EPG.DEFICIENCIAAUDITIVA AS "Deficiente Auditivo",    
       EPG.TEMDEFICIENCIA AS "Deficiente Fala",    
       EPG.DEFICIENCIAMENTAL AS "Deficiente Mental",    
       EPG.DEFICIENCIAVISUAL AS "Deficiente Visual",   
       EPG.MUN_CODIGO AS "Código Município", 
       NULL AS "Localidade",    
       0 AS "Posição Abono (0-Não 1-Sim)",    
       NULL AS "Nº de Dias de Férias Corridos",    
       NULL AS "País de Origem",    
       0 AS "Fumante (0-Não 1-Sim)",    
       NULL AS "N.Passaporte",    
       NULL AS "Telefone 3",    
       NULL AS "Data de Emissão do Passaporte",    
       NULL AS "Data validade do Passaporte",    
       NULL AS "Tipo de Aposentadoria (1-Tempo Serv./2-Idade/3-Especial)",    
       'N' AS "Reposição de Vaga (N-Não S-Sim)",    
       REPLACE(CAST(CAST(ZDEPARA_PFUNC.SALDO_FGTS AS NUMERIC(15,2)) AS VARCHAR(20)),'.',',') AS "Saldo de FGTS Real",  
       0 AS "BR-PDH (0-Não Aplicável/1-BR/2-PDH)",    
       NULL AS "Carregou Dados do Aviso Prévio",    
       CASE WHEN ZDEPARA_PFUNC.CODTIPO = 'T' THEN 0 ELSE 1 END AS "Situação IRRF (0-Não Calcula  1-Calcula)",    
       NULL AS "Código da coligada origem",    
       NULL AS "Chapa Origem",    
       NULL AS "Férias finalizadas para o próximo mês",    
       NULL AS "Número do Cartão SUS",    
       NULL AS "Tipo de redução do aviso: dias ou jornada",    
       NULL AS "Forma de redução do aviso: inicio ou fim",    
       NULL AS "Indicador de Contribuição Substituída",      
       NULL AS "Tipo de conta bancária1",      
       NULL AS "Preencher com o número do processo judicial",    
       NULL AS "Indicar se a residência pertence ao trabalhador",    
       NULL AS "Indicar se foi adquirido o imóvel próprio foi adquirido com recursos do FGTS",    
       '1' AS "Tipo de regime previdenciário",    
       '1' AS "Indicativo de Admissão",    
       NULL AS "Tipo da Reintegração",    
       NULL AS "Data da Reintegração",    
       NULL AS "Data do Efetivo Retorno ao Trabalho",    
       NULL AS "Número da Lei de Anistia",    
       NULL AS "Número do Processo Judicial",   
       CASE WHEN SEP.NATUREZAESTAGIO = 'O' THEN 'O'  
            WHEN SEP.NATUREZAESTAGIO = 'N' THEN 'N'  
        END AS "Natureza do Estágio",    
       CASE WHEN SEP.NIVELESTAGIO IN ('2','3') THEN 2  
            WHEN SEP.NIVELESTAGIO = '4' THEN 4  
        END AS "Nível do Estágio",      
       CASE WHEN LEN(SEP.AREAESTAGIO) > 3 THEN SEP.AREAESTAGIO END AS "Área de Atuação do Estagiário",      
       CASE WHEN COALESCE(SEP.NUMEROAPOLICE,'') = '' THEN NULL ELSE SEP.NUMEROAPOLICE END AS "Nr  apólice de seguro",      
       REPLACE(CONVERT(VARCHAR,SEP.DTTERMINOESTAGIO,103),'/','') AS "Data Prevista para o Término do Estágio",      
       NULL /*ZDEPARA_INSTITUICAO.CODIGO_PARA*/ AS "Código da Instituição de Ensino",  --###    
       NULL /*ZDEPARA_AGENTE_INTEGRACAO.CODIGO_PARA*/ AS "Código do Agente de Integração",  --###  
       CASE WHEN COALESCE(SEP.CPFSUPERVISORESTAGIO,'') = '' THEN NULL 
		    WHEN SEP.CPFSUPERVISORESTAGIO = '00000000000' THEN NULL 
	        ELSE SEP.CPFSUPERVISORESTAGIO END AS "CPF do Coordenador do Estágio",  
	   CASE WHEN COALESCE(SEP.NOMESUPERVISORESTAGIO,'') = '' THEN NULL ELSE SEP.NOMESUPERVISORESTAGIO END AS "Nome do Coordenador do Estágio",   
       CASE WHEN ZDEPARA_PFUNC.CNPJEMPREGADORANTERIOR = '' THEN NULL ELSE ZDEPARA_PFUNC.CNPJEMPREGADORANTERIOR END AS "CNPJ empressa anterior",    /* REFINAR CAMPO NO FUTURO */
       NULL AS "Data de Admissão do Dirigente Sindical na Empresa de Origem",    
       NULL AS "Matrícula do Trabalhador na Empresa de Origem",    
       NULL AS "Código Correspondente à Categoria de Origem do Dirigente Sindical",    
       NULL AS "Motivo de Contratação do Trabalhador Temporário",    
       NULL AS "Chapa do ex-funcionario que o trabalhador temporário esta substituindo",    
       NULL AS "Motivo cancelamento do Aviso Prévio",    
       NULL AS "Data do cancelamento do aviso prévio visando",    
       NULL AS "Número que identifica o registro do Atestado de Óbito",    
       NULL AS "Número que identifica o processo trabalhista",    
	   CASE WHEN AVISO.EPG_CODIGO IS NOT NULL THEN 'Aviso compreendido entre ' + CONVERT(VARCHAR,AVISO.DTAVISO,103) + ' a ' + CONVERT(VARCHAR,AVISO.DTTERMINO,103) END  AS "Observação sobre o desligamento do trabalhador",    
       CASE WHEN AVISO.OBS = '' THEN NULL ELSE REPLACE(REPLACE(AVISO.OBS, CHAR(13), ''),CHAR(10),'') END AS "Observação do aviso prévio",    
       NULL AS "Descrição do Salário Variável",    
       NULL AS "Observação cancelamento Aviso Prévio",    
       NULL AS "Indicativo sucessão de vínculo",    
       NULL AS "CNPJ da Empresa de Origem do Dirigente Sindical",    
       CASE WHEN ZDEPARA_PFUNC.MATRICULAANTERIOR = '' THEN NULL ELSE ZDEPARA_PFUNC.MATRICULAANTERIOR END AS "Matrícula anterior",    /* REFINAR NO FUTURO */
       CASE WHEN ZDEPARA_PFUNC.CNPJEMPREGADORANTERIOR LIKE '%[0-9]%' THEN REPLACE(CONVERT(VARCHAR,ZDEPARA_PFUNC.DATAADMISSAO,103),'/','') END  AS "Data início do vínculo",    
       NULL AS "Observação da sucessão",    
       NULL AS "Transferência por sucessão",    
       NULL AS "Data do aviso trabalhado quando aviso misto",    
       NULL AS "Indicativo de aviso misto",    
       NULL AS "Considera periodo de férias com dias úteis",    
       '0,00' AS "Saldo de férias para o periodo com dias úteis",    
       NULL AS "ID dados do residente",    
       0 AS "Estava Recebendo Seguro Desemp. Na Admissão (0-Não 1-Sim)",    
       NULL AS "Número sequêncial para transferências",    
       NULL AS "Banco de Pagamento",    
       NULL AS "Agência Banco Pagamento",    
       NULL AS "Conta Pagamento",    
       NULL AS "Operação bancária",    
       NULL AS "Tipo de conta bancária",    
       NULL AS "Indicativo de 2Pagamento em Juizo",    
       NULL AS "DIRF - Informar remuneração no Cód. da Receita 3533",    
       NULL AS "Data do desligamento feito antes da reintegração",  
       CASE WHEN EPG.MATRICULAESOCIAL = '' THEN NULL ELSE EPG.MATRICULAESOCIAL END AS "Matrícula do trabalhador no eSocial",    
	   NULL AS "Motivo da transferência",    /* REFINAR NO FUTURO */ 
       NULL AS "Código do Centro de Custo",    
       NULL AS "Identificador do Item Contábil",    
       NULL AS "Identificador da Classe de Valor",    
       NULL AS "Anos de Contribuição para INSS PPE",    
       NULL AS "Órgão Origem / Destino",    
       NULL AS "Cod Tp Regime Jurídico",    
       1 AS "Tipo de Regime da Jornada",    
       ZDEPARA_PFUNC.DESCONTA_AVISO_PREV AS "Desconta Aviso Prévio (0-Não 1-Sim)",  /*- DENIS:  NÃO PODE SER 0 ZERO PARA TODOS , DEPENDE DO TIPO DE DEMISSÃO */                
       NULL AS "Identificador da Pessoa",    
       CASE WHEN ZDEPARA_PFUNC.DATADEMISSAO IS NOT NULL THEN 1 END AS "Flag Rescisão Calculada",    
       NULL AS "Previsão de disponibilidade (Este campo deverá ficar em branco pois o mesmo não é mais utilizado",    
       NULL AS "Código do Grupo de Quiosque",    
       NULL AS "Data de Vencimento do Documento de Identidade",    
       CASE WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'AL ' THEN '4'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'ALAMEDA ' THEN '4'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'AV ' THEN '6'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'AVENIDA ' THEN '6'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'Estrada ' THEN '18'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'Lagoa ' THEN '25'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'LG ' THEN '24'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'Passeio ' THEN '33'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'PCA ' THEN '30'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'Praça ' THEN '30'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'R ' THEN '1'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'RUA ' THEN '1'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'SITIO ' THEN '37'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'St ' THEN '37'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'TR ' THEN '39'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'TRAVESA ' THEN '39'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'TRAVESSA ' THEN '39'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'VALE ' THEN '40'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'VIA ' THEN '43'
            WHEN SUBSTRING(EPG.ENDLOGRADOURO, 1, CHARINDEX(' ',EPG.ENDLOGRADOURO)) = 'VILA ' THEN '44'
            ELSE '1' 
		END AS "Tipo da Rua",    
       1 AS "Tipo do Bairro",   
       ISNULL(EPG.MUN_CODIGO_NATURALIDADE, EPG.MUN_CODIGO) AS "Código do Municipio Naturalidade",  --#  
	   NULL AS "Número do registro único de cadastro",    
       NULL AS "Orgão emissor do registro único de cadastro",    
       NULL AS "Data de emissão do registro único de cadastro1",    
       NULL AS "Data de emissão do registro único de cadastro2",    
       CASE WHEN EPG.HABILITACAONUMERO IS NOT NULL AND EPG.HABILITACAONUMERO <> '' THEN 'DETRAN' END AS "Orgão emissor da carteira habilitação",    
       NULL AS "Data de naturalização do estrangeiro no brasil",    
       NULL AS "Orgão emissor do registro nacional de estrangeiros",    
       NULL AS "Data de emissão do registro nacional de estrangeiros",    
	   CASE WHEN EPG.NOMESOCIAL <> '' THEN EPG.NOMESOCIAL END AS "Nome Social",    
       NULL AS "Código do País de Endereço",    
       NULL AS "Deficiente intelectual",    
       NULL AS "Observação deficiência",    
       NULL AS "Data do Óbito",    
       NULL AS "Matrícula da Certidão de Óbito",    
	   CASE WHEN EPG.DTFALECIMENTO IS NOT NULL AND EPG.DTFALECIMENTO <= '1900-01-01' THEN 0 ELSE 1 END AS "Falecido",    
       NULL AS "Portaria de Naturalização",    
       NULL AS "Classificação do Trabalhador Estrangeiro",    
       NULL AS "UF de Eemissão da Carteira de Motorista",    
       NULL AS "Data da Primeira Carteira de Motorista",    
       NULL AS "Ano do Primeiro Emprego PPE",    
       NULL AS "E-Mail pessoal",    
       NULL AS "Identificador da Imagem",    
       '0,00' AS "Investimento em Treinamentos Anteriores",    
       NULL AS "Fax",    
       NULL AS "Código da Profissão",    
       NULL AS "Código da Ocupação",    
       CASE WHEN EPG.CMNUMERO = '' THEN NULL  
            WHEN EPG.CMNUMERO IS NOT NULL AND LEN(EPG.CMNUMERO) > 10 THEN 'CSM: ' + EPG.CMNUMERO  
        END AS "Observações da pessoa",      
       CASE WHEN RIGHT(EPG.CMNUMERO,10) <> '' THEN RIGHT(EPG.CMNUMERO,10) END AS "Circunscrição do Serviço Militar",    
       NULL AS "Data de Emissão do Certificado Militar",    
       NULL AS "Órgão Expedidor do Certificado Militar",    
       NULL AS "Região Militar",    
       NULL AS "Situação Militar",    
       NULL AS "Data de emissão do Título de Eleitoral",    
       NULL AS "Uf do Título Eleitoral",    
       NULL AS "Tipo Sanguíneo",    
       NULL AS "Fiador no Totvs Incorporação1",    
       NULL AS "Fiador no Totvs Incorporação2",    
       NULL AS "Deficiente Mobilidade Reduzida",    
       '0' AS "Contrato trabalho em regime tempo Parcial",    
       NULL AS "Preenche Cota de PCD",    
       NULL AS "Coligada Tomador Temporário",    
       NULL AS "Código tomador temporário",    
       NULL AS "Justificativa contrato temporário",    
       NULL AS "Tipo inclusão contrato",    
       NULL AS "CNPJ empresa sucessora",    
       NULL AS "Justificativa prorrogação contrato temporário",    
       NULL AS "Data demissão Prevista",    
       NULL AS "Data Aviso prévio Trabalhado",    
       CASE WHEN EPG.CLAUSULAASSECURATORIA = 'S' THEN 2    
            WHEN EPG.CLAUSULAASSECURATORIA = 'N' THEN 3    
        END AS "Contém cláusula Asseguratória",      
       NULL AS "CPF do Trabalhador Substituído",      
       NULL AS "Tipo Inscrição Trabalhador Substituído",      
       NULL AS "Número Inscrição Trabalhador Substituído",      
       CASE WHEN ZDEPARA_PFUNC.TIPOAVISO = 'I' THEN 1 ELSE 0 END AS "Tipo de Aviso Prévio",      
       SEP.CATEGORIAESOCIAL AS "Código Categoria eSocial",   
	   0 AS "Código do Tipo de Contrato", --ESTAGIARIO: ESTAGIÁRIO SERÁ NULL (Informação: Analista Denis)    
	   
	   --#Verificar
	   ---------------------------------------------------------------------------------------------
       REPLACE(CONVERT(VARCHAR,ZDEPARA_PFUNC.HST_SAL,103),'/','') AS "Data da Mudança de Salário",    
       ZDEPARA_PFUNC.MOTIVO_SAL AS "Motivo da Mudança de Salário",
	   REPLACE(CONVERT(VARCHAR,HST_FCO,103),'/','') AS "Data da Mudança de Função",   
       ZDEPARA_PFUNC.MOTIVO_FCO AS "Motivo da Mudança de Função",
	   REPLACE(CONVERT(VARCHAR,ZDEPARA_PFUNC.HST_SIT,103),'/','') AS "Data da Mudança de Situação",    
       ZDEPARA_PFUNC.MOTIVO_SIT AS "Motivo da Mudança de Situação",    
	   REPLACE(CONVERT(VARCHAR,ZDEPARA_PFUNC.HST_SEC,103),'/','') AS "Data da Mudança de Seção",    
       ZDEPARA_PFUNC.MOTIVO_SEC AS "Motivo da Mudança de Seção",    
       REPLACE(CONVERT(VARCHAR,ZDEPARA_PFUNC.DATAADMISSAO,103),'/','') AS "Data da Mudança de Horário",    
       REPLACE(CONVERT(VARCHAR,ZDEPARA_PFUNC.DATAADMISSAO,103),'/','') AS "Data da Mudança das Informações SEFIP",    
       REPLACE(CONVERT(VARCHAR,ZDEPARA_PFUNC.DATAADMISSAO,103),'/','') AS "Data da Mudança da Contribuição Sindical",    
       REPLACE(CONVERT(VARCHAR,ZDEPARA_PFUNC.DATAADMISSAO,103),'/','') AS "Data da Mudança dos Dados Bancários",    
       REPLACE(CONVERT(VARCHAR,ZDEPARA_PFUNC.DATAADMISSAO,103),'/','') AS "Data da Mudança dos Dados Bancários Alternativo", 
	   ---------------------------------------------------------------------------------------------
	   
       NULL AS "Indicativo de função de confiança/cargo em comissão",    
       NULL AS "Código da função de confiança/cargo em comissão",    
       1 AS "Natureza da Atividade eSocial",   /* 1-Urbano 2-Rural*/
	   NULL AS "Data Mudança do Indicador de Contribuição Substituída",  
       NULL AS "Demissão por Desempenho Insuficiente ou Inadaptação",    
       NULL AS "Prefixo Período para o eSocial",    
       NULL AS "Data final da quarentena",    
       NULL AS "Tipo de contrato do prazo determinado",    
       NULL AS "Motivo da contratação por prazo determinado",    
       CASE WHEN SEP.DTTERMINOPRAZO IS NOT NULL AND SEP.DTTERMINOPRAZO > '1900-01-01' THEN 'E' END AS "Tipo do Contrato com prazo",     
       NULL AS "Preencher",    
       NULL AS "Tipo Adesão do B.E.M",  
       NULL AS "Data da Mudança do B.E.M",  
       NULL AS "Data do Acordo do B.E.M",  
       NULL AS "Percentual do B.E.M",  
       NULL AS "Duração do Acordo do B.E.M",  
       NULL AS "Valor Reduzido do B.E.M",  
       NULL AS "Data de Cancelamento do BEM",  
       NULL AS "Data de Antecipação do BEM",  
       NULL AS "Dias de prorrogação do BEM",  
	   NULL AS "Não calcula recibo de férias",	
       NULL AS "Data Prorrogação BEM",	
       NULL AS "CNPJ Empresa contratante Aprendiz",	
       NULL AS "NRO Processo Trabalhista ",	
       NULL AS "Tipo de regime previdenciario ",	
       NULL AS "Tipo de Registro trabalhista",	
       NULL AS "Prazo de residência indeterminado",
       NULL AS "Categoria de origen do trabalhador ",
       NULL AS "CNPJ da empresa cedente ",
       NULL AS "Data admissão do trabalhador no empregador de origem (Cedente)",
       NULL AS "Ônus da cessão/requisição",
       NULL AS "Matricula do trabalhador no mepregador de origem(cedente)",
       NULL AS "Tipo de regime previdenciário  do trabalhador cedido",	
       NULL AS "Tipo de regime trabalhista  do trabalhador cedido ",
       NULL AS "Beneficiário",
       NULL AS "Informa se o beneficiário é pessoa com doença incapacitante",	
       NULL AS "CNPJ do responsável pela matrícula do servidor/militar",	
       NULL AS "Data do reconhecimento da incapacidade",
       NULL AS "Data de inicio do cadastro do beneficiário",	
       NULL AS "Matrícula do beneficiário",	
       NULL AS "Função/Emprego/Cargo Acumulável",
       NULL AS "Tipo de provimento estatutário",
       NULL AS "Data em exercício estatutário",
       NULL AS "Tipo de plano de segregação da massa do estatutário",
       NULL AS "Sujeito ao teto do RGPS estatutário",
       NULL AS "Recebe abono permanência estatutário",
       NULL AS "Data de início do abono permanência estatutário",
       NULL AS "Indicar se o servidor optou pela remuneração do cargo efetivo",
       NULL AS "Tipo de regime trabalhista para servidor público com mandato eletivo",
       NULL AS "Tipo de regime previdenciário para servidor público com mandato eletivo",
       NULL AS "Data mudança do estatutário",
       NULL AS "CNPJ do orgão público de origem com mandato eletivo",
       NULL AS "Código  da categoria de origem do servidor público com mandato eletivo", 
       NULL AS "Data de exercício do servidor no órgão público de origem com mandato eletivo",
       NULL AS "Matrícula do servidor no órgão público de origem com mandato eletivo",
       NULL AS "Tipo de regime trabalhista do funcionário",
	   NULL AS "Indicativo de Situação de Remuneração Após o Desligamento",
       NULL AS "Desconsiderar Desconto Simplificado do IRRF",
       NULL AS "Data de Desligamento Judicial",
       NULL AS "Indica adesão ao Programa de Demissão Voluntária (PDV)",
       NULL AS "Modalidade de Contratação",
       NULL AS "Inscrição Estabelecimento Atividades Práticas",
       NULL AS "Funcionário Utiliza Ponto Web (Ahgora)"
  INTO ZMIGRA_PFUNC
  FROM EPG  
 INNER JOIN ZDEPARA_PFUNC  
    ON ZDEPARA_PFUNC.EMP_CODIGO = EPG.EMP_CODIGO  
   AND ZDEPARA_PFUNC.EPG_CODIGO = EPG.CODIGO  
 INNER JOIN SEP  
    ON SEP.EMP_CODIGO = ZDEPARA_PFUNC.EMP_CODIGO  
   AND SEP.EPG_CODIGO = ZDEPARA_PFUNC.EPG_CODIGO  
   AND SEP.DATA       = ZDEPARA_PFUNC.DATA  

     LEFT JOIN ZDEPARA_SECOES  
		    ON ZDEPARA_SECOES.EMPRESA_DE = SEP.EMP_CODIGO 
		   AND ZDEPARA_SECOES.FILIAL_DE	 = SEP.EST_CODIGO 
		   AND ZDEPARA_SECOES.CODIGO_DE	 = SEP.LOT_CODIGO 
	 LEFT JOIN ZDEPARA_FUNCOES  
		    ON ZDEPARA_FUNCOES.EMPRESA_DE = SEP.EMP_CODIGO   
		   AND ZDEPARA_FUNCOES.CODIGO_DE	 = SEP.CAR_CODIGO  
	 LEFT JOIN ZDEPARA_SINDICATOS 
		    ON ZDEPARA_SINDICATOS.CODIGO_DE	= SEP.SIN_CODIGO
	 LEFT JOIN ZDEPARA_HORARIOS
		    ON ZDEPARA_HORARIOS.EMPRESA_DE  = SEP.EMP_CODIGO  
		   AND ZDEPARA_HORARIOS.CODIGO_DE   = SEP.HOR_CODIGO
	 LEFT JOIN ZDEPARA_BANCO  
		    ON ZDEPARA_BANCO.EMPRESA_DE		= EPG.EMP_CODIGO  
		   AND ZDEPARA_BANCO.CODIGO_BANCO_DE	= EPG.AGE_BAN_CODIGO  
		   AND ZDEPARA_BANCO.CODIGO_AGENCIA_DE = EPG.AGE_CODIGO  
  LEFT JOIN MUN NATURALIDADE  
    ON NATURALIDADE.UFD_SIGLA = EPG.MUN_UFD_SIGLA_NATURALIDADE  
   AND NATURALIDADE.CODIGO    = EPG.MUN_CODIGO_NATURALIDADE  
  LEFT JOIN MUN ENDERECO  
    ON ENDERECO.UFD_SIGLA = EPG.MUN_UFD_SIGLA  
   AND ENDERECO.CODIGO    = EPG.MUN_CODIGO  
  LEFT JOIN AVI AVISO  
    ON AVISO.EMP_CODIGO = EPG.EMP_CODIGO   
   AND AVISO.EPG_CODIGO = EPG.CODIGO
   AND AVISO.DATACANCELAMENTO IS NULL
;

--UPDATE PARA REMOVER AGENCIAS INDEVIDAS
UPDATE ZMIGRA_PFUNC
SET [Cód  Agência Pagamento] = NULL,
    [Cód  Banco de Pagamento] = NULL,    
	[Conta de Pagamento] = NULL
WHERE [Cód  Agência Pagamento] IN ('0000', '999', '9999');

UPDATE ZMIGRA_PFUNC
SET [Código do Sindicato] = right('000' + [Código do Sindicato],3)

UPDATE ZMIGRA_PFUNC
SET [CPF] = (
    SELECT CPF_CORRETO
    FROM PFUNC_SCPF
    WHERE CHAPA = ZMIGRA_PFUNC.CHAPA
)
WHERE CODCOLIGADA = 1
  AND CHAPA BETWEEN '000001' AND '000014';