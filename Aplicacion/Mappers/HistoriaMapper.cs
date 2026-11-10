using Aplicacion.DTOs;
using Dominio.Entidades;
using Dominio.Enums;

namespace Aplicacion.Mappers
{
    public static class HistoriaMapper
    {
        public static HistoriaResumenDTO ToResumenDTO(Historia historia)
        {
            HistoriaResumenDTO dto = new HistoriaResumenDTO();
            CopiarDatosComunes(historia, dto);
            return dto;
        }

        public static HistoriaDetalleDTO ToDetalleDTO(Historia historia)
        {
            HistoriaDetalleDTO dto = new HistoriaDetalleDTO
            {
                CapituloInicial = historia.CapituloInicial == null
                    ? null
                    : CapituloMapper.ToDTOConDestinos(historia.CapituloInicial),

                Capitulos = historia.Capitulos
                    .OrderBy(c => c.Id)
                    .Select(CapituloMapper.ToDTOConDestinos)
                    .ToList()
            };

            CopiarDatosComunes(historia, dto);
            return dto;
        }

        private static void CopiarDatosComunes(Historia historia, HistoriaResumenDTO dto)
        {
            dto.Id = historia.Id;
            dto.Titulo = historia.Titulo;
            dto.Sinopsis = historia.Sinopsis;
            dto.Estado = historia.Estado.ToString();
            dto.EstaPublicada = historia.Estado == EstadoHistoria.PUBLICADA;
            dto.Categorias = historia.Categorias
                .Select(CategoriaMapper.ToDTO)
                .ToList();
        }
    }
}
