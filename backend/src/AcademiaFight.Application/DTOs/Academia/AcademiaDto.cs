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
}
