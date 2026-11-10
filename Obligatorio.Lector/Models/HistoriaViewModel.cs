namespace Obligatorio.Lector.Models
{
    public class HistoriaViewModel
    {
        public int Id { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public string Sinopsis { get; set; } = string.Empty;
        public List<CategoriaViewModel> Categorias { get; set; } = new();
    }
}
