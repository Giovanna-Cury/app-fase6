"""Converte docs/FASE6_DOCUMENTACAO.md em Word (.docx) e PDF (via Microsoft Word).

Uso:  python gerar_documento.py [pasta_saida]
Suporta o subconjunto de Markdown usado no documento: titulos, paragrafos,
listas, tabelas, blocos de codigo, imagens, **negrito** e `codigo`.
"""
import re
import sys
from pathlib import Path

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

DOCS = Path(__file__).resolve().parent.parent
SOURCE = DOCS / "FASE6_DOCUMENTACAO.md"
OUT_DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else DOCS / "fase6"
BLUE = RGBColor(0x1E, 0x40, 0xAF)
INLINE = re.compile(r"(\*\*[^*]+\*\*|`[^`]+`|\*[^*]+\*)")


def shade(cell_or_par, hex_color):
    props = cell_or_par._tc.get_or_add_tcPr() if hasattr(cell_or_par, "_tc") else cell_or_par._p.get_or_add_pPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), hex_color)
    props.append(shd)


def add_inline(paragraph, text, size=None, bold=False, color=None):
    for part in INLINE.split(text):
        if not part:
            continue
        if part.startswith("**"):
            run = paragraph.add_run(part[2:-2]); run.bold = True
        elif part.startswith("`"):
            run = paragraph.add_run(part[1:-1]); run.font.name = "Consolas"
            run.font.color.rgb = RGBColor(0x9D, 0x17, 0x4D)
        elif part.startswith("*") and len(part) > 2:
            run = paragraph.add_run(part[1:-1]); run.italic = True
        else:
            run = paragraph.add_run(part)
        if bold:
            run.bold = True
        if size:
            run.font.size = Pt(size)
        if color:
            run.font.color.rgb = color


def add_table(doc, rows):
    header, body = rows[0], rows[2:]
    table = doc.add_table(rows=1, cols=len(header))
    table.style = "Table Grid"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, text in enumerate(header):
        cell = table.rows[0].cells[i]
        cell.text = ""
        add_inline(cell.paragraphs[0], text, size=9, bold=True, color=RGBColor(0xFF, 0xFF, 0xFF))
        shade(cell, "1E40AF")
    for r, row in enumerate(body):
        cells = table.add_row().cells
        for i, text in enumerate(row[: len(header)]):
            cells[i].text = ""
            add_inline(cells[i].paragraphs[0], text, size=9)
            if r % 2:
                shade(cells[i], "EEF2F7")
    doc.add_paragraph()


def add_code(doc, lines):
    for line in lines:
        p = doc.add_paragraph()
        p.paragraph_format.space_after = Pt(0)
        p.paragraph_format.space_before = Pt(0)
        run = p.add_run(line if line else " ")
        run.font.name = "Consolas"
        run.font.size = Pt(8)
        shade(p, "F1F5F9")
    doc.add_paragraph()


def build():
    doc = Document()
    for section in doc.sections:
        section.left_margin = section.right_margin = Cm(2)
        section.top_margin = section.bottom_margin = Cm(2)
    doc.styles["Normal"].font.name = "Calibri"
    doc.styles["Normal"].font.size = Pt(10.5)
    for level in (1, 2, 3):
        doc.styles[f"Heading {level}"].font.color.rgb = BLUE

    lines = SOURCE.read_text(encoding="utf-8").splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("```"):
            block = []
            i += 1
            while not lines[i].startswith("```"):
                block.append(lines[i]); i += 1
            add_code(doc, block)
        elif line.startswith("|"):
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                rows.append([c.strip() for c in lines[i].strip().strip("|").split("|")]); i += 1
            add_table(doc, rows)
            continue
        elif line.startswith("![") and "](" in line:
            alt, path = re.match(r"!\[(.*)\]\((.*)\)", line).groups()
            doc.add_picture(str(DOCS / path), width=Cm(16.5))
            doc.paragraphs[-1].alignment = WD_ALIGN_PARAGRAPH.CENTER
            cap = doc.add_paragraph()
            cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
            add_inline(cap, alt, size=9, color=RGBColor(0x64, 0x74, 0x8B))
        elif line.startswith("# "):
            title = doc.add_paragraph()
            title.alignment = WD_ALIGN_PARAGRAPH.CENTER
            add_inline(title, line[2:], size=24, bold=True, color=BLUE)
            if i + 2 < len(lines) and lines[i + 2] and not lines[i + 2].startswith("#"):
                sub = doc.add_paragraph()
                sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
                add_inline(sub, lines[i + 2], size=12, color=RGBColor(0x47, 0x55, 0x69))
                i += 2
            doc.add_paragraph("FIAP · Fase 6").alignment = WD_ALIGN_PARAGRAPH.CENTER
        elif line.startswith("### "):
            doc.add_heading(line[4:], level=2)
        elif line.startswith("## "):
            doc.add_heading(line[3:], level=1)
        elif line.startswith("- "):
            add_inline(doc.add_paragraph(style="List Bullet"), line[2:])
        elif re.match(r"^\d+\. ", line):
            # numero explicito: "List Number" do Word continua a contagem entre listas
            p = doc.add_paragraph()
            p.paragraph_format.left_indent = Cm(0.9)
            p.paragraph_format.first_line_indent = Cm(-0.5)
            add_inline(p, line)
        elif line.strip():
            add_inline(doc.add_paragraph(), line)
        i += 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    docx_path = OUT_DIR / "Docs_Fase6.docx"
    doc.save(docx_path)
    return docx_path


def to_pdf(docx_path):
    import win32com.client
    word = win32com.client.DispatchEx("Word.Application")
    word.Visible = False
    try:
        document = word.Documents.Open(str(docx_path))
        pdf_path = docx_path.with_suffix(".pdf")
        document.SaveAs(str(pdf_path), FileFormat=17)
        document.Close(False)
        return pdf_path
    finally:
        word.Quit()


if __name__ == "__main__":
    path = build()
    print("DOCX:", path)
    print("PDF: ", to_pdf(path))
