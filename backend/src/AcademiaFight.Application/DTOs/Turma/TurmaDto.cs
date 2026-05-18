namespace AcademiaFight.Application.DTOs.Turma;

public class TurmaDto
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
}

public class CreateTurmaRequest
{
    public Guid ModalidadeId { get; set; }
    public Guid ProfessorId { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string? Nivel { get; set; }
    public int CapacidadeMaxima { get; set; }
}

public class UpdateTurmaRequest
{
    public Guid ModalidadeId { get; set; }
    public Guid ProfessorId { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string? Nivel { get; set; }
    public int CapacidadeMaxima { get; set; }
    public bool Ativo { get; set; }
}
