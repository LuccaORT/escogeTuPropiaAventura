namespace Dominio.Excepciones
{
    // Lo que se pidió no existe (o no le pertenece a quien lo pide).
    public class EntidadNoEncontradaException : DominioException
    {
        public EntidadNoEncontradaException()
        {
        }

        public EntidadNoEncontradaException(string mensaje)
            : base(mensaje)
        {
        }
    }
}
