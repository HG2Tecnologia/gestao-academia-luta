using AcademiaFight.Domain.Entities.Base;
using AcademiaFight.Domain.Enums;

namespace AcademiaFight.Domain.Entities;

public class PontoRanking : EntityBase
{
    public Guid AcademiaId { get; set; }
    public Guid AlunoId { get; set; }
    public TipoEventoXp TipoEvento { get; set; }
    public int Pontos { get; set; }
    public Guid? ReferenciaId { get; set; }
    public DateOnly Data { get; set; }

    public Usuario Aluno { get; set; } = null!;
}
