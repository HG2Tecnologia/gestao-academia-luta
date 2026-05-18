using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Catraca;

namespace AcademiaFight.Application.Interfaces;

public interface ICatracaService
{
    /// <summary>
    /// Valida se um aluno pode entrar. Chamado pela catraca ao receber identificador (e-mail ou matrícula).
    /// TODO: quando a catraca chegar, ajustar o campo identificador conforme o protocolo do hardware.
    /// </summary>
    Task<BaseResponse<CatracaValidacaoDto>> ValidarAcessoAsync(string identificador, Guid academiaId, CancellationToken ct = default);

    /// <summary>
    /// Libera a catraca manualmente via botão da secretaria.
    /// TODO: quando integrado ao hardware, chamar o endpoint/comando HTTP/TCP da catraca aqui.
    /// </summary>
    Task<BaseResponse<CatracaAberturaManuaDto>> AbrirManualmenteAsync(Guid academiaId, Guid operadorId, CancellationToken ct = default);
}
