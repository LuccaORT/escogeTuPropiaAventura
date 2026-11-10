using Dominio.Excepciones;
using Dominio.Interfaces;

namespace Dominio.Entidades
{
    public class Opcion : IValidable
    {
        public const int LargoMaximoTexto = 300;

        public int Id { get; set; }

        public string Texto { get; set; } = string.Empty;

        public Capitulo Destino { get; set; } = null!;

        public Opcion()
        {
        }

        public void Validar()
        {
            if (string.IsNullOrWhiteSpace(Texto))
            {
                throw new OpcionException(
                    "El texto de la opción es obligatorio.");
            }

            if (Texto.Length > LargoMaximoTexto)
            {
                throw new OpcionException(
                    $"El texto de la opción no puede superar los {LargoMaximoTexto} caracteres.");
            }

            if (Destino == null)
            {
                throw new OpcionException(
                    "La opción debe conducir a un capítulo.");
            }
        }
    }
}
