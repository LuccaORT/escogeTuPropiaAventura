using Dominio.Entidades;
using Dominio.ValueObjects;
using Microsoft.EntityFrameworkCore;

namespace Infraestructura.Persistencia
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options)
        {
        }

        public DbSet<Usuario> Usuarios { get; set; }

        public DbSet<Categoria> Categorias { get; set; }

        public DbSet<Historia> Historias { get; set; }

        public DbSet<Capitulo> Capitulos { get; set; }

        public DbSet<CapituloIntermedio> CapitulosIntermedios { get; set; }

        public DbSet<CapituloFinal> CapitulosFinales { get; set; }

        public DbSet<Opcion> Opciones { get; set; }

        public DbSet<Lectura> Lecturas { get; set; }

        public DbSet<Auditoria> Auditorias { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<Usuario>(usuario =>
            {
                usuario.Property(u => u.NombreCompleto).HasMaxLength(Usuario.LargoMaximoNombreCompleto);
                usuario.Property(u => u.Email).HasMaxLength(Usuario.LargoMaximoEmail);
                usuario.Property(u => u.NombreUsuario).HasMaxLength(Usuario.LargoMaximoNombreUsuario);
                usuario.Property(u => u.Contrasena).HasMaxLength(Usuario.LargoMaximoContrasena);

                usuario.HasIndex(u => u.NombreUsuario).IsUnique();
                usuario.HasIndex(u => u.Email).IsUnique();

                // RF12 - El Value Object se guarda como una columna de Usuarios
                usuario.OwnsOne(u => u.EstiloLectura, estilo =>
                {
                    estilo.Property(e => e.Valor)
                        .HasColumnName("EstiloLectura")
                        .HasMaxLength(EstiloLectura.LargoMaximo)
                        .HasDefaultValue(EstiloLectura.Claro);
                });

                usuario.Navigation(u => u.EstiloLectura).IsRequired();
            });

            modelBuilder.Entity<Categoria>()
                .Property(c => c.Nombre).HasMaxLength(Categoria.LargoMaximoNombre);

            modelBuilder.Entity<Historia>(historia =>
            {
                historia.Property(h => h.Titulo).HasMaxLength(Historia.LargoMaximoTitulo);
                historia.Property(h => h.Sinopsis).HasMaxLength(Historia.LargoMaximoSinopsis);

                historia.HasMany(h => h.Capitulos)
                    .WithOne(c => c.Historia);

                historia.HasOne(h => h.CapituloInicial)
                    .WithMany()
                    .OnDelete(DeleteBehavior.NoAction);

                historia.HasMany(h => h.Categorias)
                    .WithMany();
            });

            modelBuilder.Entity<Capitulo>()
                .Property(c => c.Titulo).HasMaxLength(Capitulo.LargoMaximoTitulo);

            modelBuilder.Entity<CapituloIntermedio>()
                .HasMany(c => c.Opciones)
                .WithOne()
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Opcion>(opcion =>
            {
                opcion.Property(o => o.Texto).HasMaxLength(Opcion.LargoMaximoTexto);

                opcion.HasOne(o => o.Destino)
                    .WithMany()
                    .OnDelete(DeleteBehavior.NoAction);
            });

            modelBuilder.Entity<Lectura>(lectura =>
            {
                lectura.HasOne(l => l.Usuario)
                    .WithMany()
                    .OnDelete(DeleteBehavior.NoAction);

                lectura.HasOne(l => l.Historia)
                    .WithMany()
                    .OnDelete(DeleteBehavior.NoAction);

                lectura.HasOne(l => l.CapituloActual)
                    .WithMany()
                    .OnDelete(DeleteBehavior.NoAction);

                lectura.HasOne(l => l.FinalAlcanzado)
                    .WithMany()
                    .OnDelete(DeleteBehavior.NoAction);
            });

            modelBuilder.Entity<Auditoria>(auditoria =>
            {
                auditoria.Property(a => a.Accion).HasMaxLength(Auditoria.LargoMaximoAccion);
                auditoria.Property(a => a.TituloHistoria).HasMaxLength(Historia.LargoMaximoTitulo);

                auditoria.HasOne(a => a.Administrador)
                    .WithMany()
                    .OnDelete(DeleteBehavior.NoAction);

                // La auditoría sobrevive a la baja de la historia.
                auditoria.HasOne(a => a.Historia)
                    .WithMany()
                    .IsRequired(false)
                    .OnDelete(DeleteBehavior.SetNull);
            });
        }
    }
}
