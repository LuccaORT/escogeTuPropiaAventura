"""Prueba de punta a punta de la Fase 2 (RF09, RF10, RF11). Requiere base recién creada con la semilla."""
import html as htmllib
import http.cookiejar
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

sys.stdout.reconfigure(encoding="utf-8")

ADMIN = "http://localhost:5173"
API = "http://localhost:5106"
LECTOR = "http://localhost:5294"

fallos = []


def chequear(nombre, condicion, detalle=""):
    print(("OK   " if condicion else "FALLA") + " " + nombre + (f" -> {detalle}" if detalle and not condicion else ""))
    if not condicion:
        fallos.append(nombre)


class Web:
    def __init__(self, base):
        self.base = base
        self.abridor = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))

    def get(self, ruta):
        try:
            r = self.abridor.open(self.base + ruta, timeout=30)
            return r.status, r.geturl(), htmllib.unescape(r.read().decode("utf-8", "replace"))
        except urllib.error.HTTPError as e:
            return e.code, ruta, htmllib.unescape(e.read().decode("utf-8", "replace"))

    def post(self, ruta_form, accion, campos):
        _, _, pagina = self.get(ruta_form)
        m = re.search(r'name="__RequestVerificationToken"[^>]*value="([^"]+)"', pagina)
        pares = list(campos) + ([("__RequestVerificationToken", m.group(1))] if m else [])
        try:
            r = self.abridor.open(self.base + accion, data=urllib.parse.urlencode(pares).encode(), timeout=30)
            return r.status, r.geturl(), htmllib.unescape(r.read().decode("utf-8", "replace"))
        except urllib.error.HTTPError as e:
            return e.code, accion, htmllib.unescape(e.read().decode("utf-8", "replace"))


def api(metodo, ruta, cuerpo=None, token=None):
    datos = json.dumps(cuerpo).encode() if cuerpo is not None else None
    req = urllib.request.Request(API + ruta, data=datos, method=metodo)
    if cuerpo is not None:
        req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            texto = r.read().decode()
            return r.status, json.loads(texto) if texto else None
    except urllib.error.HTTPError as e:
        texto = e.read().decode("utf-8", "replace")
        try:
            return e.code, json.loads(texto)
        except ValueError:
            return e.code, texto[:200]


def token(usuario, clave):
    s, r = api("POST", "/api/Auth/login", {"nombreUsuario": usuario, "contrasena": clave})
    assert s == 200, r
    return r["token"]


# --- Armado de datos desde administración ---
a = Web(ADMIN)
a.post("/Auth/Login", "/Auth/Login", [("nombreUsuario", "admin1"), ("contrasena", "Admin123!")])

for nombre, clave in [("ana", "Ana12345!"), ("beto", "Beto12345!"), ("nulo", "Nulo12345!")]:
    a.post("/Usuarios/Create", "/Usuarios/Create", [("nombreCompleto", nombre.title() + " Prueba"), ("email", nombre + "@test.uy"),
        ("nombreUsuario", nombre), ("contrasena", clave), ("rol", "LECTOR")])

siguiente_capitulo = 1


def historia(id_historia, titulo, finales):
    """Historia publicada: capítulo inicial con una opción por cada final."""
    global siguiente_capitulo
    s, u, p = a.post("/Historias/Create", "/Historias/Create", [("titulo", titulo), ("sinopsis", "Sinopsis"), ("categoriasIds", "1"),
        ("tituloCapituloInicial", "Inicio " + titulo), ("textoCapituloInicial", "Texto")])
    assert "creada" in p, p[:300]
    inicial = siguiente_capitulo
    siguiente_capitulo += 1
    for final in finales:
        s, u, p = a.post(f"/Historias/AgregarCapitulo/{id_historia}", "/Historias/AgregarCapitulo", [("historiaId", str(id_historia)),
            ("capituloAnteriorId", str(inicial)), ("titulo", final), ("texto", "Texto"), ("textoOpcion", "Ir a " + final), ("esFinal", "true")])
        assert "agregado" in p, p[:300]
        siguiente_capitulo += 1
    s, u, p = a.post(f"/Historias/Edit/{id_historia}", "/Historias/Edit", [("id", str(id_historia)), ("titulo", titulo), ("sinopsis", "Sinopsis"),
        ("categoriasIds", "1"), ("estado", "PUBLICADA")])
    assert "modificada" in p or "publicada" in p.lower(), p[:300]


historia(1, "Alfa", ["Alfa F1", "Alfa F2", "Alfa F3"])
historia(2, "Beta", ["Beta F1", "Beta F2"])
historia(3, "Gama", ["Gama F1"])     # solo una lectura sin terminar
historia(4, "Delta", ["Delta F1"])   # nunca leída
historia(5, "Epsilon", ["Epsilon F1"])  # empata con Beta

admin = token("admin1", "Admin123!")
lector = token("lector1", "Lector123!")
ana = token("ana", "Ana12345!")
beto = token("beto", "Beto12345!")

print("=== Sin datos de lectura ===")
s, r = api("GET", "/api/Metricas/ranking-historias", token=admin)
chequear("RF09 sin lecturas: 200 y vacío", s == 200 and r == [], r)
s, r = api("GET", "/api/Metricas/ranking-usuarios", token=admin)
chequear("RF11 sin lecturas: 200 y vacío", s == 200 and r == [], r)
s, r = api("GET", "/api/Metricas/historias/1/finales", token=admin)
chequear("RF10 sin lecturas: finales en cero, ninguno marcado",
         s == 200 and len(r["finales"]) == 3 and not any(f["esMasFrecuente"] for f in r["finales"]), r)

print("=== Permisos ===")
for ruta in ["ranking-historias", "ranking-usuarios", "historias/1/finales"]:
    chequear(f"{ruta} sin token: 401", api("GET", "/api/Metricas/" + ruta)[0] == 401)
    chequear(f"{ruta} con lector: 403", api("GET", "/api/Metricas/" + ruta, token=lector)[0] == 403)
s, r = api("GET", "/api/Metricas/historias/999/finales", token=admin)
chequear("RF10 historia inexistente: 404 con mensaje", s == 404 and "no existe" in r.get("mensaje", ""), r)


def leer(tok, historia_id, final=None):
    """Inicia una lectura y, si se indica, la lleva hasta ese final."""
    s, r = api("POST", "/api/Lecturas", {"historiaId": historia_id}, token=tok)
    assert s == 201, r
    if final:
        op = [o for o in r["capituloActual"]["opciones"] if o["texto"] == "Ir a " + final][0]["id"]
        s, r2 = api("POST", f"/api/Lecturas/{r['id']}/avance", {"opcionId": op}, token=tok)
        assert s == 200 and r2["completada"], r2


# Alfa: 4 completadas (F2 x2, F1 x1, F3 x1) | Beta: 2 con empate | Epsilon: 2 | Gama: sin terminar | Delta: nada
w0 = Web(LECTOR)
w0.post("/Auth/Login", "/Auth/Login", [("nombreUsuario", "admin1"), ("contrasena", "Admin123!")])
s, u, p = w0.get("/Metricas/RankingHistorias")
chequear("CP01 pantalla sin lecturas completadas avisa", s == 200 and "Todavía no hay lecturas completadas" in p, p[:300])

leer(lector, 1, "Alfa F2")
s, r = api("GET", "/api/Metricas/ranking-historias", token=admin)
chequear("CP04 y CP09 con una sola completada aparece con 1", [(x["titulo"], x["lecturasCompletadas"]) for x in r] == [("Alfa", 1)], r)
leer(lector, 1, "Alfa F2")
leer(ana, 1, "Alfa F1")
leer(beto, 1, "Alfa F3")
leer(ana, 2, "Beta F1")
leer(lector, 2, "Beta F2")
leer(ana, 5, "Epsilon F1")
leer(ana, 5, "Epsilon F1")
leer(lector, 3)
leer(beto, 1)  # lectura sin terminar de una historia con completadas: no debe sumar

print("=== RF09 ===")
s, r = api("GET", "/api/Metricas/ranking-historias", token=admin)
filas = [(x["titulo"], x["lecturasCompletadas"]) for x in r]
chequear("orden descendente con empate alfabético", filas == [("Alfa", 4), ("Beta", 2), ("Epsilon", 2)], filas)
chequear("excluye la nunca leída", "Delta" not in [x[0] for x in filas], filas)
chequear("excluye la que solo tiene lecturas sin terminar", "Gama" not in [x[0] for x in filas], filas)

print("=== RF10 ===")
s, r = api("GET", "/api/Metricas/historias/1/finales", token=admin)
filas = [(x["titulo"], x["vecesAlcanzado"], x["esMasFrecuente"]) for x in r["finales"]]
chequear("cuenta cada final y marca el más frecuente",
         filas == [("Alfa F2", 2, True), ("Alfa F1", 1, False), ("Alfa F3", 1, False)], filas)
chequear("devuelve el título de la historia", r["historiaTitulo"] == "Alfa", r)
s, r = api("GET", "/api/Metricas/historias/2/finales", token=admin)
chequear("empate: marca a los dos", all(x["esMasFrecuente"] and x["vecesAlcanzado"] == 1 for x in r["finales"]), r)
s, r = api("GET", "/api/Metricas/historias/3/finales", token=admin)
chequear("final nunca alcanzado aparece en cero sin marca",
         [(x["vecesAlcanzado"], x["esMasFrecuente"]) for x in r["finales"]] == [(0, False)], r)

print("=== RF11 ===")
s, r = api("GET", "/api/Metricas/ranking-usuarios", token=admin)
filas = [(x["nombreUsuario"], x["historiasCompletadas"]) for x in r]
# ana: Alfa, Beta, Epsilon (3, con Epsilon repetida) | lector1: Alfa, Beta (2) | beto: Alfa (1)
chequear("cuenta historias distintas, de mayor a menor", filas == [("ana", 3), ("lector1", 2), ("beto", 1)], filas)
chequear("excluye al usuario sin completadas", "nulo" not in [x[0] for x in filas], filas)

print("=== Lector ===")
w = Web(LECTOR)
s, u, p = w.get("/Metricas/RankingHistorias")
chequear("sin sesión va al login", "/Auth/Login" in u, u)
w.post("/Auth/Login", "/Auth/Login", [("nombreUsuario", "admin1"), ("contrasena", "Admin123!")])
s, u, p = w.get("/")
chequear("inicio de admin sin el aviso temporal", "todavía no están disponibles" not in p)
for destino in ["/Metricas/RankingHistorias", "/Metricas/Finales", "/Metricas/RankingUsuarios"]:
    chequear(f"menú enlaza {destino}", destino in p)
s, u, p = w.get("/Metricas/RankingHistorias")
chequear("pantalla RF09 en orden", s == 200 and p.find("Alfa") < p.find("Beta") < p.find("Epsilon") and "Delta" not in p and "Gama" not in p)
s, u, p = w.get("/Metricas/RankingUsuarios")
chequear("pantalla RF11 en orden", s == 200 and p.find("ana") < p.find("lector1") < p.find("beto") and "nulo" not in p)
s, u, p = w.get("/Metricas/Finales")
chequear("pantalla RF10 lista historias sin tabla", s == 200 and "Delta" in p and "Veces alcanzado" not in p)
s, u, p = w.get("/Metricas/Finales?historiaId=1")
chequear("pantalla RF10 marca el más frecuente", "Más frecuente" in p and p.find("Alfa F2") < p.find("Más frecuente") < p.find("Alfa F1"))
chequear("pantalla RF10 conserva la selección", re.search(r'<option[^>]*value="1"[^>]*selected', p) is not None)
s, u, p = w.get("/Metricas/Finales?historiaId=4")
chequear("pantalla RF10 avisa si nadie llegó", "Todavía nadie llegó" in p)
s, u, p = w.get("/Metricas/Finales?historiaId=999")
chequear("pantalla RF10 inexistente muestra error", s == 200 and "no existe" in p)
s, u, p = w.get("/Lecturas/Historias")
chequear("admin no entra a lectura", "permisos" in p, u)

l = Web(LECTOR)
l.post("/Auth/Login", "/Auth/Login", [("nombreUsuario", "lector1"), ("contrasena", "Lector123!")])
s, u, p = l.get("/Metricas/RankingHistorias")
chequear("lector no entra a métricas", "permisos" in p and "Lecturas completadas" not in p, u)
chequear("menú de lector sin métricas", "/Metricas/" not in p)

print("=== Swagger ===")
s, r = api("GET", "/swagger/v1/swagger.json")
chequear("Swagger documenta las métricas",
         s == 200 and all(("/api/Metricas/" + x) in r["paths"] for x in ["ranking-historias", "ranking-usuarios", "historias/{historiaId}/finales"]))

print()
print("Fallos:", len(fallos), fallos if fallos else "")
sys.exit(1 if fallos else 0)
