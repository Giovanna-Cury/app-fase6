-- =============================================================================
-- Smart HAS - Fase 6 | 07_job_agendado.sql  (OPCIONAL)
-- Automacao 100% no banco com DBMS_SCHEDULER:
--   * JOB_SHAS_WATCHDOG        - a cada 15 min executa PRC_VERIFICAR_SENSORES_INATIVOS
--   * JOB_SHAS_RELATORIO_DIARIO - todo dia 23:55 executa PRC_GERAR_RELATORIO_DIARIO
-- Requer o privilegio CREATE JOB (no Docker local ja e concedido pelo init).
-- =============================================================================
SET SERVEROUTPUT ON

BEGIN
    FOR j IN (SELECT job_name FROM user_scheduler_jobs
               WHERE job_name IN ('JOB_SHAS_WATCHDOG', 'JOB_SHAS_RELATORIO_DIARIO')) LOOP
        DBMS_SCHEDULER.DROP_JOB(j.job_name, force => TRUE);
    END LOOP;

    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_SHAS_WATCHDOG',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'DECLARE v NUMBER; BEGIN prc_verificar_sensores_inativos(60, v); END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=MINUTELY; INTERVAL=15',
        enabled         => TRUE,
        comments        => 'Smart HAS - marca sensores sem comunicacao como OFFLINE');

    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_SHAS_RELATORIO_DIARIO',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'DECLARE v NUMBER; BEGIN prc_gerar_relatorio_diario(TRUNC(SYSDATE), v); END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=23; BYMINUTE=55; BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Smart HAS - consolida o relatorio diario por sensor');

    DBMS_OUTPUT.PUT_LINE('Jobs criados.');
END;
/

SELECT job_name, enabled, state, TO_CHAR(next_run_date, 'DD/MM HH24:MI') AS proxima_execucao
  FROM user_scheduler_jobs
 WHERE job_name LIKE 'JOB_SHAS%';
