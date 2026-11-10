using Dominio.Entidades;
using Dominio.InterfacesDeRepositorio;
using Infraestructura.Persistencia;

namespace Infraestructura.Repositorios
{
    public class RepositorioCategoria : IRepositorioCategoria
    {
        private readonly AppDbContext _context;

        public RepositorioCategoria(AppDbContext context)
        {
            _context = context;
        }

        public Categoria? FindById(int id)
        {
            return _context.Categorias
                .FirstOrDefault(c => c.Id == id);
        }

        public IEnumerable<Categoria> FindAll()
        {
            return _context.Categorias.ToList();
        }
    }
}