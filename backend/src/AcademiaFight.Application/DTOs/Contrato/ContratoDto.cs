using AcademiaFight.Domain.Enums;

namespace AcademiaFight.Application.DTOs.Contrato;

public class ContratoDto
{
    public Guid Id { get; set; }
    public Guid AlunoId { get; set; }
    public string NomeAluno { get; set; } = string.Empty;
    public Guid? MatriculaId { get; set; }
    public Guid? ModalidadeId { get; set; }
    public string? NomeModalidade { get; set; }
    public StatusContrato Status { get; set; }
    public string StatusLabel => Status switch
    {
        StatusContrato.Pendente  => "Pendente",
        StatusContrato.Assinado  => "Assinado",
        StatusContrato.Cancelado => "Cancelado",
        _ => Status.ToString()
    };
    public DateTime? DataAssinatura { get; set; }
    public string? NomeAssinou { get; set; }
    public DateTime CriadoEm { get; set; }
    public Guid TokenPublico { get; set; }
}

public class ContratoDetalheDto : ContratoDto
{
    public string ConteudoHtml { get; set; } = string.Empty;
    public string? IpAssinatura { get; set; }
}

public class ContratoPublicoDto
{
    public Guid Id { get; set; }
    public string NomeAluno { get; set; } = string.Empty;
    public string NomeAcademia { get; set; } = string.Empty;
    public string? LogoUrl { get; set; }
    public string ConteudoHtml { get; set; } = string.Empty;
    public StatusContrato Status { get; set; }
    public DateTime? DataAssinatura { get; set; }
    public string? NomeAssinou { get; set; }
}

public class CreateContratoRequest
{
    public Guid AlunoId { get; set; }
    public Guid? MatriculaId { get; set; }
    public Guid? ModalidadeId { get; set; }
    public Guid? ModeloContratoId { get; set; }
}

public class AssinarContratoRequest
{
    public string NomeCompleto { get; set; } = string.Empty;
}
