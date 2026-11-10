namespace Dominio.Interfaces
{
    // Toda entidad del dominio sabe validarse a sí misma.
    public interface IValidable
    {
        void Validar();
    }
}
