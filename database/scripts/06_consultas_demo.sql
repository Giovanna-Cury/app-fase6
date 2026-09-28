-- =============================================================================
-- Smart HAS - Fase 6 | 06_consultas_demo.sql
-- Consultas que demonstram o USO PRATICO das functions e
-- procedures (SELECT, WHERE, ORDER BY, GROUP BY, blocos anonimos, ref cursor).
-- =============================================================================
SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 100
COLUMN nome            FORMAT A10
COLUMN tipo            FORMAT A16
COLUMN localizacao     FORMAT A24
COLUMN ultima_leitura  FORMAT A68
COLUMN responsavel     FORMAT A16
COLUMN resumo          FORMAT A110
COLUMN rotina          FORMAT A32
COLUMN mensagem        FORMAT A90

-- =============================================================================
-- CONSULTA 1 - Painel geral (functions no SELECT via view)
-- =============================================================================
SELECT id_sensor, status, ultima_leitura, conformidade_24h, indice_risco, responsavel
  FROM vw_shas_painel_sensor
 ORDER BY indice_risco DESC, conformidade_24h;

-- =============================================================================
-- CONSULTA 2 - Function no WHERE: sensores com conformidade < 95% nas ultimas
-- 24h (candidatos a inspecao/calibracao)
-- =============================================================================
SELECT s.nome, s.tipo, s.localizacao,
       fn_calc_conformidade(s.id_sensor, 24) AS conformidade_24h
  FROM shas_sensor s
 WHERE fn_calc_conformidade(s.id_sensor, 24) < 95
 ORDER BY conformidade_24h;

-- =============================================================================
-- CONSULTA 3 - Ranking de risco por localizacao (function no ORDER BY)
-- =============================================================================
SELECT localizacao,
       fn_calc_indice_risco(localizacao) AS indice_risco,
       CASE
           WHEN fn_calc_indice_risco(localizacao) >= 50 THEN 'ALTO'
           WHEN fn_calc_indice_risco(localizacao) >= 20 THEN 'MODERADO'
           ELSE 'BAIXO'
       END AS nivel
  FROM (SELECT DISTINCT localizacao FROM shas_sensor)
 ORDER BY fn_calc_indice_risco(localizacao) DESC;

-- =============================================================================
-- CONSULTA 4 - Conformidade semanal x diaria (mesma function, janelas distintas)
-- =============================================================================
SELECT s.nome, s.tipo,
       fn_calc_conformidade(s.id_sensor, 24)     AS conf_24h,
       fn_calc_conformidade(s.id_sensor, 24 * 7) AS conf_7d,
       ROUND(fn_calc_conformidade(s.id_sensor, 24)
             - fn_calc_conformidade(s.id_sensor, 24 * 7), 2) AS tendencia
  FROM shas_sensor s
 ORDER BY tendencia NULLS LAST;

-- =============================================================================
-- CONSULTA 5 - Classificacao "what-if": como leituras hipoteticas seriam
-- classificadas pelos limites de cada tipo de sensor (function pura)
-- =============================================================================
SELECT s.tipo, v.valor,
       fn_classificar_leitura(v.valor, s.limite_alerta, s.limite_critico) AS classificacao
  FROM (SELECT DISTINCT tipo, limite_alerta, limite_critico FROM shas_sensor) s
 CROSS JOIN (SELECT 25 AS valor FROM dual UNION ALL
             SELECT 80        FROM dual UNION ALL
             SELECT 95        FROM dual) v
 ORDER BY s.tipo, v.valor;

-- =============================================================================
-- CONSULTA 6 - Distribuicao das leituras por sensor e classificacao (7 dias)
-- =============================================================================
SELECT s.nome, l.classificacao, COUNT(*) AS qtd,
       ROUND(RATIO_TO_REPORT(COUNT(*)) OVER (PARTITION BY s.nome) * 100, 1) AS pct
  FROM shas_leitura l
  JOIN shas_sensor s ON s.id_sensor = l.id_sensor
 GROUP BY s.nome, l.classificacao
 ORDER BY s.nome, l.classificacao;

-- =============================================================================
-- CONSULTA 7 - Relatorio diario gerado pela procedure batch (ultimos 3 dias)
-- =============================================================================
SELECT TO_CHAR(r.dt_referencia, 'DD/MM') AS dia, r.resumo
  FROM shas_relatorio_diario r
 WHERE r.dt_referencia >= TRUNC(SYSDATE) - 2
 ORDER BY r.dt_referencia DESC, r.id_sensor;

-- =============================================================================
-- BLOCO 1 - PRC_REGISTRAR_LEITURA: leitura normal, critica e tratamento de erros
-- =============================================================================
DECLARE
    v_id_leitura shas_leitura.id_leitura%TYPE;
    v_class      shas_leitura.classificacao%TYPE;
    v_id_alerta  shas_alerta.id_alerta%TYPE;
BEGIN
    prc_registrar_leitura(1, 26.30, v_id_leitura, v_class, v_id_alerta);
    DBMS_OUTPUT.PUT_LINE('Leitura ' || v_id_leitura || ' => ' || v_class
                         || ' | alerta: ' || NVL(TO_CHAR(v_id_alerta), '-'));

    prc_registrar_leitura(1, 37.80, v_id_leitura, v_class, v_id_alerta);
    DBMS_OUTPUT.PUT_LINE('Leitura ' || v_id_leitura || ' => ' || v_class
                         || ' | alerta: ' || NVL(TO_CHAR(v_id_alerta), '-'));
    DBMS_OUTPUT.PUT_LINE('Formatado: ' || fn_formatar_leitura(1));
    COMMIT;

    -- Erro de negocio 1: sensor inexistente (ORA-20001)
    BEGIN
        prc_registrar_leitura(999, 10, v_id_leitura, v_class, v_id_alerta);
    EXCEPTION
        WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Esperado -> ' || SQLERRM);
    END;

    -- Erro de negocio 2: valor fora da faixa suportada (ORA-20002)
    BEGIN
        prc_registrar_leitura(1, 999999, v_id_leitura, v_class, v_id_alerta);
    EXCEPTION
        WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Esperado -> ' || SQLERRM);
    END;
END;
/

-- =============================================================================
-- BLOCO 2 - PRC_RESUMO_POR_RESPONSAVEL: consumindo o SYS_REFCURSOR com LOOP
-- =============================================================================
DECLARE
    v_cursor     SYS_REFCURSOR;
    v_id         shas_usuario.id_usuario%TYPE;
    v_nome       shas_usuario.nome%TYPE;
    v_perfil     shas_usuario.perfil%TYPE;
    v_sensores   NUMBER;
    v_atencao    NUMBER;
    v_leituras   NUMBER;
    v_criticas   NUMBER;
    v_abertos    NUMBER;
    v_conf       NUMBER;
BEGIN
    prc_resumo_por_responsavel(24, v_cursor);
    DBMS_OUTPUT.PUT_LINE(RPAD('Responsavel', 18) || RPAD('Sensores', 10) || RPAD('Atencao', 9)
                         || RPAD('Leituras', 10) || RPAD('Criticas', 10) || RPAD('Abertos', 9) || 'Conf.%');
    LOOP
        FETCH v_cursor INTO v_id, v_nome, v_perfil, v_sensores, v_atencao,
                            v_leituras, v_criticas, v_abertos, v_conf;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(RPAD(v_nome, 18) || RPAD(v_sensores, 10) || RPAD(v_atencao, 9)
                             || RPAD(v_leituras, 10) || RPAD(v_criticas, 10) || RPAD(v_abertos, 9)
                             || NVL(TO_CHAR(v_conf), '-'));
    END LOOP;
    CLOSE v_cursor;
END;
/

-- =============================================================================
-- BLOCO 3 - Rotinas batch (relatorio de hoje + watchdog)
-- =============================================================================
DECLARE
    v_qtd NUMBER;
BEGIN
    prc_gerar_relatorio_diario(TRUNC(SYSDATE), v_qtd);
    DBMS_OUTPUT.PUT_LINE('Relatorio de hoje: ' || v_qtd || ' sensores consolidados.');

    prc_verificar_sensores_inativos(60, v_qtd);
    DBMS_OUTPUT.PUT_LINE('Watchdog: ' || v_qtd || ' sensor(es) marcados OFFLINE.');

    BEGIN
        prc_gerar_relatorio_diario(TRUNC(SYSDATE) + 1, v_qtd);
    EXCEPTION
        WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Esperado -> ' || SQLERRM);
    END;
END;
/

-- =============================================================================
-- CONSULTA 8 - Alertas abertos (manuais x gerados pelo PL/SQL)
-- =============================================================================
SELECT a.id_alerta, a.severidade, a.origem, SUBSTR(a.titulo, 1, 50) AS titulo,
       TO_CHAR(a.dt_criacao, 'DD/MM HH24:MI') AS criado_em
  FROM shas_alerta a
 WHERE a.resolvido = 0
 ORDER BY DECODE(a.severidade, 'CRITICAL', 1, 'HIGH', 2, 'MEDIUM', 3, 4), a.dt_criacao DESC;

-- =============================================================================
-- CONSULTA 9 - Trilha de auditoria das rotinas (log autonomo)
-- =============================================================================
SELECT TO_CHAR(dt_log, 'DD/MM HH24:MI:SS') AS quando, rotina, nivel, mensagem
  FROM shas_log_execucao
 ORDER BY id_log DESC
 FETCH FIRST 12 ROWS ONLY;
