using Dominio.Entidades;
using Dominio.Enums;
using Dominio.InterfacesDeRepositorio;
using Infraestructura.Persistencia;

namespace Infraestructura.Repositorios
{
    public class RepositorioUsuario : IRepositorioUsuario
    {
        private readonly AppDbContext _context;

        public RepositorioUsuario(AppDbContext context)
        {
            _context = context;
        }

        public void Add(Usuario usuario)
        {
            _context.Usuarios.Add(usuario);
            _context.SaveChanges();
        }

        public void Update(Usuario usuario)
        {
            _context.Usuarios.Update(usuario);
            _context.SaveChanges();
        }

        public Usuario? FindById(int id)
        {
            return _context.Usuarios
                .FirstOrDefault(u => u.Id == id);
        }

        public Usuario? FindByNombreUsuario(string nombreUsuario)
        {
            return _context.Usuarios
                .FirstOrDefault(u => u.NombreUsuario == nombreUsuario);
        }

        public Usuario? FindByEmail(string email)
        {
            return _context.Usuarios
                .FirstOrDefault(u => u.Email == email);
        }

        public IEnumerable<Usuario> FindByRol(RolUsuario rol)
        {
            return _context.Usuarios
                .Where(u => u.Rol == rol)
                .OrderBy(u => u.NombreUsuario)
                .ToList();
        }
    }
}
