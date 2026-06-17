using AcademiaFight.Domain.Entities.Base;

namespace AcademiaFight.Domain.Entities;

/// <summary>Questionário de Prontidão para Atividade Física (PAR-Q) + Termo de Responsabilidade.</summary>
public class ParQ : EntityBase
{
    public Guid AcademiaId { get; set; }
    public Guid AlunoId { get; set; }

    // ── Respostas (true = Sim) ──────────────────────────────────────────
    public bool R1 { get; set; }  // Problema de coração/pressão com restrição médica
    public bool R2 { get; set; }  // Dores no peito ao praticar atividade física
    public bool R3 { get; set; }  // Dores no peito no último mês
    public bool R4 { get; set; }  // Desequilíbrio/tontura/perda de consciência
    public bool R5 { get; set; }  // Problema ósseo ou articular agravado por atividade física
    public bool R6 { get; set; }  // Medicação de uso contínuo
    public bool R7 { get; set; }  // Tratamento médico para pressão/problemas cardíacos
    public bool R8 { get; set; }  // Tratamento médico contínuo afetado por atividade física
    public bool R9 { get; set; }  // Cirurgia que comprometa atividade física
    public bool R10 { get; set; } // Outra razão que pode comprometer saúde

    // ── Termo de Responsabilidade ───────────────────────────────────────
    public string NomeCompleto { get; set; } = string.Empty;
    public string Cpf { get; set; } = string.Empty;
    public DateTime DataPreenchimento { get; set; } = DateTime.UtcNow;

    /// <summary>True se qualquer resposta for "Sim" (requer atenção médica).</summary>
    public bool RequerAvaliacaoMedica => R1 || R2 || R3 || R4 || R5 || R7 || R8 || R9 || R10;

    public Academia Academia { get; set; } = null!;
    public Usuario Aluno { get; set; } = null!;
}
