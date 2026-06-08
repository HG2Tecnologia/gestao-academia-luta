namespace AcademiaFight.Application.DTOs.Academia;

public class AcademiaDto
{
    public Guid Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string Subdominio { get; set; } = string.Empty;
    public string? LogoUrl { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? Telefone { get; set; }
    public bool Ativo { get; set; }
    public string? Cnpj { get; set; }
    public DateTime CriadoEm { get; set; }
    public string? TemplateContrato { get; set; }
    public string PlanoTipo { get; set; } = "Gratuito";
    public DateTime? PlanoExpiracao { get; set; }
    public int LimiteAlunos { get; set; }
    public int LimiteTurmas { get; set; }
    public int TotalAlunos { get; set; }
    public int TotalTurmas { get; set; }
}

public class AtivarPlanoProRequest
{
    public DateTime? Expiracao { get; set; }
}
