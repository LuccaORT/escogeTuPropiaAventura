namespace Dominio.Excepciones
{
    public class UsuarioException : DominioException
    {
        public UsuarioException()
        {
        }

        public UsuarioException(string mensaje)
            : base(mensaje)
        {
        }
    }
}