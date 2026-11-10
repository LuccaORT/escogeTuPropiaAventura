using Microsoft.AspNetCore.Mvc;
using Obligatorio.Lector.Models;
using Obligatorio.Lector.Sesion;
using System.Net.Http.Headers;
using System.Text.Json;

namespace Obligatorio.Lector.Controllers
{
    // Base de los controladores que consumen la Web API con el token de la sesión.
    public abstract class ClienteApiController : Controller
    {
        protected const string SinConexion = "No se pudo conectar con la API.";

        private readonly IHttpClientFactory _httpClientFactory;

        protected ClienteApiController(IHttpClientFactory httpClientFactory)
        {
            _httpClientFactory = httpClientFactory;
        }

        // RF06 - Cada llamado lleva el token en el encabezado Authorization
        protected HttpClient CrearCliente()
        {
            HttpClient cliente = _httpClientFactory.CreateClient("ApiLectura");

            string? token = HttpContext.Session.GetString(ClavesSesion.Token);

            if (!string.IsNullOrEmpty(token))
            {
                cliente.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", token);
            }

            return cliente;
        }

        // Token vencido o inválido: hay que volver a iniciar sesión
        protected IActionResult SesionVencida()
        {
            HttpContext.Session.Clear();
            return RedirectToAction("Login", "Auth");
        }

        // Usa el mensaje descriptivo de la API si lo mandó
        protected static async Task<string> LeerError(
            HttpResponseMessage respuesta,
            string mensajePorDefecto)
        {
            try
            {
                ErrorApiViewModel? error =
                    await respuesta.Content.ReadFromJsonAsync<ErrorApiViewModel>();

                return string.IsNullOrWhiteSpace(error?.Mensaje)
                    ? mensajePorDefecto
                    : error.Mensaje;
            }
            catch (Exception ex) when (ex is JsonException or NotSupportedException)
            {
                return mensajePorDefecto;
            }
        }
    }
}
