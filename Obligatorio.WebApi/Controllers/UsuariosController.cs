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
    public class UsuariosController : ControllerBase
    {
        private readonly IServicioUsuario _servicioUsuario;

        public UsuariosController(IServicioUsuario servicioUsuario)
        {
            _servicioUsuario = servicioUsuario;
        }

        /// <summary>RF12 - Estilo de lectura del usuario que inició sesión.</summary>
        [HttpGet("estilo")]
        [ProducesResponseType<EstiloLecturaDTO>(StatusCodes.Status200OK)]
        [ProducesResponseType<ErrorDTO>(StatusCodes.Status404NotFound)]
        public ActionResult<EstiloLecturaDTO> ObtenerEstilo()
        {
            return Ok(_servicioUsuario.ObtenerEstilo(User.ObtenerUsuarioId()));
        }

        /// <summary>RF12 - Cambia el estilo de lectura: CLARO u OSCURO.</summary>
        [HttpPut("estilo")]
        [ProducesResponseType<EstiloLecturaDTO>(StatusCodes.Status200OK)]
        [ProducesResponseType<ErrorDTO>(StatusCodes.Status400BadRequest)]
        [ProducesResponseType<ErrorDTO>(StatusCodes.Status404NotFound)]
        public ActionResult<EstiloLecturaDTO> CambiarEstilo([FromBody] EstiloLecturaDTO datos)
        {
            return Ok(_servicioUsuario.CambiarEstilo(
                User.ObtenerUsuarioId(),
                datos.Estilo));
        }
    }
}
