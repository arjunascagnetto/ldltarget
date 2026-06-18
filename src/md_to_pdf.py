# -*- coding: utf-8 -*-
"""
Converte reports/studio_target_ldl.md in un PDF con immagini.
markdown -> HTML (con estensioni tabelle/codice) -> PDF (xhtml2pdf).
"""
import os
import markdown
from xhtml2pdf import pisa

PROJ    = r"D:/SAS-CCV/DOWNLOAD/DAICHILDL/ldltarget"
MD      = os.path.join(PROJ, "reports", "studio_target_ldl.md")
PDF     = os.path.join(PROJ, "reports", "studio_target_ldl.pdf")
BASEDIR = os.path.join(PROJ, "reports")   # base per i path relativi (../outputs)

CSS = """
@page { size: A4; margin: 1.8cm; }
body { font-family: Helvetica, Arial, sans-serif; font-size: 10pt; color:#222; line-height:1.4; }
h1 { font-size: 19pt; color:#1a3e6e; border-bottom:2px solid #1a3e6e; padding-bottom:4px; }
h2 { font-size: 15pt; color:#1a3e6e; margin-top:18px; border-bottom:1px solid #bcd; padding-bottom:2px; }
h3 { font-size: 12.5pt; color:#244; margin-top:14px; }
table { border-collapse: collapse; width: 100%; margin: 8px 0; }
th, td { border: 1px solid #999; padding: 3px 6px; font-size: 8.5pt; }
th { background-color: #dce6f1; }
code { background:#f0f0f0; font-family: Courier, monospace; font-size: 8.5pt; }
img { max-width: 15cm; }
"""

def link_callback(uri, rel):
    """Risolve i path relativi delle immagini (../outputs/...) in path assoluti."""
    if uri.startswith(("http://", "https://", "data:")):
        return uri
    path = os.path.normpath(os.path.join(BASEDIR, uri))
    if not os.path.isfile(path):
        print("ATTENZIONE: immagine non trovata:", path)
    return path

def main():
    with open(MD, encoding="utf-8") as f:
        md_text = f.read()
    html_body = markdown.markdown(
        md_text,
        extensions=["tables", "fenced_code", "sane_lists"],
    )
    html = f"<html><head><meta charset='utf-8'><style>{CSS}</style></head><body>{html_body}</body></html>"

    with open(PDF, "wb") as out:
        status = pisa.CreatePDF(html, dest=out, link_callback=link_callback,
                                encoding="utf-8")
    if status.err:
        print("ERRORE nella generazione del PDF")
    else:
        print("PDF creato:", PDF)

if __name__ == "__main__":
    main()
