--------------------------------------------------------------------------------
-- 022 - ZMIGRA PCTABPR  (versao em LOTES, reiniciavel, via DB LINK DBLCLOUD)
--
-- Objetivo: migrar PCTABPR da base LOCAL para a base CLOUD sem estourar timeout,
--           gravando em lotes com COMMIT a cada lote e permitindo retomar
--           exatamente de onde parou em caso de queda de link.
--
-- Executar SEMPRE a partir da base LOCAL (origem), pois o DML distribuido
-- e coordenado pelo site onde a sessao esta conectada.
--
-- Ordem de execucao: PASSO 0 -> 1 -> 2 -> 3 -> 4 -> 5
--------------------------------------------------------------------------------


--==============================================================================
-- PASSO 0 - CHECAGENS NO DESTINO (fazer UMA vez, antes de tudo)
--==============================================================================

-- 0.1) Triggers ativas no destino sobre PCTABPR (WinThor costuma ter varias).
--      Cada trigger roda linha a linha e pode multiplicar o tempo por 5x ou mais.
SELECT TRIGGER_NAME, STATUS, TRIGGERING_EVENT
  FROM ALL_TRIGGERS@DBLCLOUD
 WHERE TABLE_NAME = 'PCTABPR';

-- 0.2) Indices do destino (avaliar deixar UNUSABLE durante a carga e rebuildar depois)
SELECT INDEX_NAME, UNIQUENESS, STATUS
  FROM ALL_INDEXES@DBLCLOUD
 WHERE TABLE_NAME = 'PCTABPR';

-- 0.3) Volume a migrar (rodar antes para dimensionar o tamanho do lote)
SELECT COUNT(*) QT_LOCAL FROM PCTABPR;
SELECT COUNT(*) QT_CLOUD FROM PCTABPR@DBLCLOUD;

-- 0.4) OPCIONAL - desativar triggers no destino durante a carga.
--      >>> So faca isso com o WinThor da nuvem PARADO / sem usuarios. <<<
--      Rodar CONECTADO NO DESTINO (DDL nao passa por DB Link):
--      ALTER TRIGGER <owner>.<trigger> DISABLE;
--      ... e reabilitar ao final.


--==============================================================================
-- PASSO 1 - OBJETOS DE APOIO (criar UMA vez na base LOCAL)
--==============================================================================

-- 1.1) Chaves que JA existem no destino (snapshot unico, evita ler o remoto a cada lote)
CREATE TABLE ZMIG_PCTABPR_DEST (
    CODPROD    NUMBER,
    NUMREGIAO  NUMBER
) NOLOGGING;

-- 1.2) Fila de trabalho: o que falta migrar, ja dividido em lotes
CREATE TABLE ZMIG_PCTABPR_FILA (
    CODPROD    NUMBER       NOT NULL,
    NUMREGIAO  NUMBER       NOT NULL,
    LOTE       NUMBER       NOT NULL,
    STATUS     VARCHAR2(1)  DEFAULT 'P' NOT NULL,   -- P=Pendente C=Concluido E=Erro
    DTPROC     DATE,
    ERRO       VARCHAR2(500)
) NOLOGGING;

-- 1.3) Log de execucao (auditoria e acompanhamento)
CREATE TABLE ZMIG_PCTABPR_LOG (
    LOTE       NUMBER,
    QT_LINHAS  NUMBER,
    DTINICIO   TIMESTAMP,
    DTFIM      TIMESTAMP,
    SEGUNDOS   NUMBER,
    STATUS     VARCHAR2(1),
    MENSAGEM   VARCHAR2(500)
);


--==============================================================================
-- PASSO 2 - CARREGAR AS CHAVES DO DESTINO
-- Le apenas 2 colunas do remoto. Rapido mesmo com milhoes de linhas.
--==============================================================================

    TRUNCATE TABLE ZMIG_PCTABPR_DEST;

    INSERT /*+ APPEND */ INTO ZMIG_PCTABPR_DEST (CODPROD, NUMREGIAO)
    SELECT CODPROD, NUMREGIAO FROM PCTABPR@DBLCLOUD;
    COMMIT;

    CREATE UNIQUE INDEX ZMIG_PCTABPR_DEST_PK
        ON ZMIG_PCTABPR_DEST (CODPROD, NUMREGIAO) NOLOGGING;

    BEGIN
        DBMS_STATS.GATHER_TABLE_STATS(USER,'ZMIG_PCTABPR_DEST');
    END;


--==============================================================================
-- PASSO 3 - MONTAR A FILA (anti-join 100% LOCAL, sem trafego de rede)
-- Ajuste o 5000 abaixo para o tamanho de lote desejado.
--==============================================================================

TRUNCATE TABLE ZMIG_PCTABPR_FILA;

INSERT /*+ APPEND */ INTO ZMIG_PCTABPR_FILA (CODPROD, NUMREGIAO, LOTE, STATUS)
SELECT CODPROD,
       NUMREGIAO,
       CEIL(ROW_NUMBER() OVER (ORDER BY CODPROD, NUMREGIAO) / 5000) AS LOTE,
       'P'
  FROM PCTABPR O
 WHERE NOT EXISTS (
           SELECT 1
             FROM ZMIG_PCTABPR_DEST D
            WHERE D.CODPROD   = O.CODPROD
              AND D.NUMREGIAO = O.NUMREGIAO
       );
COMMIT;

CREATE INDEX ZMIG_PCTABPR_FILA_I1
    ON ZMIG_PCTABPR_FILA (LOTE, STATUS) NOLOGGING;

CREATE UNIQUE INDEX ZMIG_PCTABPR_FILA_PK
    ON ZMIG_PCTABPR_FILA (CODPROD, NUMREGIAO) NOLOGGING;

    BEGIN
        DBMS_STATS.GATHER_TABLE_STATS(USER, 'ZMIG_PCTABPR_FILA');
    END;

-- Conferencia: quantos lotes e quantas linhas
SELECT COUNT(*) QT_PENDENTE, MAX(LOTE) QT_LOTES FROM ZMIG_PCTABPR_FILA;


--==============================================================================
-- PASSO 4 - EXECUCAO EM LOTES COM COMMIT
--
-- Pode ser interrompido a qualquer momento (Ctrl+C, queda de link, timeout).
-- Basta rodar de novo: ele retoma pelos lotes que ainda estao 'P' ou 'E'.
--==============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON

DECLARE
    -- ---------- parametros ----------
    c_max_tentativas  CONSTANT PLS_INTEGER := 3;    -- retries por lote
    c_pausa_seg       CONSTANT PLS_INTEGER := 5;    -- pausa entre retries
    c_pausa_lote      CONSTANT PLS_INTEGER := 0;    -- respiro entre lotes (seg)
    -- --------------------------------

    v_lote_ini   NUMBER;
    v_lote_fim   NUMBER;
    v_linhas     PLS_INTEGER;
    v_tent       PLS_INTEGER;
    v_ok         BOOLEAN;
    v_ini        TIMESTAMP;
    v_total      PLS_INTEGER := 0;
BEGIN
    SELECT MIN(LOTE), MAX(LOTE)
      INTO v_lote_ini, v_lote_fim
      FROM ZMIG_PCTABPR_FILA
     WHERE STATUS IN ('P','E');

    IF v_lote_ini IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('Nada pendente. Migracao ja concluida.');
        RETURN;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Processando lotes '||v_lote_ini||' a '||v_lote_fim);

    FOR i IN v_lote_ini .. v_lote_fim LOOP

        v_tent := 0;
        v_ok   := FALSE;

        WHILE NOT v_ok AND v_tent < c_max_tentativas LOOP
            v_tent := v_tent + 1;
            v_ini  := SYSTIMESTAMP;

            BEGIN
                INSERT INTO PCTABPR@DBLCLOUD (
                    CODPROD, NUMREGIAO, PTABELA, PVENDA, PERDESCMAX, PERDESCMAXTAB,
                    POFERTA, POFERTATAB, MARGEM, DTULTALTPVENDA, EXCLUIDO,
                    PTABELA1, PTABELA2, PTABELA3, PTABELA4, PTABELA5, PTABELA6, PTABELA7,
                    PVENDA1, PVENDA2, PVENDA3, PVENDA4, PVENDA5, PVENDA6, PVENDA7,
                    CODST, MARGEM_ESP, PFRETE, TABELAEMITIDA, PERDESCMAXESP, PERDESCAUTOR,
                    COTAITEM, QTDESCAUTOR, POFERTAAUX, PERDESCAUTORTAB, COTAITEMTAB,
                    QTDESCAUTORTAB, PERDESCMAXBALCAO, PERDESCMAXTABBALCAO, PERDESCFOB,
                    PTABELAMED, PVENDAMED,
                    PTABELAMED1, PTABELAMED2, PTABELAMED3, PTABELAMED4, PTABELAMED5, PTABELAMED6, PTABELAMED7,
                    PVENDAMED1, PVENDAMED2, PVENDAMED3, PVENDAMED4, PVENDAMED5, PVENDAMED6, PVENDAMED7,
                    DESCONTAFRETE, DTINICIOPTABELA, PTABELAFUTURO, DTULTALTPTABELAFUTURO, DTULTALTPTABELA,
                    PCOMREP1, PCOMREP2, PCOMREP3, PERCACRESCIMOFRETE, DTEMISSAOETIQ, NUMSEQATU,
                    PRECOFAB, ATUALIZAR,
                    PTABELAATAC, PTABELAATAC1, PTABELAATAC2, PTABELAATAC3, PTABELAATAC4, PTABELAATAC5, PTABELAATAC6, PTABELAATAC7,
                    PVENDAATAC, PVENDAATAC1, PVENDAATAC2, PVENDAATAC3, PVENDAATAC4, PVENDAATAC5, PVENDAATAC6, PVENDAATAC7,
                    PRECOANTERIORATAC, VLACRESFRETEKG, DTINICIOVALIDADE, DTFIMVALIDADE, INDICEPRECO,
                    DTIMPORTINTEGRACAO, PERCIPIVENDATAB, VLPAUTAIPIVENDATAB, VLIPIPORKGVENDATAB,
                    PRECOMAXCONSUM, DTULTATUPVENDA, DTULTALTERSRVPRC, PRECOMAXCONSUMTAB, PERCDESCSIMPLESNAC,
                    VLSTTAB, VLST, CODTRIBPISCOFINS, PRECOREVISTA, DTVALPREVISTA, OBS, ROTINA, MATRICULA,
                    PERDESCMAXIDEALTAB, PERDESCMAXPOSSIVELTAB, PERCCOMGARANTIDATAB, PERDESCMAXAVISTATAB,
                    PERDESCMAXIDEAL, PERCCOMGARANTIDA, PERDESCMAXAVISTA, PERDESCMAXPOSSIVEL,
                    VLIPITAB, VLIPI, PERCCOM, CUSTOPRECIFIC, CUSTOPRECIFICTAB, VLULTENTMES,
                    PTABELASEMIMPOSTO1, PTABELASEMIMPOSTO2, PTABELASEMIMPOSTO3, PTABELASEMIMPOSTO4,
                    PTABELASEMIMPOSTO5, PTABELASEMIMPOSTO6, PTABELASEMIMPOSTO7,
                    PVENDASEMIMPOSTO1, PVENDASEMIMPOSTO2, PVENDASEMIMPOSTO3, PVENDASEMIMPOSTO4,
                    PVENDASEMIMPOSTO5, PVENDASEMIMPOSTO6, PVENDASEMIMPOSTO7,
                    PTABELAATACSEMIMPOSTO1, PTABELAATACSEMIMPOSTO2, PTABELAATACSEMIMPOSTO3, PTABELAATACSEMIMPOSTO4,
                    PTABELAATACSEMIMPOSTO5, PTABELAATACSEMIMPOSTO6, PTABELAATACSEMIMPOSTO7,
                    PVENDAATACSEMIMPOSTO1, PVENDAATACSEMIMPOSTO2, PVENDAATACSEMIMPOSTO3, PVENDAATACSEMIMPOSTO4,
                    PVENDAATACSEMIMPOSTO5, PVENDAATACSEMIMPOSTO6, PVENDAATACSEMIMPOSTO7,
                    UTILIZARIOLOG, CALCULARIPI, PRECOMINIMOTABELA, PRECOMINIMOVENDA, FORMULA, REGPRECIFICADA,
                    PRECOMINIMOTABELA_AUX, PRECOMINIMOVENDA_AUX, VLFCPSTTAB, VLFCPST, CALCULARFECPSTVENDA,
                    VLULTENTCONTSEMSTTAB, VLULTENTCONTSEMST, REGRAALTERARDESCONTO, CODFILIALINTEGRACAO,
                    DTALTERC5, UTILIZAMULTIPLO,
                    VLCBSTAB, VLIBSTAB, VLISTAB, VLCBS, VLIBS, VLIS,
                    CODIGO_CBS, CODIGO_IBS, CODIGO_IS, PRECOCOMIVATAB, PRECOCOMIVA
                )
                SELECT
                    P.CODPROD, P.NUMREGIAO, P.PTABELA, P.PVENDA, P.PERDESCMAX, P.PERDESCMAXTAB,
                    P.POFERTA, P.POFERTATAB, P.MARGEM, P.DTULTALTPVENDA, P.EXCLUIDO,
                    P.PTABELA1, P.PTABELA2, P.PTABELA3, P.PTABELA4, P.PTABELA5, P.PTABELA6, P.PTABELA7,
                    P.PVENDA1, P.PVENDA2, P.PVENDA3, P.PVENDA4, P.PVENDA5, P.PVENDA6, P.PVENDA7,
                    P.CODST, P.MARGEM_ESP, P.PFRETE, P.TABELAEMITIDA, P.PERDESCMAXESP, P.PERDESCAUTOR,
                    P.COTAITEM, P.QTDESCAUTOR, P.POFERTAAUX, P.PERDESCAUTORTAB, P.COTAITEMTAB,
                    P.QTDESCAUTORTAB, P.PERDESCMAXBALCAO, P.PERDESCMAXTABBALCAO, P.PERDESCFOB,
                    P.PTABELAMED, P.PVENDAMED,
                    P.PTABELAMED1, P.PTABELAMED2, P.PTABELAMED3, P.PTABELAMED4, P.PTABELAMED5, P.PTABELAMED6, P.PTABELAMED7,
                    P.PVENDAMED1, P.PVENDAMED2, P.PVENDAMED3, P.PVENDAMED4, P.PVENDAMED5, P.PVENDAMED6, P.PVENDAMED7,
                    P.DESCONTAFRETE, P.DTINICIOPTABELA, P.PTABELAFUTURO, P.DTULTALTPTABELAFUTURO, P.DTULTALTPTABELA,
                    P.PCOMREP1, P.PCOMREP2, P.PCOMREP3, P.PERCACRESCIMOFRETE, P.DTEMISSAOETIQ, P.NUMSEQATU,
                    P.PRECOFAB, P.ATUALIZAR,
                    P.PTABELAATAC, P.PTABELAATAC1, P.PTABELAATAC2, P.PTABELAATAC3, P.PTABELAATAC4, P.PTABELAATAC5, P.PTABELAATAC6, P.PTABELAATAC7,
                    P.PVENDAATAC, P.PVENDAATAC1, P.PVENDAATAC2, P.PVENDAATAC3, P.PVENDAATAC4, P.PVENDAATAC5, P.PVENDAATAC6, P.PVENDAATAC7,
                    P.PRECOANTERIORATAC, P.VLACRESFRETEKG, P.DTINICIOVALIDADE, P.DTFIMVALIDADE, P.INDICEPRECO,
                    P.DTIMPORTINTEGRACAO, P.PERCIPIVENDATAB, P.VLPAUTAIPIVENDATAB, P.VLIPIPORKGVENDATAB,
                    P.PRECOMAXCONSUM, P.DTULTATUPVENDA, P.DTULTALTERSRVPRC, P.PRECOMAXCONSUMTAB, P.PERCDESCSIMPLESNAC,
                    P.VLSTTAB, P.VLST, P.CODTRIBPISCOFINS, P.PRECOREVISTA, P.DTVALPREVISTA, P.OBS, P.ROTINA, P.MATRICULA,
                    P.PERDESCMAXIDEALTAB, P.PERDESCMAXPOSSIVELTAB, P.PERCCOMGARANTIDATAB, P.PERDESCMAXAVISTATAB,
                    P.PERDESCMAXIDEAL, P.PERCCOMGARANTIDA, P.PERDESCMAXAVISTA, P.PERDESCMAXPOSSIVEL,
                    P.VLIPITAB, P.VLIPI, P.PERCCOM, P.CUSTOPRECIFIC, P.CUSTOPRECIFICTAB, P.VLULTENTMES,
                    P.PTABELASEMIMPOSTO1, P.PTABELASEMIMPOSTO2, P.PTABELASEMIMPOSTO3, P.PTABELASEMIMPOSTO4,
                    P.PTABELASEMIMPOSTO5, P.PTABELASEMIMPOSTO6, P.PTABELASEMIMPOSTO7,
                    P.PVENDASEMIMPOSTO1, P.PVENDASEMIMPOSTO2, P.PVENDASEMIMPOSTO3, P.PVENDASEMIMPOSTO4,
                    P.PVENDASEMIMPOSTO5, P.PVENDASEMIMPOSTO6, P.PVENDASEMIMPOSTO7,
                    P.PTABELAATACSEMIMPOSTO1, P.PTABELAATACSEMIMPOSTO2, P.PTABELAATACSEMIMPOSTO3, P.PTABELAATACSEMIMPOSTO4,
                    P.PTABELAATACSEMIMPOSTO5, P.PTABELAATACSEMIMPOSTO6, P.PTABELAATACSEMIMPOSTO7,
                    P.PVENDAATACSEMIMPOSTO1, P.PVENDAATACSEMIMPOSTO2, P.PVENDAATACSEMIMPOSTO3, P.PVENDAATACSEMIMPOSTO4,
                    P.PVENDAATACSEMIMPOSTO5, P.PVENDAATACSEMIMPOSTO6, P.PVENDAATACSEMIMPOSTO7,
                    P.UTILIZARIOLOG, P.CALCULARIPI, P.PRECOMINIMOTABELA, P.PRECOMINIMOVENDA, P.FORMULA, P.REGPRECIFICADA,
                    P.PRECOMINIMOTABELA_AUX, P.PRECOMINIMOVENDA_AUX, P.VLFCPSTTAB, P.VLFCPST, P.CALCULARFECPSTVENDA,
                    P.VLULTENTCONTSEMSTTAB, P.VLULTENTCONTSEMST, P.REGRAALTERARDESCONTO, P.CODFILIALINTEGRACAO,
                    P.DTALTERC5, P.UTILIZAMULTIPLO,
                    P.VLCBSTAB, P.VLIBSTAB, P.VLISTAB, P.VLCBS, P.VLIBS, P.VLIS,
                    P.CODIGO_CBS, P.CODIGO_IBS, P.CODIGO_IS, P.PRECOCOMIVATAB, P.PRECOCOMIVA
                  FROM ZMIG_PCTABPR_FILA F
                  JOIN PCTABPR P
                    ON P.CODPROD   = F.CODPROD
                   AND P.NUMREGIAO = F.NUMREGIAO
                 WHERE F.LOTE   = i
                   AND F.STATUS IN ('P','E');

                v_linhas := SQL%ROWCOUNT;

                UPDATE ZMIG_PCTABPR_FILA
                   SET STATUS = 'C',
                       DTPROC = SYSDATE,
                       ERRO   = NULL
                 WHERE LOTE   = i
                   AND STATUS IN ('P','E');

                COMMIT;   -- 2PC: fecha a transacao distribuida deste lote

                INSERT INTO ZMIG_PCTABPR_LOG
                     VALUES (i, v_linhas, v_ini, SYSTIMESTAMP,
                             ROUND(EXTRACT(SECOND FROM (SYSTIMESTAMP - v_ini))
                                   + EXTRACT(MINUTE FROM (SYSTIMESTAMP - v_ini))*60, 1),
                             'C', NULL);
                COMMIT;

                v_total := v_total + v_linhas;
                v_ok    := TRUE;

                DBMS_OUTPUT.PUT_LINE('Lote '||i||' OK - '||v_linhas||
                                     ' linhas - acumulado '||v_total);

            EXCEPTION
                WHEN OTHERS THEN
                    ROLLBACK;

                    INSERT INTO ZMIG_PCTABPR_LOG
                         VALUES (i, NULL, v_ini, SYSTIMESTAMP, NULL, 'E',
                                 'tent '||v_tent||': '||SUBSTR(SQLERRM,1,480));
                    COMMIT;

                    DBMS_OUTPUT.PUT_LINE('Lote '||i||' ERRO (tentativa '||v_tent||'): '
                                         ||SUBSTR(SQLERRM,1,200));

                    IF v_tent >= c_max_tentativas THEN
                        UPDATE ZMIG_PCTABPR_FILA
                           SET STATUS = 'E',
                               DTPROC = SYSDATE,
                               ERRO   = SUBSTR(SQLERRM,1,500)
                         WHERE LOTE = i
                           AND STATUS = 'P';
                        COMMIT;
                    ELSE
                        DBMS_LOCK.SLEEP(c_pausa_seg);
                    END IF;
            END;
        END LOOP;

        IF c_pausa_lote > 0 THEN
            DBMS_LOCK.SLEEP(c_pausa_lote);
        END IF;

    END LOOP;

    DBMS_OUTPUT.PUT_LINE('=== FIM. Total inserido nesta execucao: '||v_total||' ===');
END;
/


--==============================================================================
-- PASSO 5 - MONITORAMENTO E CONCILIACAO
--==============================================================================

-- 5.1) Progresso (rodar em OUTRA sessao enquanto o PASSO 4 executa)
SELECT STATUS, COUNT(DISTINCT LOTE) QT_LOTES, COUNT(*) QT_LINHAS
  FROM ZMIG_PCTABPR_FILA
 GROUP BY STATUS;

-- 5.2) Velocidade media e projecao
SELECT COUNT(*) LOTES_OK,
       ROUND(AVG(SEGUNDOS),1) SEG_MEDIO_LOTE,
       ROUND(SUM(QT_LINHAS)/NULLIF(SUM(SEGUNDOS),0),0) LINHAS_POR_SEG
  FROM ZMIG_PCTABPR_LOG
 WHERE STATUS = 'C';

-- 5.3) Lotes com erro e a mensagem
SELECT LOTE, MENSAGEM, DTFIM
  FROM ZMIG_PCTABPR_LOG
 WHERE STATUS = 'E'
 ORDER BY DTFIM DESC;

-- 5.4) Para reprocessar os lotes com erro: basta rodar o PASSO 4 de novo
--      (ele reprocessa STATUS 'P' e 'E'). Se quiser forcar tudo:
-- UPDATE ZMIG_PCTABPR_FILA SET STATUS='P', ERRO=NULL WHERE STATUS='E'; COMMIT;

-- 5.5) Conciliacao final de contagem
SELECT (SELECT COUNT(*) FROM PCTABPR)            QT_LOCAL,
       (SELECT COUNT(*) FROM PCTABPR@DBLCLOUD)   QT_CLOUD
  FROM DUAL;

-- 5.6) Conciliacao de conteudo por amostragem (checksum de campos-chave)
SELECT 'LOCAL' ORIGEM, COUNT(*) QT, SUM(NVL(PTABELA,0)) SOMA_PTABELA,
       SUM(NVL(PVENDA,0)) SOMA_PVENDA
  FROM PCTABPR
UNION ALL
SELECT 'CLOUD', COUNT(*), SUM(NVL(PTABELA,0)), SUM(NVL(PVENDA,0))
  FROM PCTABPR@DBLCLOUD;


--==============================================================================
-- PASSO 6 - LIMPEZA (somente apos conciliacao aprovada)
--==============================================================================
-- DROP TABLE ZMIG_PCTABPR_DEST PURGE;
-- DROP TABLE ZMIG_PCTABPR_FILA PURGE;
-- DROP TABLE ZMIG_PCTABPR_LOG  PURGE;   -- guarde o log se quiser evidencia


--==============================================================================
-- ANEXO A - VARIANTE PARALELA COM DBMS_PARALLEL_EXECUTE
-- Use somente se o lote sequencial estiver lento demais E o destino aguentar
-- gravacao concorrente. Comece com 4 threads e observe o destino.
--==============================================================================
/*
BEGIN
    DBMS_PARALLEL_EXECUTE.CREATE_TASK('ZMIG_PCTABPR');

    DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_NUMBER_COL(
        task_name    => 'ZMIG_PCTABPR',
        table_owner  => USER,
        table_name   => 'ZMIG_PCTABPR_FILA',
        table_column => 'LOTE',
        chunk_size   => 10);          -- 10 lotes por chunk

    DBMS_PARALLEL_EXECUTE.RUN_TASK(
        task_name      => 'ZMIG_PCTABPR',
        sql_stmt       => 'BEGIN PRC_ZMIG_PCTABPR_LOTE(:start_id, :end_id); END;',
        language_flag  => DBMS_SQL.NATIVE,
        parallel_level => 4);
END;
/
-- Obs.: exige encapsular o INSERT do PASSO 4 em uma procedure
--       PRC_ZMIG_PCTABPR_LOTE(p_lote_ini, p_lote_fim) com COMMIT interno.

-- Acompanhamento:
-- SELECT STATUS, COUNT(*) FROM USER_PARALLEL_EXECUTE_CHUNKS
--  WHERE TASK_NAME='ZMIG_PCTABPR' GROUP BY STATUS;
*/


--==============================================================================
-- ANEXO B - AJUSTES DE AMBIENTE QUE EVITAM QUEDA DE LINK
--==============================================================================
/*
1) TNSNAMES / connect string usado pelo DB LINK (na base LOCAL):
   adicionar keepalive para o firewall/NAT nao derrubar a sessao ociosa:

   DBLCLOUD_TNS =
     (DESCRIPTION =
       (ENABLE = BROKEN)                      <-- TCP keepalive
       (ADDRESS = (PROTOCOL=TCP)(HOST=...)(PORT=1521))
       (CONNECT_DATA = (SERVICE_NAME=...))
     )

2) SQLNET.ORA do lado que recebe (destino) - evita corte por inatividade:
   SQLNET.EXPIRE_TIME = 5
   SQLNET.RECV_TIMEOUT e SQLNET.SEND_TIMEOUT: se existirem e forem baixos,
   sao candidatos numero 1 ao seu timeout. Aumentar ou remover.

3) DISTRIBUTED_LOCK_TIMEOUT (default 60s) - causa ORA-02049.
   E parametro estatico: exige ALTER SYSTEM ... SCOPE=SPFILE + restart.
   Com lotes pequenos e commit rapido normalmente nao e mais necessario.

4) UNDO do DESTINO: o INSERT gigante consumia undo no destino ate o commit.
   Com lotes de 5.000 o problema desaparece (ORA-30036 / ORA-01555).

5) Firewall/NAT corporativo: muitos derrubam conexao TCP ociosa em 30 min.
   Como durante um INSERT grande o trafego e continuo, o vilao costuma ser
   mesmo o timeout de sessao/consulta do lado cloud.
*/
