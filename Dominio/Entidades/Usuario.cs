using Dominio.Enums;
using Dominio.Excepciones;
using Dominio.Interfaces;
using Dominio.ValueObjects;
using System.Text.RegularExpressions;

namespace Dominio.Entidades
{
    public class Usuario : IValidable
    {
        public const int LargoMaximoNombreCompleto = 150;
        public const int LargoMaximoEmail = 150;
        public const int LargoMaximoNombreUsuario = 50;
        public const int LargoMaximoContrasena = 100;

        public int Id { get; set; }

        public string NombreCompleto { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string NombreUsuario { get; set; } = string.Empty;

        public string Contrasena { get; set; } = string.Empty;

        public RolUsuario Rol { get; set; }

        // RF12 - Todo usuario arranca con el estilo claro
        public EstiloLectura EstiloLectura { get; private set; } =
            new EstiloLectura(EstiloLectura.Claro);

        public Usuario()
        {
        }

        // RF12 - El Value Object rechaza los valores no permitidos
        public void CambiarEstilo(string estilo)
        {
            EstiloLectura = new EstiloLectura(estilo);
        }

        public void Validar()
        {
            ValidarTexto(NombreCompleto, "El nombre completo", LargoMaximoNombreCompleto);
            ValidarTexto(Email, "El email", LargoMaximoEmail);
            ValidarTexto(NombreUsuario, "El nombre de usuario", LargoMaximoNombreUsuario);

            if (!Regex.IsMatch(Email, @"^[^@\s]+@[^@\s]+\.[^@\s]+$"))
            {
                throw new UsuarioException(
                    "El email no tiene un formato válido.");
            }

            if (!Enum.IsDefined(Rol))
            {
                throw new UsuarioException(
                    "El rol seleccionado no es válido.");
            }

            ValidarContrasena();
        }

        private static void ValidarTexto(string? valor, string campo, int largoMaximo)
        {
            if (string.IsNullOrWhiteSpace(valor))
            {
                throw new UsuarioException($"{campo} es obligatorio.");
            }

            if (valor.Length > largoMaximo)
            {
                throw new UsuarioException(
                    $"{campo} no puede superar los {largoMaximo} caracteres.");
            }
        }

        private void ValidarContrasena()
        {
            if (string.IsNullOrWhiteSpace(Contrasena))
            {
                throw new UsuarioException(
                    "La contraseña es obligatoria.");
            }

            if (Contrasena.Length < 8)
            {
                throw new UsuarioException(
                    "La contraseña debe tener al menos 8 caracteres.");
            }

            if (Contrasena.Length > LargoMaximoContrasena)
            {
                throw new UsuarioException(
                    $"La contraseña no puede superar los {LargoMaximoContrasena} caracteres.");
            }

            if (!Regex.IsMatch(Contrasena, "[A-Z]"))
            {
                throw new UsuarioException(
                    "La contraseña debe contener una mayúscula.");
            }

            if (!Regex.IsMatch(Contrasena, "[a-z]"))
            {
                throw new UsuarioException(
                    "La contraseña debe contener una minúscula.");
            }

            if (!Regex.IsMatch(Contrasena, "[0-9]"))
            {
                throw new UsuarioException(
                    "La contraseña debe contener un número.");
            }

            if (!Regex.IsMatch(Contrasena, @"[^a-zA-Z0-9]"))
            {
                throw new UsuarioException(
                    "La contraseña debe contener un carácter especial.");
            }
        }
    }
}
