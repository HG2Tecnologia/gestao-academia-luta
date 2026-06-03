using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Faixa;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Application.Services;

public class FaixaService : IFaixaService
{
    private readonly IAppDbContext _db;
    private readonly ILogger<FaixaService> _logger;

    public FaixaService(IAppDbContext db, ILogger<FaixaService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<BaseResponse<IEnumerable<FaixaDto>>> GetByModalidadeAsync(Guid? modalidadeId, CancellationToken ct = default)
    {
        var query = _db.Faixas.Include(f => f.Modalidade).AsQueryable();
        if (modalidadeId.HasValue)
            query = query.Where(f => f.ModalidadeId == modalidadeId.Value);

        var faixas = await query
            .OrderBy(f => f.Modalidade!.Nome)
            .ThenBy(f => f.Ordem)
            .ToListAsync(ct);

        return BaseResponse<IEnumerable<FaixaDto>>.Ok(faixas.Select(MapearDto));
    }

    public async Task<BaseResponse<FaixaDto>> CreateAsync(CreateFaixaRequest request, CancellationToken ct = default)
    {
        var modalidade = await _db.Modalidades.FirstOrDefaultAsync(m => m.Id == request.ModalidadeId, ct);
        if (modalidade is null)
            return BaseResponse<FaixaDto>.Falha("Modalidade não encontrada.");

        var ordemOcupada = await _db.Faixas
            .AnyAsync(f => f.ModalidadeId == request.ModalidadeId && f.Ordem == request.Ordem, ct);
        if (ordemOcupada)
            return BaseResponse<FaixaDto>.Falha($"Já existe uma faixa com ordem {request.Ordem} nesta modalidade.");

        var faixa = new Faixa
        {
            ModalidadeId = request.ModalidadeId,
            Nome = request.Nome,
            Cor = request.Cor,
            Ordem = request.Ordem,
            RequisitosMesesMinimos = request.RequisitosMesesMinimos,
            RequisitosPresencasMinimas = request.RequisitosPresencasMinimas,
            Descricao = request.Descricao,
            TemGraus = request.TemGraus,
            MaxGraus = request.TemGraus ? request.MaxGraus : 0,
            CorBarra = request.CorBarra
        };

        await _db.Faixas.AddAsync(faixa, ct);
        await _db.SaveChangesAsync(ct);

        faixa.Modalidade = modalidade;
        return BaseResponse<FaixaDto>.Ok(MapearDto(faixa), "Faixa criada com sucesso.");
    }

    public async Task<BaseResponse<FaixaDto>> UpdateAsync(Guid id, CreateFaixaRequest request, CancellationToken ct = default)
    {
        var faixa = await _db.Faixas
            .Include(f => f.Modalidade)
            .FirstOrDefaultAsync(f => f.Id == id, ct);

        if (faixa is null)
            return BaseResponse<FaixaDto>.Falha("Faixa não encontrada.");

        var ordemOcupada = await _db.Faixas
            .AnyAsync(f => f.ModalidadeId == request.ModalidadeId && f.Ordem == request.Ordem && f.Id != id, ct);
        if (ordemOcupada)
            return BaseResponse<FaixaDto>.Falha($"Já existe uma faixa com ordem {request.Ordem} nesta modalidade.");

        faixa.Nome = request.Nome;
        faixa.Cor = request.Cor;
        faixa.Ordem = request.Ordem;
        faixa.RequisitosMesesMinimos = request.RequisitosMesesMinimos;
        faixa.RequisitosPresencasMinimas = request.RequisitosPresencasMinimas;
        faixa.Descricao = request.Descricao;
        faixa.TemGraus = request.TemGraus;
        faixa.MaxGraus = request.TemGraus ? request.MaxGraus : 0;
        faixa.CorBarra = request.CorBarra;

        await _db.SaveChangesAsync(ct);
        return BaseResponse<FaixaDto>.Ok(MapearDto(faixa), "Faixa atualizada com sucesso.");
    }

    public async Task<BaseResponse> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var faixa = await _db.Faixas.FirstOrDefaultAsync(f => f.Id == id, ct);
        if (faixa is null)
            return BaseResponse.Falha("Faixa não encontrada.");

        var temGraduacoes = await _db.Graduacoes.AnyAsync(g => g.FaixaId == id, ct);
        if (temGraduacoes)
            return BaseResponse.Falha("Não é possível remover uma faixa que possui graduações registradas.");

        _db.Faixas.Remove(faixa);
        await _db.SaveChangesAsync(ct);
        return BaseResponse.Ok("Faixa removida com sucesso.");
    }

    public async Task<BaseResponse> ReordenarAsync(ReordenarFaixasRequest request, CancellationToken ct = default)
    {
        var faixas = await _db.Faixas
            .Where(f => f.ModalidadeId == request.ModalidadeId && request.Ids.Contains(f.Id))
            .ToListAsync(ct);

        for (int i = 0; i < request.Ids.Count; i++)
        {
            var faixa = faixas.FirstOrDefault(f => f.Id == request.Ids[i]);
            if (faixa is not null)
                faixa.Ordem = i + 1;
        }

        await _db.SaveChangesAsync(ct);
        return BaseResponse.Ok("Faixas reordenadas com sucesso.");
    }

    private static FaixaDto MapearDto(Faixa f) => new()
    {
        Id = f.Id,
        ModalidadeId = f.ModalidadeId,
        NomeModalidade = f.Modalidade?.Nome ?? string.Empty,
        Nome = f.Nome,
        Cor = f.Cor,
        Ordem = f.Ordem,
        RequisitosMesesMinimos = f.RequisitosMesesMinimos,
        RequisitosPresencasMinimas = f.RequisitosPresencasMinimas,
        Descricao = f.Descricao,
        TemGraus = f.TemGraus,
        MaxGraus = f.MaxGraus,
        CorBarra = f.CorBarra
    };
}
