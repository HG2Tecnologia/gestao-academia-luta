namespace AcademiaFight.Application.DTOs.GrupoFamiliar;

public class GrupoFamiliarDto
{
    public Guid Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public DateTime CriadoEm { get; set; }
    public List<MembroDto> Membros { get; set; } = [];
}

public class MembroDto
{
    public Guid Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string Perfil { get; set; } = string.Empty;
}
