using Microsoft.AspNetCore.Mvc;
using Obligatorio.Lector.Models;
using Obligatorio.Lector.Sesion;

namespace Obligatorio.Lector.Controllers
{
    public class AuthController : ClienteApiController
    {
        public AuthController(IHttpClientFactory httpClientFactory)
            : base(httpClientFactory)
        {
        }

        [HttpGet]
        public IActionResult Login()
        {
            return View();
        }

        // RF06 - Pueden ingresar administradores y lectores
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(
            string nombreUsuario,
            string contrasena)
        {
            try
            {
                var respuesta = await CrearCliente().PostAsJsonAsync(
                    "api/Auth/login",
                    new
                    {
                        NombreUsuario = nombreUsuario ?? string.Empty,
                        Contrasena = contrasena ?? string.Empty
                    });

                if (!respuesta.IsSuccessStatusCode)
                {
                    ViewBag.Error = await LeerError(
                        respuesta,
                        "No se pudo iniciar sesión.");

                    return View();
                }

                var login = await respuesta.Content
                    .ReadFromJsonAsync<LoginRespuestaViewModel>();

                if (login == null)
                {
                    ViewBag.Error = "Respuesta inválida de la API.";
                    return View();
                }

                HttpContext.Session.SetString(ClavesSesion.Token, login.Token);
                HttpContext.Session.SetString(ClavesSesion.NombreUsuario, login.NombreUsuario);
                HttpContext.Session.SetString(ClavesSesion.Rol, login.Rol);
                HttpContext.Session.SetString(ClavesSesion.Estilo, login.EstiloLectura);

                return RedirectToAction("Index", "Home");
            }
            catch (HttpRequestException)
            {
                ViewBag.Error = SinConexion;
                return View();
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Logout()
        {
            HttpContext.Session.Clear();

            return RedirectToAction("Login");
        }
    }
}
