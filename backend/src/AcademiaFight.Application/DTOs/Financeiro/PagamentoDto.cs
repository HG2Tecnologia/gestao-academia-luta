namespace AcademiaFight.Application.DTOs.Financeiro;

public class PagamentoDto
{
    public Guid Id { get; set; }
    public Guid AlunoId { get; set; }
    public string NomeAluno { get; set; } = string.Empty;
    public string? TelefoneAluno { get; set; }
    public string Tipo { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public decimal Valor { get; set; }
    public string? Descricao { get; set; }
    public string? DataVencimento { get; set; }
    public string? DataPagamento { get; set; }
    public string? FormaPagamento { get; set; }
    public string? Observacoes { get; set; }
    public DateTime CriadoEm { get; set; }
}

public class CreatePagamentoDto
{
    public Guid AlunoId { get; set; }
    public int Tipo { get; set; }
    public int Status { get; set; } = 1;
    public decimal Valor { get; set; }
    public string? Descricao { get; set; }
    public string? DataVencimento { get; set; }
    public string? DataPagamento { get; set; }
    public string? FormaPagamento { get; set; }
    public string? Observacoes { get; set; }
}

public class UpdatePagamentoDto
{
    public int Status { get; set; }
    public string? DataPagamento { get; set; }
    public string? FormaPagamento { get; set; }
    public string? Observacoes { get; set; }
}

public class ResumoFinanceiroDto
{
    public decimal TotalRecebidoMes { get; set; }
    public decimal TotalPendenteMes { get; set; }
    public decimal TotalAtrasado { get; set; }
    public int TotalAlunos { get; set; }
    public int AlunosInadimplentes { get; set; }
    public int AlunosEmDia { get; set; }
    public List<PagamentoDto> PagamentosRecentes { get; set; } = [];
    public List<AlunoInadimplenteDto> Inadimplentes { get; set; } = [];
}

public class AlunoInadimplenteDto
{
    public Guid AlunoId { get; set; }
    public string NomeAluno { get; set; } = string.Empty;
    public decimal TotalDevido { get; set; }
    public int DiasAtraso { get; set; }
    public string? UltimoVencimento { get; set; }
}

public class ReceitaMensalDto
{
    public int Ano { get; set; }
    public int Mes { get; set; }
    public decimal Recebido { get; set; }
    public decimal Pendente { get; set; }
    public decimal Atrasado { get; set; }
}

public class FrequenciaMensalDto
{
    public int Ano { get; set; }
    public int Mes { get; set; }
    public int TotalPresencas { get; set; }
    public int AlunosUnicos { get; set; }
}

public class RelatorioAnualDto
{
    public int Ano { get; set; }
    public decimal TotalRecebidoAno { get; set; }
    public int TotalAlunosAtivos { get; set; }
    public int TotalInadimplentes { get; set; }
    public List<ReceitaMensalDto> ReceitaMensal { get; set; } = [];
    public List<FrequenciaMensalDto> FrequenciaMensal { get; set; } = [];
    public List<AlunoInadimplenteDto> Inadimplentes { get; set; } = [];
}
