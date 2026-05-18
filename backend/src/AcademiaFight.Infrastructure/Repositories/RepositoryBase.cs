using AcademiaFight.Domain.Entities.Base;
using AcademiaFight.Domain.Interfaces.Repositories;
using AcademiaFight.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace AcademiaFight.Infrastructure.Repositories;

public class RepositoryBase<T> : IRepositoryBase<T> where T : EntityBase
{
    protected readonly AppDbContext _context;
    protected readonly DbSet<T> _dbSet;

    public RepositoryBase(AppDbContext context)
    {
        _context = context;
        _dbSet = context.Set<T>();
    }

    public async Task<T?> ObterPorIdAsync(Guid id, CancellationToken ct = default)
        => await _dbSet.FirstOrDefaultAsync(e => e.Id == id, ct);

    public async Task<IEnumerable<T>> ObterTodosAsync(CancellationToken ct = default)
        => await _dbSet.ToListAsync(ct);

    public async Task<T> AdicionarAsync(T entidade, CancellationToken ct = default)
    {
        await _dbSet.AddAsync(entidade, ct);
        await _context.SaveChangesAsync(ct);
        return entidade;
    }

    public async Task AtualizarAsync(T entidade, CancellationToken ct = default)
    {
        _dbSet.Update(entidade);
        await _context.SaveChangesAsync(ct);
    }

    public async Task RemoverAsync(T entidade, CancellationToken ct = default)
    {
        _dbSet.Remove(entidade);
        await _context.SaveChangesAsync(ct);
    }

    public async Task<bool> ExisteAsync(Guid id, CancellationToken ct = default)
        => await _dbSet.AnyAsync(e => e.Id == id, ct);
}
