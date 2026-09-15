# SQL Server Migration Explorer

Aplicacao local em Python/Streamlit para explorar bancos SQL Server em modo somente leitura, com foco em descobrir informacoes uteis para criacao de de-para de migracao.

## Arquitetura

- `app.py`: interface Streamlit com conexao, dashboard, explorador, relacionamentos, grafo, busca e exportacoes.
- `src/config.py`: configuracao via interface ou `.env`.
- `src/db.py`: conexao PyODBC, protecao contra SQL destrutivo e utilitarios de nomes SQL Server.
- `src/metadata.py`: consultas de metadados em `sys.tables`, `sys.columns`, `sys.foreign_keys`, `sys.indexes` e afins.
- `src/relationships.py`: separa relacionamentos reais por FK de hipoteses inferidas.
- `src/profiling.py`: amostras e estatisticas limitadas por coluna.
- `src/search.py`: busca global e classificacao de colunas candidatas para de-para.
- `src/security.py`: deteccao simples de campos sensiveis e mascaramento opcional.
- `src/graphing.py`: renderizacao Plotly/NetworkX.
- `src/graph_builder.py`: recortes investigativos do mapa relacional, metricas e tabelas ponte.
- `src/relationship_finder.py`: trilhas entre tabelas e SQL de validacao por caminho.
- `src/ui_graph.py`: tela analitica do mapa relacional.
- `src/exporter.py`: exportacao do contexto atual do mapa.
- `src/exports.py`: exportacao geral Excel, JSON e Markdown.

## Por que esta arquitetura

- Seguranca: todas as consultas passam por um bloqueio de comandos destrutivos e usam apenas `SELECT` ou views de sistema. A senha nao fica hardcoded.
- Analise visual: Streamlit organiza a exploracao em abas e Plotly mostra o mapa relacional.
- Descoberta de relacionamentos: FKs reais sao carregadas do catalogo do SQL Server; hipoteses usam heuristicas separadas e explicadas.
- De-para: busca, classificacao de colunas, amostras e exportacoes ajudam a montar evidencias.
- Uso pratico: a aplicacao roda localmente e aceita credenciais pela tela ou `.env`.

## Relacionamentos em dois niveis

1. Relacionamentos reais:
   - Origem exclusiva: `sys.foreign_keys` e `sys.foreign_key_columns`.
   - Tipo exibido: `REAL_FK`.
   - Confianca: alta.

2. Relacionamentos inferidos:
   - Tipo exibido: `INFERRED_HYPOTHESIS`.
   - Heuristicas: nomes de colunas, tipos compativeis, indices, chaves, nulidade, cardinalidade e sobreposicao de amostras.
   - Saida: score de 0 a 99, confianca textual e explicacao.
   - Regra: nunca sao certeza. Sempre validar com o SQL `SELECT TOP 100` sugerido.

## Instalar

```powershell
cd relationship_finder
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
```

## Executar

```powershell
streamlit run app.py
```

Use preferencialmente um usuario SQL Server somente leitura.

## Telas

- Visao geral: metricas, maiores tabelas, tabelas sem PK, tabelas sem FK e tipos de dados.
- Explorador: colunas, chaves, indices, amostras e estatisticas basicas.
- Relacionamentos: FKs reais e geracao controlada de hipoteses inferidas.
- Relationship Finder: caminhos entre duas tabelas, com ou sem hipoteses.
- Mapa relacional: ferramenta investigativa com tabela central, tabelas selecionadas, trilha entre duas tabelas e grafo completo somente sob confirmacao.
- Consultas SQL Seguras: editor SQL somente leitura, templates de descoberta, historico de sessao e exportacao do resultado limitado.
- Busca global: pesquisa por tabelas, colunas, tipos e relacionamentos.
- Exportacoes: Excel, JSON e Markdown.

## Mapa Relacional

O mapa nao renderiza o banco inteiro automaticamente. Para bases grandes, comece por:

- Tabela Central: expande vizinhos por profundidade, direcao e limite de nos.
- Tabelas Selecionadas: mostra apenas tabelas escolhidas, com opcao de incluir intermediarias.
- Trilha entre Duas Tabelas: encontra caminhos, mostra joins, confianca e SQL `SELECT TOP 100` de validacao.
- Grafo Completo: exige confirmacao explicita e respeita limite de nos.

O painel analitico do mapa mostra tabelas no contexto, relacionamentos, possiveis tabelas ponte, campos candidatos, ranking heuristico de relevancia para migracao e exportacoes somente do recorte atual.

## Consultas SQL Seguras

A guia funciona como um SQL Explorer somente leitura:

- aceita apenas `SELECT` ou `WITH`;
- bloqueia comandos destrutivos, administrativos e procedures (`DELETE`, `DROP`, `UPDATE`, `INSERT`, `ALTER`, `TRUNCATE`, `MERGE`, `CREATE`, `EXEC`, `BACKUP`, `RESTORE`, `DBCC`, `USE`, `sp_`, `xp_` etc.);
- rejeita multiplos comandos separados por ponto e virgula;
- aplica limite de linhas por `TOP` quando possivel e limita o DataFrame exibido;
- mantem historico apenas em memoria da sessao;
- exporta somente o resultado retornado em CSV, Excel, JSON e Markdown.

As consultas prontas cobrem estrutura do banco, chaves, relacionamentos, busca de campos para de-para, qualidade/preenchimento, validacao de relacionamento e possiveis tabelas ponte.

## Melhorias futuras

- Adicionar autenticacao integrada com perfis de ambiente.
- Persistir evidencias localmente em arquivo criptografado.
- Permitir anotacoes do usuario por coluna/tabela.
- Adicionar grafo com filtro por vizinhanca e comunidades.
- Incluir testes automatizados com um banco SQL Server de exemplo.
