using AcademiaFight.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Infrastructure.Jobs;

public class RankingMensalResetJob
{
    private readonly AppDbContext _db;
    private readonly ILogger<RankingMensalResetJob> _logger;

    public RankingMensalResetJob(AppDbContext db, ILogger<RankingMensalResetJob> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task ExecutarAsync()
    {
        _logger.LogInformation("RankingMensalResetJob iniciado em {Timestamp}", DateTime.UtcNow);

        try
        {
            var afetados = await _db.Database.ExecuteSqlRawAsync(
                "UPDATE usuarios SET xp_mensal = 0 WHERE xp_mensal > 0");

            _logger.LogInformation("RankingMensalResetJob concluído: {Afetados} usuário(s) resetados em {Timestamp}",
                afetados, DateTime.UtcNow);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro durante RankingMensalResetJob em {Timestamp}", DateTime.UtcNow);
            throw;
        }
    }
}
