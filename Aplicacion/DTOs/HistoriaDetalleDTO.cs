namespace Aplicacion.DTOs
{
    // Para la administración de una historia: incluye su estructura.
    public class HistoriaDetalleDTO : HistoriaResumenDTO
    {
        public CapituloDTO? CapituloInicial { get; set; }
        public List<CapituloDTO> Capitulos { get; set; } = new();

        // RF03 - El inicial se edita mientras sea el único capítulo.
        public bool PuedeEditarCapituloInicial => Capitulos.Count == 1;

        // RF04 - Solo se agregan capítulos a continuación de intermedios.
        public IEnumerable<CapituloDTO> CapitulosIntermedios =>
            Capitulos.Where(c => c.Tipo == CapituloDTO.TipoIntermedio);
    }
}
