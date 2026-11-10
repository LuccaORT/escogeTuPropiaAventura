namespace Obligatorio.Lector.Models
{
    public class RankingUsuarioViewModel
    {
        public int UsuarioId { get; set; }
        public string NombreUsuario { get; set; } = string.Empty;
        public string NombreCompleto { get; set; } = string.Empty;
        public int HistoriasCompletadas { get; set; }
    }
}
