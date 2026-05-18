using AcademiaFight.Domain.Enums;

namespace AcademiaFight.Application.DTOs.Notificacao;

public class NotificacaoDto
{
    public Guid Id { get; set; }
    public string Titulo { get; set; } = string.Empty;
    public string Mensagem { get; set; } = string.Empty;
    public TipoNotificacao Tipo { get; set; }
    public string TipoLabel => Tipo switch
    {
        TipoNotificacao.Aniversario => "aniversario",
        TipoNotificacao.Alerta => "alerta",
        _ => "info"
    };
    public bool Lida { get; set; }
    public DateTime CriadoEm { get; set; }
    public string TempoRelativo => TempoRelativoCalc(CriadoEm);

    private static string TempoRelativoCalc(DateTime dt)
    {
        var diff = DateTime.UtcNow - dt.ToUniversalTime();
        if (diff.TotalMinutes < 1) return "agora";
        if (diff.TotalMinutes < 60) return $"há {(int)diff.TotalMinutes} min";
        if (diff.TotalHours < 24) return $"há {(int)diff.TotalHours}h";
        if (diff.TotalDays < 7) return $"há {(int)diff.TotalDays} dia(s)";
        return dt.ToString("dd/MM/yyyy");
    }
}
