namespace AcademiaFight.Application.DTOs.Auth;

public class RegisterRequest
{
    public string Nome { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Senha { get; set; } = string.Empty;
    public string NomeAcademia { get; set; } = string.Empty;
    public string Subdominio { get; set; } = string.Empty;
    public string? EmailAcademia { get; set; }
    public string? Telefone { get; set; }
}
