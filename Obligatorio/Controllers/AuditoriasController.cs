using Aplicacion.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Obligatorio.Controllers
{
    [Authorize(Roles = "ADMINISTRADOR")]
    public class AuditoriasController : Controller
    {
        private readonly IServicioAuditoria _servicioAuditoria;
        private readonly IServicioHistoria _servicioHistoria;
        private readonly IServicioUsuario _servicioUsuario;

        public AuditoriasController(
            IServicioAuditoria servicioAuditoria,
            IServicioHistoria servicioHistoria,
            IServicioUsuario servicioUsuario)
        {
            _servicioAuditoria = servicioAuditoria;
            _servicioHistoria = servicioHistoria;
            _servicioUsuario = servicioUsuario;
        }

        // RF05 - Consulta filtrando por historia o por administrador
        [HttpGet]
        public IActionResult Index(int? historiaId, int? administradorId)
        {
            ViewBag.Historias = _servicioHistoria.ObtenerTodas();
            ViewBag.Administradores = _servicioUsuario.ObtenerAdministradores();
            ViewBag.HistoriaId = historiaId;
            ViewBag.AdministradorId = administradorId;

            return View(_servicioAuditoria.Buscar(historiaId, administradorId));
        }
    }
}
