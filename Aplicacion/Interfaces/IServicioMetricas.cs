using Aplicacion.DTOs;

namespace Aplicacion.Interfaces
{
    public interface IServicioMetricas
    {
        IEnumerable<RankingHistoriaDTO> ObtenerRankingHistorias();

        FinalesHistoriaDTO ObtenerFinalesPorHistoria(int historiaId);

        IEnumerable<RankingUsuarioDTO> ObtenerRankingUsuarios();
    }
}
