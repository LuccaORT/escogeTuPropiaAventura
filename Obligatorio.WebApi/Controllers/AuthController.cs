using Aplicacion.DTOs;
using Aplicacion.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Obligatorio.WebApi.Servicios;

namespace Obligatorio.WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IServicioUsuario _servicioUsuario;
        private readonly IServicioToken _servicioToken;

        public AuthController(
            IServicioUsuario servicioUsuario,
            IServicioToken servicioToken)
        {
            _servicioUsuario = servicioUsuario;
            _servicioToken = servicioToken;
        }

        /// <summary>RF06 - Inicia sesión y devuelve el token JWT.</summary>
        [AllowAnonymous]
        [HttpPost("login")]
        [ProducesResponseType<LoginRespuestaDTO>(StatusCodes.Status200OK)]
        [ProducesResponseType<ErrorDTO>(StatusCodes.Status400BadRequest)]
        [ProducesResponseType<ErrorDTO>(StatusCodes.Status401Unauthorized)]
        public ActionResult<LoginRespuestaDTO> Login([FromBody] LoginDTO datos)
        {
            UsuarioDTO usuario = _servicioUsuario.Login(
                datos.NombreUsuario,
                datos.Contrasena);

            return Ok(new LoginRespuestaDTO
            {
                Token = _servicioToken.Generar(usuario),
                NombreUsuario = usuario.NombreUsuario,
                Rol = usuario.Rol,
                EstiloLectura = usuario.EstiloLectura
            });
        }
    }
}
