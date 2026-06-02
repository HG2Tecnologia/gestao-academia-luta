using AcademiaFight.Domain.Entities.Base;

namespace AcademiaFight.Domain.Entities;

public class LancamentoPonto : EntityBase
{
    public Guid RankingCustomId { get; set; }
    public Guid AlunoId { get; set; }
    public Guid AcademiaId { get; set; }
    public int Pontos { get; set; }
    public string Descricao { get; set; } = string.Empty;
    public Guid RegistradoPorId { get; set; }
    public DateOnly Data { get; set; } = DateOnly.FromDateTime(DateTime.UtcNow);

    public RankingCustom RankingCustom { get; set; } = null!;
    public Usuario Aluno { get; set; } = null!;
    public Usuario RegistradoPor { get; set; } = null!;
}
