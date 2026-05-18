namespace AcademiaFight.Domain.Interfaces.Repositories;

public interface IRepositoryBase<T> where T : class
{
    Task<T?> ObterPorIdAsync(Guid id, CancellationToken ct = default);
    Task<IEnumerable<T>> ObterTodosAsync(CancellationToken ct = default);
    Task<T> AdicionarAsync(T entidade, CancellationToken ct = default);
    Task AtualizarAsync(T entidade, CancellationToken ct = default);
    Task RemoverAsync(T entidade, CancellationToken ct = default);
    Task<bool> ExisteAsync(Guid id, CancellationToken ct = default);
}
