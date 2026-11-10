using Aplicacion.DTOs;
using Aplicacion.Interfaces;
using Aplicacion.Mappers;
using Dominio.Entidades;
using Dominio.Excepciones;
using Dominio.InterfacesDeRepositorio;

namespace Aplicacion.Servicios
{
    public class ServicioAuditoria : IServicioAuditoria
    {
        private readonly IRepositorioAuditoria _repositorioAuditoria;
        private readonly IRepositorioUsuario _repositorioUsuario;
        private readonly IRepositorioHistoria _repositorioHistoria;

        public ServicioAuditoria(
            IRepositorioAuditoria repositorioAuditoria,
            IRepositorioUsuario repositorioUsuario,
            IRepositorioHistoria repositorioHistoria)
        {
            _repositorioAuditoria = repositorioAuditoria;
            _repositorioUsuario = repositorioUsuario;
            _repositorioHistoria = repositorioHistoria;
        }

        public void Registrar(
            string accion,
            int administradorId,
            int historiaId)
        {
            Usuario administrador =
                _repositorioUsuario.FindById(administradorId)
                ?? throw new AuditoriaException("El administrador no existe.");

            Historia historia =
                _repositorioHistoria.FindById(historiaId)
                ?? throw new AuditoriaException("La historia no existe.");

            Auditoria auditoria = new Auditoria
            {
                Accion = accion,
                Fecha = DateTime.Now,
                Administrador = administrador,
                Historia = historia,
                TituloHistoria = historia.Titulo
            };

            auditoria.Validar();

            _repositorioAuditoria.Add(auditoria);
        }

        public IEnumerable<AuditoriaDTO> Buscar(
            int? historiaId,
            int? administradorId)
        {
            return _repositorioAuditoria
                .Buscar(historiaId, administradorId)
                .Select(AuditoriaMapper.ToDTO)
                .ToList();
        }
    }
}
