using Aplicacion.DTOs;
using Aplicacion.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Obligatorio.WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "ADMINISTRADOR")]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public class MetricasController : ControllerBase
    {
        private readonly IServicioMetricas _servicioMetricas;

        public MetricasController(IServicioMetricas servicioMetricas)
        {
            _servicioMetricas = servicioMetricas;
        }

        /// <summary>RF09 - Historias por lecturas completadas, de mayor a menor.</summary>
        /// <remarks>Las historias sin lecturas completadas no aparecen.</remarks>
        [HttpGet("ranking-historias")]
        [ProducesResponseType<IEnumerable<RankingHistoriaDTO>>(StatusCodes.Status200OK)]
        public ActionResult<IEnumerable<RankingHistoriaDTO>> RankingHistorias()
        {
            return Ok(_servicioMetricas.ObtenerRankingHistorias());
        }

        /// <summary>RF10 - Veces que se alcanzó cada final de una historia.</summary>
        /// <remarks>Si hay empate, todos los finales empatados se marcan como más frecuentes.</remarks>
        [HttpGet("historias/{historiaId:int}/finales")]
        [ProducesResponseType<FinalesHistoriaDTO>(StatusCodes.Status200OK)]
        [ProducesResponseType<ErrorDTO>(StatusCodes.Status404NotFound)]
        public ActionResult<FinalesHistoriaDTO> FinalesPorHistoria(int historiaId)
        {
            return Ok(_servicioMetricas.ObtenerFinalesPorHistoria(historiaId));
        }

        /// <summary>RF11 - Usuarios por historias distintas completadas, de mayor a menor.</summary>
        /// <remarks>Completar varias veces la misma historia cuenta una sola vez.</remarks>
        [HttpGet("ranking-usuarios")]
        [ProducesResponseType<IEnumerable<RankingUsuarioDTO>>(StatusCodes.Status200OK)]
        public ActionResult<IEnumerable<RankingUsuarioDTO>> RankingUsuarios()
        {
            return Ok(_servicioMetricas.ObtenerRankingUsuarios());
        }
    }
}
