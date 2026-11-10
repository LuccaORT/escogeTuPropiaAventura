namespace Aplicacion.DTOs
{
    public class CapituloDTO
    {
        public const string TipoIntermedio = "INTERMEDIO";
        public const string TipoFinal = "FINAL";

        public int Id { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public string Texto { get; set; } = string.Empty;
        public string Tipo { get; set; } = TipoIntermedio;
        public List<OpcionDTO> Opciones { get; set; } = new();
    }
}
