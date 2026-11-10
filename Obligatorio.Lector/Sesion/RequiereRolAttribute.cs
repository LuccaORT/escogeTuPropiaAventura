using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Mvc.ViewFeatures;

namespace Obligatorio.Lector.Sesion
{
    // Sin sesión lleva al login; con otro rol vuelve al inicio con un mensaje.
    public class RequiereRolAttribute : ActionFilterAttribute
    {
        private readonly string _rol;

        public RequiereRolAttribute(string rol)
        {
            _rol = rol;
        }

        public override void OnActionExecuting(ActionExecutingContext contexto)
        {
            ISession sesion = contexto.HttpContext.Session;

            if (string.IsNullOrEmpty(sesion.GetString(ClavesSesion.Token)))
            {
                contexto.Result = new RedirectToActionResult("Login", "Auth", null);
                return;
            }

            if (sesion.GetString(ClavesSesion.Rol) != _rol)
            {
                if (contexto.Controller is Controller controlador)
                {
                    controlador.TempData["Error"] =
                        "Su usuario no tiene permisos para acceder a esa sección.";
                }

                contexto.Result = new RedirectToActionResult("Index", "Home", null);
            }
        }
    }
}
