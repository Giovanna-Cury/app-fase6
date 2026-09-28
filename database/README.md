# Smart HAS — Camada Oracle PL/SQL (Fase 6)

Modelo relacional, carga de dados simulados, **functions** e **procedures** PL/SQL
que concentram a inteligência de monitoramento do Smart HAS. O back-end Java
consome estas rotinas via JDBC (perfil Spring `oracle`).

## Estrutura

| Script | Conteúdo |
|--------|----------|
| `scripts/instalar_tudo.sql` | Instalador (roda 00→05, recompila e lista objetos inválidos) |
| `scripts/00_drop_objetos.sql` | Remove os objetos (reexecução segura) |
| `scripts/01_ddl_tabelas.sql` | 6 tabelas, PK/FK/UK/CHECK nomeadas, índices e comentários |
| `scripts/02_functions.sql` | 4 functions |
| `scripts/03_procedures.sql` | 5 procedures |
| `scripts/04_carga_dados.sql` | Carga simulada (3 usuários, 8 sensores, ~2.700 leituras, alertas, relatórios) |
| `scripts/05_views.sql` | `VW_SHAS_PAINEL_SENSOR` (functions encapsuladas numa view) |
| `scripts/06_consultas_demo.sql` | Demonstração: functions em SELECT/WHERE/ORDER BY, chamadas das procedures, erros tratados |
| `scripts/07_job_agendado.sql` | (Opcional) `DBMS_SCHEDULER`: watchdog a cada 15 min + relatório diário 23:55 |
| `evidencias/` | Saída real da execução dos scripts no Oracle 23ai |

## Objetos PL/SQL

| Objeto | Tipo | Propósito |
|--------|------|-----------|
| `FN_CLASSIFICAR_LEITURA` | function (DETERMINISTIC) | NORMAL / ALERTA / CRITICA frente aos limites do sensor |
| `FN_CALC_CONFORMIDADE` | function — **indicador** | % de leituras normais numa janela (24h, 7d...) |
| `FN_CALC_INDICE_RISCO` | function — **indicador** | Risco 0–100 do local (alertas abertos ponderados + sensores degradados) |
| `FN_FORMATAR_LEITURA` | function — **dados formatados** | `Sensor 01 (Temperatura) \| 24,50 °C \| NORMAL \| 27/09/2026 14:30` |
| `PRC_REGISTRAR_LEITURA` | procedure — **online, chamada pelo Java** | Grava leitura, atualiza sensor, cria/escalona alerta automático |
| `PRC_GERAR_RELATORIO_DIARIO` | procedure — batch | Consolida o dia por sensor (CURSOR + LOOP + MERGE) |
| `PRC_VERIFICAR_SENSORES_INATIVOS` | procedure — batch | Watchdog: OFFLINE + alerta (OPEN/FETCH/CLOSE, `WHERE CURRENT OF`) |
| `PRC_RESUMO_POR_RESPONSAVEL` | procedure | Resumo por usuário via `SYS_REFCURSOR` |
| `PRC_REGISTRAR_LOG` | procedure | Log de auditoria em `AUTONOMOUS_TRANSACTION` |

Erros de negócio: `-20001` sensor inexistente · `-20002` valor inválido ·
`-20003` parâmetro inválido · `-20004` data inválida (a API devolve 404/422).

## Opção A — Oracle local com Docker (recomendado)

```bash
cd database
docker compose up -d
docker compose logs -f oracle     # aguarde "DATABASE IS READY TO USE!"
```

Na primeira subida o container instala tudo sozinho (`docker-init/01_smarthas.sh`).
Conexão: `localhost:1521`, serviço `FREEPDB1`, usuário/senha `smarthas` / `smarthas`.

Rodar a demonstração no próprio container:

```bash
docker exec -it -w /opt/smarthas/scripts smarthas-oracle sqlplus smarthas/smarthas@//localhost:1521/FREEPDB1 @06_consultas_demo.sql
```

Reinstalar do zero: `docker compose down -v && docker compose up -d`.

## Opção B — SQL Developer (ex.: servidor Oracle da FIAP)

1. *Tools › Preferences › Environment › Encoding* = **UTF-8** (acentos corretos).
2. Conecte no seu schema, abra `scripts/instalar_tudo.sql` e execute como **script (F5)**.
3. Abra `scripts/06_consultas_demo.sql` e execute (F5) para ver functions e procedures em ação.
4. `07_job_agendado.sql` exige o privilégio `CREATE JOB` (opcional).

## Ligando a API no Oracle

```bash
cd backend-springboot
mvn spring-boot:run -Dspring-boot.run.profiles=oracle
```

Para outro servidor, use as variáveis `SMARTHAS_DB_URL`, `SMARTHAS_DB_USER` e
`SMARTHAS_DB_PASSWORD`. `SMARTHAS_SIMULATOR=true` liga o simulador IoT, que
envia leituras a cada 15 s (cada uma aciona `PRC_REGISTRAR_LEITURA`).
