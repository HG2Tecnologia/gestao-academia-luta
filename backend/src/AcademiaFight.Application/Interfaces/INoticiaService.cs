using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Noticia;

namespace AcademiaFight.Application.Interfaces;

public interface INoticiaService
{
    Task<BaseResponse<ListarNoticiasResponse>> ListarPublicadasAsync(int pagina, int tamanhoPagina, CancellationToken ct = default);
    Task<BaseResponse<ListarNoticiasResponse>> ListarTodasAdminAsync(int pagina, int tamanhoPagina, CancellationToken ct = default);
    Task<BaseResponse<NoticiaDto>> ObterPorIdAsync(Guid id, CancellationToken ct = default);
    Task<BaseResponse<NoticiaDto>> CriarAsync(CriarNoticiaRequest request, Guid autorId, CancellationToken ct = default);
    Task<BaseResponse<NoticiaDto>> AtualizarAsync(Guid id, AtualizarNoticiaRequest request, CancellationToken ct = default);
    Task<BaseResponse> PublicarAsync(Guid id, CancellationToken ct = default);
    Task<BaseResponse> RemoverAsync(Guid id, CancellationToken ct = default);
    Task<BaseResponse> ToggleNoticiasAtivasAsync(bool ativo, CancellationToken ct = default);
}
