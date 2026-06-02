namespace AcademiaFight.Application.DTOs.RankingCustom;

public class RankingCustomDto
{
    public Guid Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string? Descricao { get; set; }
    public bool IncluirPresencas { get; set; }
    public bool IncluirPontosManuais { get; set; }
    public int PesoPresencas { get; set; }
    public int PesoManuais { get; set; }
    public bool VisivelParaAluno { get; set; }
    public bool Ativo { get; set; }
    public DateOnly? DataInicio { get; set; }
    public DateOnly? DataFim { get; set; }
    public DateTime CriadoEm { get; set; }
}
