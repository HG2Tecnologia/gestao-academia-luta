using AcademiaFight.Domain.Entities.Base;
using AcademiaFight.Domain.Enums;

namespace AcademiaFight.Domain.Entities;

public class Usuario : EntityBase
{
    public Guid AcademiaId { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string SenhaHash { get; set; } = string.Empty;
    public PerfilUsuario Perfil { get; set; }
    public bool Ativo { get; set; } = true;
    public DateTime? UltimoLogin { get; set; }
    public string? RefreshToken { get; set; }
    public DateTime? RefreshTokenExpiry { get; set; }
    public string? ResetPasswordToken { get; set; }
    public DateTime? ResetPasswordTokenExpiry { get; set; }
    public string? FcmToken { get; set; }
    public string? Telefone { get; set; }
    public DateOnly? DataNascimento { get; set; }
    public string? ContatoEmergenciaNome { get; set; }
    public string? ContatoEmergenciaTelefone { get; set; }
    public string? TipoPlano { get; set; }
    public Guid? PlanoId { get; set; }
    public int? DiaVencimento { get; set; }

    // Gamificação (desnormalizado para performance de leitura)
    public int XpTotal { get; set; }
    public int XpMensal { get; set; }
    public NivelAluno Nivel { get; set; } = NivelAluno.Iniciante;
    public DateTime? NivelAtualizadoEm { get; set; }

    // Vínculo com dispositivo de acesso (catraca Toletus)
    public int? CatracaDeviceUserId { get; set; }

    // Foto de perfil (base64)
    public string? FotoBase64 { get; set; }

    // Plano familiar
    public Guid? GrupoFamiliarId { get; set; }

    public Academia Academia { get; set; } = null!;
    public Plano? Plano { get; set; }
    public GrupoFamiliar? GrupoFamiliar { get; set; }
}
