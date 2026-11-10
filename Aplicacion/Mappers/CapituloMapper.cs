using Aplicacion.DTOs;
using Dominio.Entidades;

namespace Aplicacion.Mappers
{
    public static class CapituloMapper
    {
        // Para el lector: las opciones no revelan su destino.
        public static CapituloDTO ToDTO(Capitulo capitulo)
        {
            return Mapear(capitulo, incluirDestinos: false);
        }

        // Para la administración: se ve adónde lleva cada opción.
        public static CapituloDTO ToDTOConDestinos(Capitulo capitulo)
        {
            return Mapear(capitulo, incluirDestinos: true);
        }

        private static CapituloDTO Mapear(Capitulo capitulo, bool incluirDestinos)
        {
            CapituloDTO dto = new CapituloDTO
            {
                Id = capitulo.Id,
                Titulo = capitulo.Titulo,
                Texto = capitulo.Texto,
                Tipo = capitulo is CapituloFinal
                    ? CapituloDTO.TipoFinal
                    : CapituloDTO.TipoIntermedio
            };

            if (capitulo is CapituloIntermedio intermedio)
            {
                dto.Opciones = intermedio.Opciones
                    .OrderBy(o => o.Id)
                    .Select(o => new OpcionDTO
                    {
                        Id = o.Id,
                        Texto = o.Texto,
                        DestinoTitulo = incluirDestinos ? o.Destino?.Titulo : null
                    })
                    .ToList();
            }

            return dto;
        }
    }
}
