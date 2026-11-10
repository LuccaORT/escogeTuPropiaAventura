using Aplicacion.DTOs;
using Aplicacion.Interfaces;
using Aplicacion.Mappers;
using Dominio.Entidades;
using Dominio.Enums;
using Dominio.Excepciones;
using Dominio.InterfacesDeRepositorio;

namespace Aplicacion.Servicios
{
    public class ServicioHistoria : IServicioHistoria
    {
        private readonly IRepositorioHistoria _repositorioHistoria;
        private readonly IRepositorioCategoria _repositorioCategoria;
        private readonly IRepositorioLectura _repositorioLectura;
        private readonly IServicioAuditoria _servicioAuditoria;
        private readonly IUnidadDeTrabajo _unidadDeTrabajo;

        public ServicioHistoria(
            IRepositorioHistoria repositorioHistoria,
            IRepositorioCategoria repositorioCategoria,
            IRepositorioLectura repositorioLectura,
            IServicioAuditoria servicioAuditoria,
            IUnidadDeTrabajo unidadDeTrabajo)
        {
            _repositorioHistoria = repositorioHistoria;
            _repositorioCategoria = repositorioCategoria;
            _repositorioLectura = repositorioLectura;
            _servicioAuditoria = servicioAuditoria;
            _unidadDeTrabajo = unidadDeTrabajo;
        }

        // RF03 y RF05 - Crear historia con su capítulo inicial
        public int Crear(HistoriaAltaDTO datos, int administradorId)
        {
            Historia historia = new Historia
            {
                Titulo = datos.Titulo,
                Sinopsis = datos.Sinopsis,
                Categorias = ObtenerCategoriasSeleccionadas(datos.CategoriasIds)
            };

            historia.AsignarCapituloInicial(new CapituloIntermedio
            {
                Titulo = datos.TituloCapituloInicial,
                Texto = datos.TextoCapituloInicial
            });

            historia.Validar();

            _unidadDeTrabajo.Ejecutar(() =>
            {
                _repositorioHistoria.Add(historia);

                _servicioAuditoria.Registrar(
                    "Creación de historia",
                    administradorId,
                    historia.Id);
            });

            return historia.Id;
        }

        // RF03 y RF05 - Editar datos, estado y, si se puede, el capítulo inicial
        public void Editar(HistoriaEdicionDTO datos, int administradorId)
        {
            if (!Enum.TryParse(datos.Estado, out EstadoHistoria estadoNuevo))
            {
                throw new HistoriaException(
                    "El estado seleccionado no es válido.");
            }

            Historia historia = ObtenerEntidad(datos.Id);
            EstadoHistoria estadoAnterior = historia.Estado;

            historia.Titulo = datos.Titulo;
            historia.Sinopsis = datos.Sinopsis;
            historia.Categorias = ObtenerCategoriasSeleccionadas(datos.CategoriasIds);
            historia.Validar();

            bool editaCapituloInicial =
                !string.IsNullOrWhiteSpace(datos.TituloCapituloInicial) ||
                !string.IsNullOrWhiteSpace(datos.TextoCapituloInicial);

            if (editaCapituloInicial)
            {
                historia.EditarCapituloInicial(
                    datos.TituloCapituloInicial ?? string.Empty,
                    datos.TextoCapituloInicial ?? string.Empty);
            }

            bool sePublica =
                estadoAnterior == EstadoHistoria.BORRADOR &&
                estadoNuevo == EstadoHistoria.PUBLICADA;

            bool seDespublica =
                estadoAnterior == EstadoHistoria.PUBLICADA &&
                estadoNuevo == EstadoHistoria.BORRADOR;

            if (sePublica)
            {
                historia.Publicar();
            }
            else if (seDespublica)
            {
                // Una lectura empezada no puede quedar sobre una historia
                // que vuelve a modificarse.
                if (_repositorioLectura.ExistePorHistoria(historia.Id))
                {
                    throw new HistoriaException(
                        "La historia no puede volver a borrador porque tiene lecturas registradas.");
                }

                historia.VolverABorrador();
            }

            _unidadDeTrabajo.Ejecutar(() =>
            {
                _repositorioHistoria.Update(historia);

                _servicioAuditoria.Registrar(
                    sePublica ? "Publicación de historia" : "Edición de historia",
                    administradorId,
                    historia.Id);
            });
        }

        // RF03 - Baja, solo si la historia no tiene lecturas.
        // La auditoría de la historia se conserva.
        public void Eliminar(int id, int administradorId)
        {
            Historia historia = ObtenerEntidad(id);

            if (_repositorioLectura.ExistePorHistoria(id))
            {
                throw new HistoriaException(
                    "No se puede eliminar la historia porque tiene lecturas registradas.");
            }

            _unidadDeTrabajo.Ejecutar(() =>
            {
                _servicioAuditoria.Registrar(
                    "Baja de historia",
                    administradorId,
                    historia.Id);

                _repositorioHistoria.Delete(historia);
            });
        }

        // RF04 y RF05 - Agregar un capítulo a continuación de otro
        public void AgregarCapitulo(CapituloAltaDTO datos, int administradorId)
        {
            Historia historia = ObtenerEntidad(datos.HistoriaId);

            Capitulo nuevo = datos.EsFinal
                ? new CapituloFinal { Titulo = datos.Titulo, Texto = datos.Texto }
                : new CapituloIntermedio { Titulo = datos.Titulo, Texto = datos.Texto };

            historia.AgregarCapitulo(
                datos.CapituloAnteriorId,
                nuevo,
                datos.TextoOpcion);

            _unidadDeTrabajo.Ejecutar(() =>
            {
                _repositorioHistoria.Update(historia);

                _servicioAuditoria.Registrar(
                    datos.EsFinal
                        ? "Creación de capítulo final"
                        : "Creación de capítulo intermedio",
                    administradorId,
                    historia.Id);
            });
        }

        public HistoriaDetalleDTO ObtenerPorId(int id)
        {
            return HistoriaMapper.ToDetalleDTO(ObtenerEntidad(id));
        }

        public IEnumerable<HistoriaResumenDTO> ObtenerTodas()
        {
            return _repositorioHistoria.FindAll()
                .Select(HistoriaMapper.ToResumenDTO)
                .ToList();
        }

        public IEnumerable<CategoriaDTO> ObtenerCategorias()
        {
            return _repositorioCategoria.FindAll()
                .Select(CategoriaMapper.ToDTO)
                .ToList();
        }

        private Historia ObtenerEntidad(int id)
        {
            return _repositorioHistoria.FindById(id)
                ?? throw new EntidadNoEncontradaException("La historia no existe.");
        }

        private List<Categoria> ObtenerCategoriasSeleccionadas(IEnumerable<int> ids)
        {
            List<Categoria> categorias = new List<Categoria>();

            foreach (int id in ids.Distinct())
            {
                Categoria categoria = _repositorioCategoria.FindById(id)
                    ?? throw new CategoriaException(
                        "Una de las categorías seleccionadas no existe.");

                categorias.Add(categoria);
            }

            return categorias;
        }
    }
}
