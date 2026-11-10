namespace Aplicacion.DTOs
{
    public class LecturaDTO
    {
        public int Id { get; set; }
        public DateTime FechaInicio { get; set; }
        public DateTime? FechaFinalizacion { get; set; }
        public bool Completada { get; set; }
        public int HistoriaId { get; set; }
        public string HistoriaTitulo { get; set; } = string.Empty;
        public int? FinalAlcanzadoId { get; set; }
        public string? FinalAlcanzadoTitulo { get; set; }
    }
}
