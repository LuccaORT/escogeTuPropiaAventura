using Aplicacion.DTOs;
using Aplicacion.Interfaces;
using Aplicacion.Mappers;
using Dominio.Entidades;
using Dominio.Enums;
using Dominio.Excepciones;
using Dominio.InterfacesDeRepositorio;

namespace Aplicacion.Servicios
{
    public class ServicioLectura : IServicioLectura
    {
        private readonly IRepositorioLectura _repositorioLectura;
        private readonly IRepositorioHistoria _repositorioHistoria;
        private readonly IRepositorioUsuario _repositorioUsuario;

        public ServicioLectura(
            IRepositorioLectura repositorioLectura,
            IRepositorioHistoria repositorioHistoria,
            IRepositorioUsuario repositorioUsuario)
        {
            _repositorioLectura = repositorioLectura;
            _repositorioHistoria = repositorioHistoria;
            _repositorioUsuario = repositorioUsuario;
        }

        // RF07 - Historias publicadas, filtrables por categoría
        public IEnumerable<HistoriaResumenDTO> ObtenerHistoriasPublicadas(int? categoriaId)
        {
            return _repositorioHistoria.FindPublicadas(categoriaId)
                .Select(HistoriaMapper.ToResumenDTO)
                .ToList();
        }

        // RF07 - Cada inicio crea una lectura nueva
        public LecturaDetalleDTO Iniciar(int usuarioId, int historiaId)
        {
            Usuario usuario = ObtenerUsuario(usuarioId);

            Historia historia = _repositorioHistoria.FindById(historiaId)
                ?? throw new EntidadNoEncontradaException("La historia no existe.");

            if (historia.Estado != EstadoHistoria.PUBLICADA)
            {
                throw new LecturaException(
                    "Solo se pueden leer historias publicadas.");
            }

            if (historia.CapituloInicial == null)
            {
                throw new LecturaException(
                    "La historia no tiene capítulo inicial.");
            }

            Lectura lectura = new Lectura
            {
                Usuario = usuario,
                Historia = historia,
                CapituloActual = historia.CapituloInicial,
                FechaInicio = DateTime.Now
            };

            lectura.Validar();

            _repositorioLectura.Add(lectura);

            return LecturaMapper.ToDetalleDTO(lectura);
        }

        public LecturaDetalleDTO Obtener(int lecturaId, int usuarioId)
        {
            return LecturaMapper.ToDetalleDTO(
                ObtenerEntidad(lecturaId, usuarioId));
        }

        // RF07 - Elegir una opción; al llegar a un final queda registrado
        public LecturaDetalleDTO Avanzar(int lecturaId, int usuarioId, int opcionId)
        {
            Lectura lectura = ObtenerEntidad(lecturaId, usuarioId);

            lectura.Avanzar(opcionId);
            lectura.Validar();

            _repositorioLectura.Update(lectura);

            // Se vuelve a consultar porque solo estaban cargadas las opciones
            // del capítulo anterior, no las del capítulo al que se llegó.
            return Obtener(lecturaId, usuarioId);
        }

        // RF08 - Lecturas del usuario en un mes y año
        public IEnumerable<LecturaDTO> ObtenerHistorial(int usuarioId, int mes, int anio)
        {
            if (mes < 1 || mes > 12)
            {
                throw new LecturaException(
                    "El mes debe estar entre 1 y 12.");
            }

            if (anio < 1 || anio > 9999)
            {
                throw new LecturaException(
                    "El año ingresado no es válido.");
            }

            ObtenerUsuario(usuarioId);

            return _repositorioLectura
                .FindByUsuarioMesAnio(usuarioId, mes, anio)
                .Select(LecturaMapper.ToDTO)
                .ToList();
        }

        private Usuario ObtenerUsuario(int usuarioId)
        {
            return _repositorioUsuario.FindById(usuarioId)
                ?? throw new EntidadNoEncontradaException("El usuario no existe.");
        }

        // Una lectura ajena se trata igual que una inexistente:
        // no se revela que existe.
        private Lectura ObtenerEntidad(int lecturaId, int usuarioId)
        {
            Lectura? lectura = _repositorioLectura.FindById(lecturaId);

            if (lectura == null || lectura.Usuario.Id != usuarioId)
            {
                throw new EntidadNoEncontradaException(
                    "La lectura no existe o no pertenece al usuario.");
            }

            return lectura;
        }
    }
}
