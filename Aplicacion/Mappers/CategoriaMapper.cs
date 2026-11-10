using Aplicacion.DTOs;
using Dominio.Entidades;

namespace Aplicacion.Mappers
{
    public static class CategoriaMapper
    {
        public static CategoriaDTO ToDTO(Categoria categoria)
        {
            return new CategoriaDTO
            {
                Id = categoria.Id,
                Nombre = categoria.Nombre
            };
        }
    }
}
