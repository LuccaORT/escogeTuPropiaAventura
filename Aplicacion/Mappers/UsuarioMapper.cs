using Aplicacion.DTOs;
using Dominio.Entidades;
using Dominio.Enums;
using Dominio.Excepciones;

namespace Aplicacion.Mappers
{
    public static class UsuarioMapper
    {
        public static Usuario FromDTO(UsuarioAltaDTO dto)
        {
            if (!Enum.TryParse(dto.Rol, out RolUsuario rol))
            {
                throw new UsuarioException(
                    "El rol seleccionado no es válido.");
            }

            return new Usuario
            {
                NombreCompleto = dto.NombreCompleto,
                Email = dto.Email,
                NombreUsuario = dto.NombreUsuario,
                Contrasena = dto.Contrasena,
                Rol = rol
            };
        }

        public static UsuarioDTO ToDTO(Usuario usuario)
        {
            return new UsuarioDTO
            {
                Id = usuario.Id,
                NombreCompleto = usuario.NombreCompleto,
                Email = usuario.Email,
                NombreUsuario = usuario.NombreUsuario,
                Rol = usuario.Rol.ToString(),
                EstiloLectura = usuario.EstiloLectura.Valor
            };
        }
    }
}
