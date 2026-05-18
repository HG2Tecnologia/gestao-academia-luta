using AcademiaFight.Domain.Entities.Base;
using AcademiaFight.Domain.Enums;

namespace AcademiaFight.Domain.Entities;

public class Notificacao : EntityBase
{
    public Guid AcademiaId { get; set; }
    public string Titulo { get; set; } = string.Empty;
    public string Mensagem { get; set; } = string.Empty;
    public TipoNotificacao Tipo { get; set; } = TipoNotificacao.Info;
    public bool Lida { get; set; }
    public string? ChaveDedup { get; set; }

    public Academia Academia { get; set; } = null!;
}
