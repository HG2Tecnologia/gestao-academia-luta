using AcademiaFight.Domain.Entities.Base;
using AcademiaFight.Domain.Enums;

namespace AcademiaFight.Domain.Entities;

public class AtestadoMedico : EntityBase
{
    public Guid AcademiaId { get; set; }
    public Guid AlunoId { get; set; }

    /// <summary>Base64 do arquivo (PDF ou imagem). Máx 5 MB antes de encodar.</summary>
    public string ArquivoBase64 { get; set; } = string.Empty;
    public string ArquivoMimeType { get; set; } = "application/pdf";
    public string? ArquivoNome { get; set; }

    public StatusAtestado Status { get; set; } = StatusAtestado.Pendente;
    public string? MotivoRejeicao { get; set; }

    public DateTime DataUpload { get; set; } = DateTime.UtcNow;
    public DateTime DataValidade { get; set; }

    /// <summary>True quando a academia/professor anexou o documento (auto-aprovado).</summary>
    public bool AnexadoPorAcademia { get; set; }
    public Guid? AnexadoPorId { get; set; }

    /// <summary>True quando alerta de vencimento próximo já foi enviado (evita duplicatas).</summary>
    public bool AlertaVencimentoEnviado { get; set; }

    public Academia Academia { get; set; } = null!;
    public Usuario Aluno { get; set; } = null!;
}
