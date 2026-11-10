using Aplicacion.DTOs;

namespace Aplicacion.Interfaces
{
    public interface IServicioUsuario
    {
        void Alta(UsuarioAltaDTO datos);

        // RF06 - Administradores y lectores.
        UsuarioDTO Login(string nombreUsuario, string contrasena);

        // RF01 - Solo administradores.
        UsuarioDTO LoginAdministrador(string nombreUsuario, string contrasena);

        IEnumerable<UsuarioDTO> ObtenerAdministradores();

        // RF12 - Estilo de lectura del usuario
        EstiloLecturaDTO ObtenerEstilo(int usuarioId);

        EstiloLecturaDTO CambiarEstilo(int usuarioId, string estilo);
    }
}
