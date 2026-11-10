namespace Dominio.Consultas
{
    // RF11 - Historias distintas que completó un usuario
    public record HistoriasPorUsuario(
        int UsuarioId,
        string NombreUsuario,
        string NombreCompleto,
        int HistoriasCompletadas);
}
