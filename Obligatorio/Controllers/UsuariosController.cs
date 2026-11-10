using Aplicacion.DTOs;
using Aplicacion.Interfaces;
using Dominio.Excepciones;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Obligatorio.Controllers
{
    [Authorize(Roles = "ADMINISTRADOR")]
    public class UsuariosController : Controller
    {
        private readonly IServicioUsuario _servicioUsuario;

        public UsuariosController(IServicioUsuario servicioUsuario)
        {
            _servicioUsuario = servicioUsuario;
        }

        [HttpGet]
        public IActionResult Create()
        {
            return View(new UsuarioAltaDTO());
        }

        // RF02 - Alta de usuarios
        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Create(UsuarioAltaDTO datos)
        {
            try
            {
                _servicioUsuario.Alta(datos);

                TempData["Mensaje"] = "Usuario creado correctamente.";

                return RedirectToAction("Create");
            }
            catch (DominioException ex)
            {
                ViewBag.Error = ex.Message;
                return View(datos);
            }
        }
    }
}
