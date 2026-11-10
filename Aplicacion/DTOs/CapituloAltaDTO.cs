namespace Aplicacion.DTOs
{
    // RF04 - Datos para agregar un capítulo a continuación de otro.
    public class CapituloAltaDTO
    {
        public int HistoriaId { get; set; }
        public int CapituloAnteriorId { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public string Texto { get; set; } = string.Empty;
        public string TextoOpcion { get; set; } = string.Empty;
        public bool EsFinal { get; set; }
    }
}
