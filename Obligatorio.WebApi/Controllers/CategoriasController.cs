using Aplicacion.DTOs;
using Aplicacion.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Obligatorio.WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class CategoriasController : ControllerBase
    {
        private readonly IServicioHistoria _servicioHistoria;

        public CategoriasController(IServicioHistoria servicioHistoria)
        {
            _servicioHistoria = servicioHistoria;
        }

        /// <summary>RF07 - Categorías para filtrar el listado de historias.</summary>
        [HttpGet]
        [ProducesResponseType<IEnumerable<CategoriaDTO>>(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public ActionResult<IEnumerable<CategoriaDTO>> Listar()
        {
            return Ok(_servicioHistoria.ObtenerCategorias());
        }
    }
}
