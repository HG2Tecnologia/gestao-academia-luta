using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using AcademiaFight.Domain.Enums;
using Microsoft.IdentityModel.Tokens;

namespace AcademiaFight.Tests.Setup;

public static class TestAuthHelper
{
    private const string SecretKey  = "CHAVE_DEV_APENAS_NAO_USAR_EM_PRODUCAO_32_CHARS_OK";
    private const string Issuer     = "AcademiaFightAPI";
    private const string Audience   = "AcademiaFightApp";

    /// <summary>
    /// Gera um JWT com exatamente os mesmos claims que TokenService.GerarAccessToken.
    /// </summary>
    public static string GerarToken(Guid userId, Guid academiaId, string email, string nome, PerfilUsuario perfil)
    {
        var chave = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(SecretKey));
        var credenciais = new SigningCredentials(chave, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub,   userId.ToString()),
            new(JwtRegisteredClaimNames.Email, email),
            new(JwtRegisteredClaimNames.Jti,   Guid.NewGuid().ToString()),
            new("nome",        nome),
            new("academia_id", academiaId.ToString()),
            new("perfil",      perfil.ToString()),
            new(ClaimTypes.Email, email),
            new(ClaimTypes.Role,  perfil.ToString()),
        };

        var token = new JwtSecurityToken(
            issuer:             Issuer,
            audience:           Audience,
            claims:             claims,
            notBefore:          DateTime.UtcNow,
            expires:            DateTime.UtcNow.AddHours(1),
            signingCredentials: credenciais);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
