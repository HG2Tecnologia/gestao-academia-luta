namespace AcademiaFight.Application.DTOs.Graduacao;

public class GraduacaoDto
{
    public Guid Id { get; set; }
    public Guid AlunoId { get; set; }
    public string NomeAluno { get; set; } = string.Empty;
    public Guid FaixaId { get; set; }
    public string NomeFaixa { get; set; } = string.Empty;
    public string CorFaixa { get; set; } = "#FFFFFF";
    public Guid ModalidadeId { get; set; }
    public string NomeModalidade { get; set; } = string.Empty;
    public DateOnly DataExame { get; set; }
    public bool Aprovado { get; set; }
    public Guid ProfessorId { get; set; }
    public string NomeProfessor { get; set; } = string.Empty;
    public string? Observacoes { get; set; }
    public string? CertificadoUrl { get; set; }
}

public class RegistrarGraduacaoRequest
{
    public Guid AlunoId { get; set; }
    public Guid FaixaId { get; set; }
    public DateOnly DataExame { get; set; }
    public Guid ProfessorId { get; set; }
    public bool Aprovado { get; set; }
    public string? Observacoes { get; set; }
}

public class AlunoAptoDto
{
    public Guid AlunoId { get; set; }
    public string NomeAluno { get; set; } = string.Empty;
    public string EmailAluno { get; set; } = string.Empty;
    public int MesesMatriculado { get; set; }
    public int TotalPresencas { get; set; }
    public int MesesNecessarios { get; set; }
    public int PresencasNecessarias { get; set; }
}
