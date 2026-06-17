using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.AtestadoMedico;

namespace AcademiaFight.Application.Interfaces;

public interface IAtestadoService
{
    Task<BaseResponse<AtestadoMedicoDto>> UploadAlunoAsync(UploadAtestadoRequest request, Guid alunoId, CancellationToken ct = default);
    Task<BaseResponse<AtestadoMedicoDto>> UploadAcademiaAsync(UploadAtestadoPorAcademiaRequest request, Guid responsavelId, CancellationToken ct = default);
    Task<BaseResponse<AtestadoMedicoComArquivoDto?>> ObterMeuAtestadoAsync(Guid alunoId, CancellationToken ct = default);
    Task<BaseResponse<AtestadoMedicoComArquivoDto?>> ObterAtestadoDoAlunoAsync(Guid alunoId, CancellationToken ct = default);
    Task<BaseResponse<IEnumerable<AtestadoMedicoDto>>> ListarStatusAtestadosAsync(CancellationToken ct = default);
    Task<BaseResponse> AvaliarAsync(Guid id, AvaliarAtestadoRequest request, CancellationToken ct = default);
    Task<BaseResponse> EnviarLembreteAsync(Guid alunoId, CancellationToken ct = default);
    Task VerificarVencimentosAsync(CancellationToken ct = default);
}
