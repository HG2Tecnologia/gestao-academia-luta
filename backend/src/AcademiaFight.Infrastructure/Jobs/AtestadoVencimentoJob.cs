using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using AcademiaFight.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Infrastructure.Jobs;

public class AtestadoVencimentoJob
{
    private readonly AppDbContext _db;
    private readonly ILogger<AtestadoVencimentoJob> _logger;

    public AtestadoVencimentoJob(AppDbContext db, ILogger<AtestadoVencimentoJob> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task ExecutarAsync()
    {
        _logger.LogInformation("AtestadoVencimentoJob iniciado em {Ts}", DateTime.UtcNow);

        try
        {
            var agora = DateTime.UtcNow;
            var em7Dias = agora.AddDays(7);

            // Marcar como Expirado
            var expirados = await _db.AtestadosMedicos
                .IgnoreQueryFilters()
                .Where(a => a.Status == StatusAtestado.Aprovado && a.DataValidade < agora)
                .ToListAsync();

            foreach (var a in expirados)
                a.Status = StatusAtestado.Expirado;

            // Alertar vencimentos próximos (dentro de 7 dias)
            var vencendoEmBreve = await _db.AtestadosMedicos
                .IgnoreQueryFilters()
                .Include(a => a.Aluno)
                .Where(a => a.Status == StatusAtestado.Aprovado
                         && a.DataValidade <= em7Dias
                         && a.DataValidade >= agora
                         && !a.AlertaVencimentoEnviado)
                .ToListAsync();

            var notificacoesParaAdicionar = new List<Notificacao>();

            foreach (var a in vencendoEmBreve)
            {
                a.AlertaVencimentoEnviado = true;
                var diasRestantes = (int)(a.DataValidade - agora).TotalDays + 1;

                notificacoesParaAdicionar.Add(new Notificacao
                {
                    AcademiaId = a.AcademiaId,
                    Titulo = "Atestado próximo do vencimento ⚠️",
                    Mensagem = $"O atestado de {a.Aluno?.Nome ?? "um aluno"} vence em {diasRestantes} dia(s). Solicite a renovação.",
                    Tipo = TipoNotificacao.Info,
                    ChaveDedup = $"vencimento-atestado-{a.Id}",
                });
            }

            if (notificacoesParaAdicionar.Count > 0)
                await _db.Notificacoes.AddRangeAsync(notificacoesParaAdicionar);

            var total = expirados.Count + vencendoEmBreve.Count;
            if (total > 0)
                await _db.SaveChangesAsync();

            _logger.LogInformation(
                "AtestadoVencimentoJob concluído: {Exp} expirados, {Aviso} alertas enviados em {Ts}",
                expirados.Count, vencendoEmBreve.Count, DateTime.UtcNow);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro durante AtestadoVencimentoJob em {Ts}", DateTime.UtcNow);
            throw;
        }
    }
}
