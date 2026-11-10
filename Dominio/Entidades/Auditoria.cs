using Dominio.Excepciones;
using Dominio.Interfaces;

namespace Dominio.Entidades
{
    public class Auditoria : IValidable
    {
        public const int LargoMaximoAccion = 100;

        public int Id { get; set; }

        public string Accion { get; set; } = string.Empty;

        public DateTime Fecha { get; set; }

        public Usuario Administrador { get; set; } = null!;

        // Queda en null si la historia se da de baja: el registro
        // de auditoría se conserva y el título sigue identificándola.
        public Historia? Historia { get; set; }

        public string TituloHistoria { get; set; } = string.Empty;

        public Auditoria()
        {
            Fecha = DateTime.Now;
        }

        public void Validar()
        {
            if (string.IsNullOrWhiteSpace(Accion))
            {
                throw new AuditoriaException(
                    "La acción de la auditoría es obligatoria.");
            }

            if (Accion.Length > LargoMaximoAccion)
            {
                throw new AuditoriaException(
                    $"La acción no puede superar los {LargoMaximoAccion} caracteres.");
            }

            if (Fecha == default)
            {
                throw new AuditoriaException(
                    "La fecha de la auditoría es obligatoria.");
            }

            if (Administrador == null)
            {
                throw new AuditoriaException(
                    "La auditoría debe tener un administrador.");
            }

            if (Historia == null)
            {
                throw new AuditoriaException(
                    "La auditoría debe estar asociada a una historia.");
            }

            if (string.IsNullOrWhiteSpace(TituloHistoria))
            {
                throw new AuditoriaException(
                    "La auditoría debe indicar el título de la historia.");
            }
        }
    }
}
