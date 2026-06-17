using AcademiaFight.Domain.Entities.Base;
using AcademiaFight.Domain.Enums;

namespace AcademiaFight.Domain.Entities;

public class Academia : EntityBase
{
    public string Nome { get; set; } = string.Empty;
    public string Subdominio { get; set; } = string.Empty;
    public string? LogoUrl { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? Telefone { get; set; }
    public bool Ativo { get; set; } = true;
    public string? Cnpj { get; set; }
    public string? TemplateContrato { get; set; }
    public PlanoAcademia PlanoTipo { get; set; } = PlanoAcademia.Gratuito;
    public DateTime? PlanoExpiracao { get; set; }
    public bool NoticiasAtivas { get; set; } = true;

    public ICollection<Usuario> Usuarios { get; set; } = new List<Usuario>();
    public ICollection<Modalidade> Modalidades { get; set; } = new List<Modalidade>();
    public ICollection<Turma> Turmas { get; set; } = new List<Turma>();
    public ICollection<Funcionario> Funcionarios { get; set; } = new List<Funcionario>();
}
