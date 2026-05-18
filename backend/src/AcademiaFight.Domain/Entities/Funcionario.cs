using AcademiaFight.Domain.Entities.Base;

namespace AcademiaFight.Domain.Entities;

public class Funcionario : EntityBase
{
    public Guid AcademiaId { get; set; }
    public Guid UsuarioId { get; set; }
    public string Cargo { get; set; } = string.Empty;
    public Dictionary<string, bool> Permissoes { get; set; } = new();
    public DateTime DataAdmissao { get; set; }

    public Academia Academia { get; set; } = null!;
    public Usuario Usuario { get; set; } = null!;
}
