using Dominio.Excepciones;
using Dominio.Interfaces;

namespace Dominio.Entidades
{
    public class Lectura : IValidable
    {
        public int Id { get; set; }

        public DateTime FechaInicio { get; set; }

        public DateTime? FechaFinalizacion { get; set; }

        public Usuario Usuario { get; set; } = null!;

        public Historia Historia { get; set; } = null!;

        public Capitulo CapituloActual { get; set; } = null!;

        public CapituloFinal? FinalAlcanzado { get; set; }

        public bool Completada => FechaFinalizacion.HasValue;

        public Lectura()
        {
            FechaInicio = DateTime.Now;
        }

        // RF07 - Elegir una opción del capítulo actual.
        // Si el destino es un final, la lectura termina sola.
        public void Avanzar(int opcionId)
        {
            if (Completada)
            {
                throw new LecturaException(
                    "La lectura ya finalizó. Debe iniciar una nueva.");
            }

            if (CapituloActual is not CapituloIntermedio actual)
            {
                throw new LecturaException(
                    "No se puede avanzar desde un capítulo final.");
            }

            Opcion? opcion = actual.Opciones
                .FirstOrDefault(o => o.Id == opcionId);

            if (opcion == null)
            {
                throw new LecturaException(
                    "La opción seleccionada no pertenece al capítulo actual.");
            }

            CapituloActual = opcion.Destino;

            if (opcion.Destino is CapituloFinal final)
            {
                Finalizar(final);
            }
        }

        public void Finalizar(CapituloFinal final)
        {
            if (Completada)
            {
                throw new LecturaException(
                    "La lectura ya finalizó.");
            }

            FinalAlcanzado = final;
            FechaFinalizacion = DateTime.Now;
        }

        public void Validar()
        {
            if (Usuario == null)
            {
                throw new LecturaException(
                    "La lectura debe pertenecer a un usuario.");
            }

            if (Historia == null)
            {
                throw new LecturaException(
                    "La lectura debe pertenecer a una historia.");
            }

            if (CapituloActual == null)
            {
                throw new LecturaException(
                    "La lectura debe tener un capítulo actual.");
            }

            if (FechaInicio == default)
            {
                throw new LecturaException(
                    "La fecha de inicio de la lectura es obligatoria.");
            }

            if (FechaFinalizacion.HasValue &&
                FechaFinalizacion.Value < FechaInicio)
            {
                throw new LecturaException(
                    "La fecha de finalización no puede ser anterior a la fecha de inicio.");
            }

            if (FechaFinalizacion.HasValue != (FinalAlcanzado != null))
            {
                throw new LecturaException(
                    "Una lectura finalizada debe indicar el final alcanzado, y solo ella.");
            }
        }
    }
}
