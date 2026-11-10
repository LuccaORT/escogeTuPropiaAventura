using Dominio.Excepciones;
using Dominio.Interfaces;

namespace Dominio.Entidades
{
    public class Categoria : IValidable
    {
        public const int LargoMaximoNombre = 100;

        public int Id { get; set; }

        public string Nombre { get; set; } = string.Empty;

        public Categoria()
        {
        }

        public void Validar()
        {
            if (string.IsNullOrWhiteSpace(Nombre))
            {
                throw new CategoriaException(
                    "El nombre de la categoría es obligatorio.");
            }

            if (Nombre.Length > LargoMaximoNombre)
            {
                throw new CategoriaException(
                    $"El nombre de la categoría no puede superar los {LargoMaximoNombre} caracteres.");
            }
        }
    }
}
