using AcademiaFight.Domain.Entities.Base;

namespace AcademiaFight.Domain.Entities;

public class Modalidade : EntityBase
{
    public Guid AcademiaId { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string? Descricao { get; set; }
    public bool Ativo { get; set; } = true;
    public string? SistemaFaixasJson { get; set; }

    public Academia Academia { get; set; } = null!;
    public ICollection<Turma> Turmas { get; set; } = new List<Turma>();
    public ICollection<Faixa> Faixas { get; set; } = new List<Faixa>();
}
