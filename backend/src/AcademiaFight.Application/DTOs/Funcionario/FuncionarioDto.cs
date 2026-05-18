namespace AcademiaFight.Application.DTOs.Funcionario;

public class FuncionarioDto
{
    public Guid Id { get; set; }
    public Guid UsuarioId { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Telefone { get; set; }
    public string Cargo { get; set; } = string.Empty;
    public string Perfil { get; set; } = string.Empty;
    public bool Ativo { get; set; }
    public List<string> TurmasVinculadas { get; set; } = [];
    public Dictionary<string, bool> Permissoes { get; set; } = new();
    public DateTime DataAdmissao { get; set; }
}

public class CreateFuncionarioDto
{
    public string Nome { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string Telefone { get; set; } = string.Empty;
    public string Cargo { get; set; } = string.Empty;
    public string Perfil { get; set; } = "Professor";
    public Dictionary<string, bool> Permissoes { get; set; } = new();
}

public class UpdateFuncionarioDto : CreateFuncionarioDto
{
    public bool Ativo { get; set; }
}
