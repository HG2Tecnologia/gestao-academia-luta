namespace AcademiaFight.Application.DTOs.Presenca;

public class PresencaDto
{
    public Guid Id { get; set; }
    public Guid AlunoId { get; set; }
    public string NomeAluno { get; set; } = string.Empty;
    public Guid HorarioId { get; set; }
    public string NomeTurma { get; set; } = string.Empty;
    public DateOnly Data { get; set; }
    public TimeOnly HoraCheckin { get; set; }
    public string MetodoCheckin { get; set; } = string.Empty;
    public bool Confirmado { get; set; }
    public string? ObservacoesProfessor { get; set; }
}

public class RegistrarPresencaRequest
{
    public Guid AlunoId { get; set; }
    public Guid HorarioId { get; set; }
    public DateOnly? Data { get; set; }
    public string? ObservacoesProfessor { get; set; }
    public int MetodoCheckin { get; set; } = 1;
}

public class PresencaRelatorioDto
{
    public int TotalAulas { get; set; }
    public double MediaFrequencia { get; set; }
    public IEnumerable<AlunoFrequenciaDto> Alunos { get; set; } = [];
}

public class AlunoFrequenciaDto
{
    public Guid AlunoId { get; set; }
    public string NomeAluno { get; set; } = string.Empty;
    public int Presencas { get; set; }
    public int Faltas { get; set; }
    public double Percentual { get; set; }
}

public class QrTokenResponse
{
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
}
