using AcademiaFight.Domain.Entities.Base;

namespace AcademiaFight.Domain.Entities;

public class Plano : EntityBase
{
    public Guid AcademiaId { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string? Descricao { get; set; }
    public decimal ValorMensal { get; set; }
    public decimal? TaxaMatricula { get; set; }
    public bool Ativo { get; set; } = true;

    public Academia Academia { get; set; } = null!;
    public ICollection<Usuario> Alunos { get; set; } = new List<Usuario>();
}
