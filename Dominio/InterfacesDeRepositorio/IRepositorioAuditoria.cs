using Dominio.Entidades;

namespace Dominio.InterfacesDeRepositorio
{
    public interface IRepositorioAuditoria
    {
        void Add(Auditoria auditoria);

        // RF05 - Ambos filtros son opcionales.
        IEnumerable<Auditoria> Buscar(int? historiaId, int? administradorId);
    }
}
