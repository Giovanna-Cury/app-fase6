"""Gera o DER (modelo relacional) do Smart HAS em SVG a partir da definicao
das tabelas de database/scripts/01_ddl_tabelas.sql."""

TABLES = {
    "SHAS_USUARIO": (40, 70, [
        ("PK", "id_usuario", "NUMBER(10)"), ("", "nome", "VARCHAR2(100)"),
        ("UK", "username", "VARCHAR2(50)"), ("UK", "email", "VARCHAR2(120)"),
        ("", "senha_hash", "VARCHAR2(100)"), ("", "perfil", "VARCHAR2(20)"),
        ("", "dt_criacao", "TIMESTAMP")]),
    "SHAS_SENSOR": (560, 70, [
        ("PK", "id_sensor", "NUMBER(10)"), ("", "nome", "VARCHAR2(100)"),
        ("", "tipo", "VARCHAR2(50)"), ("", "status", "VARCHAR2(20)"),
        ("", "localizacao", "VARCHAR2(150)"), ("", "valor_atual", "NUMBER(12,2)"),
        ("", "unidade", "VARCHAR2(20)"), ("", "latitude", "NUMBER(9,6)"),
        ("", "longitude", "NUMBER(9,6)"), ("", "limite_alerta", "NUMBER(12,2)"),
        ("", "limite_critico", "NUMBER(12,2)"), ("FK", "id_responsavel", "NUMBER(10)"),
        ("", "dt_atualizacao", "TIMESTAMP")]),
    "SHAS_LEITURA": (1100, 70, [
        ("PK", "id_leitura", "NUMBER(12)"), ("FK", "id_sensor", "NUMBER(10)"),
        ("", "valor", "NUMBER(12,2)"), ("", "classificacao", "VARCHAR2(10)"),
        ("", "dt_leitura", "TIMESTAMP")]),
    "SHAS_ALERTA": (1100, 470, [
        ("PK", "id_alerta", "NUMBER(10)"), ("", "titulo", "VARCHAR2(150)"),
        ("", "descricao", "VARCHAR2(1000)"), ("", "severidade", "VARCHAR2(10)"),
        ("", "localizacao", "VARCHAR2(150)"), ("", "origem", "VARCHAR2(10)"),
        ("FK", "id_sensor", "NUMBER(10)"), ("FK", "id_leitura", "NUMBER(12)"),
        ("", "resolvido", "NUMBER(1)"), ("", "dt_criacao", "TIMESTAMP"),
        ("", "dt_resolucao", "TIMESTAMP")]),
    "SHAS_RELATORIO_DIARIO": (560, 560, [
        ("PK", "id_relatorio", "NUMBER(12)"), ("FK", "id_sensor", "NUMBER(10)"),
        ("", "dt_referencia", "DATE"), ("", "qtd_leituras", "NUMBER(10)"),
        ("", "qtd_alertas", "NUMBER(10)"), ("", "qtd_criticas", "NUMBER(10)"),
        ("", "valor_minimo / medio / maximo", "NUMBER(12,2)"),
        ("", "conformidade", "NUMBER(5,2)"), ("", "resumo", "VARCHAR2(400)"),
        ("", "dt_geracao", "TIMESTAMP")]),
    "SHAS_LOG_EXECUCAO": (40, 560, [
        ("PK", "id_log", "NUMBER(12)"), ("", "rotina", "VARCHAR2(60)"),
        ("", "nivel", "VARCHAR2(10)"), ("", "mensagem", "VARCHAR2(4000)"),
        ("", "dt_log", "TIMESTAMP")]),
}
W, HEAD, ROW = 400, 38, 25


def box(name):
    x, y, cols = TABLES[name]
    return x, y, W, HEAD + ROW * len(cols) + 8


def row_y(name, col):
    x, y, cols = TABLES[name]
    idx = [c[1] for c in cols].index(col)
    return y + HEAD + ROW * idx + ROW / 2 + 4


out = ['<svg xmlns="http://www.w3.org/2000/svg" width="1540" height="930" viewBox="0 0 1540 930" '
       'font-family="Segoe UI, Arial, sans-serif">',
       '<defs>',
       '<marker id="many" viewBox="0 0 20 20" refX="19" refY="10" markerWidth="11" markerHeight="11" orient="auto">'
       '<path d="M19 10 L1 1 M19 10 L1 10 M19 10 L1 19" stroke="#334155" stroke-width="2" fill="none"/>'
       '<path d="M1 1 L1 19" stroke="#334155" stroke-width="2"/></marker>',
       '<marker id="one" viewBox="0 0 20 20" refX="1" refY="10" markerWidth="11" markerHeight="11" orient="auto">'
       '<path d="M6 1 L6 19 M11 1 L11 19" stroke="#334155" stroke-width="2"/></marker>',
       '</defs>',
       '<rect width="1540" height="930" fill="#ffffff"/>',
       '<text x="40" y="40" font-size="24" font-weight="700" fill="#0f172a">Smart HAS — Modelo Relacional (DER físico Oracle)</text>',
       '<text x="1500" y="40" font-size="14" text-anchor="end" fill="#64748b">notação pé-de-galinha · PK chave primária · FK chave estrangeira · UK única</text>']

# Relacionamentos (desenhados antes das tabelas para ficarem por baixo)
rels = [
    # (path, rotulo, pos_rotulo)
    (f"M {40+W} {row_y('SHAS_USUARIO','id_usuario')} H 500 V {row_y('SHAS_SENSOR','id_responsavel')} H 560",
     "responsável (0..N)", (505, row_y('SHAS_USUARIO', 'id_usuario') - 8)),
    (f"M {560+W} {row_y('SHAS_SENSOR','id_sensor')} H 1100",
     "gera (0..N)", (1030, row_y('SHAS_SENSOR', 'id_sensor') - 10)),
    (f"M {560+W} {row_y('SHAS_SENSOR','localizacao')} H 1040 V {row_y('SHAS_ALERTA','id_sensor')} H 1100",
     "origina (0..N)", (1040, 420)),
    (f"M {1100+W-60} {box('SHAS_LEITURA')[1]+box('SHAS_LEITURA')[3]} V 470",
     "dispara (0..N)", (1440, 420)),
    (f"M 760 {box('SHAS_SENSOR')[1]+box('SHAS_SENSOR')[3]} V 560",
     "consolidado em (0..N)", (760, 530)),
]
for d, label, (lx, ly) in rels:
    out.append(f'<path d="{d}" fill="none" stroke="#334155" stroke-width="2" marker-start="url(#one)" marker-end="url(#many)"/>')
    out.append(f'<text x="{lx}" y="{ly}" font-size="13" font-weight="600" fill="#334155" text-anchor="middle" '
               f'stroke="#ffffff" stroke-width="5" paint-order="stroke">{label}</text>')

for name, (x, y, cols) in TABLES.items():
    _, _, w, h = box(name)
    audit = name == "SHAS_LOG_EXECUCAO"
    head_color = "#475569" if audit else "#1e40af"
    out.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="10" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.5"/>')
    out.append(f'<path d="M{x} {y+HEAD} V{y+10} Q{x} {y} {x+10} {y} H{x+w-10} Q{x+w} {y} {x+w} {y+10} V{y+HEAD} Z" fill="{head_color}"/>')
    out.append(f'<text x="{x+14}" y="{y+25}" font-size="16" font-weight="700" fill="#ffffff">{name}</text>')
    for i, (key, col, typ) in enumerate(cols):
        ry = y + HEAD + ROW * i + ROW / 2 + 9
        if i % 2 == 1:
            out.append(f'<rect x="{x+1}" y="{y+HEAD+ROW*i+4}" width="{w-2}" height="{ROW}" fill="#eef2f7"/>')
        color = {"PK": "#b45309", "FK": "#1d4ed8", "UK": "#047857"}.get(key, "#0f172a")
        if key:
            out.append(f'<text x="{x+14}" y="{ry}" font-size="11" font-weight="700" fill="{color}">{key}</text>')
        weight = "700" if key == "PK" else "400"
        out.append(f'<text x="{x+46}" y="{ry}" font-size="14" font-weight="{weight}" fill="#0f172a">{col}</text>')
        out.append(f'<text x="{x+w-14}" y="{ry}" font-size="13" fill="#64748b" text-anchor="end">{typ}</text>')

out.append('<text x="40" y="912" font-size="13" fill="#64748b">SHAS_LOG_EXECUCAO é independente (trilha de auditoria gravada por PRC_REGISTRAR_LOG em transação autônoma). '
           'CHECKs: status, perfil, severidade, origem, classificacao, resolvido, limites e coordenadas.</text>')
out.append('</svg>')
open("der_smarthas.svg", "w", encoding="utf-8").write("\n".join(out))
open("der_smarthas.html", "w", encoding="utf-8").write(
    '<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;background:#fff}</style></head><body>'
    + "\n".join(out) + '</body></html>')
print("ok")
