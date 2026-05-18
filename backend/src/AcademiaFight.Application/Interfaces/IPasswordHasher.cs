namespace AcademiaFight.Application.Interfaces;

public interface IPasswordHasher
{
    string HashPassword(string senha);
    bool VerificarSenha(string senha, string hash);
}
