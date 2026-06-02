namespace AcademiaFight.Application.DTOs.RankingCustom;

public class LeaderboardCustomItemDto
{
    public int Posicao { get; set; }
    public Guid AlunoId { get; set; }
    public string NomeAluno { get; set; } = string.Empty;
    public int PontosPresencas { get; set; }
    public int PontosManuais { get; set; }
    public int TotalPontos { get; set; }
}
