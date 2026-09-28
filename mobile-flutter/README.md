# Smart HAS — Aplicativo Mobile (Flutter)

Aplicativo mobile do **Smart HAS**, um sistema inteligente de monitoramento
alinhado à **Sociedade 5.0**, com a camada **AI Logistics Extension**.

Esta é a evolução do app na **Fase 5** — **Opção B: aprimoramento significativo
da solução Flutter existente** (sem migração para React Native). O app foi
refatorado para uma **arquitetura em camadas** e está **pronto para consumir a
API REST** desenvolvida em Spring Boot (Parte 2) e compartilhada com o dashboard
Angular (Parte 3).

---

## 🚀 Como rodar (VS Code)

> Pré-requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install)
> instalado e a extensão **Flutter** no VS Code.

```bash
flutter pub get
flutter run
```

O app **já roda sozinho**, sem back-end, porque começa em **modo demonstração**
(dados mock). Credenciais de acesso:

- **Usuário:** `admin`
- **Senha:** `1234`

### Dispositivos
- **Chrome / Web:** `flutter run -d chrome`
- **Windows desktop:** `flutter run -d windows`
- **Emulador Android:** abra o emulador e rode `flutter run`

---

## 🔌 Conectando à API real (Partes 2/3)

Toda a configuração fica em [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart):

1. Suba o back-end Spring Boot em `http://localhost:8080`.
2. Em `AppConfig`, mude:
   ```dart
   static const bool useMockData = false;
   ```
3. A URL base é resolvida automaticamente por plataforma:
   - **Android emulador:** `http://10.0.2.2:8080/api`
   - **Web / Desktop / iOS:** `http://localhost:8080/api`

Se a API estiver fora do ar, o app faz **fallback automático** para os dados
mock (controlado por `fallbackToMockOnError`), mantendo a apresentação estável.

### Contrato esperado da API (para o time do Spring Boot)

| Método | Endpoint                    | Descrição                    |
|--------|-----------------------------|------------------------------|
| POST   | `/api/auth/login`           | Login → `{ token, user }`    |
| GET    | `/api/sensors`              | Lista de sensores            |
| GET    | `/api/sensors/{id}`         | Detalhe de um sensor         |
| GET    | `/api/alerts`               | Lista de alertas             |
| POST   | `/api/alerts`               | Cria um alerta               |
| PUT    | `/api/alerts/{id}/resolve`  | Resolve um alerta            |

Exemplos de JSON (os `fromJson`/`toJson` dos models seguem exatamente estas chaves):

```jsonc
// POST /api/auth/login  -> resposta
{ "token": "jwt...", "user": { "id": 1, "name": "Admin", "role": "ADMIN" } }

// GET /api/sensors -> item
{
  "id": 1, "name": "Sensor 01", "type": "Temperatura",
  "status": "ONLINE", "location": "Centro de São Paulo",
  "value": 24.5, "unit": "°C",
  "latitude": -23.5505, "longitude": -46.6333,
  "updatedAt": "2026-08-23T09:12:00"
}

// GET /api/alerts -> item
{
  "id": 1, "title": "Área de risco detectada",
  "description": "Movimentação anômala.", "severity": "CRITICAL",
  "location": "Centro de São Paulo",
  "createdAt": "2026-08-23T09:12:00", "resolved": false
}
```

O token retornado no login é enviado automaticamente em todas as requisições
seguintes no header `Authorization: Bearer <token>`.

---

## 🏛️ Arquitetura

Separação de responsabilidades em camadas (facilita testes, manutenção e a
troca entre mock e API real):

```
lib/
├── main.dart              # composition root: injeção de dependências
├── app.dart              # MaterialApp + tema + AuthGate (rota inicial)
├── core/
│   ├── config/           # AppConfig (URL da API, flags de ambiente)
│   ├── network/          # ApiClient (HTTP genérico) + exceções tipadas
│   ├── state/            # ViewState (idle/loading/success/error)
│   ├── theme/            # AppTheme (Material 3, claro e escuro)
│   └── mock/             # MockData (dados de demonstração)
├── models/               # User, Sensor, Alert (fromJson/toJson + enums)
├── services/             # AuthService, SensorService, AlertService (chamam a API)
├── repositories/         # abstração + fallback offline + persistência do token
├── providers/            # estado (ChangeNotifier): auth, sensor, alert, settings
├── screens/              # login, home, alertas, mapa, detalhe do sensor
└── widgets/              # componentes reutilizáveis (cards, loading, erro...)
```

**Fluxo de dados:** `UI (screens/widgets)` → `Provider` → `Repository` →
`Service` → `ApiClient` → **API REST**. Cada camada só conhece a camada
imediatamente abaixo.

---

## ✨ Principais melhorias desta fase

- **Arquitetura em camadas** (models / services / repositories / providers /
  UI) em vez de telas com dados fixos.
- **Camada de rede robusta:** `ApiClient` reutilizável com headers, Bearer
  token, timeout e **exceções tipadas** (`NetworkException`,
  `UnauthorizedException`, `ServerException`...).
- **Integração real com API REST** (Spring Boot), com **fallback offline** e
  flag de ambiente para alternar mock ↔ API sem tocar na UI.
- **Autenticação com persistência de sessão** via `shared_preferences`
  (auto-login ao reabrir o app) + logout.
- **Estados de UI completos:** loading, erro (com "tentar novamente"), vazio e
  sucesso — nada de tela travada.
- **Novas funcionalidades:** dashboard com KPIs em tempo real, *pull-to-refresh*,
  busca/filtro de alertas, **formulário validado para criar alertas**, detalhe
  do sensor e mapa que plota sensores por coordenadas.
- **Material 3** com tema claro/escuro alternável e persistido.
- **Testes** de parsing de models e de widget (`flutter test`).
- **Limpeza de dependências** não utilizadas (Firebase, Google Maps, Geolocator)
  que exigiam configuração externa e travavam o build — reintroduzíveis no
  roadmap quando forem de fato usadas.

---

## 🗺️ Roadmap tecnológico

- **✅ Concluído (fases anteriores):** protótipo Flutter com telas de login,
  dashboard, alertas e mapa (dados estáticos).
- **🔄 Nesta fase:** refatoração para arquitetura em camadas, camada de rede,
  autenticação com sessão, novas funcionalidades e **preparação para consumir a
  API REST** das Partes 2 (Spring Boot) e 3 (Angular).
- **🔜 Próximas fases:** conectar à API real em produção (HTTPS), notificações
  push (Firebase Cloud Messaging), mapa nativo (Google Maps) com geolocalização,
  e a camada de IA (AI Logistics Extension) consumindo os dados dos sensores.

---

## 🧪 Testes

```bash
flutter test
```

## 🔍 Análise estática

```bash
flutter analyze
```
