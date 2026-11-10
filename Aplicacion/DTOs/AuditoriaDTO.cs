namespace Aplicacion.DTOs
{
    public class AuditoriaDTO
    {
        public int Id { get; set; }
        public string Accion { get; set; } = string.Empty;
        public DateTime Fecha { get; set; }
        public int AdministradorId { get; set; }
        public string AdministradorNombre { get; set; } = string.Empty;

        // Sin valor si la historia ya fue dada de baja.
        public int? HistoriaId { get; set; }
        public string HistoriaTitulo { get; set; } = string.Empty;
    }
}
