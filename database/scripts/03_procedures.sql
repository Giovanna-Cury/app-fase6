-- =============================================================================
-- Smart HAS - Fase 6 | 03_procedures.sql
-- Procedures PL/SQL: rotinas de back-end executadas diretamente no banco.
--
-- Controle transacional (decisao de arquitetura):
--   * PRC_REGISTRAR_LEITURA e ONLINE: NAO faz COMMIT. Quem chama (API Java com
--     @Transactional, ou o script de teste) decide o COMMIT/ROLLBACK, garantindo
--     atomicidade com o restante da requisicao.
--   * PRC_GERAR_RELATORIO_DIARIO e PRC_VERIFICAR_SENSORES_INATIVOS sao BATCH:
--     fazem COMMIT ao final (podem rodar via DBMS_SCHEDULER, sem aplicacao).
--   * PRC_REGISTRAR_LOG usa AUTONOMOUS_TRANSACTION: o log persiste mesmo que a
--     transacao principal sofra ROLLBACK (trilha de auditoria confiavel).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PRC_REGISTRAR_LOG
-- Grava uma linha em SHAS_LOG_EXECUCAO em transacao autonoma.
-- Nunca propaga erro: falha de log nao pode derrubar a rotina de negocio.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_registrar_log (
    p_rotina   IN shas_log_execucao.rotina%TYPE,
    p_nivel    IN shas_log_execucao.nivel%TYPE,
    p_mensagem IN VARCHAR2
)
IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO shas_log_execucao (rotina, nivel, mensagem)
    VALUES (p_rotina, p_nivel, SUBSTR(p_mensagem, 1, 4000));
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END prc_registrar_log;
/

-- -----------------------------------------------------------------------------
-- PRC_REGISTRAR_LEITURA  (acionada pelo back-end Java: REST -> JDBC -> Oracle)
-- Registra uma leitura de sensor e aplica as regras de monitoramento:
--   1. valida o valor e a data da leitura;
--   2. trava o sensor (SELECT ... FOR UPDATE) para serializar leituras
--      concorrentes do mesmo dispositivo;
--   3. classifica a leitura via FN_CLASSIFICAR_LEITURA;
--   4. insere a leitura no historico;
--   5. atualiza valor/status atual do sensor (somente se a leitura for a mais
--      recente - leituras atrasadas entram so no historico);
--   6. se a leitura for ALERTA/CRITICA:
--        - nao existe alerta automatico aberto -> cria um novo;
--        - existe alerta aberto e a leitura e CRITICA -> escalona p/ CRITICAL;
--        - caso contrario reaproveita o aberto (evita "tempestade" de alertas).
-- Parametros:
--   IN  p_id_sensor      sensor que enviou a leitura
--   IN  p_valor          valor medido
--   OUT p_id_leitura     id da leitura gravada
--   OUT p_classificacao  NORMAL | ALERTA | CRITICA
--   OUT p_id_alerta      alerta criado/escalonado/reaproveitado (NULL se NORMAL)
--   IN  p_dt_leitura     momento da medicao (padrao: agora) - permite carga
--                        de historico e ingestao de leituras atrasadas
-- Erros: -20001 sensor inexistente | -20002 valor/data invalidos
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_registrar_leitura (
    p_id_sensor     IN  shas_sensor.id_sensor%TYPE,
    p_valor         IN  shas_leitura.valor%TYPE,
    p_id_leitura    OUT shas_leitura.id_leitura%TYPE,
    p_classificacao OUT shas_leitura.classificacao%TYPE,
    p_id_alerta     OUT shas_alerta.id_alerta%TYPE,
    p_dt_leitura    IN  TIMESTAMP DEFAULT NULL
)
IS
    c_rotina        CONSTANT VARCHAR2(30) := 'PRC_REGISTRAR_LEITURA';
    c_valor_min     CONSTANT NUMBER := -1000;
    c_valor_max     CONSTANT NUMBER := 100000;
    c_fmt_num       CONSTANT VARCHAR2(20) := 'FM999G999G990D00';
    c_nls_num       CONSTANT VARCHAR2(40) := 'NLS_NUMERIC_CHARACTERS='',.''';

    v_dt            TIMESTAMP := NVL(p_dt_leitura, SYSTIMESTAMP);
    v_sensor        shas_sensor%ROWTYPE;
    v_severidade    shas_alerta.severidade%TYPE;
    v_id_aberto     shas_alerta.id_alerta%TYPE;
    v_sev_aberto    shas_alerta.severidade%TYPE;
    v_valor_txt     VARCHAR2(60);

    e_valor_invalido EXCEPTION;
BEGIN
    SAVEPOINT sp_registrar_leitura;
    p_id_alerta := NULL;

    -- 1. Validacoes de entrada
    IF p_valor IS NULL
       OR p_valor NOT BETWEEN c_valor_min AND c_valor_max
       OR v_dt > SYSTIMESTAMP + NUMTODSINTERVAL(5, 'MINUTE') THEN
        RAISE e_valor_invalido;
    END IF;

    -- 2. Sensor (NO_DATA_FOUND se nao existir) com lock de linha
    SELECT *
      INTO v_sensor
      FROM shas_sensor
     WHERE id_sensor = p_id_sensor
       FOR UPDATE;

    -- 3. Classificacao (regra centralizada na function)
    p_classificacao := fn_classificar_leitura(p_valor, v_sensor.limite_alerta, v_sensor.limite_critico);

    -- 4. Historico
    INSERT INTO shas_leitura (id_sensor, valor, classificacao, dt_leitura)
    VALUES (p_id_sensor, p_valor, p_classificacao, v_dt)
    RETURNING id_leitura INTO p_id_leitura;

    -- 5. Estado atual do sensor
    IF v_dt >= v_sensor.dt_atualizacao THEN
        UPDATE shas_sensor
           SET valor_atual    = p_valor,
               status         = CASE p_classificacao WHEN 'NORMAL' THEN 'ONLINE' ELSE 'WARNING' END,
               dt_atualizacao = v_dt
         WHERE id_sensor = p_id_sensor;
    END IF;

    -- 6. Alertas automaticos
    IF p_classificacao <> 'NORMAL' THEN
        v_severidade := CASE p_classificacao WHEN 'CRITICA' THEN 'CRITICAL' ELSE 'MEDIUM' END;
        v_valor_txt  := TO_CHAR(p_valor, c_fmt_num, c_nls_num) || ' ' || v_sensor.unidade;

        BEGIN
            SELECT id_alerta, severidade
              INTO v_id_aberto, v_sev_aberto
              FROM shas_alerta
             WHERE id_sensor = p_id_sensor
               AND resolvido = 0
               AND origem    = 'AUTOMATICO'
             ORDER BY dt_criacao DESC
             FETCH FIRST 1 ROWS ONLY;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_id_aberto := NULL;
        END;

        IF v_id_aberto IS NULL THEN
            INSERT INTO shas_alerta (titulo, descricao, severidade, localizacao,
                                     origem, id_sensor, id_leitura, dt_criacao)
            VALUES (CASE p_classificacao
                        WHEN 'CRITICA' THEN 'Leitura crítica: '
                        ELSE 'Leitura acima do limite: '
                    END || v_sensor.nome || ' (' || v_sensor.tipo || ')',
                    'Sensor registrou ' || v_valor_txt || ' (limite de alerta '
                        || TO_CHAR(v_sensor.limite_alerta, c_fmt_num, c_nls_num)
                        || ', crítico ' || TO_CHAR(v_sensor.limite_critico, c_fmt_num, c_nls_num) || ').',
                    v_severidade, v_sensor.localizacao,
                    'AUTOMATICO', p_id_sensor, p_id_leitura, v_dt)
            RETURNING id_alerta INTO p_id_alerta;

        ELSIF v_severidade = 'CRITICAL' AND v_sev_aberto <> 'CRITICAL' THEN
            UPDATE shas_alerta
               SET severidade = 'CRITICAL',
                   titulo     = 'Leitura crítica: ' || v_sensor.nome || ' (' || v_sensor.tipo || ')',
                   descricao  = SUBSTR(descricao || ' | Escalonado para CRITICAL: '
                                       || v_valor_txt || ' em ' || TO_CHAR(v_dt, 'DD/MM HH24:MI') || '.', 1, 1000),
                   id_leitura = p_id_leitura
             WHERE id_alerta = v_id_aberto;
            p_id_alerta := v_id_aberto;

        ELSE
            p_id_alerta := v_id_aberto;
        END IF;
    END IF;

EXCEPTION
    WHEN e_valor_invalido THEN
        ROLLBACK TO sp_registrar_leitura;
        prc_registrar_log(c_rotina, 'WARN', 'Valor/data invalidos p/ sensor ' || p_id_sensor
                                            || ': ' || NVL(TO_CHAR(p_valor), 'NULL'));
        RAISE_APPLICATION_ERROR(-20002, 'Valor de leitura invalido: informe um numero entre '
                                        || c_valor_min || ' e ' || c_valor_max
                                        || ' e uma data que nao esteja no futuro.');
    WHEN NO_DATA_FOUND THEN
        ROLLBACK TO sp_registrar_leitura;
        prc_registrar_log(c_rotina, 'WARN', 'Sensor inexistente: ' || p_id_sensor);
        RAISE_APPLICATION_ERROR(-20001, 'Sensor ' || p_id_sensor || ' nao encontrado.');
    WHEN OTHERS THEN
        ROLLBACK TO sp_registrar_leitura;
        prc_registrar_log(c_rotina, 'ERROR', 'Sensor ' || p_id_sensor || ': ' || SQLERRM);
        RAISE;
END prc_registrar_leitura;
/

-- -----------------------------------------------------------------------------
-- PRC_GERAR_RELATORIO_DIARIO  (rotina BATCH - relatorio resumido)
-- Consolida, para cada sensor, as leituras de um dia em SHAS_RELATORIO_DIARIO:
-- quantidade, min/media/max, leituras em alerta/criticas, conformidade
-- (FN_CALC_CONFORMIDADE) e um resumo textual pronto para exibicao.
-- Idempotente: reexecutar o mesmo dia atualiza as linhas (MERGE).
-- Tecnicas: CURSOR explicito + FOR LOOP, IF, MERGE, functions, EXCEPTION.
--   IN  p_dt_referencia   dia a consolidar (padrao: hoje)
--   OUT p_qtd_processados quantidade de sensores consolidados
-- Erros: -20004 data futura
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_gerar_relatorio_diario (
    p_dt_referencia   IN  DATE DEFAULT NULL,
    p_qtd_processados OUT NUMBER
)
IS
    c_rotina   CONSTANT VARCHAR2(30) := 'PRC_GERAR_RELATORIO_DIARIO';
    c_fmt_num  CONSTANT VARCHAR2(20) := 'FM999G999G990D00';
    c_nls_num  CONSTANT VARCHAR2(40) := 'NLS_NUMERIC_CHARACTERS='',.''';

    CURSOR c_sensores IS
        SELECT id_sensor, nome, tipo, unidade
          FROM shas_sensor
         ORDER BY id_sensor;

    v_dia      DATE := TRUNC(NVL(p_dt_referencia, SYSDATE));
    v_ini      TIMESTAMP;
    v_fim      TIMESTAMP;
    v_qtd      NUMBER;
    v_alertas  NUMBER;
    v_criticas NUMBER;
    v_min      NUMBER;
    v_med      NUMBER;
    v_max      NUMBER;
    v_conf     NUMBER;
    v_resumo   VARCHAR2(400);
BEGIN
    IF v_dia > TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20004, 'Data de referencia nao pode estar no futuro: '
                                        || TO_CHAR(v_dia, 'DD/MM/YYYY'));
    END IF;

    v_ini := CAST(v_dia AS TIMESTAMP);
    v_fim := CAST(v_dia + 1 AS TIMESTAMP);
    p_qtd_processados := 0;

    FOR r IN c_sensores LOOP
        SELECT COUNT(*),
               COUNT(CASE WHEN classificacao = 'ALERTA'  THEN 1 END),
               COUNT(CASE WHEN classificacao = 'CRITICA' THEN 1 END),
               MIN(valor), ROUND(AVG(valor), 2), MAX(valor)
          INTO v_qtd, v_alertas, v_criticas, v_min, v_med, v_max
          FROM shas_leitura
         WHERE id_sensor  = r.id_sensor
           AND dt_leitura >= v_ini
           AND dt_leitura <  v_fim;

        IF v_qtd = 0 THEN
            v_conf   := NULL;
            v_resumo := r.nome || ': sem leituras em ' || TO_CHAR(v_dia, 'DD/MM/YYYY') || '.';
        ELSE
            v_conf   := fn_calc_conformidade(r.id_sensor, 24, v_fim);
            v_resumo := SUBSTR(r.nome || ' (' || r.tipo || '): ' || v_qtd || ' leituras, média '
                        || TO_CHAR(v_med, c_fmt_num, c_nls_num) || ' ' || r.unidade
                        || ', máx ' || TO_CHAR(v_max, c_fmt_num, c_nls_num) || ' ' || r.unidade
                        || ', ' || v_criticas || ' críticas, conformidade '
                        || TO_CHAR(v_conf, c_fmt_num, c_nls_num) || '%.', 1, 400);
        END IF;

        MERGE INTO shas_relatorio_diario d
        USING (SELECT r.id_sensor AS id_sensor, v_dia AS dt_referencia FROM dual) s
           ON (d.id_sensor = s.id_sensor AND d.dt_referencia = s.dt_referencia)
         WHEN MATCHED THEN UPDATE SET
              d.qtd_leituras = v_qtd,
              d.qtd_alertas  = v_alertas,
              d.qtd_criticas = v_criticas,
              d.valor_minimo = v_min,
              d.valor_medio  = v_med,
              d.valor_maximo = v_max,
              d.conformidade = v_conf,
              d.resumo       = v_resumo,
              d.dt_geracao   = SYSTIMESTAMP
         WHEN NOT MATCHED THEN INSERT
              (id_sensor, dt_referencia, qtd_leituras, qtd_alertas, qtd_criticas,
               valor_minimo, valor_medio, valor_maximo, conformidade, resumo)
              VALUES
              (r.id_sensor, v_dia, v_qtd, v_alertas, v_criticas,
               v_min, v_med, v_max, v_conf, v_resumo);

        p_qtd_processados := p_qtd_processados + 1;
    END LOOP;

    COMMIT;
    prc_registrar_log(c_rotina, 'INFO', 'Relatorio de ' || TO_CHAR(v_dia, 'DD/MM/YYYY')
                                        || ' gerado para ' || p_qtd_processados || ' sensores.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        prc_registrar_log(c_rotina, 'ERROR', TO_CHAR(v_dia, 'DD/MM/YYYY') || ': ' || SQLERRM);
        RAISE;
END prc_gerar_relatorio_diario;
/

-- -----------------------------------------------------------------------------
-- PRC_VERIFICAR_SENSORES_INATIVOS  (rotina BATCH - automacao / watchdog)
-- Marca como OFFLINE os sensores sem comunicacao ha mais de p_minutos e abre
-- um alerta HIGH "Sensor sem comunicação" (sem duplicar alerta ja aberto).
-- Tecnicas: CURSOR explicito parametrizado com OPEN/FETCH/CLOSE, %NOTFOUND,
-- %ISOPEN, FOR UPDATE + WHERE CURRENT OF, IF, EXCEPTION.
--   IN  p_minutos     tolerancia sem leituras (padrao 60)
--   OUT p_qtd_offline sensores marcados como OFFLINE nesta execucao
-- Erros: -20003 parametro invalido
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_verificar_sensores_inativos (
    p_minutos     IN  NUMBER DEFAULT 60,
    p_qtd_offline OUT NUMBER
)
IS
    c_rotina        CONSTANT VARCHAR2(40)  := 'PRC_VERIFICAR_SENSORES_INATIVOS';
    c_titulo_alerta CONSTANT VARCHAR2(40)  := 'Sensor sem comunicação: ';

    CURSOR c_inativos (p_limite TIMESTAMP) IS
        SELECT s.id_sensor, s.nome, s.localizacao, s.dt_atualizacao
          FROM shas_sensor s
         WHERE s.status <> 'OFFLINE'
           AND s.dt_atualizacao < p_limite
           FOR UPDATE OF s.status;

    v_reg     c_inativos%ROWTYPE;
    v_abertos NUMBER;
BEGIN
    IF p_minutos IS NULL OR p_minutos <= 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Tolerancia deve ser maior que zero (minutos).');
    END IF;

    p_qtd_offline := 0;
    OPEN c_inativos(SYSTIMESTAMP - NUMTODSINTERVAL(p_minutos, 'MINUTE'));
    LOOP
        FETCH c_inativos INTO v_reg;
        EXIT WHEN c_inativos%NOTFOUND;

        UPDATE shas_sensor
           SET status = 'OFFLINE'
         WHERE CURRENT OF c_inativos;

        SELECT COUNT(*)
          INTO v_abertos
          FROM shas_alerta
         WHERE id_sensor = v_reg.id_sensor
           AND resolvido = 0
           AND titulo LIKE c_titulo_alerta || '%';

        IF v_abertos = 0 THEN
            INSERT INTO shas_alerta (titulo, descricao, severidade, localizacao, origem, id_sensor)
            VALUES (c_titulo_alerta || v_reg.nome,
                    'Última leitura em ' || TO_CHAR(v_reg.dt_atualizacao, 'DD/MM/YYYY HH24:MI')
                        || ' (tolerância de ' || p_minutos || ' min excedida).',
                    'HIGH', v_reg.localizacao, 'AUTOMATICO', v_reg.id_sensor);
        END IF;

        p_qtd_offline := p_qtd_offline + 1;
    END LOOP;
    CLOSE c_inativos;

    COMMIT;
    prc_registrar_log(c_rotina, 'INFO', p_qtd_offline || ' sensor(es) marcados como OFFLINE (tolerancia '
                                        || p_minutos || ' min).');
EXCEPTION
    WHEN OTHERS THEN
        IF c_inativos%ISOPEN THEN
            CLOSE c_inativos;
        END IF;
        ROLLBACK;
        prc_registrar_log(c_rotina, 'ERROR', SQLERRM);
        RAISE;
END prc_verificar_sensores_inativos;
/

-- -----------------------------------------------------------------------------
-- PRC_RESUMO_POR_RESPONSAVEL  (relatorio resumido por usuario)
-- Devolve, via SYS_REFCURSOR, o resumo operacional de cada usuario
-- responsavel: sensores sob sua gestao, sensores em atencao, volume de
-- leituras e leituras criticas na janela, alertas abertos e conformidade media
-- (FN_CALC_CONFORMIDADE). Consumida pela API Java (GET /api/reports/responsibles).
--   IN  p_horas   janela de analise em horas (padrao 24)
--   OUT p_cursor  cursor com o resultado (lido pelo JDBC como ResultSet)
-- Erros: -20003 parametro invalido
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_resumo_por_responsavel (
    p_horas  IN  NUMBER DEFAULT 24,
    p_cursor OUT SYS_REFCURSOR
)
IS
    v_inicio TIMESTAMP;
BEGIN
    IF p_horas IS NULL OR p_horas <= 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Janela de tempo deve ser maior que zero (horas).');
    END IF;

    v_inicio := SYSTIMESTAMP - NUMTODSINTERVAL(p_horas, 'HOUR');

    OPEN p_cursor FOR
        SELECT u.id_usuario,
               u.nome,
               u.perfil,
               (SELECT COUNT(*)
                  FROM shas_sensor s
                 WHERE s.id_responsavel = u.id_usuario)                          AS qtd_sensores,
               (SELECT COUNT(*)
                  FROM shas_sensor s
                 WHERE s.id_responsavel = u.id_usuario
                   AND s.status <> 'ONLINE')                                     AS qtd_sensores_atencao,
               (SELECT COUNT(*)
                  FROM shas_leitura l
                  JOIN shas_sensor s ON s.id_sensor = l.id_sensor
                 WHERE s.id_responsavel = u.id_usuario
                   AND l.dt_leitura >= v_inicio)                                 AS qtd_leituras,
               (SELECT COUNT(*)
                  FROM shas_leitura l
                  JOIN shas_sensor s ON s.id_sensor = l.id_sensor
                 WHERE s.id_responsavel = u.id_usuario
                   AND l.classificacao = 'CRITICA'
                   AND l.dt_leitura >= v_inicio)                                 AS qtd_criticas,
               (SELECT COUNT(*)
                  FROM shas_alerta a
                  JOIN shas_sensor s ON s.id_sensor = a.id_sensor
                 WHERE s.id_responsavel = u.id_usuario
                   AND a.resolvido = 0)                                          AS alertas_abertos,
               (SELECT ROUND(AVG(fn_calc_conformidade(s.id_sensor, p_horas)), 2)
                  FROM shas_sensor s
                 WHERE s.id_responsavel = u.id_usuario)                          AS conformidade_media
          FROM shas_usuario u
         ORDER BY alertas_abertos DESC, qtd_sensores DESC, u.nome;
EXCEPTION
    WHEN OTHERS THEN
        prc_registrar_log('PRC_RESUMO_POR_RESPONSAVEL', 'ERROR', SQLERRM);
        RAISE;
END prc_resumo_por_responsavel;
/
