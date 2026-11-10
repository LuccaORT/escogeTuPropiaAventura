using Aplicacion.DTOs;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Obligatorio.WebApi.Servicios
{
    public class ServicioToken : IServicioToken
    {
        private readonly IConfiguration _configuracion;

        public ServicioToken(IConfiguration configuracion)
        {
            _configuracion = configuracion;
        }

        public string Generar(UsuarioDTO usuario)
        {
            string clave = _configuracion["Jwt:Key"]
                ?? throw new InvalidOperationException(
                    "No se configuró la clave JWT.");

            int minutos = int.Parse(
                _configuracion["Jwt:ExpirationMinutes"] ?? "60");

            List<Claim> claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, usuario.Id.ToString()),
                new Claim(ClaimTypes.Name, usuario.NombreUsuario),
                new Claim(ClaimTypes.Role, usuario.Rol)
            };

            SigningCredentials credenciales = new SigningCredentials(
                new SymmetricSecurityKey(Encoding.UTF8.GetBytes(clave)),
                SecurityAlgorithms.HmacSha256);

            JwtSecurityToken token = new JwtSecurityToken(
                issuer: _configuracion["Jwt:Issuer"],
                audience: _configuracion["Jwt:Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(minutos),
                signingCredentials: credenciales);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
