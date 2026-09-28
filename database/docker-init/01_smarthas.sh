#!/bin/bash
# Executado automaticamente pelo container gvenzl/oracle-free na PRIMEIRA
# inicializacao: concede CREATE JOB ao usuario da aplicacao e instala o schema.
set -e
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8

sqlplus -s / as sysdba <<SQL
ALTER SESSION SET CONTAINER = FREEPDB1;
GRANT CREATE JOB, CREATE VIEW TO ${APP_USER};
EXIT
SQL

cd /opt/smarthas/scripts
sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/FREEPDB1" <<SQL
@instalar_tudo.sql
@07_job_agendado.sql
EXIT
SQL
