using Aplicacion.DTOs;
using Dominio.Consultas;

namespace Aplicacion.Mappers
{
    public static class MetricaMapper
    {
        public static RankingHistoriaDTO ToDTO(LecturasPorHistoria fila)
        {
            return new RankingHistoriaDTO
            {
                HistoriaId = fila.HistoriaId,
                Titulo = fila.Titulo,
                LecturasCompletadas = fila.LecturasCompletadas
            };
        }

        public static RankingUsuarioDTO ToDTO(HistoriasPorUsuario fila)
        {
            return new RankingUsuarioDTO
            {
                UsuarioId = fila.UsuarioId,
                NombreUsuario = fila.NombreUsuario,
                NombreCompleto = fila.NombreCompleto,
                HistoriasCompletadas = fila.HistoriasCompletadas
            };
        }

        public static FinalAlcanzadoDTO ToDTO(LecturasPorFinal fila, int maximo)
        {
            return new FinalAlcanzadoDTO
            {
                CapituloId = fila.CapituloId,
                Titulo = fila.Titulo,
                VecesAlcanzado = fila.VecesAlcanzado,
                EsMasFrecuente = maximo > 0 && fila.VecesAlcanzado == maximo
            };
        }
    }
}
