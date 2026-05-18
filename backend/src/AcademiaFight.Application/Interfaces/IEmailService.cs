namespace AcademiaFight.Application.Interfaces;

public interface IEmailService
{
    Task EnviarRecuperacaoSenhaAsync(string email, string nome, string token, CancellationToken ct = default);
}
