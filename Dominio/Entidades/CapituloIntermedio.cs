using Dominio.Excepciones;

namespace Dominio.Entidades
{
    public class CapituloIntermedio : Capitulo
    {
        public List<Opcion> Opciones { get; set; }

        public CapituloIntermedio()
        {
            Opciones = new List<Opcion>();
        }

        public void AgregarOpcion(Opcion opcion)
        {
            opcion.Validar();
            Opciones.Add(opcion);
        }

        public override void ValidarPublicacion()
        {
            base.ValidarPublicacion();

            if (Opciones == null || Opciones.Count == 0)
            {
                throw new CapituloException(
                    $"El capítulo \"{Titulo}\" debe tener al menos una opción.");
            }

            foreach (Opcion opcion in Opciones)
            {
                opcion.Validar();

                if (!Historia.Capitulos.Contains(opcion.Destino))
                {
                    throw new CapituloException(
                        "Todas las opciones deben conducir a un capítulo de la misma historia.");
                }
            }
        }
    }
}
