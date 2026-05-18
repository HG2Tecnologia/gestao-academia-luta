using AcademiaFight.Domain.Entities.Base;

namespace AcademiaFight.Domain.Entities;

public class Graduacao : EntityBase
{
    public Guid AcademiaId { get; set; }
    public Guid AlunoId { get; set; }
    public Guid FaixaId { get; set; }
    public DateOnly DataExame { get; set; }
    public bool Aprovado { get; set; }
    public Guid ProfessorId { get; set; }
    public string? Observacoes { get; set; }
    public string? CertificadoUrl { get; set; }

    public Academia Academia { get; set; } = null!;
    public Usuario Aluno { get; set; } = null!;
    public Faixa Faixa { get; set; } = null!;
    public Usuario Professor { get; set; } = null!;
}
