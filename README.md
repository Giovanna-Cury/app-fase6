# Smart HAS — Fase 6 (FIAP)

Sistema inteligente de monitoramento urbano alinhado à **Sociedade 5.0**, com a
camada **AI Logistics Extension**. Na Fase 6 a solução ganhou uma **camada de
persistência Oracle** com **procedures e functions PL/SQL** integradas ao back-end
Java: a inteligência de monitoramento (classificação de leituras, alertas
automáticos, indicadores, relatórios e watchdog) passa a rodar **no banco**.

| Parte | Projeto | Stack | Pasta |
|-------|---------|-------|-------|
| Banco | Modelo + PL/SQL | **Oracle 19c+/23ai** | [`database/`](database) |
| API | REST | **Java 21 + Spring Boot 3** | [`backend-springboot/`](backend-springboot) |
| Web | Dashboard admin | **Angular 20** | [`web-angular/`](web-angular) |
| Mobile | App de campo | **Flutter** | [`mobile-flutter/`](mobile-flutter) |

```
 Flutter ─┐                     ┌───────────── Spring Boot ─────────────┐        ┌──────── Oracle ────────┐
          ├─ REST/JSON + JWT ──►│ Controller → Service → AnalyticsGateway│─JDBC──►│ PRC_REGISTRAR_LEITURA  │
 Angular ─┘                     │                 (porta)   │  (adapter) │        │ FN_CALC_CONFORMIDADE   │
                                │         OraclePlSql ◄─────┘  JPA (H2)  │        │ FN_CALC_INDICE_RISCO…  │
                                └────────────────────────────────────────┘        └────────────────────────┘
```

---

## ▶️ Como rodar (demo completa com Oracle)

### 1) Banco Oracle (Docker) — porta 1521
```bash
cd database
docker compose up -d        # instala tabelas, carga, functions, procedures e jobs
```
Sem Docker? Rode `database/scripts/instalar_tudo.sql` no SQL Developer — ver
[`database/README.md`](database/README.md).

### 2) API (Spring Boot) — porta 8080
```bash
cd backend-springboot
mvn spring-boot:run -Dspring-boot.run.profiles=oracle
```
- Swagger: http://localhost:8080/swagger-ui.html
- Sem o perfil `oracle`, a API sobe com **H2** e regras espelhadas em Java (modo local).

### 3) Dashboard (Angular) — porta 4200
```bash
cd web-angular
npm install
npx ng serve
```

### 4) App (Flutter)
```bash
cd mobile-flutter
flutter pub get
flutter run --dart-define=SMARTHAS_USE_MOCK=false   # consome a API real
```

> **Login (todos os projetos):** `admin` / `1234` (ADMIN) · `operador` / `1234`
> e `campo` / `1234` (OPERATOR).

## 🧪 Testes
```bash
cd backend-springboot
mvn test                                                            # H2 (sem Oracle)
SMARTHAS_ORACLE_IT=true mvn test -Dtest=OraclePlSqlIntegrationTest  # Oracle real (Docker no ar)
```

## 📚 Documentação
- [`docs/FASE6_DOCUMENTACAO.md`](docs/FASE6_DOCUMENTACAO.md) — melhorias, DER, PL/SQL e integração (base do PDF).
- [`database/README.md`](database/README.md) — scripts e objetos Oracle.
- [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md) — contrato da API (inclui endpoints da Fase 6).
- [`docs/DOCUMENTACAO.md`](docs/DOCUMENTACAO.md) — documentação da Fase 5.
