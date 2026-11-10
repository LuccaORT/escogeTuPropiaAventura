using Aplicacion.DTOs;

namespace Aplicacion.Interfaces
{
    public interface IServicioLectura
    {
        IEnumerable<HistoriaResumenDTO> ObtenerHistoriasPublicadas(int? categoriaId);

        LecturaDetalleDTO Iniciar(int usuarioId, int historiaId);

        LecturaDetalleDTO Obtener(int lecturaId, int usuarioId);

        LecturaDetalleDTO Avanzar(int lecturaId, int usuarioId, int opcionId);

        IEnumerable<LecturaDTO> ObtenerHistorial(int usuarioId, int mes, int anio);
    }
}
