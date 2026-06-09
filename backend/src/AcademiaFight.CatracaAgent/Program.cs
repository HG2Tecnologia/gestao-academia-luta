using Microsoft.AspNetCore.SignalR.Client;
using Microsoft.Extensions.Configuration;

// ── Configuração ──────────────────────────────────────────────────────────────

var config = new ConfigurationBuilder()
    .SetBasePath(AppContext.BaseDirectory)
    .AddJsonFile("appsettings.json", optional: false)
    .AddEnvironmentVariables()
    .Build();

var backendUrl  = config["Backend:Url"]       ?? "https://gestao-academia-luta.onrender.com";
var apiKey      = config["Backend:ApiKey"]    ?? "";
var academiaId  = config["Backend:AcademiaId"] ?? "";
var toletusCatracaIp = config["Toletus:CatracaIp"] ?? "169.254.37.21";

Console.Title = "Sensei Manager — Agente Catraca";
Console.WriteLine("╔══════════════════════════════════════╗");
Console.WriteLine("║   Sensei Manager — Agente Catraca    ║");
Console.WriteLine("╚══════════════════════════════════════╝");
Console.WriteLine($"Backend : {backendUrl}");
Console.WriteLine($"Academia: {academiaId}");
Console.WriteLine($"Toletus : http://{toletusCatracaIp}");
Console.WriteLine();

if (string.IsNullOrWhiteSpace(apiKey) || apiKey == "TROQUE_ESTA_CHAVE_QUANDO_INSTALAR_A_CATRACA")
{
    Console.ForegroundColor = ConsoleColor.Red;
    Console.WriteLine("ERRO: Configure a ApiKey em appsettings.json antes de iniciar.");
    Console.ResetColor();
    Console.ReadKey();
    return;
}

if (!Guid.TryParse(academiaId, out _))
{
    Console.ForegroundColor = ConsoleColor.Red;
    Console.WriteLine("ERRO: AcademiaId inválido em appsettings.json. Copie da tela de Catraca no sistema.");
    Console.ResetColor();
    Console.ReadKey();
    return;
}

// ── Cliente HTTP para o dispositivo Toletus ───────────────────────────────────

using var httpClient = new HttpClient { Timeout = TimeSpan.FromSeconds(5) };

async Task<bool> AbrirPortaToletus()
{
    try
    {
        // Ajustar o endpoint e payload conforme firmware do dispositivo Toletus LiteNet2
        var url = $"http://{toletusCatracaIp}/api/open";
        var payload = new StringContent(
            System.Text.Json.JsonSerializer.Serialize(new { action = "open", door = 1 }),
            System.Text.Encoding.UTF8,
            "application/json");

        var res = await httpClient.PostAsync(url, payload);
        return res.IsSuccessStatusCode;
    }
    catch (Exception ex)
    {
        Console.ForegroundColor = ConsoleColor.Red;
        Console.WriteLine($"[{Ts()}] ERRO ao comunicar com Toletus: {ex.Message}");
        Console.ResetColor();
        return false;
    }
}

async Task<bool> CadastrarUsuarioToletus(int userId)
{
    try
    {
        var url = $"http://{toletusCatracaIp}/api/users/add";
        var payload = new StringContent(
            System.Text.Json.JsonSerializer.Serialize(new { userId, fingers = new[] { 1, 2 }, mode = "enroll" }),
            System.Text.Encoding.UTF8,
            "application/json");
        var res = await httpClient.PostAsync(url, payload);
        return res.IsSuccessStatusCode;
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[{Ts()}] ERRO cadastrar usuário {userId}: {ex.Message}");
        return false;
    }
}

async Task<bool> RemoverUsuarioToletus(int userId)
{
    try
    {
        var url = $"http://{toletusCatracaIp}/api/users/remove";
        var payload = new StringContent(
            System.Text.Json.JsonSerializer.Serialize(new { userId }),
            System.Text.Encoding.UTF8,
            "application/json");
        var res = await httpClient.PostAsync(url, payload);
        return res.IsSuccessStatusCode;
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[{Ts()}] ERRO remover usuário {userId}: {ex.Message}");
        return false;
    }
}

// ── Conexão SignalR ───────────────────────────────────────────────────────────

var connection = new HubConnectionBuilder()
    .WithUrl($"{backendUrl}/hubs/catraca")
    .WithAutomaticReconnect(new[] { TimeSpan.FromSeconds(2), TimeSpan.FromSeconds(5), TimeSpan.FromSeconds(15), TimeSpan.FromSeconds(30) })
    .Build();

connection.On("AgenteRegistrado", (string acadId) =>
{
    Console.ForegroundColor = ConsoleColor.Green;
    Console.WriteLine($"[{Ts()}] Agente registrado na academia {acadId}. Aguardando comandos...");
    Console.ResetColor();
});

connection.On("Erro", (string msg) =>
{
    Console.ForegroundColor = ConsoleColor.Red;
    Console.WriteLine($"[{Ts()}] Erro do servidor: {msg}");
    Console.ResetColor();
});

connection.On("AbrirPorta", async () =>
{
    Console.WriteLine($"[{Ts()}] >>> Comando: AbrirPorta");
    var ok = await AbrirPortaToletus();
    Console.ForegroundColor = ok ? ConsoleColor.Green : ConsoleColor.Red;
    Console.WriteLine($"[{Ts()}] Porta {(ok ? "ABERTA" : "FALHOU")}");
    Console.ResetColor();
});

connection.On("CadastrarUsuario", async (int userId) =>
{
    Console.WriteLine($"[{Ts()}] >>> Comando: CadastrarUsuario (ID={userId})");
    Console.WriteLine($"[{Ts()}] Peça ao aluno para escanear a digital no dispositivo...");
    var ok = await CadastrarUsuarioToletus(userId);
    Console.ForegroundColor = ok ? ConsoleColor.Green : ConsoleColor.Yellow;
    Console.WriteLine($"[{Ts()}] Enrollment {(ok ? "INICIADO" : "FALHOU — verifique o dispositivo")} (ID={userId})");
    Console.ResetColor();
});

connection.On("RemoverUsuario", async (int userId) =>
{
    Console.WriteLine($"[{Ts()}] >>> Comando: RemoverUsuario (ID={userId})");
    var ok = await RemoverUsuarioToletus(userId);
    Console.WriteLine($"[{Ts()}] Usuário {userId} {(ok ? "removido" : "falhou ao remover")}");
});

connection.Reconnecting += _ =>
{
    Console.ForegroundColor = ConsoleColor.Yellow;
    Console.WriteLine($"[{Ts()}] Reconectando ao backend...");
    Console.ResetColor();
    return Task.CompletedTask;
};

connection.Reconnected += async _ =>
{
    Console.WriteLine($"[{Ts()}] Reconectado. Re-registrando agente...");
    await connection.InvokeAsync("RegistrarAgente", apiKey, academiaId);
};

// ── Iniciar ───────────────────────────────────────────────────────────────────

Console.WriteLine($"[{Ts()}] Conectando ao backend...");
await connection.StartAsync();
await connection.InvokeAsync("RegistrarAgente", apiKey, academiaId);

Console.WriteLine("Pressione Ctrl+C para encerrar.");
await Task.Delay(Timeout.Infinite);

// ── Helpers ───────────────────────────────────────────────────────────────────

static string Ts() => DateTime.Now.ToString("HH:mm:ss");
