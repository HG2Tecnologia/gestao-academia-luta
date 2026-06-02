namespace AcademiaFight.Application.DTOs.RankingCustom;

public class LancamentoPontoDto
{
    public Guid Id { get; set; }
    public Guid AlunoId { get; set; }
    public string NomeAluno { get; set; } = string.Empty;
    public int Pontos { get; set; }
    public string Descricao { get; set; } = string.Empty;
    public string NomeRegistradoPor { get; set; } = string.Empty;
    public DateOnly Data { get; set; }
    public DateTime CriadoEm { get; set; }
}
