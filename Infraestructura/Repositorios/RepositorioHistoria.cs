using Dominio.Entidades;
using Dominio.Enums;
using Dominio.InterfacesDeRepositorio;
using Infraestructura.Persistencia;
using Microsoft.EntityFrameworkCore;

namespace Infraestructura.Repositorios
{
    public class RepositorioHistoria : IRepositorioHistoria
    {
        private readonly AppDbContext _context;

        public RepositorioHistoria(AppDbContext context)
        {
            _context = context;
        }

        public void Add(Historia historia)
        {
            CapituloIntermedio capituloInicial =
                historia.CapituloInicial!;

            // Historia y capítulo se apuntan mutuamente: primero se guardan
            // sin el vínculo al inicial y después se completa con su Id.
            historia.CapituloInicial = null;
            historia.CapituloInicialId = null;

            _context.Historias.Add(historia);
            _context.SaveChanges();

            historia.CapituloInicial = capituloInicial;
            historia.CapituloInicialId = capituloInicial.Id;

            _context.SaveChanges();
        }

        public Historia? FindById(int id)
        {
            return _context.Historias
                .Include(h => h.Categorias)
                .Include(h => h.CapituloInicial)
                .Include(h => h.Capitulos)
                    .ThenInclude(c => ((CapituloIntermedio)c).Opciones)
                        .ThenInclude(o => o.Destino)
                .AsSplitQuery()
                .FirstOrDefault(h => h.Id == id);
        }

        public IEnumerable<Historia> FindAll()
        {
            return _context.Historias
                .Include(h => h.Categorias)
                .OrderBy(h => h.Titulo)
                .ToList();
        }

        public IEnumerable<Historia> FindPublicadas(int? categoriaId)
        {
            return _context.Historias
                .Include(h => h.Categorias)
                .Where(h => h.Estado == EstadoHistoria.PUBLICADA)
                .Where(h => categoriaId == null ||
                            h.Categorias.Any(c => c.Id == categoriaId))
                .OrderBy(h => h.Titulo)
                .ToList();
        }

        public void Update(Historia historia)
        {
            _context.Historias.Update(historia);
            _context.SaveChanges();
        }

        public void Delete(Historia historia)
        {
            // Se rompe primero el vínculo con el capítulo inicial,
            // porque ese capítulo también se va a borrar.
            historia.CapituloInicial = null;
            historia.CapituloInicialId = null;

            _context.SaveChanges();

            _context.Historias.Remove(historia);
            _context.SaveChanges();
        }
    }
}
