namespace Aplicacion.DTOs
{
    // RF03 - Lo único que permite cambiar la edición de una historia.
    public class HistoriaEdicionDTO
    {
        public int Id { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public string Sinopsis { get; set; } = string.Empty;
        public List<int> CategoriasIds { get; set; } = new();
        public string Estado { get; set; } = string.Empty;

        // Solo llegan cuando el capítulo inicial todavía se puede editar.
        public string? TituloCapituloInicial { get; set; }
        public string? TextoCapituloInicial { get; set; }
    }
}
