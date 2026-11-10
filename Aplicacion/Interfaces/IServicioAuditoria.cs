using Aplicacion.DTOs;

namespace Aplicacion.Interfaces
{
    public interface IServicioAuditoria
    {
        void Registrar(string accion, int administradorId, int historiaId);

        IEnumerable<AuditoriaDTO> Buscar(int? historiaId, int? administradorId);
    }
}
