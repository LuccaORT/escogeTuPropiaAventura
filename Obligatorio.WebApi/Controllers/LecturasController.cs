using Aplicacion.DTOs;
using Aplicacion.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Obligatorio.WebApi.Extensiones;

namespace Obligatorio.WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "LECTOR")]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public class LecturasController : ControllerBase
    {
        private readonly IServicioLectura _servicioLectura;

        public LecturasController(IServicioLectura servicioLectura)
        {
            _servicioLectura = servicioLectura;
        }

        /// <summary>RF07 - Inicia una nueva lectura desde el capítulo inicial.</summary>
        [HttpPost]
        [ProducesResponseType<LecturaDetalleDTO>(StatusCodes.Status201Created)]
        [ProducesResponseType<ErrorDTO>(StatusCodes.Status400BadRequest)]
        [ProducesResponseType<ErrorDTO>(StatusCodes.Status404NotFound)]
        public ActionResult<LecturaDetalleDTO> Iniciar([FromBody] IniciarLecturaDTO datos)
        {
            LecturaDetalleDTO lectura =
                _servicioLectura.Iniciar(User.ObtenerUsuarioId(), datos.HistoriaId);

            return CreatedAtAction(nameof(Obtener), new { id = lectura.Id }, lectura);
        }

        /// <summary>RF07 - Devuelve la lectura con su capítulo actual y sus opciones.</summary>
        [HttpGet("{id:int}")]
        [ProducesResponseType<LecturaDetalleDTO>(StatusCodes.Status200OK)]
        [ProducesResponseType<ErrorDTO>(StatusCodes.Status404NotFound)]
        public ActionResult<LecturaDetalleDTO> Obtener(int id)
        {
            return Ok(_servicioLectura.Obtener(id, User.ObtenerUsuarioId()));
        }

        /// <summary>RF07 - Elige una opción. Al llegar a un final la lectura termina.</summary>
        [HttpPost("{id:int}/avance")]
        [ProducesResponseType<LecturaDetalleDTO>(StatusCodes.Status200OK)]
        [ProducesResponseType<ErrorDTO>(StatusCodes.Status400BadRequest)]
        [ProducesResponseType<ErrorDTO>(StatusCodes.Status404NotFound)]
        public ActionResult<LecturaDetalleDTO> Avanzar(int id, [FromBody] AvanzarLecturaDTO datos)
        {
            return Ok(_servicioLectura.Avanzar(id, User.ObtenerUsuarioId(), datos.OpcionId));
        }

        /// <summary>RF08 - Lecturas del usuario logueado en un mes y año.</summary>
        /// <remarks>Sin resultados devuelve 200 con una lista vacía.</remarks>
        [HttpGet]
        [ProducesResponseType<IEnumerable<LecturaDTO>>(StatusCodes.Status200OK)]
        [ProducesResponseType<ErrorDTO>(StatusCodes.Status400BadRequest)]
        public ActionResult<IEnumerable<LecturaDTO>> Historial(
            [FromQuery] int mes,
            [FromQuery] int anio)
        {
            return Ok(_servicioLectura.ObtenerHistorial(User.ObtenerUsuarioId(), mes, anio));
        }
    }
}
