using Dominio.Excepciones;
using System.Security.Claims;

namespace Obligatorio.WebApi.Extensiones
{
    public static class ClaimsPrincipalExtensiones
    {
        // El id del usuario sale del token, nunca de lo que mande el cliente.
        public static int ObtenerUsuarioId(this ClaimsPrincipal usuario)
        {
            string? id = usuario.FindFirstValue(ClaimTypes.NameIdentifier);

            if (!int.TryParse(id, out int usuarioId))
            {
                throw new UsuarioException(
                    "No se pudo identificar al usuario.");
            }

            return usuarioId;
        }
    }
}
