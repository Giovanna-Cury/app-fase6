# Smart HAS — Dashboard Web (Angular)

Painel administrativo (Parte 3 do projeto FIAP **Smart HAS**) que consome a mesma API REST
do app mobile Flutter e do back-end Spring Boot. Construído com **Angular 20** e componentes
**standalone**. Toda a interface está em **português do Brasil**.

## Pré-requisitos

- Node.js 20+ (testado com Node 24) e npm.
- **A API Spring Boot precisa estar rodando em `http://localhost:8080`** (base `/api`).
  O Angular espera o CORS liberado para `http://localhost:4200` (ver contrato da API).

## Como rodar

```bash
npm install          # instala as dependências
npx ng serve         # sobe o dev server em http://localhost:4200
```

Abra `http://localhost:4200`. Você será redirecionado para `/login`.

Login de demonstração (usuários seed do contrato): **admin / 1234** (ADMIN) ou **operador / 1234** (OPERATOR).

### Build de produção

```bash
npx ng build         # gera a build em dist/web-angular
```

## Configuração

A URL da API fica em `src/environments/environment.ts`:

```ts
export const environment = { apiUrl: 'http://localhost:8080/api' };
```

## Rotas

| Rota      | Componente        | Proteção            | Descrição                                   |
|-----------|-------------------|---------------------|---------------------------------------------|
| `/login`  | `LoginComponent`  | pública             | Formulário de login (JWT).                  |
| `/home`   | `HomeComponent`   | `authGuard`         | Dashboard de sensores + KPIs.               |
| `/admin`  | `AdminComponent`  | `authGuard`         | Gestão de alertas (criar / resolver).       |
| `''`      | —                 | —                   | Redireciona para `/home`.                   |
| `**`      | —                 | —                   | Wildcard → redireciona para `/login`.       |

## Estrutura

```
src/
  environments/environment.ts        # apiUrl
  app/
    models/models.ts                 # Sensor, Alert, User, DTOs (alinhados ao contrato)
    services/
      auth.service.ts                # login/logout/isLoggedIn/currentUser + JWT no localStorage
      sensor.service.ts              # getSensors / getSensor
      alert.service.ts               # getAlerts / createAlert / resolve
      dashboard.service.ts           # getSummary (opcional)
    interceptors/auth.interceptor.ts # HttpInterceptorFn: Authorization: Bearer <token>
    guards/auth.guard.ts             # CanActivateFn: protege /home e /admin
    pages/
      login/                         # LoginComponent
      home/                          # HomeComponent (KPIs + tabela de sensores)
      admin/                         # AdminComponent (form + lista de alertas)
    app.ts / app.html / app.css      # shell + navbar (Home, Admin, Logout, usuário atual)
    app.config.ts                    # provideHttpClient(withInterceptors) + provideRouter
    app.routes.ts                    # rotas + guard
```

## Mapa dos requisitos da atividade

| Requisito                                             | Onde                                                                 |
|-------------------------------------------------------|---------------------------------------------------------------------|
| Componentes standalone                                | Todos os componentes.                                               |
| `provideHttpClient()` + router em `app.config.ts`     | `src/app/app.config.ts`.                                            |
| Environment com `apiUrl`                              | `src/environments/environment.ts` (usado por todos os services).   |
| `AuthService` (login/logout/isLoggedIn/currentUser)   | `services/auth.service.ts` (JWT + user em `localStorage`).          |
| `SensorService` (getSensors/getSensor)                | `services/sensor.service.ts`.                                       |
| `AlertService` (getAlerts/createAlert/resolve)        | `services/alert.service.ts`.                                        |
| `DashboardService` (summary — opcional)               | `services/dashboard.service.ts`.                                    |
| Interceptor funcional (`HttpInterceptorFn`)           | `interceptors/auth.interceptor.ts` via `withInterceptors`.         |
| Guard funcional (`CanActivateFn`)                     | `guards/auth.guard.ts` protege `/home` e `/admin`.                 |
| Rotas /login /home /admin + redirect + wildcard       | `app.routes.ts`.                                                    |
| Login com `[(ngModel)]` e feedback de erro            | `pages/login/`.                                                     |
| Home: KPIs + tabela `*ngFor`/`*ngIf` + loading/erro   | `pages/home/`.                                                      |
| Admin: lista `*ngFor` + form `[(ngModel)]` + resolver | `pages/admin/`.                                                     |
| Navbar/layout com Home, Admin, Logout e nome do user  | `app.html`.                                                         |
| Data binding: `{{ }}` `[ ]` `( )` `[( )]`             | Interpolação, `[class.*]`/`[disabled]`, `(click)`/`(ngSubmit)`, `[(ngModel)]`. |
| Estilo (cards, tabela, badges, banners, spinner)      | CSS por componente + `styles.css`.                                 |
