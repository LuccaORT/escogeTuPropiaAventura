using Dominio.Excepciones;
using Dominio.Interfaces;

namespace Dominio.Entidades
{
    public abstract class Capitulo : IValidable
    {
        public const int LargoMaximoTitulo = 200;

        public int Id { get; set; }

        public string Titulo { get; set; } = string.Empty;

        public string Texto { get; set; } = string.Empty;

        public Historia Historia { get; set; } = null!;

        protected Capitulo()
        {
        }

        public virtual void Validar()
        {
            if (string.IsNullOrWhiteSpace(Titulo))
            {
                throw new CapituloException(
                    "El título del capítulo es obligatorio.");
            }

            if (Titulo.Length > LargoMaximoTitulo)
            {
                throw new CapituloException(
                    $"El título del capítulo no puede superar los {LargoMaximoTitulo} caracteres.");
            }

            if (string.IsNullOrWhiteSpace(Texto))
            {
                throw new CapituloException(
                    "El texto del capítulo es obligatorio.");
            }

            if (Historia == null)
            {
                throw new CapituloException(
                    "El capítulo debe pertenecer a una historia.");
            }
        }

        // Reglas extra que se exigen recién al publicar la historia.
        public virtual void ValidarPublicacion()
        {
            Validar();
        }
    }
}
