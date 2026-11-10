namespace Obligatorio.Lector.Models
{
    public class FinalesHistoriaViewModel
    {
        public int HistoriaId { get; set; }
        public string HistoriaTitulo { get; set; } = string.Empty;
        public List<FinalAlcanzadoViewModel> Finales { get; set; } = new();
    }

    public class FinalAlcanzadoViewModel
    {
        public int CapituloId { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public int VecesAlcanzado { get; set; }
        public bool EsMasFrecuente { get; set; }
    }
}
