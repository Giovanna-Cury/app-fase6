"""Gera a apresentacao da Fase 6 (10 slides) em .pptx e PDF (via PowerPoint)."""
from pathlib import Path

from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN
from pptx.util import Emu, Inches, Pt

HERE = Path(__file__).resolve().parent
BG, SURFACE, SURFACE2 = RGBColor(0x0F, 0x17, 0x2A), RGBColor(0x1E, 0x29, 0x3B), RGBColor(0x33, 0x41, 0x55)
TEXT, DIM, BLUE = RGBColor(0xF1, 0xF5, 0xF9), RGBColor(0x94, 0xA3, 0xB8), RGBColor(0x60, 0xA5, 0xFA)
GREEN, AMBER, RED = RGBColor(0x4A, 0xDE, 0x80), RGBColor(0xFB, 0xBF, 0x24), RGBColor(0xF8, 0x71, 0x71)

prs = Presentation()
prs.slide_width, prs.slide_height = Inches(13.333), Inches(7.5)
BLANK = prs.slide_layouts[6]


def box(slide, x, y, w, h, fill=SURFACE, line=None, shape=MSO_SHAPE.ROUNDED_RECTANGLE):
    s = slide.shapes.add_shape(shape, Inches(x), Inches(y), Inches(w), Inches(h))
    s.fill.solid(); s.fill.fore_color.rgb = fill
    if line:
        s.line.color.rgb = line; s.line.width = Pt(1.25)
    else:
        s.line.fill.background()
    if shape == MSO_SHAPE.ROUNDED_RECTANGLE:
        s.adjustments[0] = 0.08
    s.shadow.inherit = False
    return s


def text(slide, x, y, w, h, content, size=16, color=TEXT, bold=False, align=PP_ALIGN.LEFT, font="Segoe UI"):
    tb = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = tb.text_frame; tf.word_wrap = True
    lines = content if isinstance(content, list) else [content]
    for i, line in enumerate(lines):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = align
        p.space_after = Pt(6)
        segs = line if isinstance(line, list) else [(line, color, bold)]
        for seg, c, b in segs:
            r = p.add_run(); r.text = seg
            r.font.size = Pt(size); r.font.color.rgb = c; r.font.bold = b; r.font.name = font
    return tb


def slide_base(title, kicker):
    s = prs.slides.add_slide(BLANK)
    s.background.fill.solid(); s.background.fill.fore_color.rgb = BG
    box(s, 0, 0, 13.333, 0.08, fill=RGBColor(0x25, 0x63, 0xEB), shape=MSO_SHAPE.RECTANGLE)
    text(s, 0.6, 0.35, 10, 0.4, kicker.upper(), size=12, color=BLUE, bold=True)
    text(s, 0.6, 0.7, 12, 0.8, title, size=30, bold=True)
    text(s, 10.3, 7.0, 2.8, 0.3, "Smart HAS · Fase 6 · FIAP", size=10, color=DIM, align=PP_ALIGN.RIGHT)
    return s


def card(s, x, y, w, h, title, lines, accent=BLUE, size=13):
    box(s, x, y, w, h)
    box(s, x, y, w, 0.06, fill=accent, shape=MSO_SHAPE.RECTANGLE)
    text(s, x + 0.25, y + 0.2, w - 0.5, 0.45, title, size=16, bold=True)
    text(s, x + 0.25, y + 0.7, w - 0.5, h - 0.8, lines, size=size, color=DIM)


def picture(s, path, x, y, w=None, h=None):
    kw = {}
    if w: kw["width"] = Inches(w)
    if h: kw["height"] = Inches(h)
    return s.shapes.add_picture(str(path), Inches(x), Inches(y), **kw)


# 1 — Capa + grupo -----------------------------------------------------------
s = prs.slides.add_slide(BLANK)
s.background.fill.solid(); s.background.fill.fore_color.rgb = BG
box(s, 0, 0, 0.18, 7.5, fill=RGBColor(0x25, 0x63, 0xEB), shape=MSO_SHAPE.RECTANGLE)
text(s, 0.8, 1.2, 8, 0.4, "FIAP · FASE 6", size=14, color=BLUE, bold=True)
text(s, 0.8, 1.7, 8.0, 2.2, ["Smart HAS", [("Oracle PL/SQL integrado", TEXT, True)], [("ao ecossistema", TEXT, True)]], size=40, bold=True)
text(s, 0.8, 4.35, 7.6, 1.2, "Procedures e functions no banco, conectadas ao back-end Java, ao app Flutter "
     "e ao painel Angular por uma única API REST.", size=18, color=DIM)
box(s, 8.9, 1.3, 3.8, 4.9)
ph = box(s, 9.65, 1.7, 2.3, 2.3, fill=SURFACE2, shape=MSO_SHAPE.OVAL)
text(s, 9.65, 2.6, 2.3, 0.5, "FOTO", size=14, color=DIM, bold=True, align=PP_ALIGN.CENTER)
text(s, 9.0, 4.25, 3.6, 1.2, "Giovanna Cardoso Pinheiro Cury Marques", size=17, bold=True, align=PP_ALIGN.CENTER)
text(s, 9.0, 5.35, 3.6, 0.5, "RM 554433", size=16, color=BLUE, bold=True, align=PP_ALIGN.CENTER)
text(s, 0.8, 6.3, 8, 0.8, [[("GitHub: ", DIM, True), ("(inserir link)", TEXT, False)],
                           [("Vídeo: ", DIM, True), ("(inserir link do YouTube — não listado)", TEXT, False)]], size=14)

# 2 — Contexto e objetivos ---------------------------------------------------
s = slide_base("Da API com H2 à inteligência no banco", "Contexto e objetivos")
card(s, 0.6, 1.9, 3.9, 3.6, "Fase 5 (MVP)", ["Flutter + Spring Boot + Angular", "API REST com JWT",
     "H2 em memória: CRUD de sensores e alertas", "Sem histórico, sem regras automáticas"], accent=DIM, size=16)
card(s, 4.72, 1.9, 3.9, 3.6, "Objetivo da Fase 6", ["Persistência Oracle com modelo relacional",
     "Regras de monitoramento em PL/SQL", "Procedure disparada por evento do back-end",
     "REST → Java → JDBC → Oracle"], accent=BLUE, size=16)
card(s, 8.84, 1.9, 3.9, 3.6, "Resultado", ["6 tabelas · 4 functions · 5 procedures", "~2.700 leituras simuladas (7 dias)",
     "Alertas automáticos + relatórios + watchdog", "25 testes H2 + 4 testes no Oracle real"], accent=GREEN, size=16)

text(s, 0.6, 5.85, 12.1, 0.9, "Fase 6: a inteligência de monitoramento (classificar, alertar, medir, consolidar, vigiar) passa a rodar no Oracle, "
     "reutilizável pelo app, pelo painel e por jobs agendados.", size=15, color=DIM)

# 3 — Arquitetura ------------------------------------------------------------
s = slide_base("Arquitetura: a regra vive no banco, o Java orquestra", "Integração entre camadas")
for i, (label, sub) in enumerate([("Flutter", "app de campo"), ("Angular", "painel admin")]):
    box(s, 0.6, 2.0 + i * 1.6, 2.2, 1.2, line=BLUE)
    text(s, 0.6, 2.15 + i * 1.6, 2.2, 1, [label, [(sub, DIM, False)]], size=17, bold=True, align=PP_ALIGN.CENTER)
text(s, 2.9, 2.75, 1.4, 0.8, ["REST", "JWT"], size=13, color=BLUE, bold=True, align=PP_ALIGN.CENTER)
box(s, 4.3, 1.8, 4.6, 3.7, line=BLUE)
text(s, 4.5, 1.95, 4.2, 0.5, "Spring Boot", size=18, bold=True)
for j, (label, c) in enumerate([("Controller  →  Service", TEXT), ("SensorAnalyticsGateway (porta)", BLUE),
                                ("OraclePlSqlAnalyticsGateway", GREEN), ("JpaAnalyticsGateway (H2, testes)", DIM)]):
    box(s, 4.55, 2.55 + j * 0.7, 4.1, 0.55, fill=SURFACE2)
    text(s, 4.65, 2.6 + j * 0.7, 3.9, 0.5, label, size=13, color=c, bold=True)
text(s, 9.0, 2.75, 1.2, 0.8, ["JDBC"], size=13, color=GREEN, bold=True, align=PP_ALIGN.CENTER)
box(s, 10.2, 1.8, 2.55, 3.7, line=RED)
text(s, 10.3, 1.95, 2.4, 3.5, ["Oracle", [("PRC_* · FN_*", RED, True)], [("6 tabelas SHAS_*", DIM, False)],
                              [("DBMS_SCHEDULER", DIM, False)], [("log autônomo", DIM, False)]], size=17, bold=True)
text(s, 0.6, 5.85, 12.1, 1, "Ports & Adapters: o perfil Spring escolhe o adapter. Com ‘oracle’, as regras executam em PL/SQL "
     "(Hibernate só valida o schema); sem Oracle, o mesmo contrato roda em Java para demo e testes.", size=14, color=DIM)

# 4 — Parte 1 ----------------------------------------------------------------
s = slide_base("Parte 1 — O que evoluiu", "Aprimoramento da solução")
card(s, 0.6, 1.8, 6.0, 4.9, "Novas funcionalidades", ["• Telemetria: registro e histórico de leituras",
     "• Classificação NORMAL / ALERTA / CRÍTICA por limites", "• Alertas automáticos com deduplicação e escalonamento",
     "• Indicadores: conformidade 24h/7d e risco por local", "• Relatório diário, resumo por responsável, auditoria",
     "• Watchdog de sensores inativos + simulador IoT"], accent=GREEN, size=15)
card(s, 6.75, 1.8, 6.0, 4.9, "Refatoração e boas práticas", ["• Ports & Adapters (gateway por perfil)",
     "• Schema versionado em SQL + ddl-auto=validate", "• ORA-20001 → 404 · ORA-20002..04 → 422",
     "• Transação online x batch explícita", "• Contrato REST retrocompatível",
     "• Angular: KPIs do back-end, pt-BR, design system", "• Flutter: fallback central + --dart-define"], accent=BLUE, size=15)

# 5 — DER --------------------------------------------------------------------
s = slide_base("Parte 2 — Modelo relacional Oracle", "DER e implantação")
picture(s, HERE / "der_smarthas.png", 0.6, 1.6, w=8.6)
card(s, 9.45, 1.6, 3.3, 5.2, "Implantação", ["instalar_tudo.sql (reexecutável)", "Docker: Oracle 23ai Free, instala sozinho",
     "SQL Developer: servidor FIAP (19c)", "Constraints nomeadas + COMMENT", "Carga PL/SQL reprodutível:",
     "3 usuários · 8 sensores", "2.685 leituras · 40 alertas", "64 linhas de relatório"], accent=AMBER, size=13)

# 6 — Functions --------------------------------------------------------------
s = slide_base("Parte 3 — Functions: indicadores e dados formatados", "PL/SQL")
fns = [("FN_CALC_CONFORMIDADE", "Indicador", "% de leituras normais na janela (24h, 7d). NULL sem dados.", GREEN),
       ("FN_CALC_INDICE_RISCO", "Indicador", "0–100 por local: alertas ponderados + sensores degradados.", RED),
       ("FN_FORMATAR_LEITURA", "Dados formatados", "“Sensor 03 (Qualidade do Ar) | 162,40 AQI | CRITICA | 27/09 20:20”", BLUE),
       ("FN_CLASSIFICAR_LEITURA", "Regra (DETERMINISTIC)", "NORMAL / ALERTA / CRITICA, reutilizada pelas procedures.", AMBER)]
for k, (name, kind, desc, c) in enumerate(fns):
    x, y = 0.6 + (k % 2) * 6.15, 1.75 + (k // 2) * 1.75
    card(s, x, y, 6.0, 1.55, name, [[(kind + " · ", c, True), (desc, DIM, False)]], accent=c, size=13)
box(s, 0.6, 5.35, 12.15, 1.45, fill=RGBColor(0x0B, 0x12, 0x20), line=SURFACE2)
text(s, 0.8, 5.45, 11.8, 1.3, ["SELECT localizacao, fn_calc_indice_risco(localizacao) AS risco",
     "  FROM (SELECT DISTINCT localizacao FROM shas_sensor) ORDER BY 2 DESC;   → Marginal Tietê 75 · Ibirapuera 50",
     "Boas práticas: IN/RETURN com %TYPE · RAISE_APPLICATION_ERROR · NO_DATA_FOUND tratado (evita NULL silencioso)"],
     size=12, color=GREEN, font="Consolas")

# 7 — Procedures -------------------------------------------------------------
s = slide_base("Parte 3 — Procedures: rotinas de back-end no banco", "PL/SQL")
prcs = [("PRC_REGISTRAR_LEITURA", "Online · chamada pelo Java", "Valida → FOR UPDATE → classifica → grava → atualiza sensor → cria / deduplica / escalona alerta. SAVEPOINT + EXCEPTION.", RED),
        ("PRC_GERAR_RELATORIO_DIARIO", "Batch · job 23:55", "CURSOR + FOR LOOP + MERGE idempotente, usando as functions.", BLUE),
        ("PRC_VERIFICAR_SENSORES_INATIVOS", "Batch · job 15 min", "OPEN/FETCH/CLOSE, WHERE CURRENT OF: marca OFFLINE e abre alerta.", AMBER),
        ("PRC_RESUMO_POR_RESPONSAVEL", "Consulta · SYS_REFCURSOR", "Resumo por usuário, lido no Java como ResultSet.", GREEN)]
for k, (name, kind, desc, c) in enumerate(prcs):
    y = 1.7 + k * 1.2
    box(s, 0.6, y, 12.15, 1.05)
    box(s, 0.6, y, 0.08, 1.05, fill=c, shape=MSO_SHAPE.RECTANGLE)
    text(s, 0.9, y + 0.12, 4.6, 0.9, [name, [(kind, c, True)]], size=15, bold=True)
    text(s, 5.6, y + 0.18, 7.0, 0.9, desc, size=13, color=DIM)
text(s, 0.6, 6.55, 12.1, 0.4, "+ PRC_REGISTRAR_LOG (AUTONOMOUS_TRANSACTION): toda execução e todo erro ficam auditados, mesmo após ROLLBACK.",
     size=13, color=DIM)

# 8 — Integração Java --------------------------------------------------------
s = slide_base("REST → Java → JDBC → Oracle", "Integração com o back-end")
box(s, 0.6, 1.7, 6.9, 4.1, fill=RGBColor(0x0B, 0x12, 0x20), line=SURFACE2)
text(s, 0.8, 1.85, 6.6, 3.9, ["new SimpleJdbcCall(jdbcTemplate)", "  .withProcedureName(\"PRC_REGISTRAR_LEITURA\")",
     "  .withoutProcedureColumnMetaDataAccess()", "  .withNamedBinding()   // p_x => ?", "  .declareParameters(",
     "     IN  p_id_sensor, p_valor, p_dt_leitura", "     OUT p_id_leitura, p_classificacao,", "         p_id_alerta);",
     "", "// SYS_REFCURSOR", "new SqlOutParameter(\"p_cursor\",", "    OracleTypes.CURSOR, RESPONSIBLE_MAPPER)"],
     size=12, color=GREEN, font="Consolas")
card(s, 7.7, 1.7, 5.05, 4.1, "Endpoints → Oracle", ["POST /sensors/{id}/readings → PRC_REGISTRAR_LEITURA",
     "GET /sensors/{id}/indicators → 3 functions", "GET /reports/responsibles → ref cursor",
     "POST /routines/* (ADMIN) → rotinas batch", "", "ORA-20001 → HTTP 404", "ORA-20002..04 → HTTP 422",
     "Transação: @Transactional (online) · COMMIT na procedure (batch)"], accent=GREEN, size=13)
text(s, 0.6, 6.05, 12.1, 0.8, "Evento de back-end: cada leitura do app, do painel ou do simulador IoT (@Scheduled) dispara a procedure. "
     "Validado por teste de integração contra o Oracle real.", size=14, color=DIM)

# 9 — Demonstração -----------------------------------------------------------
s = slide_base("Demonstração: leitura crítica vira alerta automático", "Aplicação rodando")
picture(s, HERE / "prints" / "02_sensor_detalhe.png", 0.6, 1.6, h=5.25)
picture(s, HERE / "prints" / "03_relatorios.png", 7.0, 1.6, h=5.25)
text(s, 10.75, 1.7, 2.1, 5, ["1. Registrar 91,3 dB", [("→ CRITICA, alerta #42", RED, True)], "",
     "2. Risco do local sobe para 50", "", "3. Relatório, ref cursor e auditoria no painel"], size=13, color=DIM)

# 10 — Resultados ------------------------------------------------------------
s = slide_base("Resultados e próximos passos", "Conclusão")
stats = [("6", "tabelas"), ("4", "functions"), ("5", "procedures"), ("2.685", "leituras"), ("29", "testes")]
for k, (n, lbl) in enumerate(stats):
    x = 0.6 + k * 2.47
    box(s, x, 1.75, 2.27, 1.55)
    text(s, x, 1.85, 2.27, 0.8, n, size=34, bold=True, color=BLUE, align=PP_ALIGN.CENTER)
    text(s, x, 2.7, 2.27, 0.5, lbl, size=14, color=DIM, align=PP_ALIGN.CENTER)
card(s, 0.6, 3.6, 6.0, 3.1, "Valor entregue", ["Regra única para app, painel e jobs", "Alertas sem intervenção humana",
     "KPIs de qualidade e risco para decisão", "Auditoria e reprocessamento (governança)"], accent=GREEN, size=15)
card(s, 6.75, 3.6, 6.0, 3.1, "Próximos passos", ["Deploy em nuvem (Oracle Autonomous + HTTPS)", "Push (FCM) para alertas críticos",
     "Camada de IA sobre a série histórica", "Particionamento de SHAS_LEITURA por data"], accent=AMBER, size=15)

out = HERE / "Slides_Fase6.pptx"
prs.save(out)
print("PPTX:", out)

import win32com.client  # noqa: E402

app = win32com.client.DispatchEx("PowerPoint.Application")
try:
    deck = app.Presentations.Open(str(out), WithWindow=False)
    deck.SaveAs(str(out.with_suffix(".pdf")), 32)
    deck.Close()
finally:
    app.Quit()
print("PDF: ", out.with_suffix(".pdf"))
