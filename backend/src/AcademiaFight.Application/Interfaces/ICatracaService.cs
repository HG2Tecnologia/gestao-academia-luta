using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Catraca;

namespace AcademiaFight.Application.Interfaces;

public interface ICatracaService
{
    /// <summary>
    /// Valida se um aluno pode entrar. Chamado pela catraca ao receber identificador.
    /// Identificador pode ser: ID numérico do dispositivo, e-mail ou nome do aluno.
    /// </summary>
    Task<BaseResponse<CatracaValidacaoDto>> ValidarAcessoAsync(string identificador, Guid academiaId, CancellationToken ct = default);

    /// <summary>
    /// Libera a catraca manualmente via botão da secretaria.
    /// Envia comando via SignalR ao agente local que faz o HTTP call para o dispositivo Toletus.
    /// </summary>
    Task<BaseResponse<CatracaAberturaManuaDto>> AbrirManualmenteAsync(Guid academiaId, Guid operadorId, CancellationToken ct = default);

    /// <summary>Lista todos os alunos com status de vínculo no dispositivo.</summary>
    Task<BaseResponse<List<CatracaAlunoVinculoDto>>> ListarVinculosAsync(Guid academiaId, CancellationToken ct = default);

    /// <summary>
    /// Vincula um aluno ao dispositivo Toletus, atribuindo um DeviceUserId.
    /// O agente inicia o enrollment no dispositivo (aluno escaneia digital 3x).
    /// </summary>
    Task<BaseResponse<CatracaAlunoVinculoDto>> VincularAlunoAsync(Guid alunoId, Guid academiaId, int? deviceUserId, CancellationToken ct = default);

    /// <summary>Remove o vínculo do aluno com o dispositivo e apaga do hardware.</summary>
    Task<BaseResponse<bool>> DesvincularAlunoAsync(Guid alunoId, Guid academiaId, CancellationToken ct = default);
}
