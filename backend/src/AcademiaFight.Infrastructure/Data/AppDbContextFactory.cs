using AcademiaFight.Domain.Interfaces;
using AcademiaFight.Infrastructure.Tenant;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace AcademiaFight.Infrastructure.Data;

/// <summary>
/// Factory usada pelo EF CLI para criar o DbContext durante as migrations.
/// </summary>
public class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();
        optionsBuilder.UseNpgsql(
            "Host=localhost;Database=academiafight;Username=postgres;Password=postgres123",
            npgsql => npgsql.MigrationsAssembly("AcademiaFight.Infrastructure"));

        // TenantContext vazio para uso nas migrations
        var tenantContext = new TenantContext();
        return new AppDbContext(optionsBuilder.Options, tenantContext);
    }
}
