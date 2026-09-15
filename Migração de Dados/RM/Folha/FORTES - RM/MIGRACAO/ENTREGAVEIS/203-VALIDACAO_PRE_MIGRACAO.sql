----------------------------------------------------------------------------------------------------      
-- Script:					VALIDACAO_PRE_MIGRACAO
-- Última Alteração:		14/08/2024     
-- Versão:					1 
-- Origem:					FORTES
-- Autor Alteração:			Rafael Stroppa
----------------------------------------------------------------------------------------------------

/*
--INFORMAÇÕES IMPORTANTES OBSERVADAS PELOS ANALISTAS

Chapa						: Preferencialmente deve ser mantido o código da origem. Um novo código só se acertado com o cliente e precisa de registro no mit 5. Verificar quantidade de posições da máscara.
Nº da Ficha de Registro		: Sempre deve ser verificado se existe na ORIGEM, caso não seja possível, será gerado pelo sistema (habilitar configuração)
Matrícula eSocial			: Conforme origem. Não deve ser alterado.
CTPS						: Dever ter até 10 posições.
Código Banco e Agência		: Verificar cadastros para saber se está dentro de um padrão (Lembrar da VCI cadastros FORTES).
Código do Tipo de Contrato	: Estagiário será NULL. (Ver último projeto SIMM)	Por padrão está ZERO no script, mas deve ser analisado se tem na ORIGEM. (Ver último projeto SIMM)
Código da Categoria			: Estagiário será NULL. (Ver último projeto SIMM)
Vínculo RAIS				: Estagiário será NULL. (Ver último projeto SIMM)
CNPJ Empresa Anterior		: Verificar se existe na ORIGEM o cnpj do vícnulo anterior
Matrícula anterior			: Verificar se existe na ORIGEM a matrícula do eSocial do vícnulo anterior
Data início do vínculo		: Será a data de ADMISSÃO
Férias						: Ver questão de FÉRIAS quebradas entre um mês e outro. **No FORTES verificar quebra de FÉRIAS (parcelada).
Período de Férias			: Sempre deve existir um período aquisitivo. **No QUESTOR quando a categoria ESOCIAL for igual a 101 então flag é igual a 1
Campo REF					: Verificar se está formatado corretamente. Decimal (15,2)
Campo Hora					: Verificar se está formatado corretamente (Apenas para o evento do tipo HORA) - 000:00

*/

--Nº da Ficha de Registro: Se no banco de origem TODOS os funcionários possuirem Nº da Ficha de Registro, então deve ser importado conforme origem. Caso contrário, deve ser gerado pelo RM.
--Habilitar configuração de geração automática dos códigos

SELECT 'CAMPOS QUE PRECISAM DE ATENÇÃO' AS INFORMACAO
SELECT X.*
  FROM (
		SELECT '1 - Nº da Ficha de Registro igual a NULL'		AS DADO, SUM(CASE WHEN len("Nº da Ficha de Registro") IS NULL THEN 1 ELSE 0 END) AS QTD FROM ZMIGRA_PFUNC			UNION
		SELECT '2 - Nº da Carteira de Trabalho > 10'			AS DADO, SUM(CASE WHEN len("Nº da Carteira de Trabalho") > 10 THEN 1 ELSE 0 END) AS QTD FROM ZMIGRA_PFUNC			UNION 
		SELECT '3 - Cód  Agência Pagamento > 5'					AS DADO, SUM(CASE WHEN len("Cód  Agência Pagamento") > 5 THEN 1 ELSE 0 END) AS QTD FROM ZMIGRA_PFUNC				UNION
		SELECT '4 - Cód  Banco de Pagamento = 999'				AS DADO, SUM(CASE WHEN "Cód  Banco de Pagamento" = '999' THEN 1 ELSE 0 END) AS QTD FROM ZMIGRA_PFUNC				UNION
		SELECT '5 - Cód  Agência Pagamento = 9999 ou 99999'		AS DADO, SUM(CASE WHEN "Cód  Agência Pagamento" IN ('9999','99999') THEN 1 ELSE 0 END) AS QTD FROM ZMIGRA_PFUNC		UNION
		SELECT '6 - Cód  Agência Pagamento = 0000'				AS DADO, SUM(CASE WHEN "Cód  Agência Pagamento" IN ('0000') THEN 1 ELSE 0 END) AS QTD FROM ZMIGRA_PFUNC				UNION
		SELECT '7 - Código do Sindicato = 999'					AS DADO, SUM(CASE WHEN "Código do Sindicato" IN ('999') THEN 1 ELSE 0 END) AS QTD FROM ZMIGRA_PFUNC 				UNION
		SELECT '8 - Código do Sindicato NÃO IMPORTAR'			AS DADO, SUM(CASE WHEN "Código do Sindicato" LIKE ('NÃO IMPORTAR') THEN 1 ELSE 0 END) AS QTD FROM ZMIGRA_PFUNC 
	) X
 WHERE X.QTD > 0

/* VERIFICAR SE EXISTEM CAMPOS OBRIGATÓRIOS NULO */

SELECT 'VERIFICAR SE EXISTEM CAMPOS OBRIGATÓRIOS NULO' AS INFORMACAO
SELECT X.*
  FROM (
		SELECT 'Chapa' AS CAMPO, SUM(CASE WHEN "Chapa" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Nome' AS CAMPO, SUM(CASE WHEN "Nome" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Data de Nascimento' AS CAMPO, SUM(CASE WHEN "Data de Nascimento" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Estado Civil' AS CAMPO, SUM(CASE WHEN "Estado Civil" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Sexo (M/F)' AS CAMPO, SUM(CASE WHEN "Sexo (M F)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Grau de Instrução' AS CAMPO, SUM(CASE WHEN "Grau de Instrução" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'CPF' AS CAMPO, SUM(CASE WHEN "CPF" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'NIT - Tipo de Carteira de Trabalho (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "NIT - Tipo de Carteira de Trabalho (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Naturalidade' AS CAMPO, SUM(CASE WHEN "Naturalidade" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Estado Natal' AS CAMPO, SUM(CASE WHEN "Estado Natal" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Cônjuge Brasil (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Cônjuge Brasil (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Naturalizado (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Naturalizado (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Filhos no Brasil (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Filhos no Brasil (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Código da Seção' AS CAMPO, SUM(CASE WHEN "Código da Seção" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Código da Função' AS CAMPO, SUM(CASE WHEN "Código da Função" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Código do Sindicato' AS CAMPO, SUM(CASE WHEN "Código do Sindicato" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Jornada (Formato HHH:MM)' AS CAMPO, SUM(CASE WHEN "Jornada (Formato HHH MM)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Código do Horário' AS CAMPO, SUM(CASE WHEN "Código do Horário" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Código identificador da filial' AS CAMPO, SUM(CASE WHEN "Código identificador da filial" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Índice de Início de Horário'AS CAMPO, SUM(CASE WHEN "Índice de Início de Horário" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'len("Nº da Carteira de Trabalho") > 10' AS CAMPO, SUM(CASE WHEN len("Nº da Carteira de Trabalho") > 10 THEN 1 ELSE 0 END) AS QTD FROM ZMIGRA_PFUNC UNION 
		SELECT 'len("Cód  Agência Pagamento") > 5' AS CAMPO, SUM(CASE WHEN len("Cód  Agência Pagamento") > 5 THEN 1 ELSE 0 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Contribuição Sindical (J-Já Descontou/L-Liberal/N-Não Desc.)' AS CAMPO, SUM(CASE WHEN "Contribuição Sindical (J-Já Descontou/L-Liberal/N-Não Desc.)"  IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Aposentado (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Aposentado (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Tem Mais de 65 Anos (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Tem Mais de 65 Anos (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Data de Admissão' AS CAMPO, SUM(CASE WHEN "Data de Admissão" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Motivo da Admissão' AS CAMPO, SUM(CASE WHEN "Motivo da Admissão" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Contrato tem Prazo Determinado (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Contrato tem Prazo Determinado (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Tem Aviso Prévio (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Tem Aviso Prévio (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Quer Abono (0- Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Quer Abono (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS "Quer Abono (0- Não   1-Sim)" FROM ZMIGRA_PFUNC UNION
		SELECT 'Quer 1ª Parcela de 13º (0- Não / 1-Sim)' AS CAMPO, SUM(CASE WHEN "Quer 1ª Parcela de 13º (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Férias Coletivas Globais (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Férias Coletivas Globais (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Situação RAIS' AS CAMPO, SUM(CASE WHEN "Situação RAIS" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Membro Sindical (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Membro Sindical (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Usa Vale Transporte (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Usa Vale Transporte (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Mudou Endereço (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Mudou Endereço (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Mudou Carteira de Trabalho (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Mudou Carteira de Trabalho (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Mudou Nome (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Mudou Nome (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Mudou PIS (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Mudou PIS (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Mudou Data de Admissão (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Mudou Data de Admissão (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Mudou Seção (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Mudou Seção (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Mudou Data de Nascimento (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Mudou Data de Nascimento (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Falta Alterar FGTS (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Falta Alterar FGTS (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Deduzir IRRF Mais 65 (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Deduzir IRRF Mais 65 (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Índice de Início de Horário' AS CAMPO, SUM(CASE WHEN "Índice de Início de Horário" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Usa Salário Composto (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Usa Salário Composto (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Funcionário é membro da CIPA (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Funcionário é membro da CIPA (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Funcionário é o atual? (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Funcionário é o atual? (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Funcionário tem status de supervisor? (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Funcionário tem status de supervisor? (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Usa Controle de Saldo de Verbas? (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Usa Controle de Saldo de Verbas? (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Mudou Código Contribuinte Individual (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Mudou Código Contribuinte Individual (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'FGTS mês anterior será recolhido na GRFC (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "FGTS mês anterior será recolhido na GRFC (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Tem alvará judicial p/func menor 16 anos (1-Sim 2-Não)' AS CAMPO, SUM(CASE WHEN "Tem alvará judicial p/func menor 16 anos (1-Sim 2-Não)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Quer adiantamento nas férias (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Quer adiantamento nas férias (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Posição Abono (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Posição Abono (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Fumante (0-Não 1-Sim)' AS CAMPO, SUM(CASE WHEN "Fumante (0-Não 1-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC UNION
		SELECT 'Reposição de Vaga (N-Não S-Sim)' AS CAMPO, SUM(CASE WHEN "Reposição de Vaga (N-Não S-Sim)" IS NOT NULL THEN 0 ELSE 1 END) AS QTD FROM ZMIGRA_PFUNC 
	) X
 WHERE X.QTD > 0

/* EXIBIR DADOS DIVERGENTES */

SELECT  "Codcoligada",
		"Código de Situação",
		"Chapa",
		"Nome",
		"Data de Nascimento",
		"Estado Civil",
		"Sexo (M F)",
		"Grau de Instrução",
		"CPF",
		"Tipo da Rua",
		"Telefone 1",
		"Telefone 2",

		'---------->' AS "||||| MUNICÍPIO |||||",

		"Naturalidade",
		"Estado Natal",
		"Código do Municipio Naturalidade",
		"Cidade",
		"Unidade da Federação",
		"Código Município",

		'---------->' AS "||||| CTPS |||||",

		--TAMANHO Nº CTPS (Até 10 posições)
		"Nº da Carteira de Trabalho",
		"Série - Carteira de Trabalho",
		"Data da emissão - Carteira de Trabalho",
		"UF - Carteira de Trabalho",
		len("Nº da Carteira de Trabalho") QTD_POSIÇÕES_CTPS,
		CASE WHEN len("Nº da Carteira de Trabalho") > 10 THEN 'VERIFICAR' END AS ALERTA_CTPS,

		'---------->' AS "||||| COFERIR |||||" ,

		--CONFERIR
		"Data de Admissão",
		"Data da Transferência",
		"Data de Demissão",
		--"Tipo de Admissão",
		"Motivo da Admissão",
		"Código de Saque de FGTS",
		"Matrícula do trabalhador no eSocial",
		"Nº da Ficha de Registro",
		"Código do Tipo do Funcionário",
    	 CASE "Código do Tipo do Funcionário"
    		   WHEN 'N' THEN 'Normal'
    		   WHEN 'Z' THEN 'Aprendiz'  
    		   WHEN 'D' THEN 'Diretor'   
    		   WHEN 'T' THEN 'Estagiário'
    	  END "Tipo do Funcionário",
		 "Salário (Formato 999999999999,99)",
		 "Código de recebimento",
		 "Matrícula anterior",

		'---------->' AS "||||| IMPORTANTES |||||",

		--DADOS IMPORTANTES
		"Código identificador da filial",
		"Código da Seção",
		"Código da Função",
		"Código do Sindicato",
		"Jornada (Formato HHH MM)",
		"Código do Horário",
		"Índice de Início de Horário",

		'---------->' AS "||||| PAGAMENTO |||||",

		--PAGAMENTO
		"Cód  Banco de Pagamento",
		"Cód  Agência Pagamento",
		len("Cód  Agência Pagamento") QTD_POSIÇÕES_AGENCIA,
		CASE WHEN len("Cód  Agência Pagamento") <> 5 THEN 'VERIFICAR' END AS ALERTA_CODIGO_AGENCIA,
		"Conta de Pagamento",

		'---------->' AS "||||| HISTÓRICOS |||||",

		--HISTÓRICOS
		"Data da Mudança de Salário",
		"Motivo da Mudança de Salário",
		"Data da Mudança de Função",
		"Motivo da Mudança de Função",
		"Data da Mudança de Situação",
		"Motivo da Mudança de Situação",
		"Data da Mudança de Seção",
		"Motivo da Mudança de Seção",

		'---------->' AS "||||| DATAS NECESSÁRIAS |||||",

		--DATAS NECESSÁRIAS
		"Data da Mudança de Horário",        
		"Data da Mudança das Informações SEFIP",        
		"Data da Mudança da Contribuição Sindical",       
		"Data da Mudança dos Dados Bancários",        
		"Data da Mudança dos Dados Bancários Alternativo",

		'---------->' AS "||||| AVISO PRÉVIO |||||",

		"Data de Demissão",
		"Tipo de Demissão",
		"Motivo de Demissão",
		"Tem Aviso Prévio (0-Não 1-Sim)",
		"Desconta Aviso Prévio (0-Não 1-Sim)",
		"Data do Aviso Prévio",
		"Número de Dias de Aviso",
		"Código de Saque de FGTS",
		"Saldo do FGTS no Banco (Formato 999999999999,99)",
		"Situação de FGTS (1-Optante   2-Não Optante)",
		"Período de Rescisão",

		'---------->' AS "||||| OUTROS |||||",

		"Contribuição Sindical (J-Já Descontou/L-Liberal/N-Não Desc.)",
		"Situação IRRF (0-Não Calcula  1-Calcula)",

		'---------->' AS "||||| DADOS ESTÁGIO |||||",
	    "Natureza do estágio",
	    "Nível do estágio",
	    "Área de atuação do estagiário",
	    "Nr  apólice de seguro",
	    "Data prevista para o término do estágio",
	    "Código da instituição de ensino",
	    "Código do agente de integração",  
	    "Cpf do coordenador do estágio",  
	    "Nome do coordenador do estágio"

  FROM ZMIGRA_PFUNC

 WHERE CHAPA NOT LIKE '%%'

    OR "Código identificador da filial"  IS NULL
	OR "Código da Seção" IS NULL
	OR "Código da Função" IS NULL
	OR "Código do Sindicato" IS NULL OR "Código do Sindicato" LIKE 'NÃO IMPORTAR'
	OR "Código do Horário" IS NULL 
	OR "Índice de Início de Horário" IS NULL
	OR len("Nº da Carteira de Trabalho") > 10
	OR len("Cód  Agência Pagamento") > 5
	OR "Naturalidade" IS NULL
	OR "Estado Natal"  IS NULL
	OR "Código do Municipio Naturalidade"  IS NULL
	OR "Cidade"  IS NULL
	OR "Unidade da Federação"  IS NULL
	OR "Código Município"  IS NULL

  ORDER BY 1,3

/*VERIRICAR SE EXISTEM TABELAS SEM DADOS DE FUNCIONARIOS */


SELECT 'DEPENDENTE'					AS DADO, COUNT(*) QTD_NÃO_EXISTE_FUNCIONARIO FROM ZMIGRA_PFDEPEND			X	WHERE NOT EXISTS (SELECT 1 FROM ZDEPARA_PFUNC WHERE ZDEPARA_PFUNC.CHAPA = X.CHAPA)  UNION 
SELECT 'FERIAS_PERIODO_AQUISITIVO'	AS DADO, COUNT(*) QTD_NÃO_EXISTE_FUNCIONARIO FROM ZMIGRA_PFUFERIAS			X	WHERE NOT EXISTS (SELECT 1 FROM ZDEPARA_PFUNC WHERE ZDEPARA_PFUNC.CHAPA = X.CHAPA)  UNION
SELECT 'FERIAS_PERIODO_GOZO'		AS DADO, COUNT(*) QTD_NÃO_EXISTE_FUNCIONARIO FROM ZMIGRA_PFUFERIASPER		X	WHERE NOT EXISTS (SELECT 1 FROM ZDEPARA_PFUNC WHERE ZDEPARA_PFUNC.CHAPA = X.CHAPA)  UNION
SELECT 'FERIAS_RECIBO'				AS DADO, COUNT(*) QTD_NÃO_EXISTE_FUNCIONARIO FROM ZMIGRA_PFUFERIASRECIBO	X	WHERE NOT EXISTS (SELECT 1 FROM ZDEPARA_PFUNC WHERE ZDEPARA_PFUNC.CHAPA = X.CHAPA)  UNION
SELECT 'FERIAS_VERBAS'				AS DADO, COUNT(*) QTD_NÃO_EXISTE_FUNCIONARIO FROM ZMIGRA_PFUFERIASVERBAS	X	WHERE NOT EXISTS (SELECT 1 FROM ZDEPARA_PFUNC WHERE ZDEPARA_PFUNC.CHAPA = X.CHAPA)  UNION
SELECT 'HIST_AFASTAMENTO'			AS DADO, COUNT(*) QTD_NÃO_EXISTE_FUNCIONARIO FROM ZMIGRA_PFHSTAFT			X	WHERE NOT EXISTS (SELECT 1 FROM ZDEPARA_PFUNC WHERE ZDEPARA_PFUNC.CHAPA = X.CHAPA)  UNION 
SELECT 'HIST_FUNCAO'				AS DADO, COUNT(*) QTD_NÃO_EXISTE_FUNCIONARIO FROM ZMIGRA_PFHSTFCO			X	WHERE NOT EXISTS (SELECT 1 FROM ZDEPARA_PFUNC WHERE ZDEPARA_PFUNC.CHAPA = X.CHAPA)  UNION 
SELECT 'HIST_SALARIO'				AS DADO, COUNT(*) QTD_NÃO_EXISTE_FUNCIONARIO FROM ZMIGRA_PFHSTSAL			X	WHERE NOT EXISTS (SELECT 1 FROM ZDEPARA_PFUNC WHERE ZDEPARA_PFUNC.CHAPA = X.CHAPA)  UNION 
SELECT 'HIST_SECAO'					AS DADO, COUNT(*) QTD_NÃO_EXISTE_FUNCIONARIO FROM ZMIGRA_PFHSTSEC			X	WHERE NOT EXISTS (SELECT 1 FROM ZDEPARA_PFUNC WHERE ZDEPARA_PFUNC.CHAPA = X.CHAPA)  UNION 
SELECT 'HIST_SITUACAO'				AS DADO, COUNT(*) QTD_NÃO_EXISTE_FUNCIONARIO FROM ZMIGRA_PFHSTSIT			X	WHERE NOT EXISTS (SELECT 1 FROM ZDEPARA_PFUNC WHERE ZDEPARA_PFUNC.CHAPA = X.CHAPA)  UNION 
SELECT 'FICHA_PERIODO'			    AS DADO, COUNT(*) QTD_NÃO_EXISTE_FUNCIONARIO FROM ZMIGRA_PFPERFF			X	WHERE NOT EXISTS (SELECT 1 FROM ZDEPARA_PFUNC WHERE ZDEPARA_PFUNC.CHAPA = X.CHAPA)  UNION 
SELECT 'FICHA FINANCEIRA'			AS DADO, COUNT(*) QTD_NÃO_EXISTE_FUNCIONARIO FROM ZMIGRA_PFFINANC			X	WHERE NOT EXISTS (SELECT 1 FROM ZDEPARA_PFUNC WHERE ZDEPARA_PFUNC.CHAPA = X.CHAPA)  


/* VERIFICAR SE EXISTEM CAMPOS OBRIGATÓRIOS NULO */

SELECT '02-DEPENDENTES - Nº do Dependente'							AS DADOS, COUNT(*) AS QTD_NULO FROM ZMIGRA_PFDEPEND WHERE "Nº do Dependente" IS NULL						UNION
SELECT '02-DEPENDENTES - Sexo do Dependente (M/F)'					AS DADOS, COUNT(*) AS QTD_NULO FROM ZMIGRA_PFDEPEND WHERE "Sexo do Dependente (M/F)" IS NULL				UNION
SELECT '02-DEPENDENTES - Estado Civil do Dependente'				AS DADOS, COUNT(*) AS QTD_NULO FROM ZMIGRA_PFDEPEND WHERE "Estado Civil do Dependente" IS NULL				UNION
SELECT '02-DEPENDENTES - Grau de Parentesco do Dependente'			AS DADOS, COUNT(*) AS QTD_NULO FROM ZMIGRA_PFDEPEND WHERE "Grau de Parentesco do Dependente" IS NULL		UNION
SELECT '06-VERBAS DE FÉRIAS - Código do Evento'						AS DADOS, COUNT(*) AS QTD_NULO FROM ZMIGRA_PFUFERIASVERBAS WHERE "CODEVENTO" IS NULL OR "CODEVENTO" = ''	UNION			
SELECT '07-HISTÓRICO DE SALÁRIO - Motivo de alteração salarial'		AS DADOS, COUNT(*) AS QTD_NULO FROM ZMIGRA_PFHSTSAL WHERE "Motivo de alteração salarial"  IS NULL			UNION
SELECT '08-HISTÓRICO DE SITUAÇÃO - Motivo Mudança'					AS DADOS, COUNT(*) AS QTD_NULO FROM ZMIGRA_PFHSTSIT WHERE MOTIVO IS NULL 									UNION			
SELECT '08-HISTÓRICO DE SITUAÇÃO - Código da Nova Situação'			AS DADOS, COUNT(*) AS QTD_NULO FROM ZMIGRA_PFHSTSIT WHERE NOVASITUACAO IS NULL								UNION
SELECT '09-HISTÓRICO DE CONTRIB. SIND. - Código do sindicat'		AS DADOS, COUNT(*) AS QTD_NULO FROM ZMIGRA_PFHSTCSD WHERE "Código do sindicato" IS NULL	OR "Código do sindicato" LIKE 'NÃO IMPORTAR' UNION
SELECT '10-HISTÓRICO DE FUNÇÃO - Motivo Mudança'					AS DADOS, COUNT(*) AS QTD_NULO FROM ZMIGRA_PFHSTFCO WHERE "Código do Motivo da Mud. De Função" IS NULL		UNION	
SELECT '10-HISTÓRICO DE FUNÇÃO - Código da Função'					AS DADOS, COUNT(*) AS QTD_NULO FROM ZMIGRA_PFHSTFCO WHERE "Código da Função" IS NULL						UNION
SELECT '11-HISTÓRICO DE SEÇÃO - Motivo Mudança'						AS DADOS, COUNT(*) AS QTD_NULO FROM ZMIGRA_PFHSTSEC WHERE "Código do Motivo da Mud. De Seção" IS NULL		UNION	
SELECT '11-HISTÓRICO DE SEÇÃO - Código da Seção'					AS DADOS, COUNT(*) AS QTD_NULO FROM ZMIGRA_PFHSTSEC WHERE "Código da Seção" IS NULL							UNION
SELECT '11-HISTÓRICO DE AFASTAMENTO - Motivo Afastamento'			AS DADOS, COUNT(*) AS QTD_NULO FROM ZMIGRA_PFHSTAFT WHERE "Motivo do afastamento" IS NULL					UNION
SELECT '11-HISTÓRICO DE AFASTAMENTO - Tipo Afastamento'				AS DADOS, COUNT(*) AS QTD_NULO FROM ZMIGRA_PFHSTAFT WHERE "Tipo" IS NULL									UNION
SELECT '14-FICHA FINANCEIRA - Código do Evento'						AS DADOS, COUNT(*) AS QTD_NULO FROM ZMIGRA_PFFINANC  WHERE "Código do Evento" IS NULL OR "Código do Evento" = ''