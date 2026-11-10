namespace Dominio.Excepciones
{
    // El usuario o la contraseña no son correctos.
    public class CredencialesInvalidasException : DominioException
    {
        public CredencialesInvalidasException()
        {
        }

        public CredencialesInvalidasException(string mensaje)
            : base(mensaje)
        {
        }
    }
}
