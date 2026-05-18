using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Notificacao;

namespace AcademiaFight.Application.Interfaces;

public interface INotificacaoService
{
    Task<BaseResponse<IEnumerable<NotificacaoDto>>> ListarAsync(CancellationToken ct = default);
    Task<BaseResponse> MarcarLidaAsync(Guid id, CancellationToken ct = default);
    Task<BaseResponse> MarcarTodasLidasAsync(CancellationToken ct = default);
    Task<BaseResponse> ExcluirAsync(Guid id, CancellationToken ct = default);
}
