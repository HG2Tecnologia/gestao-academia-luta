using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Auth;

namespace AcademiaFight.Application.Interfaces;

public interface IAuthService
{
    Task<BaseResponse<LoginResponse>> LoginAsync(LoginRequest request, CancellationToken ct = default);
    Task<BaseResponse<LoginResponse>> RegisterAsync(RegisterRequest request, CancellationToken ct = default);
    Task<BaseResponse<LoginResponse>> RefreshTokenAsync(RefreshTokenRequest request, CancellationToken ct = default);
    Task<BaseResponse> LogoutAsync(string refreshToken, CancellationToken ct = default);
    Task<BaseResponse> AlterarSenhaAsync(Guid usuarioId, AlterarSenhaRequest request, CancellationToken ct = default);
    Task<BaseResponse> SolicitarRecuperacaoSenhaAsync(string email, CancellationToken ct = default);
    Task<BaseResponse> RedefinirSenhaAsync(string token, string novaSenha, CancellationToken ct = default);
    Task<BaseResponse<PrimeiroAcessoResponse>> PrimeiroAcessoAsync(PrimeiroAcessoRequest request, CancellationToken ct = default);
    Task<BaseResponse<PrimeiroAcessoResponse>> RecuperarAcessoAsync(RecuperarAcessoRequest request, CancellationToken ct = default);
    Task<BaseResponse<LoginResponse>> FirebaseLoginAsync(string firebaseUid, string email, CancellationToken ct = default);
}
