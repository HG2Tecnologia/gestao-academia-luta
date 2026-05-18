namespace AcademiaFight.Application.DTOs.Ranking;

public class LeaderboardItemDto
{
    public int Posicao { get; set; }
    public Guid AlunoId { get; set; }
    public string NomeAluno { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public string Nivel { get; set; } = string.Empty;
    public int XpPeriodo { get; set; }
    public int XpTotal { get; set; }
    public int TotalConquistas { get; set; }
    public int Variacao { get; set; }
}
