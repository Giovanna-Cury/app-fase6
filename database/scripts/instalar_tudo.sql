-- =============================================================================
-- Smart HAS - Fase 6 | instalar_tudo.sql
-- Instalacao completa do schema (reexecutavel).
--
-- SQL Developer: abra este arquivo e execute como SCRIPT (F5).
--   (Preferences > Environment > Encoding = UTF-8 para acentuacao correta.)
-- SQL*Plus / SQLcl:  @instalar_tudo.sql
-- =============================================================================
SET DEFINE OFF
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

PROMPT >>> 00 - Removendo objetos anteriores
@@00_drop_objetos.sql
PROMPT >>> 01 - Criando tabelas, constraints e indices
@@01_ddl_tabelas.sql
PROMPT >>> 02 - Criando functions
@@02_functions.sql
PROMPT >>> 03 - Criando procedures
@@03_procedures.sql
PROMPT >>> 04 - Carregando dados simulados
@@04_carga_dados.sql
PROMPT >>> 05 - Criando views
@@05_views.sql

PROMPT >>> Recompilando objetos invalidados pelo DDL da carga (ALTER ... IDENTITY)
EXEC DBMS_UTILITY.COMPILE_SCHEMA(schema => USER, compile_all => FALSE);

WHENEVER SQLERROR CONTINUE
PROMPT >>> Objetos invalidos (esperado: nenhuma linha)
SELECT object_type, object_name FROM user_objects WHERE status <> 'VALID';
PROMPT >>> Instalacao concluida. Rode 06_consultas_demo.sql para a demonstracao.
