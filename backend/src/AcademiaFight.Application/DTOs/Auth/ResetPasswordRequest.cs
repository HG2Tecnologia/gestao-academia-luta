namespace AcademiaFight.Application.DTOs.Auth;

public record ResetPasswordRequest(string Token, string NovaSenha);
