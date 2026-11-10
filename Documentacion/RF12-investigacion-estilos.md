# RF12 - Investigación sobre estilos visuales

Borrador de la sección del informe. La consigna pide investigar este tema de forma autónoma, con apoyo de IA generativa, y documentarlo.

## Herramienta y método

- **IA utilizada:** Claude (modelo Opus 5.5, de Anthropic), en Claude Code.
- **Qué se le pidió:** comparar formas de ofrecer dos estilos visuales en una aplicación ASP.NET Core MVC con Bootstrap, elegir una y justificarla.
- **Cómo se verificó:** las afirmaciones técnicas se contrastaron con la documentación oficial (ver Fuentes), con el CSS de Bootstrap incluido en el proyecto y con mediciones de contraste sobre la aplicación en ejecución.

## Qué había que resolver

1. Cómo cambiar los colores de toda la aplicación.
2. Dónde guardar la elección para que sea de cada usuario.
3. Cómo asegurar que los dos estilos se lean bien.

## Cómo cambiar los colores

| Alternativa | Ventajas | Desventajas | ¿Se eligió? |
|---|---|---|---|
| Modos de color de Bootstrap 5.3 (`data-bs-theme`) | El proyecto ya usa esa versión. Un solo atributo cambia todos los componentes. | Hay que quitar las clases de color fijo y ajustar algunos contrastes. | Sí |
| `prefers-color-scheme` | No requiere guardar nada. | Sigue la configuración del sistema o del navegador, no una elección hecha en la aplicación. No cumple RF12 por sí sola. | No |
| Dos hojas de estilo | Separación total entre estilos. | Duplica CSS y hay que mantener ambas al día. | No |
| Variables CSS propias | Control total. | Obliga a redefinir lo que Bootstrap ya resuelve. | No |

Bootstrap define sus colores como variables CSS y las redefine bajo `[data-bs-theme=dark]`. El atributo también se puede aplicar a un solo elemento: así se arma la vista previa de cada estilo en la pantalla de selección.

## Dónde guardar la elección

| Alternativa | Comportamiento | ¿Se eligió? |
|---|---|---|
| `localStorage` (lo que propone el ejemplo de la documentación de Bootstrap) | Queda en el navegador, no en el usuario: dos personas en la misma computadora comparten el estilo, y se pierde al cambiar de dispositivo. | No |
| Base de datos, a través de la Web API | Queda asociada al usuario y lo acompaña en cualquier navegador. | Sí |

El MVC guarda una copia del estilo en la sesión, para no llamar a la API en cada página. Como el atributo sale escrito desde el servidor en el HTML, la página no parpadea en el otro estilo mientras carga.

## Contraste

WCAG 2.2, criterio 1.4.3 (nivel AA), exige un contraste de al menos 4.5:1 para texto normal, y 3:1 para texto grande. Activar el modo oscuro de Bootstrap no alcanzó: los botones de contorno quedaron por debajo del mínimo. Se corrigieron en `site.css` con los tonos claros que el propio Bootstrap define para ese modo.

Mediciones sobre las pantallas de lectura en ejecución:

| Elemento | Claro | Oscuro antes del ajuste | Oscuro final |
|---|---|---|---|
| Texto del capítulo | 15.43 | 11.85 | 11.85 |
| Texto secundario (`text-muted`) | 6.78 | 7.29 | 7.29 |
| Enlaces del menú | 6.98 | 7.32 | 7.32 |
| Alerta de éxito | 10.35 | 7.67 | 7.67 |
| Botón principal | 4.50 | 4.50 | 4.50 |
| Botón de contorno primario | 4.50 | **3.43** | 6.39 |
| Botón de contorno secundario | 4.69 | **3.29** | 6.74 |
| Botón de contorno de peligro | 4.53 | **3.41** | 6.10 |

En negrita, los valores que no cumplían. Los 4.50 del botón principal y del contorno primario superan apenas el mínimo (4.5008).

## Implementación

| Capa | Elemento | Responsabilidad |
|---|---|---|
| Dominio | `ValueObjects/EstiloLectura` | Value Object: solo admite `CLARO` u `OSCURO`, y es inmutable. |
| Dominio | `Usuario.CambiarEstilo` | Cambia el estilo del usuario. Todo usuario arranca en `CLARO`. |
| Infraestructura | `AppDbContext` (`OwnsOne`) | Guarda el Value Object como la columna `EstiloLectura` de `Usuarios`, con valor por defecto `CLARO`. |
| Aplicación | `ServicioUsuario` | `ObtenerEstilo` y `CambiarEstilo`. |
| Web API | `UsuariosController` | `GET` y `PUT /api/Usuarios/estilo`, solo para lectores. El usuario sale del token. |
| Web API | `AuthController` | El login devuelve el estilo guardado. |
| MVC | `PreferenciasController`, `Preferencias/Estilo` | Pantalla de selección. |
| MVC | `_Layout.cshtml` | Escribe `data-bs-theme` en `<html>` según la sesión. |

Para `EstiloLectura` se usó un tipo owned, igual que el Value Object visto en clase. La documentación actual de EF Core sugiere considerar los complex types para Value Objects. Con owned, una misma instancia no se puede compartir entre usuarios, por eso cada usuario tiene la suya.

## Decisiones y limitaciones

- El estilo es para el rol Usuario, como pide RF12. Los administradores ven siempre el estilo claro en el MVC de lectura.
- Antes de iniciar sesión se ve el estilo claro, porque todavía no se sabe quién es el usuario.
- Si el usuario cambia el estilo desde otro navegador, la sesión abierta lo toma al volver a iniciar sesión o al entrar a la pantalla de estilo.
- El proyecto usa Bootstrap 5.3.3. La documentación de Bootstrap 6.0 cambia el comportamiento por defecto y sigue la preferencia del sistema, así que una actualización de versión requeriría revisar esto.

## Fuentes

- [Color modes - Bootstrap 5.3](https://getbootstrap.com/docs/5.3/customize/color-modes/)
- [Color modes - Bootstrap 6.0](https://getbootstrap.com/docs/6.0/customize/color-modes/)
- [Understanding SC 1.4.3: Contrast (Minimum) - W3C, WCAG 2.2](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
- [prefers-color-scheme - MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-color-scheme)
- [Owned Entity Types - EF Core](https://learn.microsoft.com/en-us/ef/core/modeling/owned-entities)
- [Complex Types - EF Core](https://learn.microsoft.com/en-us/ef/core/modeling/complex-types)
