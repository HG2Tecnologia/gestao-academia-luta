using AcademiaFight.Domain.Entities.Base;

namespace AcademiaFight.Domain.Entities;

public class Noticia : EntityBase
{
    public Guid AcademiaId { get; set; }
    public string Titulo { get; set; } = string.Empty;
    public string Resumo { get; set; } = string.Empty;
    public string? Conteudo { get; set; }
    public string? ImagemBase64 { get; set; }
    public bool Publicada { get; set; } = false;
    public DateTime? PublicadaEm { get; set; }
    public Guid? AutorId { get; set; }

    public Academia Academia { get; set; } = null!;
    public Usuario? Autor { get; set; }
}
