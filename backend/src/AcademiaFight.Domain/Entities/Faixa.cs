using AcademiaFight.Domain.Entities.Base;

namespace AcademiaFight.Domain.Entities;

public class Faixa : EntityBase
{
    public Guid AcademiaId { get; set; }
    public Guid ModalidadeId { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string Cor { get; set; } = "#FFFFFF";
    public int Ordem { get; set; }
    public int RequisitosMesesMinimos { get; set; }
    public int RequisitosPresencasMinimas { get; set; }
    public string? Descricao { get; set; }
    public bool TemGraus { get; set; } = false;
    public int MaxGraus { get; set; } = 4;
    public string CorBarra { get; set; } = "#000000";

    public Academia Academia { get; set; } = null!;
    public Modalidade Modalidade { get; set; } = null!;
    public ICollection<Graduacao> Graduacoes { get; set; } = new List<Graduacao>();
}
