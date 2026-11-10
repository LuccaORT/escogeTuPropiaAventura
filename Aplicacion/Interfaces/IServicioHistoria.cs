using Aplicacion.DTOs;

namespace Aplicacion.Interfaces
{
    public interface IServicioHistoria
    {
        int Crear(HistoriaAltaDTO datos, int administradorId);

        void Editar(HistoriaEdicionDTO datos, int administradorId);

        void Eliminar(int id, int administradorId);

        void AgregarCapitulo(CapituloAltaDTO datos, int administradorId);

        HistoriaDetalleDTO ObtenerPorId(int id);

        IEnumerable<HistoriaResumenDTO> ObtenerTodas();

        IEnumerable<CategoriaDTO> ObtenerCategorias();
    }
}
