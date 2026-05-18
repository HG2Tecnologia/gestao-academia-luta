using AcademiaFight.Domain.Entities.Base;
using AcademiaFight.Domain.Enums;

namespace AcademiaFight.Domain.Entities;

public class Presenca : EntityBase
{
    public Guid AcademiaId { get; set; }
    public Guid AlunoId { get; set; }
    public Guid HorarioId { get; set; }
    public DateOnly Data { get; set; }
    public TimeOnly HoraCheckin { get; set; }
    public MetodoCheckin MetodoCheckin { get; set; } = MetodoCheckin.Manual;
    public bool Confirmado { get; set; } = true;
    public string? ObservacoesProfessor { get; set; }

    public Academia Academia { get; set; } = null!;
    public Usuario Aluno { get; set; } = null!;
    public Horario Horario { get; set; } = null!;
}
