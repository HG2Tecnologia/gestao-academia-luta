using AcademiaFight.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Infrastructure.Jobs;

public class DbKeepAliveJob
{
    private readonly AppDbContext _db;
    private readonly ILogger<DbKeepAliveJob> _logger;

    public DbKeepAliveJob(AppDbContext db, ILogger<DbKeepAliveJob> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task ExecutarAsync()
    {
        try
        {
            await _db.Database.ExecuteSqlRawAsync("SELECT 1");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "DbKeepAliveJob falhou ao pingar o banco");
        }
    }
}
