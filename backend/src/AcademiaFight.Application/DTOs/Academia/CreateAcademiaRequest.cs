namespace AcademiaFight.Application.DTOs.Academia;

public class CreateAcademiaRequest
{
    public string Nome { get; set; } = string.Empty;
    public string Subdominio { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Telefone { get; set; }
    public string? LogoUrl { get; set; }
}

public class UpdateAcademiaRequest
{
    public string Nome { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Telefone { get; set; }
    public string? LogoUrl { get; set; }
    public string? Cnpj { get; set; }
    public string? TemplateContrato { get; set; }
}

public class UpdateTemplateContratoRequest
{
    public string? Template { get; set; }
}
