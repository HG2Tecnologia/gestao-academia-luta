namespace AcademiaFight.Application.Interfaces;

/// <summary>
/// Abstração para comunicação com o dispositivo Toletus Hub via HTTP.
/// Implementação em ToletusCatracaClient.cs (Infrastructure).
/// </summary>
public interface IToletusCatracaClient
{
    /// <summary>Envia comando de abertura de porta para o dispositivo.</summary>
    Task<bool> AbrirPortaAsync(string deviceIp, CancellationToken ct = default);

    /// <summary>Cadastra um usuário no dispositivo (digital/PIN). Retorna true se bem-sucedido.</summary>
    Task<bool> CadastrarUsuarioAsync(string deviceIp, int userId, CancellationToken ct = default);

    /// <summary>Remove usuário do dispositivo.</summary>
    Task<bool> RemoverUsuarioAsync(string deviceIp, int userId, CancellationToken ct = default);

    /// <summary>Verifica se o dispositivo está acessível na rede.</summary>
    Task<bool> PingAsync(string deviceIp, CancellationToken ct = default);
}
