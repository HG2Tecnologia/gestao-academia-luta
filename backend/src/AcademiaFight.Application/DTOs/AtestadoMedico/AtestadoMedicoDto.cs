using AcademiaFight.Domain.Enums;

namespace AcademiaFight.Application.DTOs.AtestadoMedico;

public class AtestadoMedicoDto
{
    public Guid Id { get; set; }
    public Guid AlunoId { get; set; }
    public string AlunoNome { get; set; } = string.Empty;
    public StatusAtestado Status { get; set; }
    public string? MotivoRejeicao { get; set; }
    public DateTime DataUpload { get; set; }
    public DateTime DataValidade { get; set; }
    public bool AnexadoPorAcademia { get; set; }
    public string ArquivoMimeType { get; set; } = "application/pdf";
    public string? ArquivoNome { get; set; }
    public DateTime CriadoEm { get; set; }

    public bool VencendoEmBreve =>
        Status == StatusAtestado.Aprovado &&
        DataValidade <= DateTime.UtcNow.AddDays(7);
}

public class AtestadoMedicoComArquivoDto : AtestadoMedicoDto
{
    public string ArquivoBase64 { get; set; } = string.Empty;
}

public class UploadAtestadoRequest
{
    public string ArquivoBase64 { get; set; } = string.Empty;
    public string ArquivoMimeType { get; set; } = "application/pdf";
    public string? ArquivoNome { get; set; }
}

public class UploadAtestadoPorAcademiaRequest : UploadAtestadoRequest
{
    public Guid AlunoId { get; set; }
}

public class AvaliarAtestadoRequest
{
    public bool Aprovado { get; set; }
    public string? MotivoRejeicao { get; set; }
}
