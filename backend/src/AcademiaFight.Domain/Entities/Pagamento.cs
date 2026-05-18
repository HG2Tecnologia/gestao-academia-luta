using AcademiaFight.Domain.Entities.Base;
using AcademiaFight.Domain.Enums;

namespace AcademiaFight.Domain.Entities;

public class Pagamento : EntityBase
{
    public Guid AcademiaId { get; set; }
    public Guid AlunoId { get; set; }
    public TipoPagamento Tipo { get; set; }
    public StatusPagamento Status { get; set; } = StatusPagamento.Pendente;
    public decimal Valor { get; set; }
    public string? Descricao { get; set; }
    public DateOnly? DataVencimento { get; set; }
    public DateOnly? DataPagamento { get; set; }
    public string? FormaPagamento { get; set; }
    public string? Observacoes { get; set; }

    public Academia Academia { get; set; } = null!;
    public Usuario Aluno { get; set; } = null!;
}
