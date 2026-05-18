namespace AcademiaFight.Domain.Interfaces;

public interface ITenantContext
{
    Guid AcademiaId { get; }
    bool IsSet { get; }
    void SetTenant(Guid academiaId);
}
