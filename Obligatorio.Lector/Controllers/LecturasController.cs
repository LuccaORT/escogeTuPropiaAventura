using Microsoft.AspNetCore.Mvc;
using Obligatorio.Lector.Models;
using Obligatorio.Lector.Sesion;
using System.Net;

namespace Obligatorio.Lector.Controllers
{
    [RequiereRol(ClavesSesion.RolLector)]
    public class LecturasController : ClienteApiController
    {
        public LecturasController(IHttpClientFactory httpClientFactory)
            : base(httpClientFactory)
        {
        }

        // RF07 - Listar historias publicadas, filtrables por categoría
        [HttpGet]
        public async Task<IActionResult> Historias(int? categoriaId)
        {
            ViewBag.CategoriaId = categoriaId;
            ViewBag.Categorias = new List<CategoriaViewModel>();

            HttpClient cliente = CrearCliente();

            string url = categoriaId.HasValue
                ? $"api/Historias?categoriaId={categoriaId.Value}"
                : "api/Historias";

            try
            {
                var respuestaCategorias = await cliente.GetAsync("api/Categorias");

                if (respuestaCategorias.StatusCode == HttpStatusCode.Unauthorized)
                    return SesionVencida();

                if (respuestaCategorias.IsSuccessStatusCode)
                {
                    ViewBag.Categorias = await respuestaCategorias.Content
                        .ReadFromJsonAsync<List<CategoriaViewModel>>();
                }

                var respuesta = await cliente.GetAsync(url);

                if (respuesta.StatusCode == HttpStatusCode.Unauthorized)
                    return SesionVencida();

                if (!respuesta.IsSuccessStatusCode)
                {
                    ViewBag.Error = await LeerError(
                        respuesta,
                        "No se pudieron cargar las historias.");

                    return View(new List<HistoriaViewModel>());
                }

                var historias = await respuesta.Content
                    .ReadFromJsonAsync<List<HistoriaViewModel>>();

                return View(historias ?? new List<HistoriaViewModel>());
            }
            catch (HttpRequestException)
            {
                ViewBag.Error = SinConexion;
                return View(new List<HistoriaViewModel>());
            }
        }

        // RF07 - Iniciar una nueva lectura
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Iniciar(int historiaId)
        {
            try
            {
                var respuesta = await CrearCliente().PostAsJsonAsync(
                    "api/Lecturas",
                    new { HistoriaId = historiaId });

                if (respuesta.StatusCode == HttpStatusCode.Unauthorized)
                    return SesionVencida();

                if (!respuesta.IsSuccessStatusCode)
                {
                    TempData["Error"] = await LeerError(
                        respuesta,
                        "No se pudo iniciar la lectura.");

                    return RedirectToAction("Historias");
                }

                var lectura = await respuesta.Content
                    .ReadFromJsonAsync<LecturaDetalleViewModel>();

                if (lectura == null)
                {
                    TempData["Error"] = "Respuesta inválida de la API.";
                    return RedirectToAction("Historias");
                }

                return RedirectToAction("Leer", new { id = lectura.Id });
            }
            catch (HttpRequestException)
            {
                TempData["Error"] = SinConexion;
                return RedirectToAction("Historias");
            }
        }

        // RF07 - Mostrar el capítulo actual
        [HttpGet]
        public async Task<IActionResult> Leer(int id)
        {
            try
            {
                var respuesta = await CrearCliente().GetAsync($"api/Lecturas/{id}");

                if (respuesta.StatusCode == HttpStatusCode.Unauthorized)
                    return SesionVencida();

                if (!respuesta.IsSuccessStatusCode)
                {
                    TempData["Error"] = await LeerError(
                        respuesta,
                        "No se pudo obtener la lectura.");

                    return RedirectToAction("Historias");
                }

                var lectura = await respuesta.Content
                    .ReadFromJsonAsync<LecturaDetalleViewModel>();

                if (lectura == null)
                {
                    TempData["Error"] = "Respuesta inválida de la API.";
                    return RedirectToAction("Historias");
                }

                return View(lectura);
            }
            catch (HttpRequestException)
            {
                TempData["Error"] = SinConexion;
                return RedirectToAction("Historias");
            }
        }

        // RF07 - Elegir una opción y avanzar
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Avanzar(int lecturaId, int opcionId)
        {
            try
            {
                var respuesta = await CrearCliente().PostAsJsonAsync(
                    $"api/Lecturas/{lecturaId}/avance",
                    new { OpcionId = opcionId });

                if (respuesta.StatusCode == HttpStatusCode.Unauthorized)
                    return SesionVencida();

                if (!respuesta.IsSuccessStatusCode)
                {
                    TempData["Error"] = await LeerError(
                        respuesta,
                        "No se pudo avanzar al siguiente capítulo.");
                }
            }
            catch (HttpRequestException)
            {
                TempData["Error"] = SinConexion;
            }

            return RedirectToAction("Leer", new { id = lecturaId });
        }

        // RF08 - Historial de lecturas por mes y año
        [HttpGet]
        public async Task<IActionResult> Historial(int? mes, int? anio)
        {
            int mesSeleccionado = mes ?? DateTime.Now.Month;
            int anioSeleccionado = anio ?? DateTime.Now.Year;

            ViewBag.Mes = mesSeleccionado;
            ViewBag.Anio = anioSeleccionado;

            try
            {
                var respuesta = await CrearCliente().GetAsync(
                    $"api/Lecturas?mes={mesSeleccionado}&anio={anioSeleccionado}");

                if (respuesta.StatusCode == HttpStatusCode.Unauthorized)
                    return SesionVencida();

                if (!respuesta.IsSuccessStatusCode)
                {
                    ViewBag.Error = await LeerError(
                        respuesta,
                        "No se pudo obtener el historial.");

                    return View(new List<LecturaViewModel>());
                }

                var lecturas = await respuesta.Content
                    .ReadFromJsonAsync<List<LecturaViewModel>>();

                return View(lecturas ?? new List<LecturaViewModel>());
            }
            catch (HttpRequestException)
            {
                ViewBag.Error = SinConexion;
                return View(new List<LecturaViewModel>());
            }
        }
    }
}
