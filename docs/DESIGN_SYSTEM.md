# Smart HAS — Design System (visual único p/ Flutter e Angular)

Identidade visual compartilhada, inspirada no app original (tema escuro,
azul, cards arredondados, ícones e status coloridos), agora modernizada
com Material 3.

## Cores (tokens)
| Token            | Hex        | Uso                                  |
|------------------|------------|--------------------------------------|
| Primary          | `#2563EB`  | Azul da marca (botões, destaques)    |
| Primary Dark     | `#1E40AF`  | Gradiente/hover                      |
| Background (dark)| `#0F172A`  | Fundo principal (tema escuro)        |
| Surface (dark)   | `#1E293B`  | Cards/superfícies                    |
| Surface 2        | `#334155`  | Bordas/inputs                        |
| Text primary     | `#F1F5F9`  | Texto principal                      |
| Text secondary   | `#94A3B8`  | Texto secundário                     |
| Success          | `#22C55E`  | Sensor online                        |
| Warning          | `#F59E0B`  | Atenção / severidade média           |
| Danger           | `#EF4444`  | Offline / crítico                    |
| Info             | `#3B82F6`  | Baixa severidade / genérico          |

**Gradiente da marca:** `linear-gradient(135deg, #2563EB → #1E40AF)`.

## Tipografia
- Fonte: system/`Inter`/`Roboto` (sans-serif).
- Título grande: 28–34px, bold, leve `letter-spacing`.
- Título de seção: 18–20px, semibold.
- Corpo: 14–16px. Secundário: 12–13px na cor `Text secondary`.

## Componentes
- **Cards:** raio 16px, sombra suave, borda sutil (`Surface 2`), padding 16px.
- **KPI/Stat card:** ícone em "chip" colorido (cor com 15% de opacidade) +
  número grande + rótulo pequeno.
- **Status badge/pill:** fundo = cor do status a 15%, texto na cor cheia,
  raio total (pílula), padding 4×10px.
- **Botões:** raio 12px, altura ~52px, primário com o gradiente da marca.
- **Inputs:** preenchidos, raio 12px, ícone à esquerda.
- **Feedback:** loading (spinner + texto), erro (ícone + mensagem + "tentar
  novamente"), vazio (ícone + texto), sucesso (banner/snackbar verde).

## Layout
- Espaçamento base 8px (múltiplos: 8/12/16/24).
- Conteúdo com largura máx. ~1100px no web; cards em grid responsivo.
- Tela de login centralizada, com logo em badge circular e fundo em gradiente.
