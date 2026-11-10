namespace Dominio.Excepciones
{
    public class CapituloException : DominioException
    {
        public CapituloException()
        {
        }

        public CapituloException(string mensaje)
            : base(mensaje)
        {
        }
    }
}