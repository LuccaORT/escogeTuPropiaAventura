"""Prueba de punta a punta de la Fase 1: administración, API y Lector."""
import datetime
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
            return r.status, r.geturl(), r.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            return e.code, ruta, e.read().decode("utf-8", "replace")

    def post(self, ruta_form, accion, campos):
        _, _, pagina = self.get(ruta_form)
        m = re.search(r'name="__RequestVerificationToken"[^>]*value="([^"]+)"', pagina)
        pares = list(campos) + ([("__RequestVerificationToken", m.group(1))] if m else [])
        try:
            r = self.abridor.open(self.base + accion, data=urllib.parse.urlencode(pares).encode(), timeout=30)
            return r.status, r.geturl(), r.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            return e.code, accion, e.read().decode("utf-8", "replace")


def alertas(pagina):
    return [htmllib.unescape(re.sub(r"\s+", " ", x)) for x in
            re.findall(r'class="alert[^"]*"[^>]*>\s*(.*?)\s*</div>', pagina, re.S)]


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
            return r.status, json.loads(texto) if texto else None, r.headers
    except urllib.error.HTTPError as e:
        texto = e.read().decode("utf-8", "replace")
        try:
            return e.code, json.loads(texto), e.headers
        except ValueError:
            return e.code, texto[:200], e.headers


print("=== Administración ===")
a = Web(ADMIN)
s, u, p = a.get("/Historias")
chequear("sin sesión redirige al login", "/Auth/Login" in u, u)
s, u, p = a.post("/Auth/Login", "/Auth/Login", [("nombreUsuario", "lector1"), ("contrasena", "Lector123!")])
chequear("RF01 lector no entra a administración", any("permisos" in x for x in alertas(p)), alertas(p))
s, u, p = a.post("/Auth/Login", "/Auth/Login", [("nombreUsuario", "admin1"), ("contrasena", "Malisima1!")])
chequear("RF01 contraseña mala", any("incorrectos" in x for x in alertas(p)), alertas(p))
s, u, p = a.post("/Auth/Login", "/Auth/Login", [("nombreUsuario", "admin1"), ("contrasena", "Admin123!")])
chequear("RF01 admin entra", s == 200 and "Administración de historias" in p, u)
chequear("menú tiene Auditoría", "/Auditorias" in p)

usuario = [("nombreCompleto", "Ana Paz"), ("email", "ana@test.uy"), ("nombreUsuario", "ana"), ("contrasena", "Ana12345!"), ("rol", "LECTOR")]
s, u, p = a.post("/Usuarios/Create", "/Usuarios/Create", usuario)
chequear("RF02 alta correcta", any("creado" in x for x in alertas(p)), alertas(p))
s, u, p = a.post("/Usuarios/Create", "/Usuarios/Create", usuario)
chequear("RF02 usuario repetido", any("Ya existe" in x for x in alertas(p)), alertas(p))
malo = [("nombreCompleto", "X"), ("email", "sin-arroba"), ("nombreUsuario", "x1"), ("contrasena", "Ana12345!"), ("rol", "LECTOR")]
s, u, p = a.post("/Usuarios/Create", "/Usuarios/Create", malo)
chequear("RF02 email inválido y conserva datos", any("email" in x for x in alertas(p)) and 'value="x1"' in p, alertas(p))
malo = [("nombreCompleto", "X"), ("email", "x@test.uy"), ("nombreUsuario", "x1"), ("contrasena", "corta"), ("rol", "LECTOR")]
s, u, p = a.post("/Usuarios/Create", "/Usuarios/Create", malo)
chequear("RF02 contraseña débil", any("8 caracteres" in x for x in alertas(p)), alertas(p))
malo = [("nombreCompleto", "X"), ("email", "x@test.uy"), ("nombreUsuario", "x1"), ("contrasena", "Ana12345!"), ("rol", "HACKER")]
s, u, p = a.post("/Usuarios/Create", "/Usuarios/Create", malo)
chequear("RF02 rol inválido", any("rol" in x for x in alertas(p)), alertas(p))

alta_a = [("titulo", "Historia A"), ("sinopsis", "Sinopsis A"), ("categoriasIds", "1"), ("categoriasIds", "2"),
          ("tituloCapituloInicial", "Inicio A"), ("textoCapituloInicial", "Texto inicio A")]
s, u, p = a.post("/Historias/Create", "/Historias/Create", alta_a)
chequear("RF03 crear historia", any("creada" in x for x in alertas(p)), alertas(p))
s, u, p = a.post("/Historias/Create", "/Historias/Create", [("titulo", "Sin categoria"), ("sinopsis", "S"),
    ("tituloCapituloInicial", "I"), ("textoCapituloInicial", "T")])
chequear("RF03 exige categoría", any("categoría" in x for x in alertas(p)) and 'value="Sin categoria"' in p, alertas(p))
s, u, p = a.post("/Historias/Create", "/Historias/Create", [("titulo", "Historia B"), ("sinopsis", "Sinopsis B"), ("categoriasIds", "1"),
    ("tituloCapituloInicial", "Inicio B"), ("textoCapituloInicial", "Texto inicio B")])
chequear("RF03 crear segunda historia", s == 200)

editar_a = [("id", "1"), ("titulo", "Historia A2"), ("sinopsis", "Sinopsis A2"), ("categoriasIds", "1"), ("categoriasIds", "2"), ("estado", "BORRADOR"),
            ("tituloCapituloInicial", "Inicio A2"), ("textoCapituloInicial", "Texto inicio A2")]
s, u, p = a.post("/Historias/Edit/1", "/Historias/Edit", editar_a)
chequear("RF03 editar con capítulo inicial", any("modificada" in x for x in alertas(p)), alertas(p))
publicar_a = [("id", "1"), ("titulo", "Historia A2"), ("sinopsis", "Sinopsis A2"), ("categoriasIds", "1"), ("categoriasIds", "2"), ("estado", "PUBLICADA")]
s, u, p = a.post("/Historias/Edit/1", "/Historias/Edit", publicar_a)
chequear("RF03 no publica sin opciones", any("al menos una opción" in x for x in alertas(p)), alertas(p))

def capitulo(hist, anterior, titulo, final, opcion):
    return a.post(f"/Historias/AgregarCapitulo/{hist}", "/Historias/AgregarCapitulo", [("historiaId", str(hist)), ("capituloAnteriorId", str(anterior)),
        ("titulo", titulo), ("texto", "Texto de " + titulo), ("textoOpcion", opcion), ("esFinal", "true" if final else "false")])

s, u, p = capitulo(1, 1, "Medio A", False, "Seguir al medio")
chequear("RF04 agrega intermedio", any("agregado" in x for x in alertas(p)), alertas(p))
chequear("RF04 se ve la opción con destino", "Seguir al medio → Medio A" in htmllib.unescape(p))
s, u, p = a.post("/Historias/Edit/1", "/Historias/Edit", publicar_a)
chequear("RF03 no publica con intermedio sin opciones", any("Medio A" in x for x in alertas(p)), alertas(p))
s, u, p = capitulo(1, 3, "Final 1", True, "Ir al final 1")
s, u, p = capitulo(1, 1, "Final 2", True, "Ir al final 2")
chequear("RF04 agrega finales", any("agregado" in x for x in alertas(p)), alertas(p))
s, u, p = capitulo(1, 4, "Tras final", False, "No debería")
chequear("RF04 no agrega tras un final", any("capítulo final" in x for x in alertas(p)), alertas(p))
s, u, p = capitulo(1, 2, "Otra historia", False, "No debería")
chequear("RF04 no comparte capítulos entre historias", any("no existe en esta historia" in x for x in alertas(p)), alertas(p))
edit_inicial = [("id", "1"), ("titulo", "Historia A2"), ("sinopsis", "S"), ("categoriasIds", "1"), ("estado", "BORRADOR"),
                ("tituloCapituloInicial", "Otro"), ("textoCapituloInicial", "Otro")]
s, u, p = a.post("/Historias/Edit/1", "/Historias/Edit", edit_inicial)
chequear("RF03 no edita inicial con otros capítulos", any("no puede modificarse" in x for x in alertas(p)), alertas(p))
s, u, p = a.post("/Historias/Edit/1", "/Historias/Edit", publicar_a)
chequear("RF03 publica con estructura correcta", any("modificada" in x for x in alertas(p)), alertas(p))
s, u, p = capitulo(1, 1, "Tarde", True, "Tarde")
chequear("RF04 no agrega a publicada", any("publicada" in x for x in alertas(p)), alertas(p))

print("=== API ===")
s, r, _ = api("POST", "/api/Auth/login", {"nombreUsuario": "lector1", "contrasena": "Lector123!"})
chequear("RF06 login lector 200", s == 200 and r["rol"] == "LECTOR", r)
lector = r["token"]
s, r, _ = api("POST", "/api/Auth/login", {"nombreUsuario": "admin1", "contrasena": "Admin123!"})
chequear("RF06 login admin 200", s == 200 and r["rol"] == "ADMINISTRADOR", r)
admin = r["token"]
s, r, _ = api("POST", "/api/Auth/login", {"nombreUsuario": "lector1", "contrasena": "Mala"})
chequear("RF06 credenciales malas 401 con mensaje", s == 401 and "incorrectos" in r["mensaje"], r)
chequear("sin token 401", api("GET", "/api/Historias")[0] == 401)
chequear("token inválido 401", api("GET", "/api/Historias", token="xx")[0] == 401)
s, r, _ = api("GET", "/api/Historias", token=lector)
chequear("RF07 solo publicadas", s == 200 and [h["id"] for h in r] == [1], r)
chequear("RF07 listado no expone capítulos", "capitulos" not in r[0], r)
s, r, _ = api("GET", "/api/Historias?categoriaId=2", token=lector)
chequear("RF07 filtro con resultados conserva categorías", s == 200 and len(r) == 1 and len(r[0]["categorias"]) == 2, r)
s, r, _ = api("GET", "/api/Historias?categoriaId=3", token=lector)
chequear("RF07 filtro sin resultados 200 vacío", s == 200 and r == [], r)
s, r, _ = api("GET", "/api/Categorias", token=lector)
chequear("categorías", s == 200 and len(r) == 3, r)
chequear("admin puede listar historias", api("GET", "/api/Historias", token=admin)[0] == 200)
chequear("admin no lee: 403", api("POST", "/api/Lecturas", {"historiaId": 1}, token=admin)[0] == 403)
s, r, _ = api("POST", "/api/Lecturas", {"historiaId": 2}, token=lector)
chequear("borrador no se lee: 400", s == 400 and "publicadas" in r["mensaje"], r)
s, r, _ = api("POST", "/api/Lecturas", {"historiaId": 999}, token=lector)
chequear("historia inexistente 404", s == 404, r)
s, ini, h = api("POST", "/api/Lecturas", {"historiaId": 1}, token=lector)
chequear("RF07 iniciar 201 con Location", s == 201 and "/api/Lecturas/" in (h.get("Location") or ""), ini)
lid = ini["id"]
chequear("RF07 arranca en el inicial", ini["capituloActual"]["id"] == 1 and len(ini["capituloActual"]["opciones"]) == 2, ini)
chequear("opciones no revelan destino", "destinoTitulo" not in ini["capituloActual"]["opciones"][0], ini)
s, r, _ = api("GET", f"/api/Lecturas/{lid}", token=lector)
chequear("RF07 obtener lectura 200", s == 200 and r["id"] == lid, r)
s, r, _ = api("POST", "/api/Auth/login", {"nombreUsuario": "ana", "contrasena": "Ana12345!"})
ana = r["token"]
chequear("lectura ajena 404", api("GET", f"/api/Lecturas/{lid}", token=ana)[0] == 404)
chequear("avanzar lectura ajena 404", api("POST", f"/api/Lecturas/{lid}/avance", {"opcionId": 1}, token=ana)[0] == 404)
chequear("lectura inexistente 404", api("GET", "/api/Lecturas/999", token=lector)[0] == 404)
s, r, _ = api("POST", f"/api/Lecturas/{lid}/avance", {"opcionId": 999}, token=lector)
chequear("opción ajena 400", s == 400 and "no pertenece" in r["mensaje"], r)
op_medio = [o for o in ini["capituloActual"]["opciones"] if o["texto"] == "Seguir al medio"][0]["id"]
s, r, _ = api("POST", f"/api/Lecturas/{lid}/avance", {"opcionId": op_medio}, token=lector)
chequear("RF07 avanza a intermedio", s == 200 and r["capituloActual"]["titulo"] == "Medio A" and not r["completada"], r)
op_f1 = r["capituloActual"]["opciones"][0]["id"]
s, r, _ = api("POST", f"/api/Lecturas/{lid}/avance", {"opcionId": op_f1}, token=lector)
chequear("RF07 registra final", s == 200 and r["completada"] and r["finalAlcanzadoTitulo"] == "Final 1" and r["capituloActual"]["tipo"] == "FINAL", r)
s, r, _ = api("POST", f"/api/Lecturas/{lid}/avance", {"opcionId": op_f1}, token=lector)
chequear("RF07 lectura terminada no avanza", s == 400 and "nueva" in r["mensaje"], r)
s, seg, _ = api("POST", "/api/Lecturas", {"historiaId": 1}, token=lector)
chequear("RF07 misma historia, lectura nueva", s == 201 and seg["id"] != lid, seg)
hoy = datetime.date.today()
s, r, _ = api("GET", f"/api/Lecturas?mes={hoy.month}&anio={hoy.year}", token=lector)
chequear("RF08 historial del mes", s == 200 and len(r) == 2 and sorted(x["completada"] for x in r) == [False, True], r)
terminada = [x for x in r if x["completada"]][0]
chequear("RF08 indica historia y final", terminada["historiaTitulo"] == "Historia A2" and terminada["finalAlcanzadoTitulo"] == "Final 1", terminada)
s, r, _ = api("GET", "/api/Lecturas?mes=1&anio=2000", token=lector)
chequear("RF08 sin lecturas 200 vacío", s == 200 and r == [], r)
s, r, _ = api("GET", "/api/Lecturas?mes=13&anio=2026", token=lector)
chequear("RF08 mes inválido 400", s == 400 and "mes" in r["mensaje"], r)
s, r, _ = api("GET", "/swagger/v1/swagger.json")
chequear("Swagger: documento", s == 200 and "/api/Lecturas" in r["paths"] and "Bearer" in json.dumps(r.get("components", {})), s)
chequear("Swagger: descripciones XML", "RF07" in json.dumps(r), "sin comentarios")
try:
    with urllib.request.urlopen(API + "/swagger/index.html", timeout=30) as x:
        chequear("Swagger: interfaz 200", x.status == 200)
except urllib.error.HTTPError as e:
    chequear("Swagger: interfaz 200", False, e.code)
chequear("WeatherForecast eliminado", api("GET", "/WeatherForecast")[0] == 404)

print("=== Bajas y auditoría ===")
s, u, p = a.post("/Historias/Delete/1", "/Historias/DeleteConfirmed/1", [("id", "1")])
chequear("RF03 baja con lecturas da mensaje", any("lecturas" in x for x in alertas(p)), alertas(p))
vuelta = [("id", "1"), ("titulo", "Historia A2"), ("sinopsis", "S"), ("categoriasIds", "1"), ("estado", "BORRADOR")]
s, u, p = a.post("/Historias/Edit/1", "/Historias/Edit", vuelta)
chequear("con lecturas no vuelve a borrador", any("borrador" in x for x in alertas(p)), alertas(p))
s, u, p = capitulo(2, 2, "Medio B", False, "Al medio B")
s, u, p = capitulo(2, 5 + 2, "Final B", True, "Al final B") if False else (s, u, p)
_, _, form = a.get("/Historias/AgregarCapitulo/2")
ids = re.findall(r'<option value="(\d+)"', form)
s, u, p = capitulo(2, ids[-1], "Final B", True, "Al final B")
chequear("historia B con estructura", any("agregado" in x for x in alertas(p)), alertas(p))
s, u, p = a.post("/Historias/Delete/2", "/Historias/DeleteConfirmed/2", [("id", "2")])
chequear("RF03 baja sin lecturas (el error 500 de antes)", s == 200 and any("eliminada" in x for x in alertas(p)), (s, alertas(p)))
s, u, p = a.get("/Historias/Edit/2")
chequear("historia eliminada no existe", any("no existe" in x for x in alertas(p)), alertas(p))
s, u, p = a.get("/Historias/Edit/999")
chequear("editar inexistente da mensaje", any("no existe" in x for x in alertas(p)), alertas(p))
s, u, p = a.get("/Auditorias/Index")
texto = htmllib.unescape(p)
chequear("RF05 auditoría conserva historia dada de baja", "Baja de historia" in texto and "Dada de baja" in texto and "Historia B" in texto)
for accion in ["Creación de historia", "Edición de historia", "Publicación de historia", "Creación de capítulo intermedio", "Creación de capítulo final"]:
    chequear(f"RF05 registra: {accion}", accion in texto)
s, u, p = a.get("/Auditorias/Index?historiaId=1")
texto = htmllib.unescape(p)
chequear("RF05 filtro por historia", "Historia A2" in texto and "Baja de historia" not in texto)
s, u, p = a.get("/Auditorias/Index?administradorId=2")
chequear("RF05 filtro sin resultados da mensaje", any("No se encontraron" in x for x in alertas(p)), alertas(p))
s, u, p = a.get("/Auditorias/Index?administradorId=1")
chequear("RF05 filtro por administrador", "Publicaci" in htmllib.unescape(p) and "<select" in p)

print("=== Lector ===")
l = Web(LECTOR)
s, u, p = l.get("/Lecturas/Historias")
chequear("sin sesión va al login", "/Auth/Login" in u, u)
s, u, p = l.post("/Auth/Login", "/Auth/Login", [("nombreUsuario", "lector1"), ("contrasena", "Mala1234!")])
chequear("RF06 muestra error de la API", any("incorrectos" in x for x in alertas(p)), alertas(p))
s, u, p = l.post("/Auth/Login", "/Auth/Login", [("nombreUsuario", "lector1"), ("contrasena", "Lector123!")])
chequear("RF06 lector entra", "lector1" in p and "Mi historial" in p, u)
s, u, p = l.get("/Lecturas/Historias")
chequear("RF07 lista historias", "Historia A2" in p and "Comenzar lectura" in p, u)
chequear("RF07 categorías reales en el filtro", re.search(r'<option value="3"[^>]*>\s*Fantas', htmllib.unescape(p)) is not None)
s, u, p = l.get("/Lecturas/Historias?categoriaId=3")
chequear("RF07 filtro sin resultados da mensaje", any("No hay historias" in x for x in alertas(p)), alertas(p))
chequear("RF07 conserva categoría elegida", re.search(r'<option[^>]*value="3"[^>]*selected|<option selected[^>]*value="3"', p) is not None)
s, u, p = l.post("/Lecturas/Historias", "/Lecturas/Iniciar", [("historiaId", "1")])
chequear("RF07 inicia y muestra capítulo", "/Lecturas/Leer/" in u and "Inicio A2" in p and "Seguir al medio" in p, u)
nueva = re.search(r"/Lecturas/Leer/(\d+)", u).group(1)
opcion = re.search(r'name="opcionId"\s+value="(\d+)"[\s\S]*?Ir al final 2', p)
ids_op = re.findall(r'name="opcionId"\s+value="(\d+)"', p)
s, u, p = l.post(f"/Lecturas/Leer/{nueva}", "/Lecturas/Avanzar", [("lecturaId", nueva), ("opcionId", ids_op[-1])])
chequear("RF07 llega al final", "Terminaste la historia" in htmllib.unescape(p) and "Final 2" in p, u)
chequear("RF07 ofrece nueva lectura", "Iniciar una nueva lectura" in p)
s, u, p = l.post(f"/Lecturas/Leer/{nueva}", "/Lecturas/Avanzar", [("lecturaId", nueva), ("opcionId", ids_op[-1])])
chequear("RF07 muestra error de la API al reintentar", any("ya finalizó" in x for x in alertas(p)), alertas(p))
s, u, p = l.get("/Lecturas/Historial")
chequear("RF08 historial", "Historia A2" in p and "Final 2" in p and "Finalizada" in p and "En curso" in p, u)
s, u, p = l.get("/Lecturas/Historial?mes=1&anio=2000")
chequear("RF08 sin lecturas da mensaje", any("No existen lecturas" in x for x in alertas(p)), alertas(p))
s, u, p = l.get("/Lecturas/Historial?mes=13&anio=2026")
chequear("RF08 mes inválido da mensaje", any("mes" in x for x in alertas(p)), alertas(p))
s, u, p = l.get("/Lecturas/Leer/999")
chequear("lectura inexistente da mensaje", any("no existe" in x for x in alertas(p)), alertas(p))
s, u, p = l.post("/", "/Auth/Logout", [])
s, u, p = l.get("/Lecturas/Historial")
chequear("RF06 logout cierra sesión", "/Auth/Login" in u, u)

la = Web(LECTOR)
s, u, p = la.post("/Auth/Login", "/Auth/Login", [("nombreUsuario", "admin1"), ("contrasena", "Admin123!")])
chequear("RF06 administrador entra al Lector", "Consultá las métricas de lectura" in htmllib.unescape(p), alertas(p))
chequear("administrador no ve el menú de lectura", "Mi historial" not in p)
s, u, p = la.get("/Lecturas/Historias")
chequear("administrador no puede leer", any("permisos" in x for x in alertas(p)), alertas(p))

print()
print(f"Fallos: {len(fallos)}")
for f in fallos:
    print(" -", f)
