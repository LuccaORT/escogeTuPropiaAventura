using Dominio.Enums;
using Dominio.Excepciones;
using Dominio.Interfaces;

namespace Dominio.Entidades
{
    public class Historia : IValidable
    {
        public const int LargoMaximoTitulo = 200;
        public const int LargoMaximoSinopsis = 2000;

        public int Id { get; set; }

        public string Titulo { get; set; } = string.Empty;

        public string Sinopsis { get; set; } = string.Empty;

        public EstadoHistoria Estado { get; set; }

        public int? CapituloInicialId { get; set; }

        public CapituloIntermedio? CapituloInicial { get; set; }

        public List<Categoria> Categorias { get; set; }

        public List<Capitulo> Capitulos { get; set; }

        public Historia()
        {
            Categorias = new List<Categoria>();
            Capitulos = new List<Capitulo>();
            Estado = EstadoHistoria.BORRADOR;
        }

        // El capítulo inicial solo puede ser intermedio: lo garantiza el tipo.
        public void AsignarCapituloInicial(CapituloIntermedio capitulo)
        {
            if (CapituloInicial != null)
            {
                throw new HistoriaException(
                    "La historia ya tiene un capítulo inicial.");
            }

            capitulo.Historia = this;
            capitulo.Validar();

            CapituloInicial = capitulo;
            Capitulos.Add(capitulo);
        }

        // RF03 - Solo se modifica mientras no existan otros capítulos.
        public void EditarCapituloInicial(string titulo, string texto)
        {
            if (Capitulos.Count > 1)
            {
                throw new CapituloException(
                    "El capítulo inicial no puede modificarse porque la historia ya tiene otros capítulos.");
            }

            if (CapituloInicial == null)
            {
                throw new HistoriaException(
                    "La historia no tiene capítulo inicial.");
            }

            CapituloInicial.Titulo = titulo;
            CapituloInicial.Texto = texto;
            CapituloInicial.Validar();
        }

        // RF04 - Agrega el capítulo y crea la opción que lleva a él
        // en el capítulo antecedente.
        public void AgregarCapitulo(
            int capituloAnteriorId,
            Capitulo nuevo,
            string textoOpcion)
        {
            if (Estado == EstadoHistoria.PUBLICADA)
            {
                throw new HistoriaException(
                    "No se pueden agregar capítulos a una historia publicada.");
            }

            CapituloIntermedio? anterior = Capitulos
                .OfType<CapituloIntermedio>()
                .FirstOrDefault(c => c.Id == capituloAnteriorId);

            if (anterior == null)
            {
                throw new CapituloException(
                    "El capítulo anterior no existe en esta historia o es un capítulo final.");
            }

            nuevo.Historia = this;
            nuevo.Validar();

            anterior.AgregarOpcion(new Opcion
            {
                Texto = textoOpcion,
                Destino = nuevo
            });

            Capitulos.Add(nuevo);
        }

        public void Publicar()
        {
            ValidarPublicacion();
            Estado = EstadoHistoria.PUBLICADA;
        }

        public void VolverABorrador()
        {
            Estado = EstadoHistoria.BORRADOR;
        }

        public void Validar()
        {
            if (string.IsNullOrWhiteSpace(Titulo))
            {
                throw new HistoriaException(
                    "El título de la historia es obligatorio.");
            }

            if (Titulo.Length > LargoMaximoTitulo)
            {
                throw new HistoriaException(
                    $"El título de la historia no puede superar los {LargoMaximoTitulo} caracteres.");
            }

            if (string.IsNullOrWhiteSpace(Sinopsis))
            {
                throw new HistoriaException(
                    "La sinopsis de la historia es obligatoria.");
            }

            if (Sinopsis.Length > LargoMaximoSinopsis)
            {
                throw new HistoriaException(
                    $"La sinopsis no puede superar los {LargoMaximoSinopsis} caracteres.");
            }

            if (Categorias == null || Categorias.Count == 0)
            {
                throw new HistoriaException(
                    "La historia debe tener al menos una categoría.");
            }

            if (CapituloInicial == null)
            {
                throw new HistoriaException(
                    "La historia debe tener un capítulo inicial.");
            }
        }

        public void ValidarPublicacion()
        {
            Validar();

            foreach (Capitulo capitulo in Capitulos)
            {
                capitulo.ValidarPublicacion();
            }

            if (!Capitulos.OfType<CapituloFinal>().Any())
            {
                throw new HistoriaException(
                    "La historia debe tener al menos un capítulo final para poder publicarse.");
            }
        }
    }
}
