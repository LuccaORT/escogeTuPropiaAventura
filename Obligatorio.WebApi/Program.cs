using Aplicacion.Interfaces;
using Aplicacion.Servicios;
using Dominio.InterfacesDeRepositorio;
using Infraestructura.Persistencia;
using Infraestructura.Repositorios;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using Obligatorio.WebApi.Manejadores;
using Obligatorio.WebApi.Servicios;
using System.Reflection;
using System.Text;

namespace Obligatorio.WebApi
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Base de datos SQL Server
            builder.Services.AddDbContext<AppDbContext>(options =>
                options.UseSqlServer(
                    builder.Configuration.GetConnectionString("DefaultConnection")
                )
            );

            // Repositorios
            builder.Services.AddScoped<IRepositorioUsuario, RepositorioUsuario>();
            builder.Services.AddScoped<IRepositorioHistoria, RepositorioHistoria>();
            builder.Services.AddScoped<IRepositorioCategoria, RepositorioCategoria>();
            builder.Services.AddScoped<IRepositorioLectura, RepositorioLectura>();
            builder.Services.AddScoped<IRepositorioAuditoria, RepositorioAuditoria>();
            builder.Services.AddScoped<IUnidadDeTrabajo, UnidadDeTrabajo>();

            // Servicios de aplicación
            builder.Services.AddScoped<IServicioUsuario, ServicioUsuario>();
            builder.Services.AddScoped<IServicioHistoria, ServicioHistoria>();
            builder.Services.AddScoped<IServicioAuditoria, ServicioAuditoria>();
            builder.Services.AddScoped<IServicioLectura, ServicioLectura>();
            builder.Services.AddScoped<IServicioMetricas, ServicioMetricas>();
            builder.Services.AddScoped<IServicioToken, ServicioToken>();

            // Convierte las excepciones en códigos de estado HTTP
            builder.Services.AddExceptionHandler<ManejadorExcepciones>();
            builder.Services.AddProblemDetails();

            // RF06 - Autenticación mediante JWT
            var jwtKey = builder.Configuration["Jwt:Key"]
                ?? throw new InvalidOperationException(
                    "No se configuró la clave JWT.");

            builder.Services
                .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddJwtBearer(options =>
                {
                    options.TokenValidationParameters =
                        new TokenValidationParameters
                        {
                            ValidateIssuer = true,
                            ValidateAudience = true,
                            ValidateLifetime = true,
                            ValidateIssuerSigningKey = true,

                            ValidIssuer = builder.Configuration["Jwt:Issuer"],
                            ValidAudience = builder.Configuration["Jwt:Audience"],

                            IssuerSigningKey = new SymmetricSecurityKey(
                                Encoding.UTF8.GetBytes(jwtKey)),

                            ClockSkew = TimeSpan.Zero
                        };
                });

            builder.Services.AddAuthorization();

            builder.Services.AddControllers();

            // Documentación con Swagger, con botón para cargar el token
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen(options =>
            {
                options.SwaggerDoc("v1", new OpenApiInfo
                {
                    Title = "Escoge tu propia aventura - API de lectura",
                    Version = "v1",
                    Description = "Lectura de historias interactivas y métricas."
                });

                options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
                {
                    Type = SecuritySchemeType.Http,
                    Scheme = "bearer",
                    BearerFormat = "JWT",
                    Description = "Pegar el token que devuelve POST /api/Auth/login."
                });

                options.AddSecurityRequirement(documento => new OpenApiSecurityRequirement
                {
                    [new OpenApiSecuritySchemeReference("Bearer", documento)] = new List<string>()
                });

                string archivoXml = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
                options.IncludeXmlComments(Path.Combine(AppContext.BaseDirectory, archivoXml));
            });

            var app = builder.Build();

            app.UseExceptionHandler();

            // Swagger queda habilitado también en el despliegue,
            // porque la consigna permite probar la API con él.
            app.UseSwagger();
            app.UseSwaggerUI();

            app.UseHttpsRedirection();

            app.UseRouting();

            // Autenticación antes de autorización
            app.UseAuthentication();
            app.UseAuthorization();

            app.MapControllers();

            app.Run();
        }
    }
}
