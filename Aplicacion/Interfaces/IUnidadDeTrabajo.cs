namespace Aplicacion.Interfaces
{
    // Ejecuta varias operaciones como una sola: o se guardan todas o ninguna.
    public interface IUnidadDeTrabajo
    {
        void Ejecutar(Action operacion);
    }
}
