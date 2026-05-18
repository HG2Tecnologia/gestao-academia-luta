namespace AcademiaFight.Application.DTOs.Dashboard;

public class DashboardResumoDto
{
    public int TotalAlunos { get; set; }
    public int TurmasAtivas { get; set; }
    public int PresencasHoje { get; set; }
    public int AlunosInadimplentes { get; set; }
    public IEnumerable<ProximaAulaDto> ProximasAulas { get; set; } = [];
}

public class ProximaAulaDto
{
    public Guid HorarioId { get; set; }
    public string Turma { get; set; } = string.Empty;
    public string Modalidade { get; set; } = string.Empty;
    public TimeOnly HoraInicio { get; set; }
    public TimeOnly HoraFim { get; set; }
    public string? Sala { get; set; }
    public int TotalAlunos { get; set; }
    public int CapacidadeMaxima { get; set; }
}
