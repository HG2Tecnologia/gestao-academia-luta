namespace AcademiaFight.Application.DTOs.Horario;

public class HorarioDto
{
    public Guid Id { get; set; }
    public Guid TurmaId { get; set; }
    public string NomeTurma { get; set; } = string.Empty;
    public string NomeModalidade { get; set; } = string.Empty;
    public string NomeProfessor { get; set; } = string.Empty;
    public int DiaSemana { get; set; }
    public string DiaSemanaLabel { get; set; } = string.Empty;
    public TimeOnly HoraInicio { get; set; }
    public TimeOnly HoraFim { get; set; }
    public string? Sala { get; set; }
    public int TotalAlunos { get; set; }
    public int CapacidadeMaxima { get; set; }
}

public class CreateHorarioRequest
{
    public Guid TurmaId { get; set; }
    public int DiaSemana { get; set; }
    public TimeOnly HoraInicio { get; set; }
    public TimeOnly HoraFim { get; set; }
    public string? Sala { get; set; }
}

public class GradeHorariosDto
{
    public Dictionary<string, List<HorarioDto>> Grade { get; set; } = new();
}
