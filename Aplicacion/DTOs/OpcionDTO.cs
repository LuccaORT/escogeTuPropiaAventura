using System.Text.Json.Serialization;

namespace Aplicacion.DTOs
{
    public class OpcionDTO
    {
        public int Id { get; set; }
        public string Texto { get; set; } = string.Empty;

        // Solo lo completa la administración: al lector no se le
        // adelanta adónde lleva cada opción.
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public string? DestinoTitulo { get; set; }
    }
}
