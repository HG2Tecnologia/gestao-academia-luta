using AcademiaFight.Domain.Interfaces;

namespace AcademiaFight.Infrastructure.Tenant;

public class TenantContext : ITenantContext
{
    private Guid _academiaId;

    public Guid AcademiaId => _academiaId;
    public bool IsSet => _academiaId != Guid.Empty;

    public void SetTenant(Guid academiaId) => _academiaId = academiaId;
}
