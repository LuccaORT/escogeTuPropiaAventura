using Dominio.Excepciones;

namespace Dominio.ValueObjects
{
    // RF12 - Value Object: no tiene identidad propia, dos estilos con el mismo
    // valor son iguales, y no puede existir con un valor no permitido.
    public sealed record EstiloLectura
    {
        public const string Claro = "CLARO";
        public const string Oscuro = "OSCURO";
        public const int LargoMaximo = 20;

        public string Valor { get; }

        public EstiloLectura(string valor)
        {
            if (valor != Claro && valor != Oscuro)
            {
                throw new UsuarioException(
                    "El estilo de lectura seleccionado no es válido.");
            }

            Valor = valor;
        }
    }
}
