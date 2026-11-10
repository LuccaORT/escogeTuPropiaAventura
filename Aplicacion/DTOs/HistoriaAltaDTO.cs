namespace Aplicacion.DTOs
{
    // RF03 - La historia nace junto con su capítulo inicial.
    public class HistoriaAltaDTO
    {
        public string Titulo { get; set; } = string.Empty;
        public string Sinopsis { get; set; } = string.Empty;
        public List<int> CategoriasIds { get; set; } = new();
        public string TituloCapituloInicial { get; set; } = string.Empty;
        public string TextoCapituloInicial { get; set; } = string.Empty;
    }
}
