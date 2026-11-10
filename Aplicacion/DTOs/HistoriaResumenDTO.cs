namespace Aplicacion.DTOs
{
    // Para listados: no incluye los capítulos.
    public class HistoriaResumenDTO
    {
        public int Id { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public string Sinopsis { get; set; } = string.Empty;
        public string Estado { get; set; } = string.Empty;
        public bool EstaPublicada { get; set; }
        public List<CategoriaDTO> Categorias { get; set; } = new();
    }
}
