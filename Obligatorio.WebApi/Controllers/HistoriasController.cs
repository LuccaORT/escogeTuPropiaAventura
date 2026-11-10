using Aplicacion.DTOs;
using Aplicacion.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Obligatorio.WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class HistoriasController : ControllerBase
    {
        private readonly IServicioLectura _servicioLectura;

        public HistoriasController(IServicioLectura servicioLectura)
        {
            _servicioLectura = servicioLectura;
        }

        /// <summary>RF07 - Historias publicadas, opcionalmente de una categoría.</summary>
        /// <remarks>Sin resultados devuelve 200 con una lista vacía.</remarks>
        [HttpGet]
        [ProducesResponseType<IEnumerable<HistoriaResumenDTO>>(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public ActionResult<IEnumerable<HistoriaResumenDTO>> Listar([FromQuery] int? categoriaId)
        {
            return Ok(_servicioLectura.ObtenerHistoriasPublicadas(categoriaId));
        }
    }
}
