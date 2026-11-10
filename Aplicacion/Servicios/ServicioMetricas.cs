using Aplicacion.DTOs;
using Aplicacion.Interfaces;
using Aplicacion.Mappers;
using Dominio.Consultas;
using Dominio.Entidades;
using Dominio.Excepciones;
using Dominio.InterfacesDeRepositorio;

namespace Aplicacion.Servicios
{
    public class ServicioMetricas : IServicioMetricas
    {
        private readonly IRepositorioLectura _repositorioLectura;
        private readonly IRepositorioHistoria _repositorioHistoria;

        public ServicioMetricas(
            IRepositorioLectura repositorioLectura,
            IRepositorioHistoria repositorioHistoria)
        {
            _repositorioLectura = repositorioLectura;
            _repositorioHistoria = repositorioHistoria;
        }

        // RF09 - Ranking de historias más leídas
        public IEnumerable<RankingHistoriaDTO> ObtenerRankingHistorias()
        {
            return _repositorioLectura.RankingHistorias()
                .Select(MetricaMapper.ToDTO)
                .ToList();
        }

        // RF10 - Si hay empate, todos los finales empatados son los más
        // frecuentes. Si nadie llegó a un final, no se marca ninguno.
        public FinalesHistoriaDTO ObtenerFinalesPorHistoria(int historiaId)
        {
            Historia historia = _repositorioHistoria.FindById(historiaId)
                ?? throw new EntidadNoEncontradaException("La historia no existe.");

            List<LecturasPorFinal> finales =
                _repositorioLectura.FinalesPorHistoria(historiaId).ToList();

            int maximo = finales.Count > 0
                ? finales.Max(f => f.VecesAlcanzado)
                : 0;

            return new FinalesHistoriaDTO
            {
                HistoriaId = historia.Id,
                HistoriaTitulo = historia.Titulo,
                Finales = finales
                    .Select(f => MetricaMapper.ToDTO(f, maximo))
                    .ToList()
            };
        }

        // RF11 - Ranking de usuarios por historias distintas completadas
        public IEnumerable<RankingUsuarioDTO> ObtenerRankingUsuarios()
        {
            return _repositorioLectura.RankingUsuarios()
                .Select(MetricaMapper.ToDTO)
                .ToList();
        }
    }
}
