namespace Aplicacion.DTOs
{
    public class LoginRespuestaDTO
    {
        public string Token { get; set; } = string.Empty;
        public string NombreUsuario { get; set; } = string.Empty;
        public string Rol { get; set; } = string.Empty;
        public string EstiloLectura { get; set; } = string.Empty;
    }
}
