using System.Security.Cryptography;
using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Auth;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Application.Services;

public class AuthService : IAuthService
{
    private readonly IAppDbContext _db;
    private readonly ITokenService _tokenService;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IEmailService _emailService;
    private readonly IModalidadeSeedService _modalidadeSeed;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        IAppDbContext db,
        ITokenService tokenService,
        IPasswordHasher passwordHasher,
        IEmailService emailService,
        IModalidadeSeedService modalidadeSeed,
        ILogger<AuthService> logger)
    {
        _db = db;
        _tokenService = tokenService;
        _passwordHasher = passwordHasher;
        _emailService = emailService;
        _modalidadeSeed = modalidadeSeed;
        _logger = logger;
    }

    public async Task<BaseResponse<LoginResponse>> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        try
        {
            // Aceita EmailOuTelefone (mobile) ou Email (web legado)
            var identificador = !string.IsNullOrWhiteSpace(request.EmailOuTelefone)
                ? request.EmailOuTelefone.Trim().ToLower()
                : request.Email.Trim().ToLower();

            var apenasDigitos = new string(identificador.Where(char.IsDigit).ToArray());
            string? telefoneFormatado = apenasDigitos.Length switch
            {
                11 => $"({apenasDigitos[..2]}) {apenasDigitos[2..7]}-{apenasDigitos[7..]}",
                10 => $"({apenasDigitos[..2]}) {apenasDigitos[2..6]}-{apenasDigitos[6..]}",
                _ => null
            };

            var usuario = await _db.Usuarios
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(u => u.Ativo &&
                    (u.Email != null && u.Email.ToLower() == identificador ||
                     u.Telefone != null && (u.Telefone == identificador || u.Telefone == telefoneFormatado || u.Telefone == apenasDigitos)), ct);

            if (usuario is null || string.IsNullOrEmpty(usuario.SenhaHash) || !_passwordHasher.VerificarSenha(request.Senha, usuario.SenhaHash))
                return BaseResponse<LoginResponse>.Falha("Credenciais inválidas.");

            var academia = await _db.Academias
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(a => a.Id == usuario.AcademiaId && a.Ativo, ct);

            if (academia is null)
                return BaseResponse<LoginResponse>.Falha("Academia inativa. Entre em contato com o suporte.");

            Dictionary<string, bool>? permissoes = null;
            if (usuario.Perfil != PerfilUsuario.Admin)
            {
                var funcionario = await _db.Funcionarios
                    .IgnoreQueryFilters()
                    .FirstOrDefaultAsync(f => f.UsuarioId == usuario.Id, ct);
                permissoes = funcionario?.Permissoes;
            }

            var accessToken = _tokenService.GerarAccessToken(usuario, permissoes);
            var refreshToken = _tokenService.GerarRefreshToken();
            var expiracao = DateTime.UtcNow.AddMinutes(15);

            usuario.RefreshToken = refreshToken;
            usuario.RefreshTokenExpiry = DateTime.UtcNow.AddDays(7);
            usuario.UltimoLogin = DateTime.UtcNow;

            await _db.SaveChangesAsync(ct);

            _logger.LogInformation("Login realizado para {Email} na academia {AcademiaId}", request.Email, academia.Id);

            return BaseResponse<LoginResponse>.Ok(new LoginResponse
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                Expiracao = expiracao,
                Nome = usuario.Nome,
                Email = usuario.Email,
                Perfil = usuario.Perfil.ToString(),
                AcademiaId = academia.Id
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao realizar login para {Email}", request.Email);
            throw;
        }
    }

    public async Task<BaseResponse<LoginResponse>> RegisterAsync(RegisterRequest request, CancellationToken ct = default)
    {
        try
        {
            var subdominioNormalizado = request.Subdominio.ToLower().Trim();

            var subdominioExistente = await _db.Academias
                .AnyAsync(a => a.Subdominio == subdominioNormalizado, ct);

            if (subdominioExistente)
                return BaseResponse<LoginResponse>.Falha($"O subdomínio '{subdominioNormalizado}' já está em uso.");

            var emailExistente = await _db.Academias
                .AnyAsync(a => a.Email == request.Email.ToLower(), ct);

            if (emailExistente)
                return BaseResponse<LoginResponse>.Falha("Já existe uma academia cadastrada com este e-mail.");

            var academia = new Academia
            {
                Nome = request.NomeAcademia,
                Subdominio = subdominioNormalizado,
                Email = (request.EmailAcademia ?? request.Email).ToLower(),
                Telefone = request.Telefone,
                Ativo = true
            };

            await _db.Academias.AddAsync(academia, ct);

            var senhaHash = _passwordHasher.HashPassword(request.Senha);
            var accessToken = string.Empty;
            var refreshToken = _tokenService.GerarRefreshToken();

            var usuario = new Usuario
            {
                AcademiaId = academia.Id,
                Nome = request.Nome,
                Email = request.Email.ToLower(),
                SenhaHash = senhaHash,
                Perfil = PerfilUsuario.Admin,
                Ativo = true,
                RefreshToken = refreshToken,
                RefreshTokenExpiry = DateTime.UtcNow.AddDays(7)
            };

            await _db.Usuarios.AddAsync(usuario, ct);
            await _db.SaveChangesAsync(ct);

            // Semear modalidades pré-definidas para a nova academia
            await _modalidadeSeed.SeedParaAcademiaAsync(academia.Id, ct);

            // Gerar access token após salvar para ter o Id do usuário
            accessToken = _tokenService.GerarAccessToken(usuario);

            _logger.LogInformation("Nova academia registrada: {Subdominio} com admin {Email}", subdominioNormalizado, request.Email);

            return BaseResponse<LoginResponse>.Ok(new LoginResponse
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                Expiracao = DateTime.UtcNow.AddMinutes(15),
                Nome = usuario.Nome,
                Email = usuario.Email,
                Perfil = usuario.Perfil.ToString(),
                AcademiaId = academia.Id
            }, "Academia cadastrada com sucesso!");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao registrar academia para {Email}", request.Email);
            throw;
        }
    }

    public async Task<BaseResponse<LoginResponse>> RefreshTokenAsync(RefreshTokenRequest request, CancellationToken ct = default)
    {
        try
        {
            var principal = _tokenService.ObterPrincipalDoTokenExpirado(request.AccessToken);

            if (principal is null)
                return BaseResponse<LoginResponse>.Falha("Access token inválido.");

            var academiaIdClaim = principal.FindFirst("academia_id")?.Value;
            var subClaim = principal.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                           ?? principal.FindFirst("sub")?.Value;

            if (!Guid.TryParse(academiaIdClaim, out var academiaId))
                return BaseResponse<LoginResponse>.Falha("Token inválido: academia não identificada.");

            if (!Guid.TryParse(subClaim, out var usuarioId))
                return BaseResponse<LoginResponse>.Falha("Token inválido: usuário não identificado.");

            var usuario = await _db.Usuarios
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(u => u.Id == usuarioId
                                          && u.AcademiaId == academiaId
                                          && u.RefreshToken == request.RefreshToken
                                          && u.RefreshTokenExpiry > DateTime.UtcNow
                                          && u.Ativo, ct);

            if (usuario is null)
                return BaseResponse<LoginResponse>.Falha("Refresh token inválido ou expirado.");

            Dictionary<string, bool>? permissoesRefresh = null;
            if (usuario.Perfil != PerfilUsuario.Admin)
            {
                var funcionarioRefresh = await _db.Funcionarios
                    .IgnoreQueryFilters()
                    .FirstOrDefaultAsync(f => f.UsuarioId == usuario.Id, ct);
                permissoesRefresh = funcionarioRefresh?.Permissoes;
            }

            var novoAccessToken = _tokenService.GerarAccessToken(usuario, permissoesRefresh);
            var novoRefreshToken = _tokenService.GerarRefreshToken();

            usuario.RefreshToken = novoRefreshToken;
            usuario.RefreshTokenExpiry = DateTime.UtcNow.AddDays(7);

            await _db.SaveChangesAsync(ct);

            return BaseResponse<LoginResponse>.Ok(new LoginResponse
            {
                AccessToken = novoAccessToken,
                RefreshToken = novoRefreshToken,
                Expiracao = DateTime.UtcNow.AddMinutes(15),
                Nome = usuario.Nome,
                Email = usuario.Email,
                Perfil = usuario.Perfil.ToString(),
                AcademiaId = academiaId
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao renovar token");
            throw;
        }
    }

    public async Task<BaseResponse> LogoutAsync(string refreshToken, CancellationToken ct = default)
    {
        try
        {
            var usuario = await _db.Usuarios
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(u => u.RefreshToken == refreshToken, ct);

            if (usuario is not null)
            {
                usuario.RefreshToken = null;
                usuario.RefreshTokenExpiry = null;
                await _db.SaveChangesAsync(ct);
            }

            return BaseResponse.Ok("Logout realizado com sucesso.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao realizar logout");
            throw;
        }
    }

    public async Task<BaseResponse> AlterarSenhaAsync(Guid usuarioId, AlterarSenhaRequest request, CancellationToken ct = default)
    {
        var usuario = await _db.Usuarios
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(u => u.Id == usuarioId && u.Ativo, ct);

        if (usuario is null)
            return BaseResponse.Falha("Usuário não encontrado.");

        if (!_passwordHasher.VerificarSenha(request.SenhaAtual, usuario.SenhaHash))
            return BaseResponse.Falha("Senha atual incorreta.");

        if (request.NovaSenha.Length < 6)
            return BaseResponse.Falha("A nova senha deve ter no mínimo 6 caracteres.");

        usuario.SenhaHash = _passwordHasher.HashPassword(request.NovaSenha);
        await _db.SaveChangesAsync(ct);

        return BaseResponse.Ok("Senha alterada com sucesso.");
    }

    public async Task<BaseResponse> SolicitarRecuperacaoSenhaAsync(string email, CancellationToken ct = default)
    {
        var usuario = await _db.Usuarios
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(u => u.Email == email.ToLower() && u.Ativo, ct);

        // Resposta genérica para não revelar se o e-mail existe
        if (usuario is null)
            return BaseResponse.Ok("Se este e-mail estiver cadastrado, você receberá as instruções em breve.");

        var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32))
            .Replace("+", "-").Replace("/", "_").TrimEnd('=');

        usuario.ResetPasswordToken = token;
        usuario.ResetPasswordTokenExpiry = DateTime.UtcNow.AddHours(1);
        await _db.SaveChangesAsync(ct);

        await _emailService.EnviarRecuperacaoSenhaAsync(usuario.Email, usuario.Nome, token, ct);

        return BaseResponse.Ok("Se este e-mail estiver cadastrado, você receberá as instruções em breve.");
    }

    public async Task<BaseResponse<PrimeiroAcessoResponse>> PrimeiroAcessoAsync(PrimeiroAcessoRequest request, CancellationToken ct = default)
    {
        var valor = request.EmailOuTelefone.Trim().ToLower();

        // Normaliza: extrai só dígitos para comparar com telefones armazenados com ou sem máscara
        var apenasDigitos = new string(valor.Where(char.IsDigit).ToArray());
        string? telefoneFormatado = apenasDigitos.Length switch
        {
            11 => $"({apenasDigitos[..2]}) {apenasDigitos[2..7]}-{apenasDigitos[7..]}",
            10 => $"({apenasDigitos[..2]}) {apenasDigitos[2..6]}-{apenasDigitos[6..]}",
            _ => null
        };

        var usuario = await _db.Usuarios
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(u => u.Ativo && u.SenhaHash == string.Empty &&
                (u.Email != null && u.Email.ToLower() == valor ||
                 u.Telefone != null && (u.Telefone == valor || u.Telefone == telefoneFormatado || u.Telefone == apenasDigitos)), ct);

        // Se não achou usuário sem senha, verifica se existe com senha (já configurou acesso)
        if (usuario is null)
        {
            var jaConfigurado = await _db.Usuarios
                .IgnoreQueryFilters()
                .AnyAsync(u => u.Ativo && u.SenhaHash != string.Empty &&
                    (u.Email != null && u.Email.ToLower() == valor ||
                     u.Telefone != null && (u.Telefone == valor || u.Telefone == telefoneFormatado || u.Telefone == apenasDigitos)), ct);

            if (jaConfigurado)
                return BaseResponse<PrimeiroAcessoResponse>.Falha("Você já possui acesso configurado. Use a opção 'Esqueci minha senha' para redefinir.");
        }

        if (usuario is null)
            return BaseResponse<PrimeiroAcessoResponse>.Falha("Usuário não encontrado. Verifique o e-mail ou telefone informado.");

        var setupToken = Convert.ToBase64String(System.Security.Cryptography.RandomNumberGenerator.GetBytes(32))
            .Replace("+", "-").Replace("/", "_").TrimEnd('=');

        usuario.ResetPasswordToken = setupToken;
        usuario.ResetPasswordTokenExpiry = DateTime.UtcNow.AddHours(24);
        await _db.SaveChangesAsync(ct);

        return BaseResponse<PrimeiroAcessoResponse>.Ok(new PrimeiroAcessoResponse(setupToken, usuario.Nome));
    }

    public async Task<BaseResponse<PrimeiroAcessoResponse>> RecuperarAcessoAsync(RecuperarAcessoRequest request, CancellationToken ct = default)
    {
        const string erroDadosIncorretos = "Dados incorretos. Verifique as informações e tente novamente.";

        var valor = request.EmailOuTelefone.Trim().ToLower();

        var apenasDigitos = new string(valor.Where(char.IsDigit).ToArray());
        string? telefoneFormatado = apenasDigitos.Length switch
        {
            11 => $"({apenasDigitos[..2]}) {apenasDigitos[2..7]}-{apenasDigitos[7..]}",
            10 => $"({apenasDigitos[..2]}) {apenasDigitos[2..6]}-{apenasDigitos[6..]}",
            _ => null
        };

        var usuario = await _db.Usuarios
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(u => u.Ativo &&
                (u.Email != null && u.Email.ToLower() == valor ||
                 u.Telefone != null && (u.Telefone == valor || u.Telefone == telefoneFormatado || u.Telefone == apenasDigitos)), ct);

        // Mensagem genérica para não revelar se o usuário existe (anti-enumeração)
        if (usuario is null)
            return BaseResponse<PrimeiroAcessoResponse>.Falha(erroDadosIncorretos);

        if (!usuario.DataNascimento.HasValue)
            return BaseResponse<PrimeiroAcessoResponse>.Falha("Não foi possível verificar sua identidade. Entre em contato com o administrador.");

        if (usuario.DataNascimento.Value != request.DataNascimento)
            return BaseResponse<PrimeiroAcessoResponse>.Falha(erroDadosIncorretos);

        var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32))
            .Replace("+", "-").Replace("/", "_").TrimEnd('=');

        usuario.ResetPasswordToken = token;
        usuario.ResetPasswordTokenExpiry = DateTime.UtcNow.AddHours(24);
        await _db.SaveChangesAsync(ct);

        return BaseResponse<PrimeiroAcessoResponse>.Ok(new PrimeiroAcessoResponse(token, usuario.Nome));
    }

    public async Task<BaseResponse> RedefinirSenhaAsync(string token, string novaSenha, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(novaSenha) || novaSenha.Length < 6)
            return BaseResponse.Falha("A nova senha deve ter no mínimo 6 caracteres.");

        var usuario = await _db.Usuarios
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(u => u.ResetPasswordToken == token
                                      && u.ResetPasswordTokenExpiry > DateTime.UtcNow
                                      && u.Ativo, ct);

        if (usuario is null)
            return BaseResponse.Falha("Link inválido ou expirado. Solicite um novo link de recuperação.");

        usuario.SenhaHash = _passwordHasher.HashPassword(novaSenha);
        usuario.ResetPasswordToken = null;
        usuario.ResetPasswordTokenExpiry = null;
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("Senha redefinida para {Email}", usuario.Email);

        return BaseResponse.Ok("Senha redefinida com sucesso. Você já pode fazer login.");
    }
}
