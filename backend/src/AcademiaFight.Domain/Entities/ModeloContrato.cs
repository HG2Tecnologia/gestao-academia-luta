using AcademiaFight.Domain.Entities.Base;

namespace AcademiaFight.Domain.Entities;

public class ModeloContrato : EntityBase
{
    public Guid AcademiaId { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string ConteudoHtml { get; set; } = string.Empty;

    public Academia Academia { get; set; } = null!;
}
