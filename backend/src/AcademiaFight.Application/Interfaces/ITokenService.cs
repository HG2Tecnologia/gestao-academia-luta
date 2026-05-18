using System.Security.Claims;
using AcademiaFight.Domain.Entities;

namespace AcademiaFight.Application.Interfaces;

public interface ITokenService
{
    string GerarAccessToken(Usuario usuario, Dictionary<string, bool>? permissoes = null);
    string GerarRefreshToken();
    ClaimsPrincipal? ObterPrincipalDoTokenExpirado(string token);
}
