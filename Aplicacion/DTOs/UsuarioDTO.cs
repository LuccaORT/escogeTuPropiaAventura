namespace Aplicacion.DTOs
{
    // Datos de un usuario que pueden salir de la aplicación: sin contraseña.
    public class UsuarioDTO
    {
        public int Id { get; set; }
        public string NombreCompleto { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string NombreUsuario { get; set; } = string.Empty;
        public string Rol { get; set; } = string.Empty;
        public string EstiloLectura { get; set; } = string.Empty;
    }
}
