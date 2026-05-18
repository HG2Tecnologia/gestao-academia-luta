namespace AcademiaFight.Application.DTOs.Contrato;

public class ModeloContratoDto
{
    public Guid Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string ConteudoHtml { get; set; } = string.Empty;
    public DateTime CriadoEm { get; set; }
}

public class CreateModeloContratoRequest
{
    public string Nome { get; set; } = string.Empty;
    public string ConteudoHtml { get; set; } = string.Empty;
}

public class UpdateModeloContratoRequest
{
    public string Nome { get; set; } = string.Empty;
    public string ConteudoHtml { get; set; } = string.Empty;
}
