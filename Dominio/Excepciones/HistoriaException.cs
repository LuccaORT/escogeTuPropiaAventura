namespace Dominio.Excepciones
{
    public class HistoriaException : DominioException
    {
        public HistoriaException()
        {
        }

        public HistoriaException(string mensaje)
            : base(mensaje)
        {
        }
    }
}