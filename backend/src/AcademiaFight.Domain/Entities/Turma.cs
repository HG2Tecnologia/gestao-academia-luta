using AcademiaFight.Domain.Entities.Base;

namespace AcademiaFight.Domain.Entities;

public class Turma : EntityBase
{
    public Guid AcademiaId { get; set; }
    public Guid ModalidadeId { get; set; }
    public Guid ProfessorId { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string? Nivel { get; set; }
    public int CapacidadeMaxima { get; set; }
    public bool Ativo { get; set; } = true;

    public Academia Academia { get; set; } = null!;
    public Modalidade Modalidade { get; set; } = null!;
    public Usuario Professor { get; set; } = null!;
    public ICollection<Horario> Horarios { get; set; } = new List<Horario>();
    public ICollection<Matricula> Matriculas { get; set; } = new List<Matricula>();
}
