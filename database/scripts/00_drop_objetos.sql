-- =============================================================================
-- Smart HAS - Fase 6 | 00_drop_objetos.sql
-- Remove (se existirem) todos os objetos do schema Smart HAS, permitindo
-- reexecutar a instalacao do zero. Seguro para rodar em schema vazio.
-- =============================================================================
SET SERVEROUTPUT ON

DECLARE
    -- Lista ordenada: primeiro rotinas, depois tabelas filhas, depois as pais.
    TYPE t_objetos IS TABLE OF VARCHAR2(200);
    v_objetos t_objetos := t_objetos(
        'PROCEDURE PRC_RESUMO_POR_RESPONSAVEL',
        'PROCEDURE PRC_VERIFICAR_SENSORES_INATIVOS',
        'PROCEDURE PRC_GERAR_RELATORIO_DIARIO',
        'PROCEDURE PRC_REGISTRAR_LEITURA',
        'PROCEDURE PRC_REGISTRAR_LOG',
        'FUNCTION FN_FORMATAR_LEITURA',
        'FUNCTION FN_CALC_INDICE_RISCO',
        'FUNCTION FN_CALC_CONFORMIDADE',
        'FUNCTION FN_CLASSIFICAR_LEITURA',
        'VIEW VW_SHAS_PAINEL_SENSOR',
        'TABLE SHAS_LOG_EXECUCAO',
        'TABLE SHAS_RELATORIO_DIARIO',
        'TABLE SHAS_ALERTA',
        'TABLE SHAS_LEITURA',
        'TABLE SHAS_SENSOR',
        'TABLE SHAS_USUARIO'
    );
BEGIN
    FOR i IN 1 .. v_objetos.COUNT LOOP
        BEGIN
            IF v_objetos(i) LIKE 'TABLE %' THEN
                EXECUTE IMMEDIATE 'DROP ' || v_objetos(i) || ' CASCADE CONSTRAINTS PURGE';
            ELSE
                EXECUTE IMMEDIATE 'DROP ' || v_objetos(i);
            END IF;
            DBMS_OUTPUT.PUT_LINE('Removido: ' || v_objetos(i));
        EXCEPTION
            -- ORA-00942 (tabela/view inexistente) e ORA-04043 (objeto inexistente)
            WHEN OTHERS THEN
                IF SQLCODE NOT IN (-942, -4043) THEN
                    RAISE;
                END IF;
        END;
    END LOOP;
END;
/
