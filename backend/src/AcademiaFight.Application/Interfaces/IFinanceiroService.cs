using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Financeiro;

namespace AcademiaFight.Application.Interfaces;

public interface IFinanceiroService
{
    Task<BaseResponse<ResumoFinanceiroDto>> GetResumoAsync(int? ano = null, int? mes = null, CancellationToken ct = default);
    Task<BaseResponse<IEnumerable<PagamentoDto>>> ListarAsync(Guid? alunoId, string? status, int? ano, int? mes, int page, int pageSize, CancellationToken ct = default);
    Task<BaseResponse<IEnumerable<PagamentoDto>>> ListarPorAlunoAsync(Guid alunoId, CancellationToken ct = default);
    Task<BaseResponse<PagamentoDto>> CriarAsync(CreatePagamentoDto dto, CancellationToken ct = default);
    Task<BaseResponse<PagamentoDto>> AtualizarAsync(Guid id, UpdatePagamentoDto dto, CancellationToken ct = default);
    Task<BaseResponse<bool>> DeletarAsync(Guid id, CancellationToken ct = default);
    Task<BaseResponse<int>> GerarCobrancasMensaisAsync(CancellationToken ct = default);
    Task<BaseResponse<RelatorioAnualDto>> GetRelatorioAnualAsync(int ano, CancellationToken ct = default);
}
