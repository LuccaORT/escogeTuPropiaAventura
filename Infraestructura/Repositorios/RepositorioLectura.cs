using Dominio.Consultas;
using Dominio.Entidades;
using Dominio.InterfacesDeRepositorio;
using Infraestructura.Persistencia;
using Microsoft.EntityFrameworkCore;

namespace Infraestructura.Repositorios
{
    public class RepositorioLectura : IRepositorioLectura
    {
        private readonly AppDbContext _context;

        public RepositorioLectura(AppDbContext context)
        {
            _context = context;
        }

        public bool ExistePorHistoria(int historiaId)
        {
            return _context.Lecturas
                .Any(l => l.Historia.Id == historiaId);
        }

        public void Add(Lectura lectura)
        {
            _context.Lecturas.Add(lectura);
            _context.SaveChanges();
        }

        // Trae el capítulo actual con sus opciones y los destinos,
        // que es lo que hace falta para mostrarlo y para avanzar.
        public Lectura? FindById(int id)
        {
            return _context.Lecturas
                .Include(l => l.Usuario)
                .Include(l => l.Historia)
                .Include(l => l.FinalAlcanzado)
                .Include(l => l.CapituloActual)
                    .ThenInclude(c => ((CapituloIntermedio)c).Opciones)
                        .ThenInclude(o => o.Destino)
                .AsSplitQuery()
                .FirstOrDefault(l => l.Id == id);
        }

        public void Update(Lectura lectura)
        {
            _context.Lecturas.Update(lectura);
            _context.SaveChanges();
        }

        public IEnumerable<Lectura> FindByUsuarioMesAnio(
            int usuarioId,
            int mes,
            int anio)
        {
            return _context.Lecturas
                .Include(l => l.Historia)
                .Include(l => l.FinalAlcanzado)
                .Where(l =>
                    l.Usuario.Id == usuarioId &&
                    l.FechaInicio.Month == mes &&
                    l.FechaInicio.Year == anio)
                .OrderByDescending(l => l.FechaInicio)
                .ToList();
        }

        // Al agrupar solo lecturas completadas, las historias sin ninguna
        // no aparecen. Ante un empate ordena alfabéticamente.
        public IEnumerable<LecturasPorHistoria> RankingHistorias()
        {
            return _context.Lecturas
                .Where(l => l.FechaFinalizacion != null)
                .GroupBy(l => new { l.Historia.Id, l.Historia.Titulo })
                .OrderByDescending(g => g.Count())
                .ThenBy(g => g.Key.Titulo)
                .Select(g => new LecturasPorHistoria(
                    g.Key.Id,
                    g.Key.Titulo,
                    g.Count()))
                .ToList();
        }

        // Parte de los finales y no de las lecturas,
        // para incluir los que nunca se alcanzaron.
        public IEnumerable<LecturasPorFinal> FinalesPorHistoria(int historiaId)
        {
            return _context.CapitulosFinales
                .Where(c => c.Historia.Id == historiaId)
                .Select(c => new
                {
                    c.Id,
                    c.Titulo,
                    Veces = _context.Lecturas.Count(l => l.FinalAlcanzado!.Id == c.Id)
                })
                .OrderByDescending(f => f.Veces)
                .ThenBy(f => f.Titulo)
                .Select(f => new LecturasPorFinal(f.Id, f.Titulo, f.Veces))
                .ToList();
        }

        // Una misma historia completada varias veces cuenta una sola vez.
        public IEnumerable<HistoriasPorUsuario> RankingUsuarios()
        {
            return _context.Lecturas
                .Where(l => l.FechaFinalizacion != null)
                .GroupBy(l => new
                {
                    l.Usuario.Id,
                    l.Usuario.NombreUsuario,
                    l.Usuario.NombreCompleto
                })
                .Select(g => new
                {
                    g.Key.Id,
                    g.Key.NombreUsuario,
                    g.Key.NombreCompleto,
                    Historias = g.Select(l => l.Historia.Id).Distinct().Count()
                })
                .OrderByDescending(u => u.Historias)
                .ThenBy(u => u.NombreUsuario)
                .Select(u => new HistoriasPorUsuario(
                    u.Id,
                    u.NombreUsuario,
                    u.NombreCompleto,
                    u.Historias))
                .ToList();
        }
    }
}
