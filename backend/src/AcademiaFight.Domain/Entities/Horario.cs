using AcademiaFight.Domain.Entities.Base;
using AcademiaFight.Domain.Enums;

namespace AcademiaFight.Domain.Entities;

public class Horario : EntityBase
{
    public Guid AcademiaId { get; set; }
    public Guid TurmaId { get; set; }
    public DiaSemana DiaSemana { get; set; }
    public TimeOnly HoraInicio { get; set; }
    public TimeOnly HoraFim { get; set; }
    public string? Sala { get; set; }

    public Academia Academia { get; set; } = null!;
    public Turma Turma { get; set; } = null!;
    public ICollection<Presenca> Presencas { get; set; } = new List<Presenca>();
}
