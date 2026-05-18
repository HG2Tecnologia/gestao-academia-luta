namespace AcademiaFight.Application.DTOs.Ranking;

public class LeaderboardDto
{
    public string Periodo { get; set; } = string.Empty;
    public int TotalParticipantes { get; set; }
    public int Pagina { get; set; }
    public int TamanhoPagina { get; set; }
    public int TotalPaginas { get; set; }
    public IEnumerable<LeaderboardItemDto> Items { get; set; } = [];
}
