using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Presenca;

namespace AcademiaFight.Application.Interfaces;

public interface IPresencaService
{
    Task<BaseResponse<PresencaDto>> RegistrarAsync(RegistrarPresencaRequest request, CancellationToken ct = default);
    Task<BaseResponse<PresencaDto>> RegistrarPorQrCodeAsync(string tokenQr, CancellationToken ct = default);
    Task<BaseResponse<IEnumerable<PresencaDto>>> GetHistoricoAlunoAsync(Guid alunoId, DateOnly de, DateOnly ate, CancellationToken ct = default);
    Task<BaseResponse<IEnumerable<PresencaDto>>> GetPresencasAulaAsync(Guid horarioId, DateOnly data, CancellationToken ct = default);
    Task<BaseResponse<PresencaRelatorioDto>> GetRelatorioFrequenciaAsync(Guid turmaId, DateOnly de, DateOnly ate, CancellationToken ct = default);
    Task<BaseResponse<QrTokenResponse>> GerarTokenQrAlunoAsync(Guid alunoId, CancellationToken ct = default);
}
