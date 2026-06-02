namespace AcademiaFight.Application.DTOs.RankingCustom;

public class LeaderboardCustomDto
{
    public Guid RankingId { get; set; }
    public string NomeRanking { get; set; } = string.Empty;
    public string? Descricao { get; set; }
    public bool IncluirPresencas { get; set; }
    public bool IncluirPontosManuais { get; set; }
    public int PesoPresencas { get; set; }
    public int PesoManuais { get; set; }
    public DateOnly? DataInicio { get; set; }
    public DateOnly? DataFim { get; set; }
    public int TotalParticipantes { get; set; }
    public int Pagina { get; set; }
    public int TamanhoPagina { get; set; }
    public int TotalPaginas { get; set; }
    public IEnumerable<LeaderboardCustomItemDto> Items { get; set; } = [];
}
