# Smart HAS — Back-end (Spring Boot)

API REST do sistema de monitoramento inteligente **Smart HAS** (projeto FIAP).
Implementa autenticação JWT, CRUD de sensores e alertas, dashboard de KPIs,
documentação Swagger e — **na Fase 6** — integração com **Oracle PL/SQL**
(telemetria, alertas automáticos, indicadores, relatórios e rotinas batch).

- **Stack:** Java 21, Spring Boot 3.3.5 (Web, Data JPA, JDBC, Security, Validation, Thymeleaf), Oracle (ojdbc11) ou H2, springdoc-openapi, JJWT.
- **Base URL:** `http://localhost:8080/api`

## Como rodar

```bash
cd backend-springboot
mvn spring-boot:run
```

Ou empacotando o jar:

```bash
mvn clean package
java -jar target/smarthas-api-0.0.1-SNAPSHOT.jar
```

A aplicação sobe em `http://localhost:8080`.

- Landing page (Thymeleaf): `http://localhost:8080/`
- Swagger UI: `http://localhost:8080/swagger-ui.html`
- OpenAPI JSON: `http://localhost:8080/v3/api-docs`
- Console H2: `http://localhost:8080/h2-console`

### Console H2 (credenciais)
- **JDBC URL:** `jdbc:h2:mem:smarthas`
- **User:** `sa`
- **Password:** _(em branco)_

## Usuários seed

| username | senha | role     |
|----------|-------|----------|
| admin    | 1234  | ADMIN    |
| operador | 1234  | OPERATOR |

## Autenticação (JWT)

1. `POST /api/auth/login` com `{ "username": "admin", "password": "1234" }`.
2. Resposta: `{ "token": "<jwt>", "user": { id, name, username, email, role } }`.
3. Nos demais endpoints envie o header `Authorization: Bearer <token>`.

No Swagger UI, clique em **Authorize** e cole o token.

## Endpoints

| Método | Rota                        | Acesso       | Descrição                       |
|--------|-----------------------------|--------------|---------------------------------|
| POST   | `/api/auth/login`           | público      | Login, retorna token + usuário  |
| GET    | `/api/sensors`              | autenticado  | Lista sensores                  |
| GET    | `/api/sensors/{id}`         | autenticado  | Um sensor                       |
| POST   | `/api/sensors`              | ADMIN        | Cria sensor                     |
| PUT    | `/api/sensors/{id}`         | ADMIN        | Atualiza sensor                 |
| DELETE | `/api/sensors/{id}`         | ADMIN        | Remove sensor (204)             |
| GET    | `/api/alerts`               | autenticado  | Lista alertas                   |
| GET    | `/api/alerts/{id}`          | autenticado  | Um alerta                       |
| POST   | `/api/alerts`               | autenticado  | Cria alerta                     |
| PUT    | `/api/alerts/{id}/resolve`  | autenticado  | Marca alerta como resolvido     |
| DELETE | `/api/alerts/{id}`          | ADMIN        | Remove alerta (204)             |
| GET    | `/api/dashboard/summary`    | autenticado  | KPIs (totais de sensores/alertas)|

Rotas públicas adicionais: `/`, `/swagger-ui/**`, `/v3/api-docs/**`, `/h2-console/**`.

## Formato de erro

Todos os erros seguem:

```json
{ "message": "texto legível", "status": 404, "timestamp": "2026-08-23T09:12:00" }
```

Status usados: 400, 401, 403, 404, 422, 500.

## CORS

Liberados para desenvolvimento: `http://localhost:4200` (Angular) e `http://localhost` /
`http://localhost:*` (Flutter web e demais clientes), todos os métodos e headers.

## Testes

```bash
mvn test
```

Cobrem: carregamento de contexto (`@SpringBootTest`), login retornando 200 + token,
`/api/sensors` retornando 401 sem token e 200 com token, e bloqueio de criação de
sensor por OPERATOR (403).

## Notas

- Senhas armazenadas com **BCrypt**.
- Sessão **stateless**, CSRF desabilitado para a API, filtro JWT (`OncePerRequestFilter`).
- H2 **em memória** com `ddl-auto=update`; o `DataSeeder` recria os dados a cada start.
- Enums serializados pelo NAME (`ONLINE`, `CRITICAL`, ...); datas em ISO-8601.

## Fase 6 — Oracle PL/SQL

### Perfis

| Perfil | Banco | Regras de monitoramento | Carga de dados |
|--------|-------|-------------------------|----------------|
| *(padrão)* | H2 em memória | `JpaAnalyticsGateway` (Java) | `DataSeeder` |
| `oracle` | Oracle (`database/`) | `OraclePlSqlAnalyticsGateway` → procedures/functions | `04_carga_dados.sql` |

```bash
mvn spring-boot:run -Dspring-boot.run.profiles=oracle
# outro servidor: SMARTHAS_DB_URL / SMARTHAS_DB_USER / SMARTHAS_DB_PASSWORD
# simulador IoT:  SMARTHAS_SIMULATOR=true
```

No perfil `oracle` o Hibernate roda com `ddl-auto=validate`: o schema é versionado
pelos scripts SQL e a aplicação **falha no startup** se as entidades divergirem das tabelas.

### Arquitetura da integração (Ports & Adapters)

```
Controller ──► Service ──► SensorAnalyticsGateway (porta)
                              ├── OraclePlSqlAnalyticsGateway  @Profile("oracle")
                              │     SimpleJdbcCall (named binding) → PRC_*
                              │     JdbcTemplate SELECT fn_*(...) FROM shas_sensor
                              │     OracleTypes.CURSOR → SYS_REFCURSOR mapeado em records
                              └── JpaAnalyticsGateway          @Profile("!oracle")
```

- `OracleErrorTranslator`: `ORA-20001` → 404, `ORA-20002..20004` → 422 (mensagem do PL/SQL).
- `PRC_REGISTRAR_LEITURA` roda dentro do `@Transactional` do service (a procedure não
  faz COMMIT); as rotinas batch controlam o próprio COMMIT.
- `ReadingSimulator` (`@Scheduled`, opcional): gateway IoT simulado que dispara a procedure.

### Endpoints novos

| Método | Rota | Acesso | Oracle |
|--------|------|--------|--------|
| POST | `/api/sensors/{id}/readings` | autenticado | `PRC_REGISTRAR_LEITURA` |
| GET | `/api/sensors/{id}/readings` | autenticado | `SHAS_LEITURA` |
| GET | `/api/sensors/{id}/indicators` | autenticado | `FN_CALC_CONFORMIDADE`, `FN_CALC_INDICE_RISCO`, `FN_FORMATAR_LEITURA` |
| GET | `/api/reports/daily` | autenticado | `SHAS_RELATORIO_DIARIO` |
| GET | `/api/reports/responsibles` | autenticado | `PRC_RESUMO_POR_RESPONSAVEL` |
| GET | `/api/reports/logs` | ADMIN | `SHAS_LOG_EXECUCAO` |
| POST | `/api/routines/daily-report` | ADMIN | `PRC_GERAR_RELATORIO_DIARIO` |
| POST | `/api/routines/inactive-sensors` | ADMIN | `PRC_VERIFICAR_SENSORES_INATIVOS` |

### Testes

```bash
mvn test                                                            # 25 testes (H2)
SMARTHAS_ORACLE_IT=true mvn test -Dtest=OraclePlSqlIntegrationTest  # 4 testes no Oracle real
```

> **Windows:** se o Tomcat falhar com `Unable to establish loopback connection`, rode com
> `-Djdk.net.unixdomain.tmpdir=C:\Temp` (limitação do JDK com a pasta TEMP do usuário).
