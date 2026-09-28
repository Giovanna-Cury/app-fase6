# Smart HAS — Contrato da API REST (fonte da verdade)

Este contrato é seguido por **os três projetos**: app Flutter (`mobile-flutter`),
back-end Spring Boot (`backend-springboot`) e dashboard Angular (`web-angular`).

- **Base URL:** `http://localhost:8080/api`
- **Formato:** JSON (UTF-8)
- **Auth:** JWT Bearer. Após o login, todo request autenticado envia
  `Authorization: Bearer <token>`.
- **Erros:** sempre `{ "message": "texto legível", "status": <int>, "timestamp": "..." }`
  com o HTTP status apropriado (400, 401, 403, 404, 422, 500).
- **CORS:** liberar `http://localhost:4200` (Angular) e `http://localhost:*`
  para os demais clientes durante o desenvolvimento.

## Perfis / roles
- `ADMIN` — acesso total (inclui deletar sensores/alertas).
- `OPERATOR` — leitura + criação de alertas.

## Usuários seed (para login de demonstração)
| username | senha | role     |
|----------|-------|----------|
| admin    | 1234  | ADMIN    |
| operador | 1234  | OPERATOR |

---

## Endpoints

### Auth
`POST /api/auth/login`
```jsonc
// request
{ "username": "admin", "password": "1234" }
// response 200
{ "token": "<jwt>", "user": { "id": 1, "name": "Administrador", "username": "admin", "email": "admin@smarthas.com", "role": "ADMIN" } }
// erro 401 -> { "message": "Usuário ou senha inválidos.", "status": 401, ... }
```

### Sensores (CRUD)
| Método | Rota                  | Role       | Descrição            |
|--------|-----------------------|------------|----------------------|
| GET    | `/api/sensors`        | autenticado| lista todos          |
| GET    | `/api/sensors/{id}`   | autenticado| um sensor            |
| POST   | `/api/sensors`        | ADMIN      | cria                 |
| PUT    | `/api/sensors/{id}`   | ADMIN      | atualiza             |
| DELETE | `/api/sensors/{id}`   | ADMIN      | remove (204)         |

Objeto **Sensor**:
```jsonc
{
  "id": 1,
  "name": "Sensor 01",
  "type": "Temperatura",
  "status": "ONLINE",          // ONLINE | WARNING | OFFLINE
  "location": "Centro de São Paulo",
  "value": 24.5,
  "unit": "°C",
  "latitude": -23.5505,
  "longitude": -46.6333,
  "updatedAt": "2026-08-23T09:12:00"
}
```

### Alertas (CRUD)
| Método | Rota                        | Role       | Descrição              |
|--------|-----------------------------|------------|------------------------|
| GET    | `/api/alerts`               | autenticado| lista todos            |
| GET    | `/api/alerts/{id}`          | autenticado| um alerta              |
| POST   | `/api/alerts`               | autenticado| cria                   |
| PUT    | `/api/alerts/{id}/resolve`  | autenticado| marca como resolvido   |
| DELETE | `/api/alerts/{id}`          | ADMIN      | remove (204)           |

Objeto **Alert**:
```jsonc
{
  "id": 1,
  "title": "Área de risco detectada",
  "description": "Movimentação anômala identificada pela IA.",
  "severity": "CRITICAL",       // LOW | MEDIUM | HIGH | CRITICAL
  "location": "Centro de São Paulo",
  "createdAt": "2026-08-23T09:12:00",
  "resolved": false
}
```

### Dashboard (resumo — opcional, usado pelos KPIs)
`GET /api/dashboard/summary`
```jsonc
{
  "totalSensors": 8, "onlineSensors": 3, "offlineSensors": 1, "activeAlerts": 7,
  "warningSensors": 4, "criticalAlerts": 5, "readingsLast24h": 376,
  "dataEngine": "ORACLE_PLSQL"   // ou "JPA" quando a API roda sem Oracle (H2)
}
```

> **Fase 6 — campos novos (retrocompatíveis):** `Sensor` ganhou `alertThreshold`,
> `criticalThreshold`, `responsibleId`, `responsibleName`; `Alert` ganhou
> `origin` (`MANUAL`/`AUTOMATICO`), `sensorId`, `resolvedAt`. Clientes antigos
> ignoram os campos extras.

## Fase 6 — Telemetria e rotinas PL/SQL

| Método | Rota | Acesso | Objeto Oracle acionado |
|--------|------|--------|------------------------|
| POST | `/api/sensors/{id}/readings` | autenticado | `PRC_REGISTRAR_LEITURA` |
| GET | `/api/sensors/{id}/readings?limit=48` | autenticado | `SHAS_LEITURA` |
| GET | `/api/sensors/{id}/indicators` | autenticado | `FN_CALC_CONFORMIDADE`, `FN_CALC_INDICE_RISCO`, `FN_FORMATAR_LEITURA` |
| GET | `/api/reports/daily?date=AAAA-MM-DD` | autenticado | `SHAS_RELATORIO_DIARIO` |
| GET | `/api/reports/responsibles?hours=24` | autenticado | `PRC_RESUMO_POR_RESPONSAVEL` (SYS_REFCURSOR) |
| GET | `/api/reports/logs?limit=20` | ADMIN | `SHAS_LOG_EXECUCAO` |
| POST | `/api/routines/daily-report?date=AAAA-MM-DD` | ADMIN | `PRC_GERAR_RELATORIO_DIARIO` |
| POST | `/api/routines/inactive-sensors?toleranceMinutes=60` | ADMIN | `PRC_VERIFICAR_SENSORES_INATIVOS` |

```jsonc
// POST /api/sensors/3/readings   { "value": 162.4 }       (measuredAt opcional)
{ "readingId": 2687, "sensorId": 3, "value": 162.4,
  "classification": "CRITICA", "alertId": 38, "engine": "ORACLE_PLSQL" }

// GET /api/sensors/3/indicators
{ "sensorId": 3, "conformity24h": 66.67, "conformity7d": 70.83, "riskIndex": 50,
  "formattedLastReading": "Sensor 03 (Qualidade do Ar) | 162,40 AQI | CRITICA | 27/09/2026 19:55",
  "engine": "ORACLE_PLSQL" }
```

**Erros de negócio vindos do PL/SQL** (`RAISE_APPLICATION_ERROR`) são traduzidos:
`ORA-20001` → **404**; `ORA-20002` a `ORA-20004` → **422**, sempre no formato
`{ message, status, timestamp }` (a `message` é o texto definido no PL/SQL).

## Validações (POST/PUT)
- Sensor: `name`, `type`, `location`, `status` obrigatórios.
- Alert: `title`, `location`, `severity` obrigatórios.
- Sensor: `criticalThreshold` ≥ `alertThreshold` (422) — mesma regra da constraint `CK_SHAS_SENSOR_LIMITES`.
- Leitura: `value` obrigatório; faixa −1000..100000 e `measuredAt` não futuro (422).
- Campos inválidos → HTTP 400/422 com `message` explicando.

## Swagger
- UI em `http://localhost:8080/swagger-ui.html` (ou `/swagger-ui/index.html`).
- OpenAPI JSON em `http://localhost:8080/v3/api-docs`.
