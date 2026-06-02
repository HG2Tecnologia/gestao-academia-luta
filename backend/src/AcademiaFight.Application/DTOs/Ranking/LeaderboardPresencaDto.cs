namespace AcademiaFight.Application.DTOs.Ranking;

public class LeaderboardPresencaDto
{
    public string Escopo { get; set; } = string.Empty;
    public string NomeEscopo { get; set; } = string.Empty;
    public DateOnly? DataInicio { get; set; }
    public DateOnly? DataFim { get; set; }
    public int TotalParticipantes { get; set; }
    public int Pagina { get; set; }
    public int TamanhoPagina { get; set; }
    public int TotalPaginas { get; set; }
    public IEnumerable<LeaderboardPresencaItemDto> Items { get; set; } = [];
}

public class LeaderboardPresencaItemDto
{
    public int Posicao { get; set; }
    public Guid AlunoId { get; set; }
    public string NomeAluno { get; set; } = string.Empty;
    public int TotalPresencas { get; set; }
}
