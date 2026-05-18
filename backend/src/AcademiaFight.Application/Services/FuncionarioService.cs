using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Funcionario;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace AcademiaFight.Application.Services;

public class FuncionarioService : IFuncionarioService
{
    private readonly IAppDbContext _db;
    private readonly IPasswordHasher _hasher;

    public FuncionarioService(IAppDbContext db, IPasswordHasher hasher)
    {
        _db = db;
        _hasher = hasher;
    }

    public async Task<BaseResponse<IEnumerable<FuncionarioDto>>> ListarAsync(string? nome, string? perfil, CancellationToken ct = default)
    {
        var query = _db.Funcionarios
            .Include(f => f.Usuario)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(nome))
            query = query.Where(f => f.Usuario.Nome.ToLower().Contains(nome.ToLower()));

        if (!string.IsNullOrWhiteSpace(perfil) && Enum.TryParse<PerfilUsuario>(perfil, out var perfilEnum))
            query = query.Where(f => f.Usuario.Perfil == perfilEnum);

        var funcionarios = await query
            .OrderBy(f => f.Usuario.Nome)
            .ToListAsync(ct);

        var usuarioIds = funcionarios.Select(f => f.UsuarioId).ToList();

        var turmasPorProfessor = await _db.Turmas
            .Where(t => usuarioIds.Contains(t.ProfessorId) && t.Ativo)
            .Select(t => new { t.ProfessorId, t.Nome })
            .ToListAsync(ct);

        var turmasDict = turmasPorProfessor
            .GroupBy(t => t.ProfessorId)
            .ToDictionary(g => g.Key, g => g.Select(t => t.Nome).ToList());

        var itens = funcionarios.Select(f =>
        {
            var dto = MapearDto(f);
            dto.TurmasVinculadas = turmasDict.GetValueOrDefault(f.UsuarioId, []);
            return dto;
        });

        return BaseResponse<IEnumerable<FuncionarioDto>>.Ok(itens);
    }

    public async Task<BaseResponse<FuncionarioDto>> ObterPorIdAsync(Guid id, CancellationToken ct = default)
    {
        var f = await _db.Funcionarios.Include(x => x.Usuario)
            .FirstOrDefaultAsync(x => x.Id == id, ct);
        if (f is null) return BaseResponse<FuncionarioDto>.Falha("Funcionário não encontrado.");

        var dto = MapearDto(f);
        dto.TurmasVinculadas = await _db.Turmas
            .Where(t => t.ProfessorId == f.UsuarioId && t.Ativo)
            .Select(t => t.Nome)
            .ToListAsync(ct);

        return BaseResponse<FuncionarioDto>.Ok(dto);
    }

    public async Task<BaseResponse<FuncionarioDto>> CriarAsync(CreateFuncionarioDto request, Guid academiaId, CancellationToken ct = default)
    {
        if (!Enum.TryParse<PerfilUsuario>(request.Perfil, out var perfil))
            perfil = PerfilUsuario.Professor;

        var usuario = new Usuario
        {
            AcademiaId = academiaId,
            Nome = request.Nome,
            Email = string.IsNullOrWhiteSpace(request.Email) ? null : request.Email,
            SenhaHash = _hasher.HashPassword(Guid.NewGuid().ToString()),
            Perfil = perfil,
            Ativo = true,
            Telefone = request.Telefone,
        };
        _db.Usuarios.Add(usuario);

        var funcionario = new Funcionario
        {
            AcademiaId = academiaId,
            Usuario = usuario,
            Cargo = request.Cargo,
            Permissoes = request.Permissoes,
            DataAdmissao = DateTime.UtcNow,
        };
        _db.Funcionarios.Add(funcionario);

        await _db.SaveChangesAsync(ct);
        return BaseResponse<FuncionarioDto>.Ok(MapearDto(funcionario));
    }

    public async Task<BaseResponse<FuncionarioDto>> AtualizarAsync(Guid id, UpdateFuncionarioDto request, CancellationToken ct = default)
    {
        var f = await _db.Funcionarios.Include(x => x.Usuario)
            .FirstOrDefaultAsync(x => x.Id == id, ct);
        if (f is null) return BaseResponse<FuncionarioDto>.Falha("Funcionário não encontrado.");

        if (!Enum.TryParse<PerfilUsuario>(request.Perfil, out var perfil))
            perfil = f.Usuario.Perfil;

        f.Usuario.Nome = request.Nome;
        f.Usuario.Email = string.IsNullOrWhiteSpace(request.Email) ? null : request.Email;
        f.Usuario.Telefone = string.IsNullOrWhiteSpace(request.Telefone) ? f.Usuario.Telefone : request.Telefone;
        f.Usuario.Perfil = perfil;
        f.Usuario.Ativo = request.Ativo;
        f.Cargo = request.Cargo;
        f.Permissoes = request.Permissoes;

        await _db.SaveChangesAsync(ct);
        return BaseResponse<FuncionarioDto>.Ok(MapearDto(f));
    }

    public async Task<BaseResponse> RemoverAsync(Guid id, CancellationToken ct = default)
    {
        var f = await _db.Funcionarios.Include(x => x.Usuario)
            .FirstOrDefaultAsync(x => x.Id == id, ct);
        if (f is null) return BaseResponse.Falha("Funcionário não encontrado.");
        f.Usuario.Ativo = false;
        await _db.SaveChangesAsync(ct);
        return BaseResponse.Ok("Funcionário desativado.");
    }

    private static FuncionarioDto MapearDto(Funcionario f) => new()
    {
        Id = f.Id,
        UsuarioId = f.UsuarioId,
        Nome = f.Usuario?.Nome ?? string.Empty,
        Email = f.Usuario?.Email ?? string.Empty,
        Telefone = f.Usuario?.Telefone,
        Cargo = f.Cargo,
        Perfil = f.Usuario?.Perfil.ToString() ?? string.Empty,
        Ativo = f.Usuario?.Ativo ?? false,
        Permissoes = f.Permissoes,
        DataAdmissao = f.DataAdmissao,
    };
}
