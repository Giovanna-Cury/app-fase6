"""Monta a pasta de entrega (FIAP ON) e o .zip, sem dependencias/artefatos de build.

    python empacotar_entrega.py

Resultado (ao lado da pasta SmartHAS):
    Trabalho_Fase6/Docs_Fase6.pdf, Slides_Fase6.pdf, LINKS.txt, SmartHAS/ (codigo)
    Trabalho_Fase6.zip
"""
import shutil
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parent.parent                 # .../SmartHAS
DELIVERY = PROJECT.parent                    # .../Trabalho_Fase6
EXCLUDED_DIRS = {"node_modules", "target", "dist", ".angular", ".dart_tool", "build", ".idea", "__pycache__"}

for name in ("Docs_Fase6.pdf", "Slides_Fase6.pdf"):
    shutil.copy2(HERE / name, DELIVERY / name)

links = DELIVERY / "LINKS.txt"
if not links.exists():
    links.write_text("Repositorio GitHub: (inserir link)\nVideo YouTube (nao listado): (inserir link)\n", encoding="utf-8")

zip_path = DELIVERY.parent / "Trabalho_Fase6.zip"
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
    for path in sorted(DELIVERY.rglob("*")):
        rel = path.relative_to(DELIVERY)
        if any(part in EXCLUDED_DIRS for part in rel.parts) or path.is_dir():
            continue
        zf.write(path, Path("Trabalho_Fase6") / rel)

print(f"{zip_path} ({zip_path.stat().st_size / 1_048_576:.1f} MB)")
