namespace Aplicacion.DTOs
{
    public class FinalAlcanzadoDTO
    {
        public int CapituloId { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public int VecesAlcanzado { get; set; }
        public bool EsMasFrecuente { get; set; }
    }
}
