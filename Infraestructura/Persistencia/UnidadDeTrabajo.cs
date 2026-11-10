using Aplicacion.Interfaces;

namespace Infraestructura.Persistencia
{
    public class UnidadDeTrabajo : IUnidadDeTrabajo
    {
        private readonly AppDbContext _context;

        public UnidadDeTrabajo(AppDbContext context)
        {
            _context = context;
        }

        public void Ejecutar(Action operacion)
        {
            using var transaccion = _context.Database.BeginTransaction();

            operacion();

            // Si la operación lanza una excepción no se llega al Commit
            // y, al liberarse, la transacción hace rollback sola.
            transaccion.Commit();
        }
    }
}
