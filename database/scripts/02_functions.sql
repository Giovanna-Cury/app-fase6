-- =============================================================================
-- Smart HAS - Fase 6 | 02_functions.sql
-- Functions PL/SQL reutilizaveis (chamaveis em SELECT, WHERE, ORDER BY, views,
-- procedures e pelo back-end Java via JDBC).
--
-- Catalogo de erros de negocio (RAISE_APPLICATION_ERROR) usado em todo o schema:
--   -20001  Sensor inexistente
--   -20002  Valor de leitura invalido
--   -20003  Parametro invalido (janela de tempo, minutos, localizacao)
--   -20004  Data de referencia invalida
-- O back-end Java traduz esses codigos para HTTP 404 / 422.
--
-- Observacao importante: quando uma function chamada dentro de um SELECT
-- levanta NO_DATA_FOUND, o Oracle devolve NULL silenciosamente. Por isso as
-- functions abaixo convertem NO_DATA_FOUND em um erro de negocio explicito.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- FN_CLASSIFICAR_LEITURA  (regra de negocio / dados formatados de dominio)
-- Classifica um valor medido frente aos limites do sensor.
--   IN  p_valor          valor medido
--   IN  p_limite_alerta  limite de ALERTA (NULL = sem limite)
--   IN  p_limite_critico limite CRITICO  (NULL = sem limite)
--   RETURN 'NORMAL' | 'ALERTA' | 'CRITICA'
-- DETERMINISTIC: mesma entrada => mesma saida (permite cache e uso em indices).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_classificar_leitura (
    p_valor          IN NUMBER,
    p_limite_alerta  IN NUMBER,
    p_limite_critico IN NUMBER
) RETURN VARCHAR2
    DETERMINISTIC
IS
BEGIN
    IF p_valor IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'Valor de leitura nao pode ser nulo.');
    END IF;

    IF p_limite_critico IS NOT NULL AND p_valor >= p_limite_critico THEN
        RETURN 'CRITICA';
    ELSIF p_limite_alerta IS NOT NULL AND p_valor >= p_limite_alerta THEN
        RETURN 'ALERTA';
    END IF;

    RETURN 'NORMAL';
END fn_classificar_leitura;
/

-- -----------------------------------------------------------------------------
-- FN_CALC_CONFORMIDADE  (INDICADOR)
-- Indice de conformidade do sensor: % de leituras NORMAIS numa janela de tempo.
-- E o principal KPI de qualidade operacional do Smart HAS: quanto menor, mais
-- tempo o ponto monitorado passou fora da faixa segura.
--   IN  p_id_sensor  sensor avaliado
--   IN  p_horas      tamanho da janela em horas (padrao 24)
--   IN  p_dt_fim     fim (exclusivo) da janela  (padrao agora)
--   RETURN NUMBER 0..100 com 2 casas | NULL quando nao ha leituras na janela
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_calc_conformidade (
    p_id_sensor IN shas_sensor.id_sensor%TYPE,
    p_horas     IN NUMBER    DEFAULT 24,
    p_dt_fim    IN TIMESTAMP DEFAULT NULL
) RETURN NUMBER
IS
    v_existe   NUMBER;
    v_fim      TIMESTAMP := NVL(p_dt_fim, SYSTIMESTAMP);
    v_total    NUMBER;
    v_normais  NUMBER;
BEGIN
    IF p_horas IS NULL OR p_horas <= 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Janela de tempo deve ser maior que zero (horas).');
    END IF;

    -- Garante que o sensor existe (dispara NO_DATA_FOUND caso contrario).
    SELECT 1
      INTO v_existe
      FROM shas_sensor
     WHERE id_sensor = p_id_sensor;

    SELECT COUNT(*),
           COUNT(CASE WHEN classificacao = 'NORMAL' THEN 1 END)
      INTO v_total, v_normais
      FROM shas_leitura
     WHERE id_sensor  = p_id_sensor
       AND dt_leitura >= v_fim - NUMTODSINTERVAL(p_horas, 'HOUR')
       AND dt_leitura <  v_fim;

    IF v_total = 0 THEN
        RETURN NULL; -- sem dados: indicador indefinido (nao e 0% nem 100%)
    END IF;

    RETURN ROUND(v_normais / v_total * 100, 2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Sensor ' || p_id_sensor || ' nao encontrado.');
END fn_calc_conformidade;
/

-- -----------------------------------------------------------------------------
-- FN_CALC_INDICE_RISCO  (INDICADOR)
-- Indice de risco (0-100) de uma localizacao, combinando:
--   * alertas abertos ponderados por severidade
--       CRITICAL = 40 | HIGH = 25 | MEDIUM = 10 | LOW = 5
--   * sensores degradados no local
--       WARNING = 10 | OFFLINE = 15 (ponto cego no monitoramento)
-- O resultado e limitado a 100. Comparacao de localizacao sem diferenciar
-- maiusculas/minusculas e espacos nas bordas.
--   IN  p_localizacao  nome do local (ex.: 'Marginal Tiete')
--   RETURN NUMBER 0..100
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_calc_indice_risco (
    p_localizacao IN shas_alerta.localizacao%TYPE
) RETURN NUMBER
IS
    c_peso_critical CONSTANT PLS_INTEGER := 40;
    c_peso_high     CONSTANT PLS_INTEGER := 25;
    c_peso_medium   CONSTANT PLS_INTEGER := 10;
    c_peso_low      CONSTANT PLS_INTEGER := 5;
    c_peso_warning  CONSTANT PLS_INTEGER := 10;
    c_peso_offline  CONSTANT PLS_INTEGER := 15;

    v_local        VARCHAR2(150) := UPPER(TRIM(p_localizacao));
    v_pts_alertas  NUMBER := 0;
    v_pts_sensores NUMBER := 0;
BEGIN
    IF v_local IS NULL THEN
        RAISE_APPLICATION_ERROR(-20003, 'Localizacao deve ser informada.');
    END IF;

    SELECT NVL(SUM(CASE severidade
                       WHEN 'CRITICAL' THEN c_peso_critical
                       WHEN 'HIGH'     THEN c_peso_high
                       WHEN 'MEDIUM'   THEN c_peso_medium
                       ELSE c_peso_low
                   END), 0)
      INTO v_pts_alertas
      FROM shas_alerta
     WHERE resolvido = 0
       AND UPPER(TRIM(localizacao)) = v_local;

    SELECT NVL(SUM(CASE status
                       WHEN 'WARNING' THEN c_peso_warning
                       WHEN 'OFFLINE' THEN c_peso_offline
                       ELSE 0
                   END), 0)
      INTO v_pts_sensores
      FROM shas_sensor
     WHERE UPPER(TRIM(localizacao)) = v_local;

    RETURN LEAST(100, v_pts_alertas + v_pts_sensores);
END fn_calc_indice_risco;
/

-- -----------------------------------------------------------------------------
-- FN_FORMATAR_LEITURA  (DADOS FORMATADOS)
-- Devolve a ultima leitura do sensor pronta para exibicao (padrao pt-BR):
--   'Sensor 01 (Temperatura) | 24,50 °C | NORMAL | 27/09/2026 14:30'
-- Usada em relatorios, na view do painel e na API (endpoint de indicadores).
--   IN  p_id_sensor  sensor
--   RETURN VARCHAR2 (texto formatado)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_formatar_leitura (
    p_id_sensor IN shas_sensor.id_sensor%TYPE
) RETURN VARCHAR2
IS
    c_fmt_num   CONSTANT VARCHAR2(20) := 'FM999G999G990D00';
    c_nls_num   CONSTANT VARCHAR2(40) := 'NLS_NUMERIC_CHARACTERS='',.''';

    v_nome      shas_sensor.nome%TYPE;
    v_tipo      shas_sensor.tipo%TYPE;
    v_unidade   shas_sensor.unidade%TYPE;
    v_valor     shas_leitura.valor%TYPE;
    v_class     shas_leitura.classificacao%TYPE;
    v_dt        shas_leitura.dt_leitura%TYPE;
BEGIN
    SELECT nome, tipo, unidade
      INTO v_nome, v_tipo, v_unidade
      FROM shas_sensor
     WHERE id_sensor = p_id_sensor;

    BEGIN
        SELECT valor, classificacao, dt_leitura
          INTO v_valor, v_class, v_dt
          FROM shas_leitura
         WHERE id_sensor = p_id_sensor
         ORDER BY dt_leitura DESC, id_leitura DESC
         FETCH FIRST 1 ROWS ONLY;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN v_nome || ' (' || v_tipo || ') | sem leituras registradas';
    END;

    RETURN v_nome || ' (' || v_tipo || ') | '
        || TO_CHAR(v_valor, c_fmt_num, c_nls_num)
        || CASE WHEN v_unidade IS NOT NULL THEN ' ' || v_unidade END
        || ' | ' || v_class
        || ' | ' || TO_CHAR(v_dt, 'DD/MM/YYYY HH24:MI');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Sensor ' || p_id_sensor || ' nao encontrado.');
END fn_formatar_leitura;
/
