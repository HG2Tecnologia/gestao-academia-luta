using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;

namespace AcademiaFight.Infrastructure.Services;

public class TokenService : ITokenService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<TokenService> _logger;

    private string SecretKey => _configuration["Jwt:SecretKey"]
        ?? throw new InvalidOperationException("Jwt:SecretKey não configurado.");

    private string Issuer => _configuration["Jwt:Issuer"]
        ?? throw new InvalidOperationException("Jwt:Issuer não configurado.");

    private string Audience => _configuration["Jwt:Audience"]
        ?? throw new InvalidOperationException("Jwt:Audience não configurado.");

    public TokenService(IConfiguration configuration, ILogger<TokenService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public string GerarAccessToken(Usuario usuario, Dictionary<string, bool>? permissoes = null)
    {
        var chave = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(SecretKey));
        var credenciais = new SigningCredentials(chave, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, usuario.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, usuario.Email),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new("nome", usuario.Nome),
            new("academia_id", usuario.AcademiaId.ToString()),
            new("perfil", usuario.Perfil.ToString()),
            new(ClaimTypes.Email, usuario.Email),
            new(ClaimTypes.Role, usuario.Perfil.ToString())
        };

        if (permissoes is { Count: > 0 })
            claims.Add(new Claim("permissoes", System.Text.Json.JsonSerializer.Serialize(permissoes)));

        var token = new JwtSecurityToken(
            issuer: Issuer,
            audience: Audience,
            claims: claims,
            notBefore: DateTime.UtcNow,
            expires: DateTime.UtcNow.AddMinutes(15),
            signingCredentials: credenciais);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public string GerarRefreshToken()
    {
        var bytes = new byte[64];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(bytes);
        return Convert.ToBase64String(bytes);
    }

    public ClaimsPrincipal? ObterPrincipalDoTokenExpirado(string token)
    {
        var parametros = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = Issuer,
            ValidateAudience = true,
            ValidAudience = Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(SecretKey)),
            ValidateLifetime = false // Aceitar tokens expirados para o refresh
        };

        try
        {
            var handler = new JwtSecurityTokenHandler();
            var principal = handler.ValidateToken(token, parametros, out var tokenValidado);

            if (tokenValidado is not JwtSecurityToken jwtToken
                || !jwtToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogWarning("Token com algoritmo inválido recebido para refresh");
                return null;
            }

            return principal;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Falha ao validar token expirado para refresh");
            return null;
        }
    }
}
