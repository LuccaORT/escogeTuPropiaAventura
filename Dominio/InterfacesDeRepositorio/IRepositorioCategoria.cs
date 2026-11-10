using Dominio.Entidades;

namespace Dominio.InterfacesDeRepositorio
{
    public interface IRepositorioCategoria
    {
        Categoria? FindById(int id);

        IEnumerable<Categoria> FindAll();
    }
}