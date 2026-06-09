namespace AcademiaFight.Application.DTOs.Presenca;

public class AlunoQrInfoDto
{
    public Guid AlunoId { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string FaixaNome { get; set; } = string.Empty;
    public string FaixaCor { get; set; } = "#888888";
    public List<string> Turmas { get; set; } = [];
    public int TotalPresencasMes { get; set; }
    public bool TemAulaAgora { get; set; }
    public Guid? HorarioAtivoId { get; set; }
}
