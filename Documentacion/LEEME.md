# Documentación del obligatorio

## Informe en PDF

`Informe.pdf` se arma con `informe/generar_informe.py`, que usa Microsoft Edge o Chrome y la biblioteca `pypdf`.

1. Completar `informe/datos-entrega.json`: enlaces y datos de la IA.
2. Guardar la captura en `informe/img` e indicarla con una ruta como `img/captura.png`.
3. Ejecutarlo:

   ```bash
   python Documentacion/informe/generar_informe.py
   ```

La carátula sale en blanco y se completa directamente sobre el PDF. El programa recalcula las páginas del índice y lista lo que falta completar. En el PDF, lo pendiente aparece resaltado en amarillo. Los textos están en `informe/contenido.html` y en `RF12-investigacion-estilos.md`.

## Diagramas

Las imágenes de `informe/img` son capturas de pantalla de PlantUML online. `diagramas/generar_diagramas.py` lee las clases del código e imprime el enlace de cada diagrama. Si cambia el código, hay que correrlo, abrir los enlaces de los diagramas afectados, reemplazar sus capturas y regenerar el informe.

## Archivo de Astah

La consigna pide un archivo de Astah con los mismos diagramas. Se arma en Astah a partir de las imágenes de `informe/img` y se guarda como `Documentacion/Diagramas.asta`, para que entre en el zip de la entrega.

## Datos de prueba

Ver `generacion-datos-ia.md`. El script final es `BaseDeDatos/Obligatorio.sql`.

## Publicación en Somee

Las tres aplicaciones comparten el sitio `escogetuaventura.somee.com`, porque el plan gratis da un solo sitio:

| Ruta | Aplicación |
|---|---|
| `/` | Lectura |
| `/admin` | Administración (aplicación IIS) |
| `/webapi` | Web API (aplicación IIS) |

Se publican con `-p:AspNetCoreHostingModel=OutOfProcess -p:UseAppHost=false`, porque IIS admite una sola aplicación dentro del proceso por grupo de aplicaciones. La base de Somee se creó con `BaseDeDatos/Obligatorio.sql`.

La cadena de conexión y la clave JWT de producción están solo en los `appsettings.Production.json` del servidor; no van en el repositorio ni en el zip. Para desarrollo, la clave JWT está en `Obligatorio.WebApi/appsettings.Development.json`.

## Pruebas automatizadas

`../Pruebas` tiene las pruebas de punta a punta. Necesitan las tres aplicaciones corriendo (administración en el puerto 5173, API en 5106 y lector en 5294) y una base recién creada. `prueba_fase4.py` espera los datos de `Obligatorio.sql`; las otras, solo `admin1`, `lector1` y las categorías.
