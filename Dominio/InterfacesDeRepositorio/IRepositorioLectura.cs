using Dominio.Consultas;
using Dominio.Entidades;
using System.Collections.Generic;

namespace Dominio.InterfacesDeRepositorio
{
    public interface IRepositorioLectura
    {
        // RF03 - Comprobar si una historia tiene lecturas
        bool ExistePorHistoria(int historiaId);

        // RF07 - Guardar una nueva lectura
        void Add(Lectura lectura);

        // RF07 - Obtener una lectura por ID
        Lectura? FindById(int id);

        // RF07 - Actualizar el avance de una lectura
        void Update(Lectura lectura);

        // RF08 - Consultar lecturas por usuario, mes y año
        IEnumerable<Lectura> FindByUsuarioMesAnio(
            int usuarioId,
            int mes,
            int anio);

        // RF09 - Historias con lecturas completadas, de mayor a menor
        IEnumerable<LecturasPorHistoria> RankingHistorias();

        // RF10 - Todos los finales de una historia, de más a menos alcanzado
        IEnumerable<LecturasPorFinal> FinalesPorHistoria(int historiaId);

        // RF11 - Usuarios según historias distintas completadas, de mayor a menor
        IEnumerable<HistoriasPorUsuario> RankingUsuarios();
    }
}
