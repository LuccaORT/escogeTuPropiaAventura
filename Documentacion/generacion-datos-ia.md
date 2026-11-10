# Generación de datos de prueba con IA generativa

Notas de trabajo para generar los datos. La sección que se entrega está en el informe, que toma de acá los prompts.

## Qué se generó

| Archivo | Contenido |
|---|---|
| `BaseDeDatos/generador/precarga.json` | Categorías, usuarios, historias, capítulos, opciones y finales. |
| `BaseDeDatos/generador/uso.json` | Lecturas, es decir, los datos que surgen del uso del sistema. |
| `BaseDeDatos/generador/generar_script.py` | Valida los dos archivos y arma el script. |
| `BaseDeDatos/Obligatorio.sql` | Script final para entregar: esquema e inserts. |

En el script, los comentarios separan la **precarga generada con IA** de los **datos de uso**. Los Id los genera la base de datos: el script guarda cada Id nuevo con `SCOPE_IDENTITY()` y lo reutiliza en las claves foráneas, sin insertar Id a mano.

## Conversación

Los datos actuales son el resultado de estos prompts, ejecutados en claude.ai con Claude Sonnet 5.5. El link, la captura y el modelo están cargados en `informe/datos-entrega.json` y aparecen en el informe.

Si se vuelven a generar los datos, hay que guardar las respuestas como `precarga.json` y `uso.json` en `BaseDeDatos/generador/` y correr el generador. Si informa errores, se le pegan a la IA como un prompt más, para que los corrija.

```bash
python BaseDeDatos/generador/generar_script.py
```

## Prompts

### Prompt 1: contexto y datos base

```text
Estoy armando los datos de prueba de "Escoge tu propia aventura", una aplicación de historias interactivas en español rioplatense. Una historia tiene un capítulo inicial, capítulos intermedios con opciones, y capítulos finales.

Reglas:
- Cada capítulo, salvo el inicial, tiene exactamente un antecedente: los caminos forman un árbol y los finales no se comparten.
- Un capítulo final no tiene opciones. Un capítulo intermedio de una historia publicada tiene al menos una opción.
- Título de hasta 200 caracteres, sinopsis de hasta 2000, texto de opción de hasta 300.
- Las contraseñas tienen al menos 8 caracteres, con mayúscula, minúscula, número y carácter especial.
- Todo el contenido tiene que ser original, sin personajes ni obras existentes.

Generá solo este JSON, sin historias todavía:
{"categorias": [10 nombres], "usuarios": [{"nombreCompleto", "email", "nombreUsuario", "contrasena", "rol", "estilo"}]}

Quiero 12 usuarios con emails @aventura.example: admin1 y admin2 con rol ADMINISTRADOR y contraseña Admin123!, y 10 con rol LECTOR y contraseña Lector123!, entre ellos lector1 y nuevo. El campo estilo es CLARO u OSCURO, con algunos de cada uno.
```

### Prompt 2: historias

```text
Agregá al JSON la lista "historias" y dos listas más: "ediciones": [{"historia", "admin", "fecha"}] con 3 elementos, y "bajas": [{"titulo", "admin", "creada", "baja"}] con 1 elemento. Formato de cada historia:

{"clave", "titulo", "estado", "admin", "creada", "categorias": [...], "sinopsis",
 "capitulos": [{"clave", "titulo", "texto", "opciones": [{"texto", "destino"}]}, {"clave", "titulo", "texto", "final": true}]}

El primer capítulo de la lista es el inicial. "destino" es la clave de otro capítulo de la misma historia. "admin" es admin1 o admin2. Las fechas tienen formato 2026-07-06T10:00:00, entre julio y principios de noviembre de 2026.

Quiero 13 historias, todas distintas en tema y usando las 10 categorías:
- 11 PUBLICADAS, con 2 a 4 finales cada una. Una de ellas, con 4 finales.
- 1 BORRADOR completa, lista para publicar.
- 1 BORRADOR que tenga solo el capítulo inicial, con "opciones": [].
Los textos de 2 o 3 oraciones, coherentes, y los finales titulados "Final: ...". Devolvé el JSON completo.
```

### Prompt 3: datos de uso

```text
Ahora generá uso.json con este formato: {"lecturas": [["usuario", "clave de historia", "clave del capítulo donde quedó", "fecha de inicio", minutos]]}. Los minutos son el tiempo hasta llegar al final; si la lectura quedó en un capítulo intermedio, van en null.

Quiero entre 30 y 40 lecturas, de agosto a principios de noviembre de 2026, posteriores a la creación de cada historia, que permitan probar las métricas:
- Ranking de historias por lecturas completadas, con cantidades distintas y algún empate.
- La historia de 4 finales con 9 lecturas completadas, repartidas 5, 3 y 1, y un final nunca alcanzado.
- Una historia publicada sin ninguna lectura y otra solo con lecturas sin terminar: ninguna de las dos debe aparecer en el ranking.
- Una historia con dos finales empatados.
- Ranking de usuarios por historias distintas completadas, con algún usuario que repita una misma historia. El usuario "nuevo" no lee nada.
- lector1 con lecturas en varios meses y ninguna en julio, para probar el historial.
Solo los LECTOR leen, y solo historias PUBLICADAS.
```

## Control de los datos

- **Antes de generar el script:** el generador valida largos, emails, contraseñas, roles, que los caminos sean un árbol, que las publicadas cumplan las reglas de publicación, que las lecturas sean de lectores sobre historias publicadas, y el mínimo de 10 filas por tabla.
- **Sobre la base creada:** el script se ejecutó en una base vacía y se comprobó que la aplicación inicia sesión con todos los usuarios, que las métricas coinciden con las calculadas de forma independiente desde los archivos, que se llega a todos los finales de todas las historias publicadas y que el dominio acepta publicar la historia en borrador completa y rechaza la incompleta.

## Filas por tabla

| Tabla | Filas |
|---|---|
| Categorias | 10 |
| Usuarios | 12 |
| Historias | 13 |
| CategoriaHistoria | 17 |
| Capitulos | 63 |
| Opciones | 50 |
| Auditorias | 79 |
| Lecturas | 36 |

## Qué permite probar cada métrica

Con el conjunto actual; si se reemplazan los datos, estos valores cambian. Los valores calculados quedan en `BaseDeDatos/generador/metricas-esperadas.json`.

**RF09 - Historias más leídas**

| Historia | Lecturas completadas |
|---|---|
| El faro que no se apaga | 9 |
| Estación Orión-9 | 5 |
| El taxi bajo el puente de la rambla | 4 |
| La casa de la calle Sauce | 4 |
| Carta en el tren de las siete | 3 |
| Expedición al Cerro del Eco | 2 |
| El gato contador de Barrio Sur | 1 |
| El pliego de la cuchilla | 1 |
| La última llamada de la noche | 1 |

No aparecen *Don Robot se jubila* (nunca leída) ni *El jardín de los relojes* (solo lecturas sin terminar).

**RF10 - Final más alcanzado**

| Caso | Historia | Resultado |
|---|---|---|
| Frecuencias distintas | El faro que no se apaga | 5, 3, 1 y un final en 0 |
| Empate | El taxi bajo el puente de la rambla | 2, 2 y 0: se marcan los dos |
| Sin lecturas completadas | Don Robot se jubila | Todos en 0, sin marca |

**RF11 - Usuarios con más historias leídas**

lector1 7, lector2 4, lector3 4, lector4 4, lector5 3, lector6 3, lector7 3, lector8 1. lector2 completó dos veces *El faro que no se apaga* y cuenta una sola. No aparecen `lector9`, que solo tiene lecturas sin terminar, ni `nuevo`, que no tiene lecturas.

**RF08 - Historial**

`lector1` tiene lecturas en agosto, septiembre, octubre y noviembre de 2026, y ninguna en julio, para ver el mensaje de historial vacío.

## Credenciales de prueba

| Usuario | Contraseña | Rol |
|---|---|---|
| admin1, admin2 | Admin123! | Administrador |
| lector1 a lector9, nuevo | Lector123! | Lector |
