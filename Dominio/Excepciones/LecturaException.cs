namespace Dominio.Excepciones
{
    public class LecturaException : DominioException
    {
        public LecturaException()
        {
        }

        public LecturaException(string mensaje)
            : base(mensaje)
        {
        }
    }
}