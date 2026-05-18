namespace AcademiaFight.Application.DTOs.Ranking;

public class ConquistaDto
{
    public Guid Id { get; set; }
    public string Tipo { get; set; } = string.Empty;
    public string Nome { get; set; } = string.Empty;
    public string Descricao { get; set; } = string.Empty;
    public string IconeUrl { get; set; } = string.Empty;
    public int PontosXpBonus { get; set; }
    public bool Desbloqueada { get; set; }
    public DateTime? DesbloqueadaEm { get; set; }
}
