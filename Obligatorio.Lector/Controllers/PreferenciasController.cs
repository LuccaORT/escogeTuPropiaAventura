using Microsoft.AspNetCore.Mvc;
using Obligatorio.Lector.Models;
using Obligatorio.Lector.Sesion;
using System.Net;

namespace Obligatorio.Lector.Controllers
{
    [RequiereRol(ClavesSesion.RolLector)]
    public class PreferenciasController : ClienteApiController
    {
        public PreferenciasController(IHttpClientFactory httpClientFactory)
            : base(httpClientFactory)
        {
        }

        // RF12 - Muestra el estilo guardado y los disponibles
        [HttpGet]
        public async Task<IActionResult> Estilo()
        {
            string estiloActual = HttpContext.Session.GetString(ClavesSesion.Estilo)
                ?? ClavesSesion.EstiloClaro;

            try
            {
                var respuesta = await CrearCliente().GetAsync("api/Usuarios/estilo");

                if (respuesta.StatusCode == HttpStatusCode.Unauthorized)
                    return SesionVencida();

                if (!respuesta.IsSuccessStatusCode)
                {
                    ViewBag.Error = await LeerError(
                        respuesta,
                        "No se pudo obtener el estilo de lectura.");

                    return View(new EstiloLecturaViewModel { Estilo = estiloActual });
                }

                var estilo = await respuesta.Content
                    .ReadFromJsonAsync<EstiloLecturaViewModel>();

                if (estilo == null)
                {
                    ViewBag.Error = "Respuesta inválida de la API.";
                    return View(new EstiloLecturaViewModel { Estilo = estiloActual });
                }

                // Por si se cambió desde otra sesión del mismo usuario.
                HttpContext.Session.SetString(ClavesSesion.Estilo, estilo.Estilo);

                return View(estilo);
            }
            catch (HttpRequestException)
            {
                ViewBag.Error = SinConexion;
                return View(new EstiloLecturaViewModel { Estilo = estiloActual });
            }
        }

        // RF12 - Guarda el estilo en la API y lo aplica a la sesión
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Estilo(string estilo)
        {
            try
            {
                var respuesta = await CrearCliente().PutAsJsonAsync(
                    "api/Usuarios/estilo",
                    new { Estilo = estilo ?? string.Empty });

                if (respuesta.StatusCode == HttpStatusCode.Unauthorized)
                    return SesionVencida();

                if (!respuesta.IsSuccessStatusCode)
                {
                    TempData["Error"] = await LeerError(
                        respuesta,
                        "No se pudo guardar el estilo de lectura.");

                    return RedirectToAction("Estilo");
                }

                var guardado = await respuesta.Content
                    .ReadFromJsonAsync<EstiloLecturaViewModel>();

                if (guardado == null)
                {
                    TempData["Error"] = "Respuesta inválida de la API.";
                    return RedirectToAction("Estilo");
                }

                HttpContext.Session.SetString(ClavesSesion.Estilo, guardado.Estilo);

                TempData["Mensaje"] = "Estilo de lectura guardado.";
            }
            catch (HttpRequestException)
            {
                TempData["Error"] = SinConexion;
            }

            return RedirectToAction("Estilo");
        }
    }
}
