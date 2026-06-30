using System.IdentityModel.Tokens.Jwt;
using System.Security.Cryptography.X509Certificates;
using Microsoft.IdentityModel.Tokens;

namespace AcademiaFight.API.Services;

public class FirebaseTokenVerifier
{
    private const string GooglePublicKeysUrl =
        "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com";

    private readonly IHttpClientFactory _httpClientFactory;
    private readonly string _projectId;
    private readonly ILogger<FirebaseTokenVerifier> _logger;

    public FirebaseTokenVerifier(
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration,
        ILogger<FirebaseTokenVerifier> logger)
    {
        _httpClientFactory = httpClientFactory;
        _logger = logger;
        _projectId = configuration["Firebase:ProjectId"]
            ?? throw new InvalidOperationException("Firebase:ProjectId não configurado.");
    }

    public async Task<(bool Success, string? Uid, string? Email, string? Error)> VerifyAsync(
        string idToken, CancellationToken ct = default)
    {
        try
        {
            var client = _httpClientFactory.CreateClient();
            var keysJson = await client.GetStringAsync(GooglePublicKeysUrl, ct);

            var rawKeys = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, string>>(keysJson)!;

            var signingKeys = rawKeys
                .Select(kv =>
                {
                    var cert = X509Certificate2.CreateFromPem(kv.Value);
                    return (SecurityKey)new X509SecurityKey(cert) { KeyId = kv.Key };
                })
                .ToList();

            var handler = new JwtSecurityTokenHandler();
            var validationParams = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = $"https://securetoken.google.com/{_projectId}",
                ValidateAudience = true,
                ValidAudience = _projectId,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                IssuerSigningKeys = signingKeys,
                ClockSkew = TimeSpan.FromMinutes(5),
            };

            var principal = handler.ValidateToken(idToken, validationParams, out var validatedToken);
            var jwt = (JwtSecurityToken)validatedToken;

            var uid = jwt.Subject;
            var email = principal.FindFirst("email")?.Value?.ToLower();

            return (true, uid, email, null);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Falha ao verificar token Firebase");
            return (false, null, null, ex.Message);
        }
    }
}
