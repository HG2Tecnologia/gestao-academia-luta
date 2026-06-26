using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Noticia;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using AcademiaFight.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace AcademiaFight.Application.Services;

public class NoticiaService : INoticiaService
{
    private readonly IAppDbContext _db;
    private readonly ITenantContext _tenant;

    public NoticiaService(IAppDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    public async Task<BaseResponse<ListarNoticiasResponse>> ListarPublicadasAsync(int pagina, int tamanhoPagina, CancellationToken ct = default)
    {
        var query = _db.Noticias.Where(n => n.Publicada).OrderByDescending(n => n.PublicadaEm);
        var total = await query.CountAsync(ct);
        var items = await query
            .Skip((pagina - 1) * tamanhoPagina)
            .Take(tamanhoPagina)
            .Include(n => n.Autor)
            .Select(n => MapearDto(n))
            .ToListAsync(ct);

        return BaseResponse<ListarNoticiasResponse>.Ok(new ListarNoticiasResponse
        {
            Items = items,
            Total = total,
            Pagina = pagina,
            TotalPaginas = (int)Math.Ceiling((double)total / tamanhoPagina)
        });
    }

    public async Task<BaseResponse<ListarNoticiasResponse>> ListarTodasAdminAsync(int pagina, int tamanhoPagina, CancellationToken ct = default)
    {
        var query = _db.Noticias.OrderByDescending(n => n.CriadoEm);
        var total = await query.CountAsync(ct);
        var items = await query
            .Skip((pagina - 1) * tamanhoPagina)
            .Take(tamanhoPagina)
            .Include(n => n.Autor)
            .Select(n => MapearDto(n))
            .ToListAsync(ct);

        return BaseResponse<ListarNoticiasResponse>.Ok(new ListarNoticiasResponse
        {
            Items = items,
            Total = total,
            Pagina = pagina,
            TotalPaginas = (int)Math.Ceiling((double)total / tamanhoPagina)
        });
    }

    public async Task<BaseResponse<NoticiaDto>> ObterPorIdAsync(Guid id, CancellationToken ct = default)
    {
        var n = await _db.Noticias.Include(x => x.Autor).FirstOrDefaultAsync(x => x.Id == id, ct);
        if (n is null) return BaseResponse<NoticiaDto>.Falha("Notícia não encontrada.");
        return BaseResponse<NoticiaDto>.Ok(MapearDtoCompleto(n));
    }

    public async Task<BaseResponse<NoticiaDto>> CriarAsync(CriarNoticiaRequest request, Guid autorId, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Titulo))
            return BaseResponse<NoticiaDto>.Falha("Título obrigatório.");
        if (string.IsNullOrWhiteSpace(request.Resumo))
            return BaseResponse<NoticiaDto>.Falha("Resumo obrigatório.");

        var noticia = new Noticia
        {
            Titulo = request.Titulo.Trim(),
            Resumo = request.Resumo.Trim(),
            Conteudo = request.Conteudo?.Trim(),
            ImagemBase64 = request.ImagemBase64,
            AutorId = autorId,
            Publicada = request.PublicarAgora,
            PublicadaEm = request.PublicarAgora ? DateTime.UtcNow : null
        };

        await _db.Noticias.AddAsync(noticia, ct);
        await _db.SaveChangesAsync(ct);

        if (request.PublicarAgora)
            await _notificarAlunosAsync(noticia, ct);

        var criada = await _db.Noticias.Include(x => x.Autor).FirstAsync(x => x.Id == noticia.Id, ct);
        return BaseResponse<NoticiaDto>.Ok(MapearDtoCompleto(criada), "Notícia criada com sucesso.");
    }

    public async Task<BaseResponse<NoticiaDto>> AtualizarAsync(Guid id, AtualizarNoticiaRequest request, CancellationToken ct = default)
    {
        var noticia = await _db.Noticias.Include(x => x.Autor).FirstOrDefaultAsync(x => x.Id == id, ct);
        if (noticia is null) return BaseResponse<NoticiaDto>.Falha("Notícia não encontrada.");

        noticia.Titulo = request.Titulo.Trim();
        noticia.Resumo = request.Resumo.Trim();
        noticia.Conteudo = request.Conteudo?.Trim();
        if (request.ImagemBase64 is not null)
            noticia.ImagemBase64 = request.ImagemBase64;

        await _db.SaveChangesAsync(ct);
        return BaseResponse<NoticiaDto>.Ok(MapearDtoCompleto(noticia), "Notícia atualizada.");
    }

    public async Task<BaseResponse> PublicarAsync(Guid id, CancellationToken ct = default)
    {
        var noticia = await _db.Noticias.FirstOrDefaultAsync(x => x.Id == id, ct);
        if (noticia is null) return BaseResponse.Falha("Notícia não encontrada.");
        if (noticia.Publicada) return BaseResponse.Falha("Notícia já publicada.");

        noticia.Publicada = true;
        noticia.PublicadaEm = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);
        await _notificarAlunosAsync(noticia, ct);

        return BaseResponse.Ok("Notícia publicada.");
    }

    public async Task<BaseResponse> RemoverAsync(Guid id, CancellationToken ct = default)
    {
        var noticia = await _db.Noticias.FirstOrDefaultAsync(x => x.Id == id, ct);
        if (noticia is null) return BaseResponse.Falha("Notícia não encontrada.");
        _db.Noticias.Remove(noticia);
        await _db.SaveChangesAsync(ct);
        return BaseResponse.Ok("Notícia removida.");
    }

    public async Task<BaseResponse> ToggleNoticiasAtivasAsync(bool ativo, CancellationToken ct = default)
    {
        var academia = await _db.Academias.FirstOrDefaultAsync(a => a.Id == _tenant.AcademiaId, ct);
        if (academia is null) return BaseResponse.Falha("Academia não encontrada.");
        academia.NoticiasAtivas = ativo;
        await _db.SaveChangesAsync(ct);
        return BaseResponse.Ok(ativo ? "Seção de notícias ativada." : "Seção de notícias desativada.");
    }

    private async Task _notificarAlunosAsync(Noticia noticia, CancellationToken ct)
    {
        await _db.Notificacoes.AddAsync(new Notificacao
        {
            AcademiaId = _tenant.AcademiaId,
            Titulo = "Nova notícia publicada",
            Mensagem = noticia.Titulo,
            Tipo = TipoNotificacao.Info,
            ChaveDedup = $"noticia-publicada-{noticia.Id}"
        }, ct);
        await _db.SaveChangesAsync(ct);
    }

    private static NoticiaDto MapearDto(Noticia n) => new()
    {
        Id = n.Id,
        Titulo = n.Titulo,
        Resumo = n.Resumo,
        Conteudo = n.Conteudo,
        ImagemBase64 = null,
        Publicada = n.Publicada,
        PublicadaEm = n.PublicadaEm,
        AutorNome = n.Autor?.Nome,
        CriadoEm = n.CriadoEm
    };

    private static NoticiaDto MapearDtoCompleto(Noticia n) => new()
    {
        Id = n.Id,
        Titulo = n.Titulo,
        Resumo = n.Resumo,
        Conteudo = n.Conteudo,
        ImagemBase64 = n.ImagemBase64,
        Publicada = n.Publicada,
        PublicadaEm = n.PublicadaEm,
        AutorNome = n.Autor?.Nome,
        CriadoEm = n.CriadoEm
    };
}
