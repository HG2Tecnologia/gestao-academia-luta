namespace AcademiaFight.Application.DTOs.Dashboard;

public class AlunoProximoGraduacaoDto
{
    public Guid AlunoId { get; set; }
    public string NomeAluno { get; set; } = string.Empty;
    public string NomeModalidade { get; set; } = string.Empty;
    public string NomeFaixaAtual { get; set; } = string.Empty;
    public string CorFaixaAtual { get; set; } = "#FFFFFF";
    public int TotalPresencas { get; set; }
    public int PresencasNecessarias { get; set; }
    public bool JaApto { get; set; }
    public int Percentual { get; set; }
}
