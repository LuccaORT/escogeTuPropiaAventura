namespace Aplicacion.DTOs
{
    // RF02 - Datos que se ingresan al dar de alta un usuario.
    public class UsuarioAltaDTO
    {
        public string NombreCompleto { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string NombreUsuario { get; set; } = string.Empty;
        public string Contrasena { get; set; } = string.Empty;
        public string Rol { get; set; } = string.Empty;
    }
}
