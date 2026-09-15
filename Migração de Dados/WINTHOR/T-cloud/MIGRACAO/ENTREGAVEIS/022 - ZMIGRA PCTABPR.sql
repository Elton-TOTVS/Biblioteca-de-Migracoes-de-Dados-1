DECLARE
    V_LINHAS_LOTE  PLS_INTEGER := 0;
    V_TOTAL         PLS_INTEGER := 0;
    V_TENTATIVA     PLS_INTEGER := 0;
    V_MAX_TENTATIVAS CONSTANT PLS_INTEGER := 10;
BEGIN
    LOOP
        V_TENTATIVA := 0;

        LOOP
            BEGIN
                EXECUTE IMMEDIATE q'~
                    INSERT INTO PCTABPR@DBLCLOUD (
                        CODPROD, NUMREGIAO, PTABELA, PVENDA, PERDESCMAX, PERDESCMAXTAB,
	                POFERTA, POFERTATAB, MARGEM, DTULTALTPVENDA, EXCLUIDO,
	                PTABELA1, PTABELA2, PTABELA3, PTABELA4, PTABELA5, PTABELA6, PTABELA7,
	                PVENDA1, PVENDA2, PVENDA3, PVENDA4, PVENDA5, PVENDA6, PVENDA7,
	                CODST, MARGEM_ESP, PFRETE, TABELAEMITIDA, PERDESCMAXESP, PERDESCAUTOR,
	                COTAITEM, QTDESCAUTOR, POFERTAAUX, PERDESCAUTORTAB, COTAITEMTAB,
	                QTDESCAUTORTAB, PERDESCMAXBALCAO, PERDESCMAXTABBALCAO, PERDESCFOB,
	                PTABELAMED, PVENDAMED,
	                PTABELAMED1, PTABELAMED2, PTABELAMED3, PTABELAMED4,
	                PTABELAMED5, PTABELAMED6, PTABELAMED7,
	                PVENDAMED1, PVENDAMED2, PVENDAMED3, PVENDAMED4,
                        PVENDAMED5, PVENDAMED6, PVENDAMED7,
                        DESCONTAFRETE, DTINICIOPTABELA, PTABELAFUTURO,
                        DTULTALTPTABELAFUTURO, DTULTALTPTABELA,
                        PCOMREP1, PCOMREP2, PCOMREP3, PERCACRESCIMOFRETE,
                        DTEMISSAOETIQ, NUMSEQATU, PRECOFAB, ATUALIZAR,
                        PTABELAATAC, PTABELAATAC1, PTABELAATAC2, PTABELAATAC3,
                        PTABELAATAC4, PTABELAATAC5, PTABELAATAC6, PTABELAATAC7,
                        PVENDAATAC, PVENDAATAC1, PVENDAATAC2, PVENDAATAC3,
                        PVENDAATAC4, PVENDAATAC5, PVENDAATAC6, PVENDAATAC7,
                        PRECOANTERIORATAC, VLACRESFRETEKG, DTINICIOVALIDADE,
                        DTFIMVALIDADE, INDICEPRECO, DTIMPORTINTEGRACAO,
                        PERCIPIVENDATAB, VLPAUTAIPIVENDATAB, VLIPIPORKGVENDATAB,
                        PRECOMAXCONSUM, DTULTATUPVENDA, DTULTALTERSRVPRC,
                        PRECOMAXCONSUMTAB, PERCDESCSIMPLESNAC,
                        VLSTTAB, VLST, CODTRIBPISCOFINS, PRECOREVISTA,
                        DTVALPREVISTA, OBS, ROTINA, MATRICULA,
                        PERDESCMAXIDEALTAB, PERDESCMAXPOSSIVELTAB,
                        PERCCOMGARANTIDATAB, PERDESCMAXAVISTATAB,
                        PERDESCMAXIDEAL, PERCCOMGARANTIDA,
                        PERDESCMAXAVISTA, PERDESCMAXPOSSIVEL,
                        VLIPITAB, VLIPI, PERCCOM, CUSTOPRECIFIC,
                        CUSTOPRECIFICTAB, VLULTENTMES,
                        PTABELASEMIMPOSTO1, PTABELASEMIMPOSTO2,
                        PTABELASEMIMPOSTO3, PTABELASEMIMPOSTO4,
                        PTABELASEMIMPOSTO5, PTABELASEMIMPOSTO6,
                        PTABELASEMIMPOSTO7,
                        PVENDASEMIMPOSTO1, PVENDASEMIMPOSTO2,
                        PVENDASEMIMPOSTO3, PVENDASEMIMPOSTO4,
                        PVENDASEMIMPOSTO5, PVENDASEMIMPOSTO6,
                        PVENDASEMIMPOSTO7,
                        PTABELAATACSEMIMPOSTO1, PTABELAATACSEMIMPOSTO2,
                        PTABELAATACSEMIMPOSTO3, PTABELAATACSEMIMPOSTO4,
                        PTABELAATACSEMIMPOSTO5, PTABELAATACSEMIMPOSTO6,
                        PTABELAATACSEMIMPOSTO7,
                        PVENDAATACSEMIMPOSTO1, PVENDAATACSEMIMPOSTO2,
                        PVENDAATACSEMIMPOSTO3, PVENDAATACSEMIMPOSTO4,
                        PVENDAATACSEMIMPOSTO5, PVENDAATACSEMIMPOSTO6,
                        PVENDAATACSEMIMPOSTO7,
                        UTILIZARIOLOG, CALCULARIPI, PRECOMINIMOTABELA,
                        PRECOMINIMOVENDA, FORMULA, REGPRECIFICADA,
                        PRECOMINIMOTABELA_AUX, PRECOMINIMOVENDA_AUX,
                        VLFCPSTTAB, VLFCPST, CALCULARFECPSTVENDA,
                        VLULTENTCONTSEMSTTAB, VLULTENTCONTSEMST,
                        REGRAALTERARDESCONTO, CODFILIALINTEGRACAO,
                        DTALTERC5, UTILIZAMULTIPLO,
                        VLCBSTAB, VLIBSTAB, VLISTAB,
                        VLCBS, VLIBS, VLIS,
                        CODIGO_CBS, CODIGO_IBS, CODIGO_IS,
                        PRECOCOMIVATAB, PRECOCOMIVA
                        )
                        SELECT
                            P.CODPROD, P.NUMREGIAO, P.PTABELA, P.PVENDA,
                        P.PERDESCMAX, P.PERDESCMAXTAB,
                        P.POFERTA, P.POFERTATAB, P.MARGEM,
                        P.DTULTALTPVENDA, P.EXCLUIDO,
                        P.PTABELA1, P.PTABELA2, P.PTABELA3, P.PTABELA4,
                        P.PTABELA5, P.PTABELA6, P.PTABELA7,
                        P.PVENDA1, P.PVENDA2, P.PVENDA3, P.PVENDA4,
                        P.PVENDA5, P.PVENDA6, P.PVENDA7,
                        P.CODST, P.MARGEM_ESP, P.PFRETE, P.TABELAEMITIDA,
                        P.PERDESCMAXESP, P.PERDESCAUTOR,
                        P.COTAITEM, P.QTDESCAUTOR, P.POFERTAAUX,
                        P.PERDESCAUTORTAB, P.COTAITEMTAB,
                        P.QTDESCAUTORTAB, P.PERDESCMAXBALCAO,
                        P.PERDESCMAXTABBALCAO, P.PERDESCFOB,
                        P.PTABELAMED, P.PVENDAMED,
                        P.PTABELAMED1, P.PTABELAMED2, P.PTABELAMED3,
                        P.PTABELAMED4, P.PTABELAMED5, P.PTABELAMED6,
                        P.PTABELAMED7,
                        P.PVENDAMED1, P.PVENDAMED2, P.PVENDAMED3,
                        P.PVENDAMED4, P.PVENDAMED5, P.PVENDAMED6,
                        P.PVENDAMED7,
                        P.DESCONTAFRETE, P.DTINICIOPTABELA, P.PTABELAFUTURO,
                        P.DTULTALTPTABELAFUTURO, P.DTULTALTPTABELA,
                        P.PCOMREP1, P.PCOMREP2, P.PCOMREP3,
                        P.PERCACRESCIMOFRETE, P.DTEMISSAOETIQ,
                        P.NUMSEQATU, P.PRECOFAB, P.ATUALIZAR,
                        P.PTABELAATAC, P.PTABELAATAC1, P.PTABELAATAC2,
                        P.PTABELAATAC3, P.PTABELAATAC4, P.PTABELAATAC5,
                        P.PTABELAATAC6, P.PTABELAATAC7,
                        P.PVENDAATAC, P.PVENDAATAC1, P.PVENDAATAC2,
                        P.PVENDAATAC3, P.PVENDAATAC4, P.PVENDAATAC5,
                        P.PVENDAATAC6, P.PVENDAATAC7,
                        P.PRECOANTERIORATAC, P.VLACRESFRETEKG,
                        P.DTINICIOVALIDADE, P.DTFIMVALIDADE, P.INDICEPRECO,
                        P.DTIMPORTINTEGRACAO, P.PERCIPIVENDATAB,
                        P.VLPAUTAIPIVENDATAB, P.VLIPIPORKGVENDATAB,
                        P.PRECOMAXCONSUM, P.DTULTATUPVENDA,
                        P.DTULTALTERSRVPRC, P.PRECOMAXCONSUMTAB,
                        P.PERCDESCSIMPLESNAC,
                        P.VLSTTAB, P.VLST, P.CODTRIBPISCOFINS,
                        P.PRECOREVISTA, P.DTVALPREVISTA,
                        P.OBS, P.ROTINA, P.MATRICULA,
                        P.PERDESCMAXIDEALTAB, P.PERDESCMAXPOSSIVELTAB,
                        P.PERCCOMGARANTIDATAB, P.PERDESCMAXAVISTATAB,
                        P.PERDESCMAXIDEAL, P.PERCCOMGARANTIDA,
                        P.PERDESCMAXAVISTA, P.PERDESCMAXPOSSIVEL,
                        P.VLIPITAB, P.VLIPI, P.PERCCOM,
                        P.CUSTOPRECIFIC, P.CUSTOPRECIFICTAB, P.VLULTENTMES,
                        P.PTABELASEMIMPOSTO1, P.PTABELASEMIMPOSTO2,
                        P.PTABELASEMIMPOSTO3, P.PTABELASEMIMPOSTO4,
                        P.PTABELASEMIMPOSTO5, P.PTABELASEMIMPOSTO6,
                        P.PTABELASEMIMPOSTO7,
                        P.PVENDASEMIMPOSTO1, P.PVENDASEMIMPOSTO2,
                        P.PVENDASEMIMPOSTO3, P.PVENDASEMIMPOSTO4,
                        P.PVENDASEMIMPOSTO5, P.PVENDASEMIMPOSTO6,
                        P.PVENDASEMIMPOSTO7,
                        P.PTABELAATACSEMIMPOSTO1,
                        P.PTABELAATACSEMIMPOSTO2,
                        P.PTABELAATACSEMIMPOSTO3,
                        P.PTABELAATACSEMIMPOSTO4,
                        P.PTABELAATACSEMIMPOSTO5,
                        P.PTABELAATACSEMIMPOSTO6,
                        P.PTABELAATACSEMIMPOSTO7,
                        P.PVENDAATACSEMIMPOSTO1,
                        P.PVENDAATACSEMIMPOSTO2,
                        P.PVENDAATACSEMIMPOSTO3,
                        P.PVENDAATACSEMIMPOSTO4,
                        P.PVENDAATACSEMIMPOSTO5,
                        P.PVENDAATACSEMIMPOSTO6,
                        P.PVENDAATACSEMIMPOSTO7,
                        P.UTILIZARIOLOG, P.CALCULARIPI,
                        P.PRECOMINIMOTABELA, P.PRECOMINIMOVENDA,
                        P.FORMULA, P.REGPRECIFICADA,
                        P.PRECOMINIMOTABELA_AUX,
                        P.PRECOMINIMOVENDA_AUX,
                        P.VLFCPSTTAB, P.VLFCPST,
                        P.CALCULARFECPSTVENDA,
                        P.VLULTENTCONTSEMSTTAB,
                        P.VLULTENTCONTSEMST,
                        P.REGRAALTERARDESCONTO,
                        P.CODFILIALINTEGRACAO,
                        P.DTALTERC5, P.UTILIZAMULTIPLO,
                        P.VLCBSTAB, P.VLIBSTAB, P.VLISTAB,
                        P.VLCBS, P.VLIBS, P.VLIS,
                        P.CODIGO_CBS, P.CODIGO_IBS, P.CODIGO_IS,
                        P.PRECOCOMIVATAB, P.PRECOCOMIVA
                        FROM PCTABPR P
                        WHERE NOT EXISTS (
                            SELECT 1
                            FROM PCTABPR@DBLCLOUD D
                            WHERE D.CODPROD   = P.CODPROD
                            AND D.NUMREGIAO = P.NUMREGIAO
                        )
                        AND ROWNUM <= 1000
                ~';

                V_LINHAS_LOTE := SQL%ROWCOUNT;

                -- Finaliza imediatamente a transação distribuída do lote.
                COMMIT;

                EXIT;

            EXCEPTION
                WHEN OTHERS THEN
                    IF SQLCODE = -2049 THEN
                        -- Desfaz somente o lote atual.
                        ROLLBACK;

                        V_TENTATIVA := V_TENTATIVA + 1;

                        DBMS_OUTPUT.PUT_LINE(
                            'Lote bloqueado. Tentativa ' ||
                            V_TENTATIVA || ' de ' ||
                            V_MAX_TENTATIVAS
                        );

                        IF V_TENTATIVA >= V_MAX_TENTATIVAS THEN
                            DBMS_OUTPUT.PUT_LINE(
                                'Limite de tentativas atingido.'
                            );
                            RAISE;
                        END IF;

                        /*
                            Não há SLEEP aqui.
                            O próprio ORA-02049 já ocorreu depois do
                            tempo de espera configurado no Oracle.
                            O LOOP refaz a tentativa automaticamente.
                        */
                    ELSE
                        ROLLBACK;
                        RAISE;
                    END IF;
            END;
        END LOOP;

        EXIT WHEN V_LINHAS_LOTE = 0;

        V_TOTAL := V_TOTAL + V_LINHAS_LOTE;

        DBMS_OUTPUT.PUT_LINE(
            'Inseridos no lote: ' || V_LINHAS_LOTE ||
            ' | Total inserido: ' || V_TOTAL
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(
        'Processamento concluído. Total inserido: ' || V_TOTAL
    );

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        DBMS_OUTPUT.PUT_LINE(
            'Processamento interrompido: ' || SQLERRM
        );

        RAISE;
END;
/