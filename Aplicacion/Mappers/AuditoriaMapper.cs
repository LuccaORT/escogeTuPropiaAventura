using Aplicacion.DTOs;
using Dominio.Entidades;

namespace Aplicacion.Mappers
{
    public static class AuditoriaMapper
    {
        public static AuditoriaDTO ToDTO(Auditoria auditoria)
        {
            return new AuditoriaDTO
            {
                Id = auditoria.Id,
                Accion = auditoria.Accion,
                Fecha = auditoria.Fecha,
                AdministradorId = auditoria.Administrador.Id,
                AdministradorNombre = auditoria.Administrador.NombreUsuario,
                HistoriaId = auditoria.Historia?.Id,
                HistoriaTitulo = auditoria.TituloHistoria
            };
        }
    }
}
