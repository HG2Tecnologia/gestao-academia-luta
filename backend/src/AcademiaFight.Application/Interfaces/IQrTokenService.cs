using AcademiaFight.Application.DTOs.Presenca;

namespace AcademiaFight.Application.Interfaces;

public interface IQrTokenService
{
    QrTokenResponse GerarToken(Guid alunoId, Guid academiaId);
    Guid? ValidarToken(string token);
}
