using Microsoft.AspNetCore.Mvc;
using Obligatorio.Lector.Models;
using Obligatorio.Lector.Sesion;
using System.Net;

namespace Obligatorio.Lector.Controllers
{
    [RequiereRol(ClavesSesion.RolAdministrador)]
    public class MetricasController : ClienteApiController
    {
        public MetricasController(IHttpClientFactory httpClientFactory)
            : base(httpClientFactory)
        {
        }

        // RF09 - Ranking de historias más leídas
        [HttpGet]
        public async Task<IActionResult> RankingHistorias()
        {
            return await MostrarRanking<RankingHistoriaViewModel>(
                "api/Metricas/ranking-historias",
                "No se pudo obtener el ranking de historias.");
        }

        // RF11 - Ranking de usuarios con más historias leídas
        [HttpGet]
        public async Task<IActionResult> RankingUsuarios()
        {
            return await MostrarRanking<RankingUsuarioViewModel>(
                "api/Metricas/ranking-usuarios",
                "No se pudo obtener el ranking de usuarios.");
        }

        // RF10 - Elegir una historia y ver cuántas veces se alcanzó cada final
        [HttpGet]
        public async Task<IActionResult> Finales(int? historiaId)
        {
            ViewBag.HistoriaId = historiaId;
            ViewBag.Historias = new List<HistoriaViewModel>();

            HttpClient cliente = CrearCliente();

            try
            {
                var respuestaHistorias = await cliente.GetAsync("api/Historias");

                if (respuestaHistorias.StatusCode == HttpStatusCode.Unauthorized)
                    return SesionVencida();

                if (!respuestaHistorias.IsSuccessStatusCode)
                {
                    ViewBag.Error = await LeerError(
                        respuestaHistorias,
                        "No se pudieron cargar las historias.");

                    return View((FinalesHistoriaViewModel?)null);
                }

                ViewBag.Historias = await respuestaHistorias.Content
                    .ReadFromJsonAsync<List<HistoriaViewModel>>();

                if (!historiaId.HasValue)
                    return View((FinalesHistoriaViewModel?)null);

                var respuesta = await cliente.GetAsync(
                    $"api/Metricas/historias/{historiaId.Value}/finales");

                if (respuesta.StatusCode == HttpStatusCode.Unauthorized)
                    return SesionVencida();

                if (!respuesta.IsSuccessStatusCode)
                {
                    ViewBag.Error = await LeerError(
                        respuesta,
                        "No se pudieron obtener los finales de la historia.");

                    return View((FinalesHistoriaViewModel?)null);
                }

                var finales = await respuesta.Content
                    .ReadFromJsonAsync<FinalesHistoriaViewModel>();

                return View(finales);
            }
            catch (HttpRequestException)
            {
                ViewBag.Error = SinConexion;
                return View((FinalesHistoriaViewModel?)null);
            }
        }

        private async Task<IActionResult> MostrarRanking<T>(
            string url,
            string mensajeError)
        {
            try
            {
                var respuesta = await CrearCliente().GetAsync(url);

                if (respuesta.StatusCode == HttpStatusCode.Unauthorized)
                    return SesionVencida();

                if (!respuesta.IsSuccessStatusCode)
                {
                    ViewBag.Error = await LeerError(respuesta, mensajeError);
                    return View(new List<T>());
                }

                var filas = await respuesta.Content.ReadFromJsonAsync<List<T>>();

                return View(filas ?? new List<T>());
            }
            catch (HttpRequestException)
            {
                ViewBag.Error = SinConexion;
                return View(new List<T>());
            }
        }
    }
}
