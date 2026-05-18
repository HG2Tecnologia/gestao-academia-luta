using AcademiaFight.Domain.Entities.Base;

namespace AcademiaFight.Domain.Entities;

public class ConquistaAluno : EntityBase
{
    public Guid AcademiaId { get; set; }
    public Guid AlunoId { get; set; }
    public Guid ConquistaId { get; set; }
    public DateTime DesbloqueadaEm { get; set; }
    public bool VistaPeloAluno { get; set; }

    public Usuario Aluno { get; set; } = null!;
    public Conquista Conquista { get; set; } = null!;
}
