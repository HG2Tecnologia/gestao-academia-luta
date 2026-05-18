namespace AcademiaFight.Application.DTOs.Modalidade;

public class ModalidadeDto
{
    public Guid Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string? Descricao { get; set; }
    public bool Ativo { get; set; }
    public string? SistemaFaixasJson { get; set; }
}

public class CreateModalidadeRequest
{
    public string Nome { get; set; } = string.Empty;
    public string? Descricao { get; set; }
    public string? SistemaFaixasJson { get; set; }
}

public class UpdateModalidadeRequest
{
    public string Nome { get; set; } = string.Empty;
    public string? Descricao { get; set; }
    public bool Ativo { get; set; }
    public string? SistemaFaixasJson { get; set; }
}
