namespace AcademiaFight.Application.DTOs.Usuario;

public class MeuPerfilDto
{
    public Guid Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? Telefone { get; set; }
    public string Perfil { get; set; } = string.Empty;
}

public class AtualizarMeuPerfilRequest
{
    public string Nome { get; set; } = string.Empty;
    public string? Telefone { get; set; }
}
