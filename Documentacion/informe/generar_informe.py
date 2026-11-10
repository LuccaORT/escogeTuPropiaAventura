"""Arma Documentacion/Informe.pdf con Microsoft Edge o Chrome, sin instalar nada más que pypdf.

Completar datos-entrega.json y ejecutar: python generar_informe.py
La captura se indica con una ruta relativa a esta carpeta. La carátula queda en blanco.
Hace dos pasadas: la primera ubica cada título y la segunda escribe las páginas en el índice.
"""
import html
import json
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

from pypdf import PdfReader

AQUI = pathlib.Path(__file__).parent
DOC = AQUI.parent
RAIZ = DOC.parent
SALIDA = DOC / "Informe.pdf"

NAVEGADORES = [
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
]

pendientes = []

datos = json.loads((AQUI / "datos-entrega.json").read_text(encoding="utf-8"))
metricas = json.loads((RAIZ / "BaseDeDatos" / "generador" / "metricas-esperadas.json").read_text(encoding="utf-8"))
contenido = (AQUI / "contenido.html").read_text(encoding="utf-8")


def valor(texto, descripcion):
    if texto:
        return html.escape(texto)
    pendientes.append(descripcion)
    return f'<span class="pendiente">[completar: {html.escape(descripcion)}]</span>'


def enlace(url, descripcion):
    if url:
        e = html.escape(url)
        return f'<a href="{e}">{e}</a>'
    return valor(url, descripcion)


def imagen(ruta, descripcion, clase):
    if ruta and (AQUI / ruta).exists():
        return f'<img class="{clase}" src="{html.escape(ruta)}" alt="{html.escape(descripcion)}">'
    pendientes.append(descripcion)
    return f'<div class="{clase} vacia">[completar: {html.escape(descripcion)}]</div>'


# ---------- Markdown mínimo, para reutilizar la investigación de RF12 ----------

def en_linea(texto):
    texto = html.escape(texto, quote=False)
    texto = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", texto)
    texto = re.sub(r"`(.+?)`", r"<code>\1</code>", texto)
    texto = re.sub(r"\[(.+?)\]\((.+?)\)", r'<a href="\2">\1</a>', texto)
    return texto


def markdown(texto, nivel_base=2):
    salida, lista, tabla = [], False, []

    def cerrar_tabla():
        if tabla:
            filas = [[c.strip() for c in f.strip().strip("|").split("|")] for f in tabla]
            salida.append("<table><thead><tr>" + "".join(f"<th>{en_linea(c)}</th>" for c in filas[0]) + "</tr></thead><tbody>")
            for fila in filas[2:]:
                salida.append("<tr>" + "".join(f"<td>{en_linea(c)}</td>" for c in fila) + "</tr>")
            salida.append("</tbody></table>")
            tabla.clear()

    for linea in texto.splitlines():
        if linea.startswith("|"):
            tabla.append(linea)
            continue
        cerrar_tabla()
        if linea.startswith("- "):
            if not lista:
                salida.append("<ul>")
                lista = True
            salida.append(f"<li>{en_linea(linea[2:])}</li>")
            continue
        if lista:
            salida.append("</ul>")
            lista = False
        m = re.match(r"(#+) (.*)", linea)
        if m:
            h = len(m.group(1)) + nivel_base - 1
            salida.append(f"<h{h}>{en_linea(m.group(2))}</h{h}>")
        elif linea.strip():
            salida.append(f"<p>{en_linea(linea)}</p>")
    cerrar_tabla()
    if lista:
        salida.append("</ul>")
    return "\n".join(salida)


def investigacion_estilos():
    texto = (DOC / "RF12-investigacion-estilos.md").read_text(encoding="utf-8")
    # Sin el título y el aviso de borrador, que son del archivo y no del informe.
    return markdown(texto[texto.index("## Herramienta y método"):].replace("## ", "### "), nivel_base=1)


def prompts():
    texto = (DOC / "generacion-datos-ia.md").read_text(encoding="utf-8")
    bloques = re.findall(r"### (Prompt .+?)\n\n```text\n(.*?)```", texto, re.S)
    return "\n".join(f'<h4>{html.escape(t)}</h4><pre>{html.escape(b.strip())}</pre>' for t, b in bloques)


# ---------- Tablas calculadas desde los datos de prueba ----------

def filas_tabla(encabezados, filas):
    cabeza = "".join(f"<th>{html.escape(str(e))}</th>" for e in encabezados)
    cuerpo = "".join("<tr>" + "".join(f"<td>{html.escape(str(c))}</td>" for c in f) + "</tr>" for f in filas)
    return f"<table><thead><tr>{cabeza}</tr></thead><tbody>{cuerpo}</tbody></table>"


def tablas_datos():
    return {
        "{{tabla_filas}}": filas_tabla(["Tabla", "Filas"], metricas["filas"].items()),
        "{{tabla_ranking_historias}}": filas_tabla(["Historia", "Lecturas completadas"], metricas["rankingHistorias"]),
        "{{tabla_ranking_usuarios}}": filas_tabla(["Usuario", "Historias distintas completadas"], metricas["rankingUsuarios"]),
        "{{tabla_finales}}": filas_tabla(
            ["Historia", "Veces que se alcanzó cada final"],
            [(h, ", ".join(sorted((str(v) for v in f.values()), key=int, reverse=True))) for h, f in metricas["finales"].items()]),
    }


# ---------- Portada ----------

def portada():
    # Queda en blanco a propósito: los integrantes la completan sobre el PDF.
    integrante = ('<div class="integrante"><div class="foto en-blanco"></div>'
                  '<p>Nombre: <span class="linea"></span></p>'
                  '<p>Nº de estudiante: <span class="linea"></span></p></div>')
    return integrante * 2


# ---------- Armado ----------

def armar(paginas):
    pendientes.clear()
    cuerpo = contenido
    reemplazos = {
        "{{grupo}}": '<span class="linea"></span>',
        "{{integrantes}}": portada(),
        "{{url_administracion}}": enlace(datos["enlaces"]["administracion"], "URL de administración en Somee"),
        "{{url_lectura}}": enlace(datos["enlaces"]["lectura"], "URL de lectura en Somee"),
        "{{url_api}}": enlace(datos["enlaces"]["api"], "URL de la Web API en Somee"),
        "{{url_github}}": enlace(datos["enlaces"]["github"], "repositorio de GitHub"),
        "{{ia_herramienta}}": valor(datos["ia"]["herramienta"], "herramienta y modelo de IA"),
        "{{ia_link}}": enlace(datos["ia"]["linkPrompts"], "link a los prompts"),
        "{{ia_captura}}": imagen(datos["ia"]["captura"], "captura de los prompts", "captura"),
        "{{prompts}}": prompts(),
        "{{investigacion_estilos}}": investigacion_estilos(),
    }
    reemplazos.update(tablas_datos())
    for clave, texto in reemplazos.items():
        cuerpo = cuerpo.replace(clave, texto)

    # Numera los títulos h2 y h3 con id de sección y arma el índice.
    entradas = []
    contadores = [0, 0]

    def numerar(m):
        nivel = int(m.group(1))
        titulo = m.group(2)
        if nivel == 2:
            contadores[0] += 1
            contadores[1] = 0
            numero = f"{contadores[0]}"
        else:
            contadores[1] += 1
            numero = f"{contadores[0]}.{contadores[1]}"
        ancla = f"s{numero.replace('.', '-')}"
        entradas.append((nivel, numero, re.sub(r"<[^>]+>", "", titulo), ancla))
        return f'<h{nivel} id="{ancla}">{numero}. {titulo}</h{nivel}>'

    cuerpo = re.sub(r"<h([23])>(.*?)</h\1>", numerar, cuerpo)
    indice = "".join(
        f'<li class="n{n}"><a href="#{a}"><span>{num}. {html.escape(t, quote=False)}</span>'
        f'<span class="pag">{paginas.get(a, "0")}</span></a></li>'
        for n, num, t, a in entradas)
    return cuerpo.replace("{{indice}}", indice), entradas


def imprimir(pagina_html):
    navegador = next((n for n in NAVEGADORES if pathlib.Path(n).exists()), None) or shutil.which("msedge") or shutil.which("chrome")
    if not navegador:
        sys.exit("No se encontró Edge ni Chrome.")
    archivo = AQUI / "_informe.html"
    archivo.write_text(pagina_html, encoding="utf-8")
    with tempfile.TemporaryDirectory() as perfil:
        subprocess.run([navegador, "--headless=new", "--disable-gpu", f"--user-data-dir={perfil}",
                        "--no-pdf-header-footer", "--virtual-time-budget=8000",
                        f"--print-to-pdf={SALIDA}", archivo.as_uri()],
                       check=True, timeout=180, stdin=subprocess.DEVNULL,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    archivo.unlink()


def normalizar(texto):
    return re.sub(r"\s+", "", texto)


def ubicar(entradas):
    lector = PdfReader(str(SALIDA))
    textos = [normalizar(p.extract_text() or "") for p in lector.pages]
    # El índice repite los títulos: la búsqueda arranca después de la última página que lo contiene.
    ultimo = normalizar(f"{entradas[-1][1]}. {entradas[-1][2]}")
    inicio = next((i for i, t in enumerate(textos) if ultimo in t), 1) + 1
    paginas, actual = {}, inicio
    for _, numero, titulo, ancla in entradas:
        buscado = normalizar(f"{numero}. {titulo}")
        for i in range(actual, len(textos)):
            if buscado in textos[i]:
                paginas[ancla] = str(i + 1)
                actual = i
                break
        else:
            sys.exit(f"No se encontró el título en el PDF: {numero}. {titulo}")
    return paginas, len(textos)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    pagina, entradas = armar({})
    imprimir(pagina)
    paginas, _ = ubicar(entradas)
    pagina, entradas = armar(paginas)
    imprimir(pagina)
    comprobadas, total = ubicar(entradas)
    if comprobadas != paginas:
        sys.exit("Las páginas cambiaron entre pasadas: volver a ejecutar.")
    print(f"Informe generado: {SALIDA} ({total} páginas)")
    if pendientes:
        print("Falta completar:")
        for p in dict.fromkeys(pendientes):
            print(" -", p)


if __name__ == "__main__":
    main()
