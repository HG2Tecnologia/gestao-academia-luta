using AcademiaFight.Application.DTOs.Matricula;

namespace AcademiaFight.Application.DTOs.Turma;

public class TurmaDetalheDto
{
    public Guid Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public Guid ModalidadeId { get; set; }
    public string ModalidadeNome { get; set; } = string.Empty;
    public Guid ProfessorId { get; set; }
    public string ProfessorNome { get; set; } = string.Empty;
    public string? Nivel { get; set; }
    public int CapacidadeMaxima { get; set; }
    public bool Ativo { get; set; }
    public int TotalAlunos { get; set; }
    public IEnumerable<MatriculaDto> Alunos { get; set; } = [];
    public IEnumerable<HorarioResumoDto> Horarios { get; set; } = [];
}

public class HorarioResumoDto
{
    public Guid Id { get; set; }
    public int DiaSemana { get; set; }
    public string DiaSemanaLabel { get; set; } = string.Empty;
    public TimeOnly HoraInicio { get; set; }
    public TimeOnly HoraFim { get; set; }
    public string? Sala { get; set; }
}
