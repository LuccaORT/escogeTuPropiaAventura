using Aplicacion.DTOs;
using Dominio.Entidades;

namespace Aplicacion.Mappers
{
    public static class LecturaMapper
    {
        public static LecturaDTO ToDTO(Lectura lectura)
        {
            LecturaDTO dto = new LecturaDTO();
            CopiarDatosComunes(lectura, dto);
            return dto;
        }

        public static LecturaDetalleDTO ToDetalleDTO(Lectura lectura)
        {
            LecturaDetalleDTO dto = new LecturaDetalleDTO
            {
                CapituloActual = CapituloMapper.ToDTO(lectura.CapituloActual)
            };

            CopiarDatosComunes(lectura, dto);
            return dto;
        }

        private static void CopiarDatosComunes(Lectura lectura, LecturaDTO dto)
        {
            dto.Id = lectura.Id;
            dto.FechaInicio = lectura.FechaInicio;
            dto.FechaFinalizacion = lectura.FechaFinalizacion;
            dto.Completada = lectura.Completada;
            dto.HistoriaId = lectura.Historia.Id;
            dto.HistoriaTitulo = lectura.Historia.Titulo;
            dto.FinalAlcanzadoId = lectura.FinalAlcanzado?.Id;
            dto.FinalAlcanzadoTitulo = lectura.FinalAlcanzado?.Titulo;
        }
    }
}
