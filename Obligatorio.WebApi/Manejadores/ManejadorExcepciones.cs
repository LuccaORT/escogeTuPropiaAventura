using Aplicacion.DTOs;
using Dominio.Excepciones;
using Microsoft.AspNetCore.Diagnostics;

namespace Obligatorio.WebApi.Manejadores
{
    // Único lugar donde una excepción se traduce a un código HTTP:
    // los controladores no necesitan repetir try/catch.
    public class ManejadorExcepciones : IExceptionHandler
    {
        private readonly ILogger<ManejadorExcepciones> _logger;

        public ManejadorExcepciones(ILogger<ManejadorExcepciones> logger)
        {
            _logger = logger;
        }

        public async ValueTask<bool> TryHandleAsync(
            HttpContext contexto,
            Exception excepcion,
            CancellationToken cancelacion)
        {
            int codigo = excepcion switch
            {
                EntidadNoEncontradaException => StatusCodes.Status404NotFound,
                CredencialesInvalidasException => StatusCodes.Status401Unauthorized,
                DominioException => StatusCodes.Status400BadRequest,
                _ => StatusCodes.Status500InternalServerError
            };

            string mensaje;

            if (excepcion is DominioException)
            {
                mensaje = excepcion.Message;
            }
            else
            {
                // El detalle técnico queda en el log, no en la respuesta.
                _logger.LogError(excepcion, "Error no controlado en la API.");
                mensaje = "Ocurrió un error inesperado. Intente nuevamente.";
            }

            contexto.Response.StatusCode = codigo;

            await contexto.Response.WriteAsJsonAsync(
                new ErrorDTO { Mensaje = mensaje },
                cancelacion);

            return true;
        }
    }
}
