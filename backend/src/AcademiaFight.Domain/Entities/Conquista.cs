using AcademiaFight.Domain.Enums;

namespace AcademiaFight.Domain.Entities;

// Catálogo global de conquistas — não tem AcademiaId nem herda EntityBase
public class Conquista
{
    public Guid Id { get; set; }
    public TipoConquista Tipo { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string Descricao { get; set; } = string.Empty;
    public string IconeUrl { get; set; } = string.Empty;
    public int PontosXpBonus { get; set; }
    public DateTime CriadoEm { get; set; }
    public DateTime? AtualizadoEm { get; set; }
}
