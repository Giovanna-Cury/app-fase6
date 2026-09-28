# Smart HAS — Roteiro dos Slides (até 10) e do Vídeo (até 5 min)

> Base para montar o PowerPoint e gravar o vídeo (YouTube não listado).
> Regra do trabalho: reservar parte do vídeo para a **demonstração prática**.

---

## Slide 1 — Capa e grupo
- Título: **Smart HAS — Fase 5**
- Subtítulo: Sistema Inteligente de Monitoramento (Sociedade 5.0)
- **Integrantes:** nome + **RM** + **foto** de cada um.
- Turma/curso e data.

## Slide 2 — O problema e o objetivo
- Monitoramento urbano em tempo real (sensores, alertas, áreas de risco).
- Objetivo: apoiar decisões e evoluir para uma solução integrada e conectada.

## Slide 3 — Arquitetura da solução
- Diagrama: **Flutter (mobile)** e **Angular (web)** consumindo a **API Spring Boot + banco**.
- Destaque: os três compartilham **a mesma API REST** (um contrato único).

## Slide 4 — Parte 1: Escolha da stack (Opção B — Flutter)
- Justificativa: base consolidada, multiplataforma, foco em evolução técnica.
- Roadmap: ✅ feito | 🔄 nesta fase | 🔜 próximas fases.

## Slide 5 — Parte 1: Aprimoramentos do app Flutter
- Arquitetura em camadas, camada de rede com JWT, sessão persistida.
- Estados de loading/erro, novas telas, tema claro/escuro, testes.
- (Print do app rodando.)

## Slide 6 — Parte 2: API Spring Boot
- Controllers/Services/Models, JWT (auth + roles), H2 + JPA (CRUD).
- Validação, tratamento de erros, Thymeleaf e **Swagger**.
- (Print do Swagger UI.)

## Slide 7 — Parte 3: Dashboard Angular
- HttpClient + interceptor JWT, rotas `/login` `/home` `/admin`, guard.
- Data binding (`{{ }}`, `[ ]`, `( )`, `[( )]`), `*ngIf`/`*ngFor`, `[(ngModel)]`.
- (Print do dashboard.)

## Slide 8 — Integração ponta a ponta
- Mesmo login/JWT nos 3 clientes; mesmo dado de sensores/alertas.
- Segurança: Bearer token + CORS.

## Slide 9 — Demonstração (roteiro do vídeo)
1. Subir a API (`mvn spring-boot:run`) → mostrar Swagger.
2. Abrir o **Angular** → login → dashboard → criar/resolver alerta.
3. Abrir o **app Flutter** → login → dashboard → alertas → mapa.
4. Mostrar que o dado criado na web aparece via API.

## Slide 10 — Conclusão e próximos passos
- De protótipo estático → solução integrada, segura e escalável.
- Próximos passos: nuvem/HTTPS, push (FCM), mapa nativo, camada de IA.
- **Link do vídeo** (YouTube não listado).

---

### Dicas para o vídeo (≤ 5 min)
- ~2 min de slides (contexto + arquitetura + decisões) e ~3 min de **demo ao vivo**.
- Deixe a API já rodando antes de gravar para evitar espera.
- Garanta que o vídeo esteja **acessível** (não listado, sem exigir login).
