namespace Obligatorio.Lector.Models
{
    public class CapituloViewModel
    {
        public int Id { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public string Texto { get; set; } = string.Empty;
        public string Tipo { get; set; } = string.Empty;
        public List<OpcionViewModel> Opciones { get; set; } = new();

        public bool EsFinal => Tipo == "FINAL";
    }

    public class OpcionViewModel
    {
        public int Id { get; set; }
        public string Texto { get; set; } = string.Empty;
    }
}
