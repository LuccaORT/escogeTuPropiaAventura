namespace Dominio.Excepciones
{
    public class OpcionException : DominioException
    {
        public OpcionException()
        {
        }

        public OpcionException(string mensaje)
            : base(mensaje)
        {
        }
    }
}