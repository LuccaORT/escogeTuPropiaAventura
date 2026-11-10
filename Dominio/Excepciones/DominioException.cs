namespace Dominio.Excepciones
{
    public class DominioException : Exception
    {
        public DominioException()
        {
        }

        public DominioException(string mensaje) : base(mensaje)
        {
        }
    }
}