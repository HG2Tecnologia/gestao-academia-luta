using System.Net;
using System.Net.Mail;
using AcademiaFight.Application.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Infrastructure.Services;

public class SmtpEmailService : IEmailService
{
    private readonly IConfiguration _config;
    private readonly ILogger<SmtpEmailService> _logger;

    public SmtpEmailService(IConfiguration config, ILogger<SmtpEmailService> logger)
    {
        _config = config;
        _logger = logger;
    }

    public async Task EnviarRecuperacaoSenhaAsync(string email, string nome, string token, CancellationToken ct = default)
    {
        var frontendUrl = _config["FrontendUrl"] ?? "http://localhost:4200";
        var link = $"{frontendUrl}/reset-password?token={Uri.EscapeDataString(token)}";

        var smtp = _config.GetSection("Smtp");
        var host = smtp["Host"] ?? throw new InvalidOperationException("Smtp:Host não configurado.");
        var port = int.Parse(smtp["Port"] ?? "587");
        var user = smtp["User"] ?? throw new InvalidOperationException("Smtp:User não configurado.");
        var pass = smtp["Password"] ?? throw new InvalidOperationException("Smtp:Password não configurado.");
        var from = smtp["From"] ?? user;
        var fromName = smtp["FromName"] ?? "Academia Fight";

        var corpo = $"""
            <html><body style="font-family:sans-serif;color:#1a1a2e;max-width:520px;margin:auto">
              <div style="background:#1e3a5f;padding:24px;border-radius:8px 8px 0 0;text-align:center">
                <h1 style="color:#fff;margin:0;font-size:22px">Academia Fight</h1>
              </div>
              <div style="background:#f8f9fa;padding:32px;border-radius:0 0 8px 8px">
                <p style="font-size:16px">Olá, <strong>{nome}</strong>!</p>
                <p>Recebemos uma solicitação para redefinir a senha da sua conta.</p>
                <p>Clique no botão abaixo para criar uma nova senha. O link expira em <strong>1 hora</strong>.</p>
                <div style="text-align:center;margin:32px 0">
                  <a href="{link}" style="background:#1e3a5f;color:#fff;padding:14px 32px;border-radius:6px;text-decoration:none;font-size:15px;font-weight:600">
                    Redefinir senha
                  </a>
                </div>
                <p style="font-size:13px;color:#666">Se você não solicitou isso, ignore este e-mail. Sua senha permanecerá a mesma.</p>
                <hr style="border:none;border-top:1px solid #e0e0e0;margin:24px 0">
                <p style="font-size:12px;color:#999;text-align:center">Academia Fight — Gestão inteligente para artes marciais</p>
              </div>
            </body></html>
            """;

        using var client = new SmtpClient(host, port)
        {
            Credentials = new NetworkCredential(user, pass),
            EnableSsl = true,
        };

        var message = new MailMessage
        {
            From = new MailAddress(from, fromName),
            Subject = "Redefinição de senha — Academia Fight",
            Body = corpo,
            IsBodyHtml = true,
        };
        message.To.Add(email);

        await client.SendMailAsync(message, ct);
        _logger.LogInformation("E-mail de recuperação de senha enviado para {Email}", email);
    }
}
