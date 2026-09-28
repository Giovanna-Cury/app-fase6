-- =============================================================================
-- Smart HAS - Fase 6 | 05_views.sql
-- Views de apoio construidas sobre as functions PL/SQL.
-- =============================================================================
-- -----------------------------------------------------------------------------
-- VIEW: painel consolidado por sensor (functions encapsuladas numa view,
-- reutilizavel por relatorios/BI sem duplicar regra de negocio).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_shas_painel_sensor AS
SELECT s.id_sensor,
       s.nome,
       s.tipo,
       s.status,
       s.localizacao,
       u.nome                                 AS responsavel,
       fn_formatar_leitura(s.id_sensor)       AS ultima_leitura,
       fn_calc_conformidade(s.id_sensor, 24)  AS conformidade_24h,
       fn_calc_indice_risco(s.localizacao)    AS indice_risco
  FROM shas_sensor s
  LEFT JOIN shas_usuario u ON u.id_usuario = s.id_responsavel;
