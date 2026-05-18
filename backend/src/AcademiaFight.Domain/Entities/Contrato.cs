using AcademiaFight.Domain.Entities.Base;
using AcademiaFight.Domain.Enums;

namespace AcademiaFight.Domain.Entities;

public class Contrato : EntityBase
{
    public Guid AcademiaId { get; set; }
    public Guid AlunoId { get; set; }
    public Guid? MatriculaId { get; set; }
    public string ConteudoHtml { get; set; } = string.Empty;
    public StatusContrato Status { get; set; } = StatusContrato.Pendente;
    public DateTime? DataAssinatura { get; set; }
    public string? IpAssinatura { get; set; }
    public string? NomeAssinou { get; set; }

    public Guid TokenPublico { get; set; } = Guid.NewGuid();
    public Guid? ModeloContratoId { get; set; }
    public Guid? ModalidadeId { get; set; }

    public Academia Academia { get; set; } = null!;
    public Usuario Aluno { get; set; } = null!;
    public Matricula? Matricula { get; set; }
    public ModeloContrato? Modelo { get; set; }
    public Modalidade? Modalidade { get; set; }
}
