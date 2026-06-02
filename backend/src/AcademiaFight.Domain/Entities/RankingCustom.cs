using AcademiaFight.Domain.Entities.Base;

namespace AcademiaFight.Domain.Entities;

public class RankingCustom : EntityBase
{
    public Guid AcademiaId { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string? Descricao { get; set; }

    /// <summary>
    /// Quando true, conta as presenças do aluno multiplicadas por PesoPresencas.
    /// </summary>
    public bool IncluirPresencas { get; set; } = true;

    /// <summary>
    /// Quando true, soma os pontos lançados manualmente multiplicados por PesoManuais.
    /// </summary>
    public bool IncluirPontosManuais { get; set; } = true;

    /// <summary>
    /// Multiplicador de cada presença. Padrão 1 (soma simples).
    /// </summary>
    public int PesoPresencas { get; set; } = 1;

    /// <summary>
    /// Multiplicador de cada ponto manual. Padrão 1 (soma simples).
    /// </summary>
    public int PesoManuais { get; set; } = 1;

    public bool VisivelParaAluno { get; set; } = false;
    public bool Ativo { get; set; } = true;

    /// <summary>
    /// Quando definido, presenças anteriores a esta data são ignoradas no cálculo.
    /// </summary>
    public DateOnly? DataInicio { get; set; }

    /// <summary>
    /// Quando definido, presenças posteriores a esta data são ignoradas no cálculo.
    /// </summary>
    public DateOnly? DataFim { get; set; }

    public Academia Academia { get; set; } = null!;
    public ICollection<LancamentoPonto> Lancamentos { get; set; } = [];
}
