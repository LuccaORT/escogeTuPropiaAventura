using Dominio.Entidades;
using Dominio.InterfacesDeRepositorio;
using Infraestructura.Persistencia;
using Microsoft.EntityFrameworkCore;

namespace Infraestructura.Repositorios
{
    public class RepositorioAuditoria : IRepositorioAuditoria
    {
        private readonly AppDbContext _context;

        public RepositorioAuditoria(AppDbContext context)
        {
            _context = context;
        }

        public void Add(Auditoria auditoria)
        {
            _context.Auditorias.Add(auditoria);
            _context.SaveChanges();
        }

        public IEnumerable<Auditoria> Buscar(int? historiaId, int? administradorId)
        {
            return _context.Auditorias
                .Include(a => a.Administrador)
                .Include(a => a.Historia)
                .Where(a => historiaId == null || a.Historia!.Id == historiaId)
                .Where(a => administradorId == null || a.Administrador.Id == administradorId)
                .OrderByDescending(a => a.Fecha)
                .ThenByDescending(a => a.Id)
                .ToList();
        }
    }
}
