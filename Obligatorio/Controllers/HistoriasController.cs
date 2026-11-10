using Aplicacion.DTOs;
using Aplicacion.Interfaces;
using Dominio.Excepciones;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Obligatorio.Controllers
{
    [Authorize(Roles = "ADMINISTRADOR")]
    public class HistoriasController : Controller
    {
        private readonly IServicioHistoria _servicioHistoria;

        public HistoriasController(IServicioHistoria servicioHistoria)
        {
            _servicioHistoria = servicioHistoria;
        }

        private int ObtenerAdministradorId()
        {
            string? id = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (!int.TryParse(id, out int administradorId))
            {
                throw new AuditoriaException(
                    "No se pudo identificar al administrador.");
            }

            return administradorId;
        }

        // RF03 - Listar historias
        [HttpGet]
        public IActionResult Index()
        {
            return View(_servicioHistoria.ObtenerTodas());
        }

        // RF03 - Formulario de creación
        [HttpGet]
        public IActionResult Create()
        {
            ViewBag.Categorias = _servicioHistoria.ObtenerCategorias();

            return View(new HistoriaAltaDTO());
        }

        // RF03 - Crear historia
        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Create(HistoriaAltaDTO datos)
        {
            try
            {
                _servicioHistoria.Crear(datos, ObtenerAdministradorId());

                TempData["Mensaje"] = "Historia creada correctamente.";

                return RedirectToAction("Index");
            }
            catch (DominioException ex)
            {
                ViewBag.Error = ex.Message;
                ViewBag.Categorias = _servicioHistoria.ObtenerCategorias();

                return View(datos);
            }
        }

        // RF03 - Formulario de edición
        [HttpGet]
        public IActionResult Edit(int id)
        {
            try
            {
                ViewBag.Categorias = _servicioHistoria.ObtenerCategorias();

                return View(_servicioHistoria.ObtenerPorId(id));
            }
            catch (DominioException ex)
            {
                TempData["Error"] = ex.Message;
                return RedirectToAction("Index");
            }
        }

        // RF03 - Editar historia
        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Edit(HistoriaEdicionDTO datos)
        {
            try
            {
                _servicioHistoria.Editar(datos, ObtenerAdministradorId());

                TempData["Mensaje"] = "Historia modificada correctamente.";

                return RedirectToAction("Index");
            }
            catch (EntidadNoEncontradaException ex)
            {
                TempData["Error"] = ex.Message;
                return RedirectToAction("Index");
            }
            catch (DominioException ex)
            {
                ViewBag.Error = ex.Message;
                ViewBag.Categorias = _servicioHistoria.ObtenerCategorias();

                return View(_servicioHistoria.ObtenerPorId(datos.Id));
            }
        }

        // RF03 - Confirmar eliminación
        [HttpGet]
        public IActionResult Delete(int id)
        {
            try
            {
                return View(_servicioHistoria.ObtenerPorId(id));
            }
            catch (DominioException ex)
            {
                TempData["Error"] = ex.Message;
                return RedirectToAction("Index");
            }
        }

        // RF03 - Eliminar historia
        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult DeleteConfirmed(int id)
        {
            try
            {
                _servicioHistoria.Eliminar(id, ObtenerAdministradorId());

                TempData["Mensaje"] = "Historia eliminada correctamente.";
            }
            catch (DominioException ex)
            {
                TempData["Error"] = ex.Message;
            }

            return RedirectToAction("Index");
        }

        // RF04 - Formulario para agregar capítulos
        [HttpGet]
        public IActionResult AgregarCapitulo(int id)
        {
            try
            {
                HistoriaDetalleDTO historia = _servicioHistoria.ObtenerPorId(id);

                if (historia.EstaPublicada)
                {
                    TempData["Error"] =
                        "No se pueden agregar capítulos a una historia publicada.";

                    return RedirectToAction("Index");
                }

                ViewBag.Historia = historia;

                return View(new CapituloAltaDTO { HistoriaId = id });
            }
            catch (DominioException ex)
            {
                TempData["Error"] = ex.Message;
                return RedirectToAction("Index");
            }
        }

        // RF04 - Agregar capítulo
        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult AgregarCapitulo(CapituloAltaDTO datos)
        {
            try
            {
                _servicioHistoria.AgregarCapitulo(datos, ObtenerAdministradorId());

                TempData["Mensaje"] = "Capítulo agregado correctamente.";

                return RedirectToAction("Edit", new { id = datos.HistoriaId });
            }
            catch (EntidadNoEncontradaException ex)
            {
                TempData["Error"] = ex.Message;
                return RedirectToAction("Index");
            }
            catch (DominioException ex)
            {
                ViewBag.Error = ex.Message;
                ViewBag.Historia = _servicioHistoria.ObtenerPorId(datos.HistoriaId);

                return View(datos);
            }
        }
    }
}
