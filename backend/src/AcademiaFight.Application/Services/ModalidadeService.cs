using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Modalidade;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Application.Services;

public class ModalidadeService : IModalidadeService
{
    private readonly IAppDbContext _db;
    private readonly ILogger<ModalidadeService> _logger;

    public ModalidadeService(IAppDbContext db, ILogger<ModalidadeService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<BaseResponse<IEnumerable<ModalidadeDto>>> ListarAsync(bool? ativo = null, CancellationToken ct = default)
    {
        try
        {
            var query = _db.Modalidades.AsQueryable();
            if (ativo.HasValue) query = query.Where(m => m.Ativo == ativo.Value);

            var modalidades = await query
                .OrderBy(m => m.Ativo == false) // ativos primeiro
                .ThenBy(m => m.Nome)
                .Select(m => new ModalidadeDto
                {
                    Id = m.Id,
                    Nome = m.Nome,
                    Descricao = m.Descricao,
                    Ativo = m.Ativo,
                    SistemaFaixasJson = m.SistemaFaixasJson
                })
                .ToListAsync(ct);

            return BaseResponse<IEnumerable<ModalidadeDto>>.Ok(modalidades);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao listar modalidades");
            throw;
        }
    }

    public async Task<BaseResponse<ModalidadeDto>> ToggleAtivoAsync(Guid id, CancellationToken ct = default)
    {
        var modalidade = await _db.Modalidades.FirstOrDefaultAsync(m => m.Id == id, ct);
        if (modalidade is null) return BaseResponse<ModalidadeDto>.Falha("Modalidade não encontrada.");

        modalidade.Ativo = !modalidade.Ativo;
        await _db.SaveChangesAsync(ct);
        return BaseResponse<ModalidadeDto>.Ok(MapearDto(modalidade));
    }

    public async Task<BaseResponse<ModalidadeDto>> ObterPorIdAsync(Guid id, CancellationToken ct = default)
    {
        try
        {
            var modalidade = await _db.Modalidades
                .FirstOrDefaultAsync(m => m.Id == id, ct);

            if (modalidade is null)
                return BaseResponse<ModalidadeDto>.Falha("Modalidade não encontrada.");

            return BaseResponse<ModalidadeDto>.Ok(MapearDto(modalidade));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao obter modalidade {Id}", id);
            throw;
        }
    }

    public async Task<BaseResponse<ModalidadeDto>> CriarAsync(CreateModalidadeRequest request, CancellationToken ct = default)
    {
        try
        {
            var modalidade = new Modalidade
            {
                Nome = request.Nome,
                Descricao = request.Descricao,
                SistemaFaixasJson = request.SistemaFaixasJson,
                Ativo = true
            };

            await _db.Modalidades.AddAsync(modalidade, ct);
            await _db.SaveChangesAsync(ct);

            _logger.LogInformation("Modalidade criada: {Nome}", modalidade.Nome);

            return BaseResponse<ModalidadeDto>.Ok(MapearDto(modalidade), "Modalidade criada com sucesso.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao criar modalidade {Nome}", request.Nome);
            throw;
        }
    }

    public async Task<BaseResponse<ModalidadeDto>> AtualizarAsync(Guid id, UpdateModalidadeRequest request, CancellationToken ct = default)
    {
        try
        {
            var modalidade = await _db.Modalidades
                .FirstOrDefaultAsync(m => m.Id == id, ct);

            if (modalidade is null)
                return BaseResponse<ModalidadeDto>.Falha("Modalidade não encontrada.");

            modalidade.Nome = request.Nome;
            modalidade.Descricao = request.Descricao;
            modalidade.Ativo = request.Ativo;
            modalidade.SistemaFaixasJson = request.SistemaFaixasJson;

            await _db.SaveChangesAsync(ct);

            _logger.LogInformation("Modalidade {Id} atualizada", id);

            return BaseResponse<ModalidadeDto>.Ok(MapearDto(modalidade), "Modalidade atualizada com sucesso.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao atualizar modalidade {Id}", id);
            throw;
        }
    }

    public async Task<BaseResponse> RemoverAsync(Guid id, CancellationToken ct = default)
    {
        try
        {
            var modalidade = await _db.Modalidades
                .FirstOrDefaultAsync(m => m.Id == id, ct);

            if (modalidade is null)
                return BaseResponse.Falha("Modalidade não encontrada.");

            var possuiTurmas = await _db.Turmas.AnyAsync(t => t.ModalidadeId == id, ct);
            if (possuiTurmas)
                return BaseResponse.Falha("Não é possível remover uma modalidade que possui turmas cadastradas.");

            _db.Modalidades.Remove(modalidade);
            await _db.SaveChangesAsync(ct);

            _logger.LogInformation("Modalidade {Id} removida", id);

            return BaseResponse.Ok("Modalidade removida com sucesso.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao remover modalidade {Id}", id);
            throw;
        }
    }

    private static ModalidadeDto MapearDto(Modalidade m) => new()
    {
        Id = m.Id,
        Nome = m.Nome,
        Descricao = m.Descricao,
        Ativo = m.Ativo,
        SistemaFaixasJson = m.SistemaFaixasJson
    };
}
