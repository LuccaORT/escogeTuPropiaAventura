namespace Aplicacion.DTOs
{
    // Una lectura junto con el capítulo en el que va el lector.
    public class LecturaDetalleDTO : LecturaDTO
    {
        public CapituloDTO CapituloActual { get; set; } = new();
    }
}
