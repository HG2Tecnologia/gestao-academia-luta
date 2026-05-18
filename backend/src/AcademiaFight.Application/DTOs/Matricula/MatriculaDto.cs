namespace AcademiaFight.Application.DTOs.Matricula;

public class MatriculaDto
{
    public Guid Id { get; set; }
    public Guid AlunoId { get; set; }
    public string NomeAluno { get; set; } = string.Empty;
    public string EmailAluno { get; set; } = string.Empty;
    public Guid TurmaId { get; set; }
    public string NomeTurma { get; set; } = string.Empty;
    public DateOnly DataInicio { get; set; }
    public DateOnly? DataFim { get; set; }
    public bool Ativo { get; set; }
}

public class CreateMatriculaRequest
{
    public Guid AlunoId { get; set; }
    public Guid TurmaId { get; set; }
    public DateOnly? DataInicio { get; set; }
}
