namespace Dominio.Consultas
{
    // RF09 - Lecturas completadas de una historia
    public record LecturasPorHistoria(int HistoriaId, string Titulo, int LecturasCompletadas);
}
