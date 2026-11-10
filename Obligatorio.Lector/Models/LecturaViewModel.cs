namespace Obligatorio.Lector.Models
{
    public class LecturaViewModel
    {
        public int Id { get; set; }
        public DateTime FechaInicio { get; set; }
        public DateTime? FechaFinalizacion { get; set; }
        public bool Completada { get; set; }
        public int HistoriaId { get; set; }
        public string HistoriaTitulo { get; set; } = string.Empty;
        public string? FinalAlcanzadoTitulo { get; set; }
    }

    public class LecturaDetalleViewModel : LecturaViewModel
    {
        public CapituloViewModel CapituloActual { get; set; } = new();
    }
}
