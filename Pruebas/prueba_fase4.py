"""Prueba de la Fase 4: la aplicación funcionando sobre la base creada por Obligatorio.sql."""
import html as htmllib
import http.cookiejar
import json
import pathlib
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

sys.stdout.reconfigure(encoding="utf-8")

ADMIN = "http://localhost:5173"
API = "http://localhost:5106"
LECTOR = "http://localhost:5294"
GEN = pathlib.Path(__file__).resolve().parent.parent / "BaseDeDatos" / "generador"
esperado = json.loads((GEN / "metricas-esperadas.json").read_text(encoding="utf-8"))
datos = json.loads((GEN / "precarga.json").read_text(encoding="utf-8"))

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
    d = json.dumps(cuerpo).encode() if cuerpo is not None else None
    req = urllib.request.Request(API + ruta, data=d, method=metodo)
    if cuerpo is not None:
        req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            t = r.read().decode()
            return r.status, json.loads(t) if t else None
    except urllib.error.HTTPError as e:
        t = e.read().decode("utf-8", "replace")
        try:
            return e.code, json.loads(t)
        except ValueError:
            return e.code, t[:200]


def sql(consulta):
    r = subprocess.run(["sqlcmd", "-S", ".", "-E", "-C", "-d", "ObligatorioDB_Dev", "-h", "-1", "-W", "-Q", "SET NOCOUNT ON; " + consulta],
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    return r.stdout.strip()


print("=== Base de datos ===")
for tabla, cantidad in esperado["filas"].items():
    real = int(sql(f"SELECT COUNT(*) FROM {tabla}"))
    chequear(f"{tabla}: {real} filas (mínimo 10)", real == cantidad and real >= 10, (real, cantidad))
chequear("Todas las historias tienen capítulo inicial", sql("SELECT COUNT(*) FROM Historias WHERE CapituloInicialId IS NULL") == "0")
chequear("Capítulo inicial pertenece a su historia",
         sql("SELECT COUNT(*) FROM Historias h JOIN Capitulos c ON c.Id=h.CapituloInicialId WHERE c.HistoriaId<>h.Id") == "0")
chequear("Opciones dentro de la misma historia",
         sql("SELECT COUNT(*) FROM Opciones o JOIN Capitulos a ON a.Id=o.CapituloIntermedioId JOIN Capitulos d ON d.Id=o.DestinoId WHERE a.HistoriaId<>d.HistoriaId") == "0")
chequear("Finales de lecturas pertenecen a su historia",
         sql("SELECT COUNT(*) FROM Lecturas l JOIN Capitulos c ON c.Id=l.FinalAlcanzadoId WHERE c.HistoriaId<>l.HistoriaId OR c.Discriminator<>'CapituloFinal'") == "0")
chequear("Lecturas completadas son consistentes",
         sql("SELECT COUNT(*) FROM Lecturas WHERE (FechaFinalizacion IS NULL AND FinalAlcanzadoId IS NOT NULL) OR (FechaFinalizacion IS NOT NULL AND FinalAlcanzadoId IS NULL)") == "0")
chequear("Tildes guardadas correctamente", sql("SELECT COUNT(*) FROM Historias WHERE Titulo = N'Expedición al Cerro del Eco'") == "1")


def login(usuario, clave="Lector123!"):
    s, r = api("POST", "/api/Auth/login", {"nombreUsuario": usuario, "contrasena": clave})
    return r if s == 200 else None


print("=== Usuarios ===")
for u in datos["usuarios"]:
    r = login(u["nombreUsuario"], u["contrasena"])
    chequear(f"{u['nombreUsuario']} entra con rol y estilo", r is not None and r["rol"] == u["rol"] and r["estiloLectura"] == u["estilo"], r)

admin = login("admin1", "Admin123!")["token"]
lector = login("lector1")["token"]

print("=== Métricas contra lo calculado desde los datos ===")
s, r = api("GET", "/api/Metricas/ranking-historias", token=admin)
real = [[x["titulo"], x["lecturasCompletadas"]] for x in r]
chequear("RF09 coincide y en orden", real == esperado["rankingHistorias"], real)
nombres = [x[0] for x in real]
chequear("RF09 excluye nunca leída", "Don Robot se jubila" not in nombres, nombres)
chequear("RF09 excluye solo en curso", "El jardín de los relojes" not in nombres, nombres)
chequear("RF09 tiene empates", len({x[1] for x in real}) < len(real))

s, r = api("GET", "/api/Metricas/ranking-usuarios", token=admin)
real = [[x["nombreUsuario"], x["historiasCompletadas"]] for x in r]
chequear("RF11 coincide y en orden", real == esperado["rankingUsuarios"], real)
chequear("RF11 excluye al usuario sin lecturas", "nuevo" not in [x[0] for x in real], real)

s, publicadas = api("GET", "/api/Historias", token=admin)
chequear("11 historias publicadas", s == 200 and len(publicadas) == 11, len(publicadas))
for h in publicadas:
    s, r = api("GET", f"/api/Metricas/historias/{h['id']}/finales", token=admin)
    real = {x["titulo"]: x["vecesAlcanzado"] for x in r["finales"]}
    chequear(f"RF10 {h['titulo']}", real == esperado["finales"][h["titulo"]], (real, esperado["finales"][h["titulo"]]))
    maximo = max(real.values())
    marcados = {x["titulo"] for x in r["finales"] if x["esMasFrecuente"]}
    chequear(f"RF10 marca del más frecuente en {h['titulo']}",
             marcados == ({k for k, v in real.items() if v == maximo} if maximo else set()), marcados)
faro = next(h for h in publicadas if h["titulo"] == "El faro que no se apaga")
s, r = api("GET", f"/api/Metricas/historias/{faro['id']}/finales", token=admin)
chequear("RF10 el faro tiene frecuencias distintas y un final en cero",
         sorted(x["vecesAlcanzado"] for x in r["finales"]) == [0, 1, 3, 5], r)

print("=== Historial ===")
s, r = api("GET", "/api/Lecturas?mes=8&anio=2026", token=lector)
chequear("RF08 lector1 en agosto", s == 200 and len(r) == 2, r)
s, r = api("GET", "/api/Lecturas?mes=7&anio=2026", token=lector)
chequear("RF08 julio vacío", s == 200 and r == [], r)

print("=== Categorías ===")
s, cats = api("GET", "/api/Categorias", token=lector)
chequear("10 categorías", s == 200 and len(cats) == 10, cats)
terror = next(c for c in cats if c["nombre"] == "Terror")
s, r = api("GET", f"/api/Historias?categoriaId={terror['id']}", token=lector)
chequear("RF07 filtra por categoría", [x["titulo"] for x in r] == ["La casa de la calle Sauce"], r)

print("=== Administración ===")
a = Web(ADMIN)
s, u, p = a.post("/Auth/Login", "/Auth/Login", [("nombreUsuario", "admin1"), ("contrasena", "Admin123!")])
chequear("admin entra y ve las historias", "La feria de los espejos" in p or "Administración" in p, u)
ids = {x.split("|")[1]: int(x.split("|")[0]) for x in sql("SELECT CAST(Id AS varchar)+'|'+Titulo FROM Historias").splitlines()}
categoria_id = sql("SELECT TOP 1 Id FROM Categorias ORDER BY Id")

s, u, p = a.get(f"/Historias/Edit/{ids['La feria de los espejos']}")
chequear("borrador con solo el inicial permite editarlo", "tituloCapituloInicial" in p or "TituloCapituloInicial" in p)
s, u, p = a.post(f"/Historias/Edit/{ids['La feria de los espejos']}", "/Historias/Edit", [("id", ids["La feria de los espejos"]), ("titulo", "La feria de los espejos"),
    ("sinopsis", "Sinopsis"), ("categoriasIds", categoria_id), ("estado", "PUBLICADA")])
chequear("no publica la incompleta", "al menos una opción" in p, p[:200])

s, u, p = a.post(f"/Historias/Edit/{ids['La biblioteca bajo el agua']}", "/Historias/Edit", [("id", ids["La biblioteca bajo el agua"]), ("titulo", "La biblioteca bajo el agua"),
    ("sinopsis", "Sinopsis"), ("categoriasIds", categoria_id), ("estado", "PUBLICADA")])
chequear("publica la completa: el dominio la valida", sql(f"SELECT Estado FROM Historias WHERE Id={ids['La biblioteca bajo el agua']}") == "1", p[:300])

s, u, p = a.post(f"/Historias/Delete/{ids['El faro que no se apaga']}", f"/Historias/DeleteConfirmed/{ids['El faro que no se apaga']}", [("id", ids["El faro que no se apaga"])])
chequear("no borra la que tiene lecturas", "lecturas" in p.lower() and sql(f"SELECT COUNT(*) FROM Historias WHERE Id={ids['El faro que no se apaga']}") == "1", p[:200])

s, u, p = a.get("/Auditorias")
chequear("auditoría muestra la historia dada de baja", "El señor de las nubes de cartón" in p and "Dada de baja" in p)
s, u, p = a.get(f"/Auditorias?historiaId={ids['La casa de la calle Sauce']}")
sin_filtros = re.sub(r"<select.*?</select>", "", p, flags=re.S)
chequear("auditoría filtra por historia", "La casa de la calle Sauce" in sin_filtros and "El faro que no se apaga" not in sin_filtros)
admin2 = sql("SELECT Id FROM Usuarios WHERE NombreUsuario='admin2'")
s, u, p = a.get(f"/Auditorias?administradorId={admin2}")
sin_filtros = re.sub(r"<select.*?</select>", "", p, flags=re.S)
chequear("auditoría filtra por administrador", "Estación Orión-9" in sin_filtros and "El faro que no se apaga" not in sin_filtros)
s, u, p = a.post(f"/Historias/Delete/{ids['La feria de los espejos']}", f"/Historias/DeleteConfirmed/{ids['La feria de los espejos']}", [("id", ids["La feria de los espejos"])])
chequear("borra la que no tiene lecturas y conserva su auditoría",
         sql(f"SELECT COUNT(*) FROM Historias WHERE Id={ids['La feria de los espejos']}") == "0" and
         sql("SELECT COUNT(*) FROM Auditorias WHERE Accion=N'Baja de historia' AND HistoriaId IS NULL AND TituloHistoria=N'La feria de los espejos'") == "1", p[:200])

print("=== Lector ===")
w = Web(LECTOR)
s, u, p = w.post("/Auth/Login", "/Auth/Login", [("nombreUsuario", "lector2"), ("contrasena", "Lector123!")])
chequear("lector2 entra en oscuro", 'data-bs-theme="dark"' in p)
s, u, p = w.get("/Lecturas/Historias")
chequear("lista las publicadas con textos correctos", "Expedición al Cerro del Eco" in p and "La feria de los espejos" not in p)

print("=== Todos los caminos de todas las publicadas ===")
nuevo = login("nuevo")["token"]
por_titulo = {h["titulo"]: h for h in datos["historias"]}
for h in publicadas:
    modelo = por_titulo[h["titulo"]]
    finales_modelo = {x["titulo"] for x in modelo["capitulos"] if x.get("final")}
    alcanzados = set()

    def recorrer(camino):
        s, l = api("POST", "/api/Lecturas", {"historiaId": h["id"]}, token=nuevo)
        assert s == 201, l
        for indice in camino:
            s, l = api("POST", f"/api/Lecturas/{l['id']}/avance", {"opcionId": l["capituloActual"]["opciones"][indice]["id"]}, token=nuevo)
            assert s == 200, l
        return l

    pendientes = [[]]
    while pendientes:
        camino = pendientes.pop()
        l = recorrer(camino)
        if l["completada"]:
            alcanzados.add(l["finalAlcanzadoTitulo"])
        else:
            pendientes += [camino + [i] for i in range(len(l["capituloActual"]["opciones"]))]
    chequear(f"se llega a todos los finales de {h['titulo']}", alcanzados == finales_modelo, (alcanzados, finales_modelo))

s, r = api("GET", "/api/Metricas/ranking-usuarios", token=admin)
chequear("las lecturas nuevas se reflejan en el ranking", any(x["nombreUsuario"] == "nuevo" for x in r), r)

print()
print("Fallos:", len(fallos), fallos if fallos else "")
sys.exit(1 if fallos else 0)
