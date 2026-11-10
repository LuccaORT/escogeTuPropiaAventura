using Aplicacion.DTOs;

namespace Obligatorio.WebApi.Servicios
{
    public interface IServicioToken
    {
        string Generar(UsuarioDTO usuario);
    }
}
