"""Prueba de punta a punta de la Fase 3 (RF12). Requiere admin1 y lector1; crea a su segundo lector."""
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

    def login(self, usuario, clave):
        return self.post("/Auth/Login", "/Auth/Login", [("nombreUsuario", usuario), ("contrasena", clave)])


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


def tema(pagina):
    m = re.search(r'<html[^>]*data-bs-theme="(\w+)"', pagina)
    return m.group(1) if m else None


a = Web(ADMIN)
a.post("/Auth/Login", "/Auth/Login", [("nombreUsuario", "admin1"), ("contrasena", "Admin123!")])
a.post("/Usuarios/Create", "/Usuarios/Create", [("nombreCompleto", "Otra Lectora"), ("email", "otra@test.uy"),
    ("nombreUsuario", "otra"), ("contrasena", "Otra12345!"), ("rol", "LECTOR")])

print("=== API ===")
s, r = api("POST", "/api/Auth/login", {"nombreUsuario": "lector1", "contrasena": "Lector123!"})
chequear("usuario de la semilla toma CLARO por defecto de la base", s == 200 and r["estiloLectura"] == "CLARO", r)
lector = r["token"]
s, r = api("POST", "/api/Auth/login", {"nombreUsuario": "otra", "contrasena": "Otra12345!"})
chequear("usuario dado de alta arranca en CLARO", s == 200 and r["estiloLectura"] == "CLARO", r)
otra = r["token"]
admin = api("POST", "/api/Auth/login", {"nombreUsuario": "admin1", "contrasena": "Admin123!"})[1]["token"]

chequear("GET sin token: 401", api("GET", "/api/Usuarios/estilo")[0] == 401)
chequear("PUT sin token: 401", api("PUT", "/api/Usuarios/estilo", {"estilo": "OSCURO"})[0] == 401)
chequear("GET con admin: 403", api("GET", "/api/Usuarios/estilo", token=admin)[0] == 403)
chequear("PUT con admin: 403", api("PUT", "/api/Usuarios/estilo", {"estilo": "OSCURO"}, token=admin)[0] == 403)

s, r = api("GET", "/api/Usuarios/estilo", token=lector)
chequear("GET devuelve el guardado", s == 200 and r == {"estilo": "CLARO"}, r)
s, r = api("PUT", "/api/Usuarios/estilo", {"estilo": "OSCURO"}, token=lector)
chequear("PUT cambia a OSCURO", s == 200 and r == {"estilo": "OSCURO"}, r)
s, r = api("GET", "/api/Usuarios/estilo", token=lector)
chequear("el cambio queda guardado", s == 200 and r == {"estilo": "OSCURO"}, r)
s, r = api("GET", "/api/Usuarios/estilo", token=otra)
chequear("no afecta a otro usuario", s == 200 and r == {"estilo": "CLARO"}, r)
s, r = api("POST", "/api/Auth/login", {"nombreUsuario": "lector1", "contrasena": "Lector123!"})
chequear("el login devuelve el estilo guardado", r["estiloLectura"] == "OSCURO", r)

for malo, nombre in [("AZUL", "inexistente"), ("oscuro", "en minúscula"), ("", "vacío")]:
    s, r = api("PUT", "/api/Usuarios/estilo", {"estilo": malo}, token=lector)
    chequear(f"estilo {nombre}: 400 con mensaje", s == 400 and "no es válido" in r.get("mensaje", ""), r)
s, r = api("GET", "/api/Usuarios/estilo", token=lector)
chequear("un valor inválido no cambia el guardado", r == {"estilo": "OSCURO"}, r)
s, r = api("PUT", "/api/Usuarios/estilo", {"estilo": "CLARO"}, token=lector)
chequear("PUT vuelve a CLARO", s == 200 and r == {"estilo": "CLARO"}, r)

print("=== Lector ===")
w = Web(LECTOR)
s, u, p = w.get("/Auth/Login")
chequear("sin sesión se ve claro", tema(p) == "light", tema(p))
s, u, p = w.get("/Preferencias/Estilo")
chequear("sin sesión la pantalla va al login", "/Auth/Login" in u, u)

s, u, p = w.login("lector1", "Lector123!")
chequear("arranca en claro", tema(p) == "light", tema(p))
chequear("menú con Estilo de lectura", "/Preferencias/Estilo" in p)
s, u, p = w.get("/Preferencias/Estilo")
chequear("pantalla marca el estilo actual", re.search(r'value="CLARO"[^>]*checked', p) is not None and not re.search(r'value="OSCURO"[^>]*checked', p))
s, u, p = w.post("/Preferencias/Estilo", "/Preferencias/Estilo", [("estilo", "OSCURO")])
chequear("guardar avisa y aplica oscuro", "Estilo de lectura guardado" in p and tema(p) == "dark", tema(p))
chequear("pantalla marca el nuevo estilo", re.search(r'value="OSCURO"[^>]*checked', p) is not None)
for ruta in ["/", "/Lecturas/Historias", "/Lecturas/Historial"]:
    s, u, p = w.get(ruta)
    chequear(f"{ruta} en oscuro", tema(p) == "dark", tema(p))
s, u, p = w.post("/Preferencias/Estilo", "/Preferencias/Estilo", [("estilo", "AZUL")])
chequear("estilo inválido muestra el error y no cambia", "no es válido" in p and tema(p) == "dark", tema(p))

s, u, p = w.post("/", "/Auth/Logout", [])
chequear("al cerrar sesión vuelve a claro", tema(p) == "light", tema(p))

o = Web(LECTOR)
s, u, p = o.login("otra", "Otra12345!")
chequear("otro usuario sigue en claro", tema(p) == "light", tema(p))

s, u, p = w.login("lector1", "Lector123!")
chequear("al volver a entrar recupera su oscuro", tema(p) == "dark", tema(p))

# Cambio hecho desde otra sesión del mismo usuario
s, r = api("PUT", "/api/Usuarios/estilo", {"estilo": "CLARO"}, token=lector)
s, u, p = w.get("/Preferencias/Estilo")
chequear("la pantalla se sincroniza con lo guardado", tema(p) == "light" and re.search(r'value="CLARO"[^>]*checked', p) is not None, tema(p))

ad = Web(LECTOR)
s, u, p = ad.login("admin1", "Admin123!")
chequear("administrador sin el menú de estilo", "/Preferencias/Estilo" not in p)
s, u, p = ad.get("/Preferencias/Estilo")
chequear("administrador no entra a la pantalla", "permisos" in p, u)

print("=== Swagger ===")
s, r = api("GET", "/swagger/v1/swagger.json")
ruta = r["paths"].get("/api/Usuarios/estilo", {}) if s == 200 else {}
chequear("Swagger documenta GET y PUT", "get" in ruta and "put" in ruta, list(ruta))

print()
print("Fallos:", len(fallos), fallos if fallos else "")
sys.exit(1 if fallos else 0)
