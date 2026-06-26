using AcademiaFight.Domain.Enums;

namespace AcademiaFight.Application.DTOs.Aluno;

public class AlunoDto
{
    public Guid Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? Telefone { get; set; }
    public string? DataNascimento { get; set; }
    public string? ContatoEmergenciaNome { get; set; }
    public string? ContatoEmergenciaTelefone { get; set; }
    public string? TipoPlano { get; set; }
    public Guid? PlanoId { get; set; }
    public string? PlanoNome { get; set; }
    public int? DiaVencimento { get; set; }
    public string? Matricula { get; set; }
    public string? FaixaAtualNome { get; set; }
    public string? FaixaAtualCor { get; set; }
    public string? FaixaAtualCorBarra { get; set; }
    public bool FaixaAtualTemGraus { get; set; }
    public int FaixaAtualMaxGraus { get; set; } = 4;
    public int GrauAtual { get; set; }
    public List<string> Turmas { get; set; } = [];
    public List<TurmaResumoDto> TurmasDetalhes { get; set; } = [];
    public bool Ativo { get; set; }
    public int XpTotal { get; set; }
    public string Nivel { get; set; } = string.Empty;
    public DateTime CriadoEm { get; set; }
    public string? SituacaoFinanceira { get; set; } // "EmDia" | "Pendente" | "Inadimplente"
    public StatusAtestado? StatusAtestado { get; set; }
    public DateTime? AtestadoValidade { get; set; }
    public string? FotoBase64 { get; set; }
}

public class CreateAlunoDto
{
    public string Nome { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string Telefone { get; set; } = string.Empty;
    public string? DataNascimento { get; set; }
    public string? ContatoEmergenciaNome { get; set; }
    public string? ContatoEmergenciaTelefone { get; set; }
    public string? TipoPlano { get; set; }
    public Guid? PlanoId { get; set; }
    public int? DiaVencimento { get; set; }
}

public class UpdateAlunoDto : CreateAlunoDto
{
    public bool Ativo { get; set; }
}

public class TurmaResumoDto
{
    public string Nome { get; set; } = string.Empty;
    public Guid ModalidadeId { get; set; }
    public string NomeModalidade { get; set; } = string.Empty;
    public int TotalPresencas { get; set; }
}

public class AniversarianteDto
{
    public Guid Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public int DiaNascimento { get; set; }
    public int MesNascimento { get; set; }
}
