namespace Dominio.Excepciones
{
    public class AuditoriaException : DominioException
    {
        public AuditoriaException()
        {
        }

        public AuditoriaException(string mensaje)
            : base(mensaje)
        {
        }
    }
}