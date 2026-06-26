using AcademiaFight.Domain.Entities.Base;

namespace AcademiaFight.Domain.Entities;

public class GrupoFamiliar : EntityBase
{
    public Guid AcademiaId { get; set; }
    public string Nome { get; set; } = string.Empty;

    public Academia Academia { get; set; } = null!;
    public ICollection<Usuario> Membros { get; set; } = [];
}
