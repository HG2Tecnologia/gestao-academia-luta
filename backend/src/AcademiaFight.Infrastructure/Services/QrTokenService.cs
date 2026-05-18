using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using AcademiaFight.Application.DTOs.Presenca;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Application.Helpers;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace AcademiaFight.Infrastructure.Services;

public class QrTokenService : IQrTokenService
{
    private readonly IConfiguration _config;

    private string QrKey => _config["Jwt:QrSecretKey"] ?? _config["Jwt:SecretKey"]
        ?? throw new InvalidOperationException("Jwt:SecretKey não configurado.");

    public QrTokenService(IConfiguration config)
    {
        _config = config;
    }

    public QrTokenResponse GerarToken(Guid alunoId, Guid academiaId)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(QrKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expira = DateTimeHelper.Agora().AddHours(24);

        var token = new JwtSecurityToken(
            issuer: "AcademiaFightQR",
            audience: "AcademiaFightApp",
            claims:
            [
                new Claim("aluno_id", alunoId.ToString()),
                new Claim("academia_id", academiaId.ToString())
            ],
            expires: expira,
            signingCredentials: creds
        );

        return new QrTokenResponse
        {
            Token = new JwtSecurityTokenHandler().WriteToken(token),
            ExpiresAt = expira
        };
    }

    public Guid? ValidarToken(string token)
    {
        try
        {
            var handler = new JwtSecurityTokenHandler();
            var principal = handler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = "AcademiaFightQR",
                ValidateAudience = true,
                ValidAudience = "AcademiaFightApp",
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(QrKey)),
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            }, out _);

            var alunoIdStr = principal.FindFirstValue("aluno_id");
            return Guid.TryParse(alunoIdStr, out var id) ? id : null;
        }
        catch
        {
            return null;
        }
    }
}
