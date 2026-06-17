namespace AcademiaFight.Application.DTOs.ParQ;

public class ParQDto
{
    public Guid Id { get; set; }
    public Guid AlunoId { get; set; }
    public string AlunoNome { get; set; } = string.Empty;
    public bool R1 { get; set; }
    public bool R2 { get; set; }
    public bool R3 { get; set; }
    public bool R4 { get; set; }
    public bool R5 { get; set; }
    public bool R6 { get; set; }
    public bool R7 { get; set; }
    public bool R8 { get; set; }
    public bool R9 { get; set; }
    public bool R10 { get; set; }
    public string NomeCompleto { get; set; } = string.Empty;
    public string Cpf { get; set; } = string.Empty;
    public DateTime DataPreenchimento { get; set; }
    public bool RequerAvaliacaoMedica { get; set; }
    public DateTime CriadoEm { get; set; }
}

public class PreencherParQRequest
{
    public bool R1 { get; set; }
    public bool R2 { get; set; }
    public bool R3 { get; set; }
    public bool R4 { get; set; }
    public bool R5 { get; set; }
    public bool R6 { get; set; }
    public bool R7 { get; set; }
    public bool R8 { get; set; }
    public bool R9 { get; set; }
    public bool R10 { get; set; }
    public string NomeCompleto { get; set; } = string.Empty;
    public string Cpf { get; set; } = string.Empty;
}
