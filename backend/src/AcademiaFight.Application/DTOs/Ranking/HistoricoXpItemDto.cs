namespace AcademiaFight.Application.DTOs.Ranking;

public class HistoricoXpItemDto
{
    public Guid Id { get; set; }
    public string TipoEvento { get; set; } = string.Empty;
    public int Pontos { get; set; }
    public DateOnly Data { get; set; }
    public DateTime CriadoEm { get; set; }
}
