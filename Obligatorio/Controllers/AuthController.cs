using Aplicacion.DTOs;
using Aplicacion.Interfaces;
using Dominio.Excepciones;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Obligatorio.Controllers
{
    public class AuthController : Controller
    {
        private readonly IServicioUsuario _servicioUsuario;

        public AuthController(IServicioUsuario servicioUsuario)
        {
            _servicioUsuario = servicioUsuario;
        }

        [HttpGet]
        public IActionResult Login()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(
            string nombreUsuario,
            string contrasena)
        {
            try
            {
                UsuarioDTO usuario =
                    _servicioUsuario.LoginAdministrador(
                        nombreUsuario,
                        contrasena);

                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.NameIdentifier, usuario.Id.ToString()),
                    new Claim(ClaimTypes.Name, usuario.NombreUsuario),
                    new Claim(ClaimTypes.Role, usuario.Rol)
                };

                var identidad = new ClaimsIdentity(
                    claims,
                    CookieAuthenticationDefaults.AuthenticationScheme);

                await HttpContext.SignInAsync(
                    CookieAuthenticationDefaults.AuthenticationScheme,
                    new ClaimsPrincipal(identidad));

                return RedirectToAction("Index", "Home");
            }
            catch (DominioException ex)
            {
                ViewBag.Error = ex.Message;
                return View();
            }
        }

        [Authorize]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Logout()
        {
            await HttpContext.SignOutAsync(
                CookieAuthenticationDefaults.AuthenticationScheme);

            return RedirectToAction("Login", "Auth");
        }

        public IActionResult AccesoDenegado()
        {
            return View();
        }
    }
}
