"""Arma los diagramas en PlantUML e imprime el enlace de cada uno en PlantUML online.

Los atributos y operaciones se leen del código C#, así el diagrama no se desactualiza.
Acá solo se define qué clases entran en cada diagrama y cómo se relacionan.
Las imágenes del informe son capturas de esos enlaces, guardadas en ../informe/img.
"""
import base64
import pathlib
import re
import string
import sys
import zlib

AQUI = pathlib.Path(__file__).parent
RAIZ = AQUI.parent.parent
SERVIDOR = "https://www.plantuml.com/plantuml"


# ---------- Lectura del código C# ----------

ENCABEZADO = re.compile(
    r"^\s*(?:public\s+)?(?:(abstract|static|sealed)\s+)*(class|record|interface|enum)\s+(\w+)(\s*\([^)]*\))?",
    re.M)
PROPIEDAD = re.compile(r"^\s*public\s+(?!const|static|class|abstract class)([\w<>?,\[\] ]+?)\s+(\w+)\s*(?:\{|=>)", re.M)
METODO = re.compile(
    r"^\s*public\s+(?:static\s+|override\s+|virtual\s+|async\s+|abstract\s+)*([\w<>?,\[\] ]+?)\s+(\w+)\s*\(([^)]*)\)", re.M)
METODO_INTERFAZ = re.compile(r"^\s*([\w<>?,\[\]]+(?: [\w<>?,\[\]]+)?)\s+(\w+)\s*\(([^)]*)\)\s*;", re.M)


def parametros(texto):
    texto = re.sub(r"\[\w[^\]]*\]\s*", "", texto)
    partes, profundidad, actual = [], 0, ""
    for caracter in texto:
        profundidad += (caracter == "<") - (caracter == ">")
        if caracter == "," and profundidad == 0:
            partes.append(actual)
            actual = ""
        else:
            actual += caracter
    if actual.strip():
        partes.append(actual)
    resultado = []
    for p in partes:
        p = re.sub(r"^this\s+", "", p.split("=")[0].strip())
        if " " in p:
            tipo, nombre = p.rsplit(None, 1)
            resultado.append((nombre, tipo))
    return resultado


def leer_clases(carpeta):
    clases = {}
    for archivo in sorted((RAIZ / carpeta).rglob("*.cs")):
        if {"bin", "obj", "migrations"} & {p.lower() for p in archivo.parts}:
            continue
        texto = re.sub(r"///.*|//.*", "", archivo.read_text(encoding="utf-8-sig"))
        encabezados = list(ENCABEZADO.finditer(texto))
        for i, m in enumerate(encabezados):
            fin = encabezados[i + 1].start() if i + 1 < len(encabezados) else len(texto)
            cuerpo = texto[m.end():fin]
            nombre, tipo = m.group(3), m.group(2)
            clase = {"nombre": nombre, "tipo": tipo, "abstracta": "abstract" in texto[m.start():m.end()],
                     "atributos": [], "operaciones": [], "literales": []}
            if tipo == "enum":
                clase["literales"] = re.findall(r"\b([A-Z_]{2,})\b", cuerpo)
            elif tipo == "interface":
                for r, n, p in METODO_INTERFAZ.findall(cuerpo):
                    clase["operaciones"].append((n, r.strip(), parametros(p)))
            else:
                if m.group(4):
                    clase["atributos"] = parametros(m.group(4).strip()[1:-1])
                for t, n in PROPIEDAD.findall(cuerpo):
                    if n != nombre:
                        clase["atributos"].append((n, t.strip()))
                for r, n, p in METODO.findall(cuerpo):
                    if n != nombre and r.strip() not in ("new", "return"):
                        clase["operaciones"].append((n, r.strip(), parametros(p)))
            clases[nombre] = clase
    return clases


DOMINIO = leer_clases("Dominio")
APP = leer_clases("Aplicacion")
INFRA = leer_clases("Infraestructura")
WEBAPI = leer_clases("Obligatorio.WebApi")
LECTOR = leer_clases("Obligatorio.Lector")


# ---------- Escritura de PlantUML ----------

ENCABEZADO_PUML = """skinparam classAttributeIconSize 0
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam nodesep 35
skinparam ranksep 45
skinparam packageStyle rectangle
set separator none
hide empty members
hide circle
"""

# Atributos que se dibujan como asociación y no como texto dentro de la clase.
OMITIR = {
    "Historia": {"Estado", "CapituloInicial", "CapituloInicialId", "Categorias", "Capitulos"},
    "Capitulo": {"Historia"},
    "CapituloIntermedio": {"Opciones"},
    "Opcion": {"Destino"},
    "Lectura": {"Usuario", "Historia", "CapituloActual", "FinalAlcanzado"},
    "Auditoria": {"Administrador", "Historia"},
    "Usuario": {"Rol", "EstiloLectura"},
    "LecturaDetalleDTO": {"CapituloActual"},
    "CapituloDTO": {"Opciones"},
    "LecturaDetalleViewModel": {"CapituloActual"},
    "CapituloViewModel": {"Opciones"},
}


def clase(fuente, nombre, color="", alias=None, estereotipo="", miembros=True, solo_operaciones=None):
    c = fuente[nombre]
    id_ = alias or nombre
    cabecera = {"interface": "interface", "enum": "enum"}.get(c["tipo"], "abstract class" if c["abstracta"] else "class")
    titulo = f'"{nombre}" as {id_}' if alias else nombre
    if estereotipo:
        titulo += f" <<{estereotipo}>>"
    if color:
        titulo += f" {color}"
    lineas = [f"{cabecera} {titulo} {{"]
    if miembros:
        lineas += [f"  {x}" for x in c["literales"]]
        lineas += [f"  +{n} : {t}" for n, t in c["atributos"] if n not in OMITIR.get(nombre, ())]
        for n, r, ps in c["operaciones"]:
            if solo_operaciones is None or n in solo_operaciones:
                firma = ", ".join(f"{pn} : {pt}" for pn, pt in ps)
                lineas.append(f"  +{n}({firma}) : {r}")
    lineas.append("}")
    return "\n".join(lineas)


def paquete(nombre, *contenido):
    interior = "\n".join(contenido)
    return f'package "{nombre}" {{\n{interior}\n}}'


def columnas(nombres, por_fila):
    """Sin relaciones, PlantUML pone todo en una fila: estos enlaces invisibles arman una grilla."""
    return "\n".join(f"{nombres[i]} -[hidden]down- {nombres[i + por_fila]}" for i in range(len(nombres) - por_fila))


AMA, GRIS, AZUL, VERDE, ROSA, CELESTE, LILA, NARANJA = (
    "#FFF9D6", "#EEEEEE", "#D7E9F7", "#E2F2DC", "#FBE3EA", "#DCE6F7", "#E9E1F5", "#FCEBD9")

DIAGRAMAS = {}

DIAGRAMAS["casos-de-uso"] = """left to right direction
skinparam packageStyle rectangle
actor "Administrador" as Admin
actor "Usuario (lector)" as Lector

rectangle "Aplicación de administración" {
  usecase "RF01 Iniciar y cerrar sesión\\n(administración)" as RF01
  usecase "RF02 Registrar usuario" as RF02
  usecase "RF03 Crear historia" as Crear
  usecase "RF03 Editar historia" as Editar
  usecase "RF03 Publicar historia" as Publicar
  usecase "RF03 Eliminar historia" as Eliminar
  usecase "RF04 Agregar capítulo" as Capitulo
  usecase "RF05 Consultar auditoría" as Consultar
  usecase "RF05 Registrar auditoría" as Registrar
}

rectangle "Aplicación de lectura (Web API y MVC)" {
  usecase "RF06 Iniciar y cerrar sesión\\n(lectura)" as RF06
  usecase "RF07 Listar historias publicadas" as Listar
  usecase "RF07 Lectura de historia" as Leer
  usecase "RF08 Historial de lecturas" as Historial
  usecase "RF09 Ver historias más leídas" as RF09
  usecase "RF10 Ver final más alcanzado" as RF10
  usecase "RF11 Ver usuarios con más\\nhistorias leídas" as RF11
  usecase "RF12 Seleccionar estilo de lectura" as RF12
}

Admin --> RF01
Admin --> RF02
Admin --> Crear
Admin --> Editar
Admin --> Eliminar
Admin --> Capitulo
Admin --> Consultar
Admin --> RF06
Admin --> RF09
Admin --> RF10
Admin --> RF11

RF06 <-- Lector
Listar <-- Lector
Leer <-- Lector
Historial <-- Lector
RF12 <-- Lector

Crear ..> Registrar : <<include>>
Editar ..> Registrar : <<include>>
Eliminar ..> Registrar : <<include>>
Capitulo ..> Registrar : <<include>>
Publicar ..> Editar : <<extend>>
Publicar ..> Registrar : <<include>>
"""

DIAGRAMAS["dominio-entidades"] = "\n".join([
    clase(DOMINIO, "IValidable", GRIS),
    *[clase(DOMINIO, n, AMA) for n in ["Usuario", "Categoria", "Historia", "Capitulo", "CapituloIntermedio", "CapituloFinal", "Opcion", "Lectura", "Auditoria"]],
    clase(DOMINIO, "EstadoHistoria", GRIS),
    clase(DOMINIO, "RolUsuario", GRIS),
    clase(DOMINIO, "EstiloLectura", AZUL, estereotipo="value object"),
    """
Historia "*" --> "1..*" Categoria : categorias
Historia "1" *-- "1..*" Capitulo : capitulos
Historia "1" --> "0..1" CapituloIntermedio : capituloInicial
Historia --> EstadoHistoria : estado
Capitulo <|-- CapituloIntermedio
Capitulo <|-- CapituloFinal
CapituloIntermedio "1" *-- "*" Opcion : opciones
Opcion "*" --> "1" Capitulo : destino
Lectura "*" --> "1" Usuario : usuario
Lectura "*" --> "1" Historia : historia
Lectura "*" --> "1" Capitulo : capituloActual
Lectura "*" --> "0..1" CapituloFinal : finalAlcanzado
Auditoria "*" --> "1" Usuario : administrador
Auditoria "*" --> "0..1" Historia : historia
Usuario "1" *-- "1" EstiloLectura : estiloLectura
Usuario --> RolUsuario : rol
IValidable <|.. Usuario
IValidable <|.. Categoria
IValidable <|.. Historia
IValidable <|.. Capitulo
IValidable <|.. Opcion
IValidable <|.. Lectura
IValidable <|.. Auditoria
"""])

EXCEPCIONES = ["UsuarioException", "HistoriaException", "CapituloException", "OpcionException", "CategoriaException",
               "LecturaException", "AuditoriaException", "EntidadNoEncontradaException", "CredencialesInvalidasException"]
REPOS = ["IRepositorioUsuario", "IRepositorioHistoria", "IRepositorioCategoria", "IRepositorioLectura", "IRepositorioAuditoria"]
DIAGRAMAS["dominio-repositorios"] = "\n".join([
    paquete("InterfacesDeRepositorio", *[clase(DOMINIO, n, AMA) for n in REPOS]),
    paquete("Consultas", *[clase(DOMINIO, n, AZUL) for n in ["LecturasPorHistoria", "LecturasPorFinal", "HistoriasPorUsuario"]]),
    "IRepositorioLectura ..> LecturasPorHistoria\nIRepositorioLectura ..> LecturasPorFinal\nIRepositorioLectura ..> HistoriasPorUsuario",
    "IRepositorioUsuario -[hidden]down- IRepositorioAuditoria\nIRepositorioHistoria -[hidden]down- IRepositorioLectura",
])

DIAGRAMAS["dominio-excepciones"] = "\n".join([
    "left to right direction",
    clase(DOMINIO, "DominioException", GRIS, miembros=False),
    *[clase(DOMINIO, n, GRIS, miembros=False) for n in EXCEPCIONES],
    "\n".join(f"DominioException <|-- {n}" for n in EXCEPCIONES),
])

SERVICIOS = ["Usuario", "Historia", "Lectura", "Metricas", "Auditoria"]
DIAGRAMAS["aplicacion-servicios"] = "\n".join([
    *[clase(APP, f"IServicio{n}", VERDE) for n in SERVICIOS],
    *[clase(APP, f"Servicio{n}", VERDE, miembros=False) for n in SERVICIOS],
    clase(APP, "IUnidadDeTrabajo", VERDE),
    "\n".join(f"IServicio{n} <|.. Servicio{n}" for n in SERVICIOS),
    "ServicioHistoria ..> IServicioAuditoria\nServicioHistoria ..> IUnidadDeTrabajo",
    "ServicioUsuario -[hidden]down- IServicioMetricas\nServicioHistoria -[hidden]down- IServicioAuditoria\nServicioLectura -[hidden]down- IUnidadDeTrabajo",
])

DIAGRAMAS["aplicacion-dependencias"] = "\n".join([
    *[clase(APP, f"Servicio{n}", VERDE, miembros=False) for n in SERVICIOS],
    *[clase(DOMINIO, n, AMA, miembros=False) for n in REPOS],
    """
ServicioUsuario ..> IRepositorioUsuario
ServicioHistoria ..> IRepositorioHistoria
ServicioHistoria ..> IRepositorioCategoria
ServicioHistoria ..> IRepositorioLectura
ServicioLectura ..> IRepositorioLectura
ServicioLectura ..> IRepositorioHistoria
ServicioLectura ..> IRepositorioUsuario
ServicioMetricas ..> IRepositorioLectura
ServicioMetricas ..> IRepositorioHistoria
ServicioAuditoria ..> IRepositorioAuditoria
ServicioAuditoria ..> IRepositorioUsuario
ServicioAuditoria ..> IRepositorioHistoria
"""])

LISTA_DTOS = sorted(n for n in APP if n.endswith("DTO"))
LISTA_MAPPERS = sorted(n for n in APP if n.endswith("Mapper"))
DIAGRAMAS["aplicacion-dtos"] = "\n".join([*[clase(APP, n, ROSA) for n in LISTA_DTOS], columnas(LISTA_DTOS, 6),
                                          "HistoriaResumenDTO <|-- HistoriaDetalleDTO", "LecturaDTO <|-- LecturaDetalleDTO"])
DIAGRAMAS["aplicacion-mappers"] = "\n".join([*[clase(APP, n, VERDE) for n in LISTA_MAPPERS], columnas(LISTA_MAPPERS, 3)])

DIAGRAMAS["lectura-presentacion"] = "\n".join([
    paquete("Obligatorio.Lector (MVC)",
            clase(LECTOR, "ClienteApiController", NARANJA),
            clase(LECTOR, "LecturasController", NARANJA, alias="MvcLecturas"),
            clase(LECTOR, "RequiereRolAttribute", NARANJA, miembros=False),
            clase(LECTOR, "LecturaViewModel", NARANJA),
            clase(LECTOR, "LecturaDetalleViewModel", NARANJA),
            clase(LECTOR, "CapituloViewModel", NARANJA),
            clase(LECTOR, "OpcionViewModel", NARANJA)),
    paquete("Obligatorio.WebApi",
            clase(WEBAPI, "LecturasController", LILA, alias="ApiLecturas"),
            clase(WEBAPI, "ClaimsPrincipalExtensiones", LILA),
            clase(WEBAPI, "ManejadorExcepciones", LILA, miembros=False)),
    clase(APP, "IServicioLectura", VERDE, miembros=False),
    """
ClienteApiController <|-- MvcLecturas
MvcLecturas ..> RequiereRolAttribute
MvcLecturas ..> LecturaDetalleViewModel
LecturaViewModel <|-- LecturaDetalleViewModel
LecturaDetalleViewModel --> "1" CapituloViewModel : capituloActual
CapituloViewModel --> "*" OpcionViewModel : opciones
MvcLecturas ..> ApiLecturas : HTTP + JWT
ApiLecturas ..> IServicioLectura
ApiLecturas ..> ClaimsPrincipalExtensiones
ManejadorExcepciones ..> ApiLecturas : traduce errores
"""])

DIAGRAMAS["lectura-aplicacion"] = "\n".join([
    paquete("Aplicacion",
            clase(APP, "IServicioLectura", VERDE),
            clase(APP, "ServicioLectura", VERDE, miembros=False),
            clase(APP, "LecturaMapper", VERDE),
            clase(APP, "CapituloMapper", VERDE),
            clase(APP, "LecturaDTO", ROSA),
            clase(APP, "LecturaDetalleDTO", ROSA),
            clase(APP, "CapituloDTO", ROSA),
            clase(APP, "OpcionDTO", ROSA)),
    """
IServicioLectura <|.. ServicioLectura
ServicioLectura ..> LecturaMapper
ServicioLectura ..> LecturaDetalleDTO
LecturaMapper ..> CapituloMapper
LecturaDTO <|-- LecturaDetalleDTO
LecturaDetalleDTO --> "1" CapituloDTO : capituloActual
CapituloDTO --> "*" OpcionDTO : opciones
"""])

DIAGRAMAS["lectura-infraestructura"] = "\n".join([
    clase(APP, "ServicioLectura", VERDE, miembros=False),
    paquete("Dominio (interfaces de repositorio)",
            clase(DOMINIO, "IRepositorioLectura", AMA, solo_operaciones={"Add", "FindById", "Update", "FindByUsuarioMesAnio"}),
            clase(DOMINIO, "IRepositorioHistoria", AMA, solo_operaciones={"FindById", "FindPublicadas"}),
            clase(DOMINIO, "IRepositorioUsuario", AMA, solo_operaciones={"FindById"})),
    paquete("Infraestructura",
            clase(INFRA, "RepositorioLectura", CELESTE, miembros=False),
            clase(INFRA, "RepositorioHistoria", CELESTE, miembros=False),
            clase(INFRA, "RepositorioUsuario", CELESTE, miembros=False),
            clase(INFRA, "AppDbContext", CELESTE, miembros=False)),
    """
ServicioLectura ..> IRepositorioLectura
ServicioLectura ..> IRepositorioHistoria
ServicioLectura ..> IRepositorioUsuario
IRepositorioLectura <|.. RepositorioLectura
IRepositorioHistoria <|.. RepositorioHistoria
IRepositorioUsuario <|.. RepositorioUsuario
RepositorioLectura ..> AppDbContext
RepositorioHistoria ..> AppDbContext
RepositorioUsuario ..> AppDbContext
"""])


# ---------- Enlaces a PlantUML online ----------

ALFABETO_PLANTUML = string.digits + string.ascii_uppercase + string.ascii_lowercase + "-_"
TRADUCCION = bytes.maketrans(
    (string.ascii_uppercase + string.ascii_lowercase + string.digits + "+/").encode(),
    ALFABETO_PLANTUML.encode())


def codificar(texto):
    compresor = zlib.compressobj(9, zlib.DEFLATED, -15)
    datos = compresor.compress(texto.encode("utf-8")) + compresor.flush()
    return base64.b64encode(datos).translate(TRADUCCION).decode().rstrip("=")


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    for nombre, cuerpo in DIAGRAMAS.items():
        texto = f"@startuml\n{ENCABEZADO_PUML}\n{cuerpo}\n@enduml\n"
        print(f"{nombre}\n{SERVIDOR}/uml/{codificar(texto)}\n")


if __name__ == "__main__":
    main()
