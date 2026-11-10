using Dominio.Entidades;
using Dominio.Enums;

namespace Dominio.InterfacesDeRepositorio
{
    public interface IRepositorioUsuario
    {
        void Add(Usuario usuario);

        void Update(Usuario usuario);

        Usuario? FindById(int id);

        Usuario? FindByNombreUsuario(string nombreUsuario);

        Usuario? FindByEmail(string email);

        IEnumerable<Usuario> FindByRol(RolUsuario rol);
    }
}
