using AcademiaFight.Application.Interfaces;

namespace AcademiaFight.Infrastructure.Services;

public class BCryptPasswordHasher : IPasswordHasher
{
    private const int WorkFactor = 12;

    public string HashPassword(string senha)
        => BCrypt.Net.BCrypt.HashPassword(senha, WorkFactor);

    public bool VerificarSenha(string senha, string hash)
        => BCrypt.Net.BCrypt.Verify(senha, hash);
}
