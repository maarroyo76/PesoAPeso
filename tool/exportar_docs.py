"""Exporta los documentos Markdown de docs/ a Word (.docx) para la entrega.

Los diagramas Mermaid se dibujan con Chrome sin interfaz y se insertan como
imagen. Uso:

    python3 -m venv /tmp/venv && /tmp/venv/bin/pip install python-docx pillow
    /tmp/venv/bin/python tool/exportar_docs.py docs "Documentos Capstone/Fase 2/Evidencias Proyecto/Evidencias de documentación"

El primer argumento es la carpeta de los .md y el segundo, donde quedan los
.docx. Necesita Google Chrome instalado y conexión para cargar Mermaid desde
cdn.jsdelivr.net. Convierte el subconjunto de Markdown que usan estos
documentos: títulos, párrafos, listas, casillas, tablas, bloques de código,
negrita, cursiva, código y enlaces.
"""

import hashlib
import html
import pathlib
import re
import subprocess
import sys
import tempfile

from docx import Document
from docx.enum.section import WD_ORIENT, WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor
from PIL import Image, ImageChops

MERMAID = "https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.min.js"
INK = RGBColor(0x4B, 0x2E, 0x6B)
CACHE = pathlib.Path(tempfile.gettempdir()) / "peso_a_peso_mermaid"


def render_mermaid(code: str) -> pathlib.Path:
    """PNG del diagrama, recortado; se reutiliza si el código no cambió."""
    CACHE.mkdir(exist_ok=True)
    out = CACHE / (hashlib.sha1(code.encode()).hexdigest() + ".png")
    if out.exists():
        return out
    page = f"""<!doctype html><html><head><meta charset="utf-8">
<style>body{{margin:0;background:#fff;font-family:sans-serif}} .mermaid{{padding:16px}}</style>
<script src="{MERMAID}"></script></head><body>
<pre class="mermaid">{html.escape(code)}</pre>
<script>mermaid.initialize({{startOnLoad:true, theme:'neutral'}});</script>
</body></html>"""
    page_file = CACHE / (out.stem + ".html")
    page_file.write_text(page, encoding="utf-8")
    raw = CACHE / (out.stem + ".raw.png")
    subprocess.run(
        ["google-chrome", "--headless=new", "--disable-gpu", "--hide-scrollbars",
         "--window-size=1600,4000", "--force-device-scale-factor=2",
         "--virtual-time-budget=15000", f"--screenshot={raw}", page_file.as_uri()],
        check=True, capture_output=True)
    img = Image.open(raw).convert("RGB")
    box = ImageChops.difference(img, Image.new("RGB", img.size, "white")).getbbox()
    if box is None:
        raise RuntimeError("El diagrama Mermaid salió vacío; revisa su sintaxis.")
    left, top, right, bottom = box
    img.crop((max(left - 20, 0), max(top - 20, 0),
              min(right + 20, img.width), min(bottom + 20, img.height))).save(out)
    raw.unlink()
    page_file.unlink()
    return out


def add_diagram(doc, png: pathlib.Path):
    """Inserta el diagrama; los muy anchos van en una página horizontal para
    que el texto siga siendo legible."""
    width, height = Image.open(png).size
    if width / height < 1.6:
        doc.add_picture(str(png), width=Cm(16.5))
        return
    landscape = doc.add_section(WD_SECTION.NEW_PAGE)
    landscape.orientation = WD_ORIENT.LANDSCAPE
    landscape.page_width, landscape.page_height = (
        landscape.page_height, landscape.page_width)
    doc.add_picture(str(png), width=Cm(25))
    portrait = doc.add_section(WD_SECTION.NEW_PAGE)
    portrait.orientation = WD_ORIENT.PORTRAIT
    portrait.page_width, portrait.page_height = (
        portrait.page_height, portrait.page_width)


INLINE = re.compile(r"(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`|\[[^\]]+\]\([^)]+\))")


def add_inline(paragraph, text: str):
    """Agrega texto con negrita, cursiva, código y enlaces (sin el URL)."""
    for part in INLINE.split(text):
        if not part:
            continue
        if part.startswith("**"):
            run = paragraph.add_run(part[2:-2])
            run.bold = True
        elif part.startswith("`"):
            run = paragraph.add_run(part[1:-1])
            run.font.name = "Consolas"
            run.font.size = Pt(9.5)
        elif part.startswith("["):
            run = paragraph.add_run(re.match(r"\[([^\]]+)\]", part).group(1))
        elif part.startswith("*"):
            run = paragraph.add_run(part[1:-1])
            run.italic = True
        else:
            paragraph.add_run(part)


def shade(cell, color: str):
    props = cell._tc.get_or_add_tcPr()
    fill = OxmlElement("w:shd")
    fill.set(qn("w:val"), "clear")
    fill.set(qn("w:color"), "auto")
    fill.set(qn("w:fill"), color)
    props.append(fill)


def add_table(doc, rows):
    cells = [[c.strip() for c in r.strip().strip("|").split("|")] for r in rows]
    cells = [r for r in cells if not all(re.fullmatch(r":?-{3,}:?", c) for c in r)]
    table = doc.add_table(rows=len(cells), cols=len(cells[0]))
    table.style = "Table Grid"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, row in enumerate(cells):
        for j, value in enumerate(row[: len(cells[0])]):
            cell = table.cell(i, j)
            cell.text = ""
            p = cell.paragraphs[0]
            add_inline(p, value)
            for run in p.runs:
                run.font.size = Pt(9)
                if i == 0:
                    run.bold = True
            if i == 0:
                shade(cell, "E7DEEC")
    doc.add_paragraph()


def convert(md_path: pathlib.Path, out_dir: pathlib.Path) -> pathlib.Path:
    doc = Document()
    for section in doc.sections:
        section.left_margin = section.right_margin = Cm(2.2)
    normal = doc.styles["Normal"]
    normal.font.name = "Calibri"
    normal.font.size = Pt(11)
    for level in range(1, 4):
        doc.styles[f"Heading {level}"].font.color.rgb = INK

    lines = md_path.read_text(encoding="utf-8").splitlines()
    i = 0
    paragraph: list[str] = []

    def flush():
        if paragraph:
            add_inline(doc.add_paragraph(), " ".join(paragraph))
            paragraph.clear()

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if stripped.startswith("```"):
            flush()
            lang = stripped[3:].strip()
            block = []
            i += 1
            while i < len(lines) and not lines[i].strip().startswith("```"):
                block.append(lines[i])
                i += 1
            if lang == "mermaid":
                add_diagram(doc, render_mermaid("\n".join(block)))
            else:
                p = doc.add_paragraph()
                run = p.add_run("\n".join(block))
                run.font.name = "Consolas"
                run.font.size = Pt(9)
        elif stripped.startswith("|"):
            flush()
            rows = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                rows.append(lines[i])
                i += 1
            add_table(doc, rows)
            continue
        elif m := re.match(r"(#{1,4})\s+(.*)", stripped):
            flush()
            doc.add_heading(m.group(2), level=len(m.group(1)))
        elif m := re.match(r"- \[( |x)\]\s+(.*)", stripped):
            flush()
            text = m.group(2)
            while i + 1 < len(lines) and lines[i + 1].startswith("  ") and lines[i + 1].strip():
                i += 1
                text += " " + lines[i].strip()
            add_inline(doc.add_paragraph(style="List Bullet"), ("☑ " if m.group(1) == "x" else "☐ ") + text)
        elif m := re.match(r"(-|\d+\.)\s+(.*)", stripped):
            flush()
            text = m.group(2)
            while i + 1 < len(lines) and lines[i + 1].startswith("  ") and lines[i + 1].strip():
                i += 1
                text += " " + lines[i].strip()
            style = "List Bullet" if m.group(1) == "-" else "List Number"
            add_inline(doc.add_paragraph(style=style), text)
        elif not stripped:
            flush()
        else:
            paragraph.append(stripped)
        i += 1
    flush()

    out = out_dir / (md_path.stem + ".docx")
    doc.save(out)
    return out


if __name__ == "__main__":
    source, target = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    target.mkdir(parents=True, exist_ok=True)
    for md in sorted(source.glob("[0-9][0-9]_*.md")):
        print("→", convert(md, target).name)
