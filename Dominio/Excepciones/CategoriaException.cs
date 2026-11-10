namespace Dominio.Excepciones
{
    public class CategoriaException : DominioException
    {
        public CategoriaException()
        {
        }

        public CategoriaException(string mensaje)
            : base(mensaje)
        {
        }
    }
}