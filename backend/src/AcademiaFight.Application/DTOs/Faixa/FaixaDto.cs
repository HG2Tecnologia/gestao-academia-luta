namespace AcademiaFight.Application.DTOs.Faixa;

public class FaixaDto
{
    public Guid Id { get; set; }
    public Guid ModalidadeId { get; set; }
    public string NomeModalidade { get; set; } = string.Empty;
    public string Nome { get; set; } = string.Empty;
    public string Cor { get; set; } = "#FFFFFF";
    public int Ordem { get; set; }
    public int RequisitosMesesMinimos { get; set; }
    public int RequisitosPresencasMinimas { get; set; }
    public string? Descricao { get; set; }
}

public class CreateFaixaRequest
{
    public Guid ModalidadeId { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string Cor { get; set; } = "#FFFFFF";
    public int Ordem { get; set; }
    public int RequisitosMesesMinimos { get; set; }
    public int RequisitosPresencasMinimas { get; set; }
    public string? Descricao { get; set; }
}

public class ReordenarFaixasRequest
{
    public Guid ModalidadeId { get; set; }
    public List<Guid> Ids { get; set; } = [];
}
