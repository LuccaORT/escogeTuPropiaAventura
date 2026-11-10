"""Valida precarga.json y uso.json y arma ../Obligatorio.sql (esquema + inserts).

Los Id los genera siempre la base de datos: el script guarda cada Id nuevo en una
variable con SCOPE_IDENTITY() y la usa en las claves foráneas. Por eso los inserts
tienen que correr en un mismo lote, sin GO entre ellos.
"""
import datetime
import json
import pathlib
import re
import sys

AQUI = pathlib.Path(__file__).parent
LARGO_TITULO, LARGO_SINOPSIS, LARGO_OPCION = 200, 2000, 300
MINIMO_POR_TABLA = 10
INTERMEDIO, FINAL = "CapituloIntermedio", "CapituloFinal"

errores = []


def error(mensaje):
    errores.append(mensaje)


def leer(nombre):
    return json.loads((AQUI / nombre).read_text(encoding="utf-8"))


def fecha(texto):
    return datetime.datetime.fromisoformat(texto)


def validar_usuario(u):
    if not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", u["email"]):
        error(f"email inválido: {u['email']}")
    c = u["contrasena"]
    if len(c) < 8 or not all(re.search(p, c) for p in ("[A-Z]", "[a-z]", "[0-9]", "[^a-zA-Z0-9]")):
        error(f"contraseña inválida: {u['nombreUsuario']}")
    if u["rol"] not in ("ADMINISTRADOR", "LECTOR"):
        error(f"rol inválido: {u['nombreUsuario']}")
    if u["estilo"] not in ("CLARO", "OSCURO"):
        error(f"estilo inválido: {u['nombreUsuario']}")


def validar_historia(h, categorias, admins):
    c = h["clave"]
    if len(h["titulo"]) > LARGO_TITULO or len(h["sinopsis"]) > LARGO_SINOPSIS:
        error(f"{c}: título o sinopsis demasiado largos")
    if not h["categorias"]:
        error(f"{c}: sin categorías")
    for categoria in h["categorias"]:
        if categoria not in categorias:
            error(f"{c}: categoría desconocida {categoria}")
    if h["admin"] not in admins:
        error(f"{c}: {h['admin']} no es administrador")

    capitulos = {x["clave"]: x for x in h["capitulos"]}
    if len(capitulos) != len(h["capitulos"]):
        error(f"{c}: claves de capítulo repetidas")
    if h["capitulos"][0].get("final"):
        error(f"{c}: el capítulo inicial no puede ser final")

    # Cada capítulo tiene un único antecedente: los caminos forman un árbol.
    llegadas = {}
    for x in h["capitulos"]:
        if len(x["titulo"]) > LARGO_TITULO or not x["texto"].strip():
            error(f"{c}/{x['clave']}: título o texto inválido")
        if x.get("final") and x.get("opciones"):
            error(f"{c}/{x['clave']}: un final no puede tener opciones")
        for o in x.get("opciones", []):
            if len(o["texto"]) > LARGO_OPCION:
                error(f"{c}/{x['clave']}: opción demasiado larga")
            if o["destino"] not in capitulos:
                error(f"{c}/{x['clave']}: destino inexistente {o['destino']}")
            llegadas[o["destino"]] = llegadas.get(o["destino"], 0) + 1

    for x in h["capitulos"][1:]:
        if llegadas.get(x["clave"], 0) != 1:
            error(f"{c}/{x['clave']}: debe tener exactamente un antecedente")
    if llegadas.get(h["capitulos"][0]["clave"]):
        error(f"{c}: el capítulo inicial no puede ser destino")

    if h["estado"] == "PUBLICADA":
        if not any(x.get("final") for x in h["capitulos"]):
            error(f"{c}: publicada sin finales")
        for x in h["capitulos"]:
            if not x.get("final") and not x.get("opciones"):
                error(f"{c}/{x['clave']}: publicada con un intermedio sin opciones")


def validar_lecturas(lecturas, historias, usuarios, hoy):
    for fila in lecturas:
        usuario, historia, capitulo, inicio, minutos = fila
        if usuarios.get(usuario, {}).get("rol") != "LECTOR":
            error(f"lectura de {usuario}: no es lector")
        h = historias.get(historia)
        if h is None:
            error(f"lectura: historia inexistente {historia}")
            continue
        if h["estado"] != "PUBLICADA":
            error(f"lectura de {historia}: no está publicada")
        if fecha(inicio) < fecha(h["creada"]):
            error(f"lectura de {historia}: anterior a la creación de la historia")
        if fecha(inicio) > hoy:
            error(f"lectura de {historia}: fecha futura")
        x = next((y for y in h["capitulos"] if y["clave"] == capitulo), None)
        if x is None:
            error(f"lectura de {historia}: capítulo inexistente {capitulo}")
        elif bool(x.get("final")) != (minutos is not None):
            error(f"lectura de {historia}/{capitulo}: un final lleva minutos y uno en curso no")


def metricas(datos, lecturas):
    completadas = [f for f in lecturas if f[4] is not None]
    por_historia = {}
    for f in completadas:
        por_historia[f[1]] = por_historia.get(f[1], 0) + 1
    titulos = {h["clave"]: h["titulo"] for h in datos["historias"]}
    ranking_h = sorted(((titulos[k], v) for k, v in por_historia.items()), key=lambda x: (-x[1], x[0]))

    distintas = {}
    for f in completadas:
        distintas.setdefault(f[0], set()).add(f[1])
    ranking_u = sorted(((k, len(v)) for k, v in distintas.items()), key=lambda x: (-x[1], x[0]))

    finales = {}
    for h in datos["historias"]:
        if h["estado"] != "PUBLICADA":
            continue
        cuenta = {x["titulo"]: sum(1 for f in completadas if f[1] == h["clave"] and f[2] == x["clave"])
                  for x in h["capitulos"] if x.get("final")}
        finales[h["titulo"]] = cuenta

    return {"rankingHistorias": ranking_h, "rankingUsuarios": ranking_u, "finales": finales}


def s(texto):
    return "N'" + texto.replace("'", "''") + "'"


def f_sql(valor):
    return "'" + fecha(valor).isoformat(timespec="seconds") + "'"


def armar_datos(datos, lecturas):
    L = []
    declarados = []

    def var(nombre):
        # Las claves pueden traer guiones, que no son válidos en una variable de T-SQL.
        nombre = re.sub(r"[^\w@]", "_", nombre)
        declarados.append(nombre)
        return nombre

    categorias_var = {c: var(f"@cat{i}") for i, c in enumerate(datos["categorias"], 1)}
    usuarios_var = {u["nombreUsuario"]: var(f"@u_{u['nombreUsuario']}") for u in datos["usuarios"]}
    historias_var = {h["clave"]: var(f"@h_{h['clave']}") for h in datos["historias"]}
    capitulos_var = {(h["clave"], x["clave"]): var(f"@c_{h['clave']}_{x['clave']}")
                     for h in datos["historias"] for x in h["capitulos"]}

    L.append("-- ============================================================")
    L.append("-- PRECARGA GENERADA CON IA: categorías, usuarios, historias,")
    L.append("-- capítulos, opciones y finales.")
    L.append("-- ============================================================")
    L.append("")
    L.append("-- Categorias")
    for c in datos["categorias"]:
        L.append(f"INSERT INTO Categorias (Nombre) VALUES ({s(c)}); SET {categorias_var[c]} = SCOPE_IDENTITY();")

    L.append("")
    L.append("-- Usuarios (Rol: 0 = ADMINISTRADOR, 1 = LECTOR)")
    for u in datos["usuarios"]:
        rol = 0 if u["rol"] == "ADMINISTRADOR" else 1
        L.append(f"INSERT INTO Usuarios (NombreCompleto, Email, NombreUsuario, Contrasena, Rol, EstiloLectura) "
                 f"VALUES ({s(u['nombreCompleto'])}, {s(u['email'])}, {s(u['nombreUsuario'])}, {s(u['contrasena'])}, {rol}, {s(u['estilo'])}); "
                 f"SET {usuarios_var[u['nombreUsuario']]} = SCOPE_IDENTITY();")

    for h in datos["historias"]:
        estado = 1 if h["estado"] == "PUBLICADA" else 0
        hv = historias_var[h["clave"]]
        L += ["", f"-- Historia: {h['titulo']} ({h['estado']})"]
        # CapituloInicialId se completa después: historia y capítulo inicial se referencian entre sí.
        L.append(f"INSERT INTO Historias (Titulo, Sinopsis, Estado, CapituloInicialId) "
                 f"VALUES ({s(h['titulo'])}, {s(h['sinopsis'])}, {estado}, NULL); SET {hv} = SCOPE_IDENTITY();")
        for c in h["categorias"]:
            L.append(f"INSERT INTO CategoriaHistoria (CategoriasId, HistoriaId) VALUES ({categorias_var[c]}, {hv});")
        for x in h["capitulos"]:
            tipo = FINAL if x.get("final") else INTERMEDIO
            L.append(f"INSERT INTO Capitulos (Titulo, Texto, HistoriaId, Discriminator) "
                     f"VALUES ({s(x['titulo'])}, {s(x['texto'])}, {hv}, '{tipo}'); "
                     f"SET {capitulos_var[(h['clave'], x['clave'])]} = SCOPE_IDENTITY();")
        L.append(f"UPDATE Historias SET CapituloInicialId = {capitulos_var[(h['clave'], h['capitulos'][0]['clave'])]} WHERE Id = {hv};")
        for x in h["capitulos"]:
            for o in x.get("opciones", []):
                L.append(f"INSERT INTO Opciones (Texto, DestinoId, CapituloIntermedioId) "
                         f"VALUES ({s(o['texto'])}, {capitulos_var[(h['clave'], o['destino'])]}, {capitulos_var[(h['clave'], x['clave'])]});")

    L += ["", "-- ============================================================",
          "-- DATOS DE USO: auditoría y lecturas, los que el sistema",
          "-- registra mientras se usa.",
          "-- ============================================================"]

    L += ["", "-- Auditorias"]

    def auditoria(accion, cuando, admin, historia_sql, titulo):
        L.append(f"INSERT INTO Auditorias (Accion, Fecha, AdministradorId, HistoriaId, TituloHistoria) "
                 f"VALUES ({s(accion)}, {f_sql(cuando)}, {usuarios_var[admin]}, {historia_sql}, {s(titulo)});")

    for h in datos["historias"]:
        momento = fecha(h["creada"])
        hv = historias_var[h["clave"]]
        auditoria("Creación de historia", momento.isoformat(), h["admin"], hv, h["titulo"])
        for x in h["capitulos"][1:]:
            momento += datetime.timedelta(minutes=12)
            accion = "Creación de capítulo final" if x.get("final") else "Creación de capítulo intermedio"
            auditoria(accion, momento.isoformat(), h["admin"], hv, h["titulo"])
        if h["estado"] == "PUBLICADA":
            momento += datetime.timedelta(minutes=20)
            auditoria("Publicación de historia", momento.isoformat(), h["admin"], hv, h["titulo"])
    titulos = {h["clave"]: h["titulo"] for h in datos["historias"]}
    for e in datos["ediciones"]:
        auditoria("Edición de historia", e["fecha"], e["admin"], historias_var[e["historia"]], titulos[e["historia"]])

    # Una historia dada de baja: la historia no queda, pero la auditoría sí,
    # con HistoriaId en NULL y el título conservado (como hace la aplicación).
    for b in datos["bajas"]:
        auditoria("Creación de historia", b["creada"], b["admin"], "NULL", b["titulo"])
        auditoria("Baja de historia", b["baja"], b["admin"], "NULL", b["titulo"])

    L += ["", "-- Lecturas (FechaFinalizacion y FinalAlcanzadoId en NULL = todavía en curso)"]
    for usuario, historia, capitulo, inicio, minutos in lecturas:
        cv = capitulos_var[(historia, capitulo)]
        if minutos is None:
            fin, final = "NULL", "NULL"
        else:
            fin, final = f_sql((fecha(inicio) + datetime.timedelta(minutes=minutos)).isoformat()), cv
        L.append(f"INSERT INTO Lecturas (FechaInicio, FechaFinalizacion, UsuarioId, HistoriaId, CapituloActualId, FinalAlcanzadoId) "
                 f"VALUES ({f_sql(inicio)}, {fin}, {usuarios_var[usuario]}, {historias_var[historia]}, {cv}, {final});")

    cabecera = ["SET NOCOUNT ON;", "SET XACT_ABORT ON;", "BEGIN TRANSACTION;", ""]
    for i in range(0, len(declarados), 8):
        cabecera.append("DECLARE " + ", ".join(f"{d} int" for d in declarados[i:i + 8]) + ";")
    cabecera.append("")
    return "\n".join(cabecera + L + ["", "COMMIT TRANSACTION;", "GO"])


def contar_filas(datos, lecturas):
    capitulos = sum(len(h["capitulos"]) for h in datos["historias"])
    opciones = sum(len(x.get("opciones", [])) for h in datos["historias"] for x in h["capitulos"])
    audit = sum(1 + len(h["capitulos"]) - 1 + (1 if h["estado"] == "PUBLICADA" else 0) for h in datos["historias"])
    audit += len(datos["ediciones"]) + 2 * len(datos["bajas"])
    return {
        "Categorias": len(datos["categorias"]),
        "Usuarios": len(datos["usuarios"]),
        "Historias": len(datos["historias"]),
        "CategoriaHistoria": sum(len(h["categorias"]) for h in datos["historias"]),
        "Capitulos": capitulos,
        "Opciones": opciones,
        "Auditorias": audit,
        "Lecturas": len(lecturas),
    }


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    datos = leer("precarga.json")
    lecturas = leer("uso.json")["lecturas"]
    usuarios = {u["nombreUsuario"]: u for u in datos["usuarios"]}
    historias = {h["clave"]: h for h in datos["historias"]}
    admins = {k for k, u in usuarios.items() if u["rol"] == "ADMINISTRADOR"}

    if len(usuarios) != len(datos["usuarios"]) or len(historias) != len(datos["historias"]):
        error("hay usuarios o historias repetidos")
    for u in datos["usuarios"]:
        validar_usuario(u)
    for h in datos["historias"]:
        validar_historia(h, set(datos["categorias"]), admins)
    validar_lecturas(lecturas, historias, usuarios, fecha("2026-11-05T00:00:00"))

    filas = contar_filas(datos, lecturas)
    for tabla, cantidad in filas.items():
        if cantidad < MINIMO_POR_TABLA:
            error(f"{tabla}: {cantidad} filas, el mínimo es {MINIMO_POR_TABLA}")

    if errores:
        print("ERRORES:")
        print("\n".join("  " + e for e in errores))
        return 1

    esquema = (AQUI / "esquema.sql").read_text(encoding="utf-8-sig").replace("\r\n", "\n").strip()
    encabezado = (
        "-- Escoge tu propia aventura - Script de base de datos\n"
        "-- Ejecutar sobre una base de datos VACÍA: crea el esquema y carga los datos.\n"
        "-- Los Id los genera la base de datos.\n"
    )
    salida = "\n\n".join([
        encabezado,
        "-- ESQUEMA (generado con dotnet ef migrations script)\n" + esquema,
        armar_datos(datos, lecturas)]) + "\n"
    (AQUI.parent / "Obligatorio.sql").write_bytes(("﻿" + salida).encode("utf-8").replace(b"\n", b"\r\n"))

    resultado = metricas(datos, lecturas)
    resultado["filas"] = filas
    (AQUI / "metricas-esperadas.json").write_text(
        json.dumps(resultado, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print("Script generado.")
    for tabla, cantidad in filas.items():
        print(f"  {tabla}: {cantidad}")
    print(json.dumps(resultado["rankingHistorias"], ensure_ascii=False))
    print(json.dumps(resultado["rankingUsuarios"], ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
