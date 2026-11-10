namespace Aplicacion.DTOs
{
    public class RankingUsuarioDTO
    {
        public int UsuarioId { get; set; }
        public string NombreUsuario { get; set; } = string.Empty;
        public string NombreCompleto { get; set; } = string.Empty;
        public int HistoriasCompletadas { get; set; }
    }
}
