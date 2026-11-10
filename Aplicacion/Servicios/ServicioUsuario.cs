using Aplicacion.DTOs;
using Aplicacion.Interfaces;
using Aplicacion.Mappers;
using Dominio.Entidades;
using Dominio.Enums;
using Dominio.Excepciones;
using Dominio.InterfacesDeRepositorio;

namespace Aplicacion.Servicios
{
    public class ServicioUsuario : IServicioUsuario
    {
        private readonly IRepositorioUsuario _repositorioUsuario;

        public ServicioUsuario(IRepositorioUsuario repositorioUsuario)
        {
            _repositorioUsuario = repositorioUsuario;
        }

        // RF02 - Alta de usuarios
        public void Alta(UsuarioAltaDTO datos)
        {
            Usuario usuario = UsuarioMapper.FromDTO(datos);

            usuario.Validar();

            if (_repositorioUsuario.FindByNombreUsuario(usuario.NombreUsuario) != null)
            {
                throw new UsuarioException(
                    "Ya existe un usuario con ese nombre de usuario.");
            }

            if (_repositorioUsuario.FindByEmail(usuario.Email) != null)
            {
                throw new UsuarioException(
                    "Ya existe un usuario con ese email.");
            }

            _repositorioUsuario.Add(usuario);
        }

        // RF01 - Login de la aplicación de administración
        public UsuarioDTO LoginAdministrador(string nombreUsuario, string contrasena)
        {
            UsuarioDTO usuario = Login(nombreUsuario, contrasena);

            if (usuario.Rol != RolUsuario.ADMINISTRADOR.ToString())
            {
                throw new CredencialesInvalidasException(
                    "El usuario no tiene permisos de administrador.");
            }

            return usuario;
        }

        // RF06 - Login de la aplicación de lectura
        public UsuarioDTO Login(string nombreUsuario, string contrasena)
        {
            if (string.IsNullOrWhiteSpace(nombreUsuario))
            {
                throw new UsuarioException(
                    "Debe ingresar el nombre de usuario.");
            }

            if (string.IsNullOrWhiteSpace(contrasena))
            {
                throw new UsuarioException(
                    "Debe ingresar la contraseña.");
            }

            Usuario? usuario =
                _repositorioUsuario.FindByNombreUsuario(nombreUsuario);

            // Mismo mensaje en ambos casos: no se revela qué dato falló.
            if (usuario == null || usuario.Contrasena != contrasena)
            {
                throw new CredencialesInvalidasException(
                    "Usuario o contraseña incorrectos.");
            }

            return UsuarioMapper.ToDTO(usuario);
        }

        // RF12 - Estilo de lectura guardado para el usuario
        public EstiloLecturaDTO ObtenerEstilo(int usuarioId)
        {
            return new EstiloLecturaDTO
            {
                Estilo = ObtenerEntidad(usuarioId).EstiloLectura.Valor
            };
        }

        // RF12 - Cada usuario tiene su propio estilo
        public EstiloLecturaDTO CambiarEstilo(int usuarioId, string estilo)
        {
            Usuario usuario = ObtenerEntidad(usuarioId);

            usuario.CambiarEstilo(estilo);

            _repositorioUsuario.Update(usuario);

            return new EstiloLecturaDTO
            {
                Estilo = usuario.EstiloLectura.Valor
            };
        }

        private Usuario ObtenerEntidad(int usuarioId)
        {
            return _repositorioUsuario.FindById(usuarioId)
                ?? throw new EntidadNoEncontradaException("El usuario no existe.");
        }

        public IEnumerable<UsuarioDTO> ObtenerAdministradores()
        {
            return _repositorioUsuario.FindByRol(RolUsuario.ADMINISTRADOR)
                .Select(UsuarioMapper.ToDTO)
                .ToList();
        }
    }
}
