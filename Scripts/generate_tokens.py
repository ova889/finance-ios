#!/usr/bin/env python3
"""Genera Finance/DesignTokens.swift desde el CSS de la web (fuente de verdad).

Uso:  python3 Scripts/generate_tokens.py
Regenera DesignTokens.swift con los colores :root y las medidas curadas
que mapean selectores CSS -> constantes Swift. El CI falla si hay drift.

Medidas curadas (selectores de la web -> nombre Swift):
  .mobile-nav  (bloque #barra-unica)     -> navPill*
  .nav-item/.nav-item .nav-icon          -> navItem*
  .campo-wayne                            -> campo*
  .btn-wayne / .btn-wayne-sm              -> btnWayne*
  .btn-ghost                              -> btnGhost*
  .c-sum (media <=460px)                  -> resumen*
  .h-title                                -> hTitle*
  .titulo-batsenal (media <=460px)        -> tituloPagina*
  .privacy-toggle                         -> privacidad*
  .toast-offline                          -> toast*
  .barra-presupuesto                      -> barraPresupuesto*
  .navbar (media <=460px)                 -> topBar*
"""

import re
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
CSS = BASE / "Scripts" / "web-reference" / "style.css"
OUT = BASE / "Finance" / "DesignTokens.swift"


def parse_hex(value: str):
    value = value.strip()
    m = re.fullmatch(r"#([0-9a-fA-F]{6})", value)
    if not m:
        return None
    h = m.group(1)
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def clamp_float(text: str) -> float | None:
    m = re.search(r"([\d.]+)px", text)
    return float(m.group(1)) if m else None


def rgba_to_swift(text: str) -> str | None:
    m = re.search(r"rgba\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*\)", text)
    if not m:
        return None
    r, g, b, a = (float(x) for x in m.groups())
    return f"Color(red: {r / 255:.4f}, green: {g / 255:.4f}, blue: {b / 255:.4f}).opacity({a:.2f})"


def get_prop(block: str, prop: str) -> str | None:
    m = re.search(rf"{re.escape(prop)}\s*:\s*([^;]+);", block)
    return m.group(1).strip() if m else None


def get_block(css: str, selector: str) -> str:
    start = css.find(selector)
    if start == -1:
        return ""
    brace = css.find("{", start)
    return extract_braces(css, brace)


def extract_braces(css: str, open_brace: int) -> str:
    depth = 0
    for i in range(open_brace, len(css)):
        if css[i] == "{":
            depth += 1
        elif css[i] == "}":
            depth -= 1
            if depth == 0:
                return css[open_brace + 1:i]
    return ""


def get_media_block(css: str, selector: str) -> str:
    m = re.search(r"@media[^{]*\(max-width:\s*460px\)", css)
    if not m:
        return ""
    media = extract_braces(css, css.find("{", m.start()))
    result = ""
    for fm in re.finditer(rf"{re.escape(selector)}(?=\s*{{)", media):
        result = extract_braces(media, fm.end())
    return result


def main() -> int:
    css = CSS.read_text()
    root = get_block(css, ":root")
    lines = [
        "// Auto-generado desde Scripts/web-reference/style.css",
        "// NO editar a mano. Regenerar: python3 Scripts/generate_tokens.py",
        "// Drift check en CI: Scripts/generate_tokens.py && git diff --exit-code",
        "",
        "import SwiftUI",
        "",
        "enum DesignTokens {",
    ]

    # ---------- Colores :root ----------
    for name, value in re.findall(r"--([\w-]+):\s*([^;]+);", root):
        swift_name = re.sub(r"-(\w)", lambda m: m.group(1).upper(), name)
        value = value.strip()
        hexv = parse_hex(value)
        if hexv:
            lines.append(f"    static let color{swift_name.capitalize()} = Color(red: {hexv[0]:.4f}, green: {hexv[1]:.4f}, blue: {hexv[2]:.4f})")
            continue
        if value.startswith("rgba"):
            lines.append(f"    static let color{swift_name.capitalize()} = {rgba_to_swift(value)}")
            continue
        if "Inter" in value or "apple" in value:
            lines.append(f"    static let fontPila = \"{value.replace('\"', '\\\"')}\"")

    # ---------- Medidas curadas ----------
    pill = get_block(css, "#barra-unica")
    campo = get_block(css, ".campo-wayne")
    btn = get_block(css, ".btn-wayne")
    btn_sm = get_block(css, ".btn-wayne-sm")
    ghost = get_block(css, ".btn-ghost")
    htitle = get_block(css, ".h-title")
    titulo = get_media_block(css, ".titulo-batsenal")
    csum = get_media_block(css, ".c-sum")
    csum_et = get_media_block(css, ".c-sum .etiqueta")
    csum_m = get_media_block(css, ".c-sum .monto")
    priv = get_block(css, ".privacy-toggle")
    toast = get_block(css, ".toast-offline")
    barra = get_block(css, ".barra-presupuesto")
    navitem = get_media_block(css, ".nav-item")
    navicon = get_media_block(css, ".nav-item .nav-icon")
    navbar = get_media_block(css, ".navbar")
    rowcards = get_media_block(css, ".row-cards")
    contenedor = get_media_block(css, ".contenedor-principal")

    def add(swift_name, text, factory=None):
        if not text:
            return
        if factory is not None:
            val = factory(text)
            if val is not None:
                lines.append(f"    static let {swift_name} = {val}")
            return
        f = clamp_float(text)
        if f is not None:
            lines.append(f"    static let {swift_name}: CGFloat = {f}")
        else:
            v = rgba_to_swift(text)
            if v:
                lines.append(f"    static let {swift_name} = {v}")

    add("navPillFondo", get_prop(pill, "background"), rgba_to_swift)
    add("navPillBorde", get_prop(pill, "border"))
    add("navPillAltura", get_prop(pill, "height"))
    add("navPillRadio", get_prop(pill, "border-radius"))
    add("navItemTamano", get_prop(navitem, "width"))
    add("navIconoTamano", get_prop(navicon, "width"))
    add("navItemColor", get_prop(get_block(css, ".nav-item"), "color"), rgba_to_swift)

    add("campoAltura", get_prop(campo, "min-height"))
    add("campoRadio", get_prop(campo, "border-radius"))
    add("campoFondo", get_prop(campo, "background"), rgba_to_swift)
    add("campoBorde", get_prop(campo, "border"))

    add("btnWayneAltura", get_prop(btn, "min-height"))
    add("btnWayneSmAltura", get_prop(btn_sm, "min-height"))
    add("btnWayneSmTamano", get_prop(btn_sm, "font-size"))
    add("btnWayneSmKerning", get_prop(btn_sm, "letter-spacing"))
    add("btnGhostAltura", get_prop(ghost, "min-height"))

    add("hTitleTamano", get_prop(htitle, "font-size"))
    add("tituloPaginaTamano", get_prop(titulo, "font-size"))

    add("resumenGap", get_prop(rowcards, "gap"))
    add("resumenEtiquetaTamano", get_prop(csum_et, "font-size"))
    add("resumenMontoTamano", get_prop(csum_m, "font-size"))

    add("privacidadTamano", get_prop(priv, "width"))
    add("privacidadRadio", get_prop(priv, "border-radius"))
    add("privacidadBorde", get_prop(priv, "border"))

    add("toastFondo", get_prop(toast, "background"), rgba_to_swift)
    add("toastRadio", get_prop(toast, "border-radius"))

    add("barraPresupuestoAltura", get_prop(barra, "height"))
    add("barraPresupuestoRadio", get_prop(barra, "border-radius"))

    add("topBarAltura", get_prop(navbar, "min-height"))
    add("contenedorPaddingBottom", get_prop(contenedor, "padding"), lambda t: f"{float(t.split()[-1].replace('px', '')):.1f}")

    lines.append("}")
    OUT.write_text("\n".join(lines) + "\n")
    print(f"OK -> {OUT} ({len(lines)} líneas)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
