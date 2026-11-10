namespace Aplicacion.DTOs
{
    public class FinalesHistoriaDTO
    {
        public int HistoriaId { get; set; }
        public string HistoriaTitulo { get; set; } = string.Empty;
        public List<FinalAlcanzadoDTO> Finales { get; set; } = new();
    }
}
