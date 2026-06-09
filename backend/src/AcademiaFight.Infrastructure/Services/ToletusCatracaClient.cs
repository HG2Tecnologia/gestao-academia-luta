using System.Net.Http.Json;
using AcademiaFight.Application.Interfaces;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Infrastructure.Services;

/// <summary>
/// Cliente HTTP para o dispositivo Toletus Hub (LiteNet2).
///
/// CONFIGURAÇÃO: O IP do dispositivo é passado por parâmetro em cada chamada.
/// Por padrão, o Toletus LiteNet2 usa endereço link-local (169.254.x.x) quando
/// conectado diretamente por cabo Ethernet no PC.
///
/// PROTOCOLO: O Toletus Hub expõe uma API HTTP local. Os endpoints exatos dependem
/// da versão do firmware. Ajustar as constantes abaixo conforme o manual do dispositivo.
/// Referência: documentação Toletus SDK / LiteNet2 API Guide.
/// </summary>
public class ToletusCatracaClient : IToletusCatracaClient
{
    private readonly IHttpClientFactory _httpFactory;
    private readonly ILogger<ToletusCatracaClient> _logger;

    // Ajustar conforme o firmware do dispositivo (documentação Toletus)
    private const string AbrirPortaPath   = "/api/open";
    private const string CadastrarUserPath = "/api/users/add";
    private const string RemoverUserPath   = "/api/users/remove";
    private const string PingPath          = "/api/status";
    private const int    TimeoutMs         = 3000;

    public ToletusCatracaClient(IHttpClientFactory httpFactory, ILogger<ToletusCatracaClient> logger)
    {
        _httpFactory = httpFactory;
        _logger = logger;
    }

    public async Task<bool> AbrirPortaAsync(string deviceIp, CancellationToken ct = default)
    {
        try
        {
            using var http = CreateClient();
            var url = $"http://{deviceIp}{AbrirPortaPath}";
            _logger.LogInformation("Catraca: enviando comando abrir para {Url}", url);

            // O payload exato depende do firmware Toletus — ajustar conforme documentação
            var payload = new { action = "open", door = 1 };
            var res = await http.PostAsJsonAsync(url, payload, ct);

            if (res.IsSuccessStatusCode)
            {
                _logger.LogInformation("Catraca: porta aberta com sucesso ({StatusCode})", (int)res.StatusCode);
                return true;
            }

            _logger.LogWarning("Catraca: dispositivo retornou {StatusCode}", (int)res.StatusCode);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Catraca: erro ao enviar comando de abertura para {Ip}", deviceIp);
            return false;
        }
    }

    public async Task<bool> CadastrarUsuarioAsync(string deviceIp, int userId, CancellationToken ct = default)
    {
        try
        {
            using var http = CreateClient();
            var url = $"http://{deviceIp}{CadastrarUserPath}";
            _logger.LogInformation("Catraca: cadastrando usuário {UserId} em {Ip}", userId, deviceIp);

            // Payload para iniciar enrollment no dispositivo — ajustar conforme firmware Toletus
            var payload = new { userId, fingers = new[] { 1, 2 }, mode = "enroll" };
            var res = await http.PostAsJsonAsync(url, payload, ct);

            return res.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Catraca: erro ao cadastrar usuário {UserId} em {Ip}", userId, deviceIp);
            return false;
        }
    }

    public async Task<bool> RemoverUsuarioAsync(string deviceIp, int userId, CancellationToken ct = default)
    {
        try
        {
            using var http = CreateClient();
            var url = $"http://{deviceIp}{RemoverUserPath}";
            _logger.LogInformation("Catraca: removendo usuário {UserId} de {Ip}", userId, deviceIp);

            var payload = new { userId };
            var res = await http.PostAsJsonAsync(url, payload, ct);

            return res.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Catraca: erro ao remover usuário {UserId} de {Ip}", userId, deviceIp);
            return false;
        }
    }

    public async Task<bool> PingAsync(string deviceIp, CancellationToken ct = default)
    {
        try
        {
            using var http = CreateClient();
            var res = await http.GetAsync($"http://{deviceIp}{PingPath}", ct);
            return res.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }

    private HttpClient CreateClient()
    {
        var http = _httpFactory.CreateClient("toletus");
        http.Timeout = TimeSpan.FromMilliseconds(TimeoutMs);
        return http;
    }
}
