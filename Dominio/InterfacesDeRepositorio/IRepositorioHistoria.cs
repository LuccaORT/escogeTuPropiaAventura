using Dominio.Entidades;

namespace Dominio.InterfacesDeRepositorio
{
    public interface IRepositorioHistoria
    {
        void Add(Historia historia);

        // Trae la historia completa: categorías, capítulos, opciones y destinos.
        Historia? FindById(int id);

        // Listado liviano: historias con sus categorías.
        IEnumerable<Historia> FindAll();

        // RF07 - Publicadas, opcionalmente de una categoría.
        IEnumerable<Historia> FindPublicadas(int? categoriaId);

        void Update(Historia historia);

        void Delete(Historia historia);
    }
}
