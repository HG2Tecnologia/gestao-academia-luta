namespace AcademiaFight.Application.DTOs.Plano;

public class PlanoDto
{
    public Guid Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string? Descricao { get; set; }
    public decimal ValorMensal { get; set; }
    public decimal? TaxaMatricula { get; set; }
    public bool Ativo { get; set; }
    public int TotalAlunos { get; set; }
}

public class CreatePlanoDto
{
    public string Nome { get; set; } = string.Empty;
    public string? Descricao { get; set; }
    public decimal ValorMensal { get; set; }
    public decimal? TaxaMatricula { get; set; }
}

public class UpdatePlanoDto : CreatePlanoDto
{
    public bool Ativo { get; set; }
}
