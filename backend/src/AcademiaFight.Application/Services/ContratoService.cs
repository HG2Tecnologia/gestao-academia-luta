using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Contrato;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using AcademiaFight.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Application.Services;

public class ContratoService : IContratoService
{
    private readonly IAppDbContext _db;
    private readonly ITenantContext _tenant;
    private readonly ILogger<ContratoService> _logger;
    private readonly IRankingNotifier _notifier;

    public ContratoService(IAppDbContext db, ITenantContext tenant, ILogger<ContratoService> logger, IRankingNotifier notifier)
    {
        _db = db;
        _tenant = tenant;
        _logger = logger;
        _notifier = notifier;
    }

    public async Task<BaseResponse<IEnumerable<ContratoDto>>> ListarAsync(Guid? alunoId = null, CancellationToken ct = default)
    {
        var query = _db.Contratos.Include(c => c.Aluno).Include(c => c.Modalidade).AsQueryable();
        if (alunoId.HasValue)
            query = query.Where(c => c.AlunoId == alunoId.Value);

        var lista = await query.OrderByDescending(c => c.CriadoEm).ToListAsync(ct);
        return BaseResponse<IEnumerable<ContratoDto>>.Ok(lista.Select(MapearDto));
    }

    public async Task<BaseResponse<ContratoDetalheDto>> ObterAsync(Guid id, CancellationToken ct = default)
    {
        var contrato = await _db.Contratos.Include(c => c.Aluno).Include(c => c.Modalidade).FirstOrDefaultAsync(c => c.Id == id, ct);
        if (contrato is null)
            return BaseResponse<ContratoDetalheDto>.Falha("Contrato não encontrado.");

        return BaseResponse<ContratoDetalheDto>.Ok(MapearDetalheDto(contrato));
    }

    public async Task<BaseResponse<ContratoPublicoDto>> ObterPorTokenAsync(Guid token, CancellationToken ct = default)
    {
        var contrato = await _db.Contratos
            .IgnoreQueryFilters()
            .Include(c => c.Aluno)
            .Include(c => c.Academia)
            .FirstOrDefaultAsync(c => c.TokenPublico == token, ct);

        if (contrato is null)
            return BaseResponse<ContratoPublicoDto>.Falha("Contrato não encontrado.");

        return BaseResponse<ContratoPublicoDto>.Ok(new ContratoPublicoDto
        {
            Id = contrato.Id,
            NomeAluno = contrato.Aluno?.Nome ?? string.Empty,
            NomeAcademia = contrato.Academia?.Nome ?? string.Empty,
            LogoUrl = contrato.Academia?.LogoUrl,
            ConteudoHtml = contrato.ConteudoHtml,
            Status = contrato.Status,
            DataAssinatura = contrato.DataAssinatura,
            NomeAssinou = contrato.NomeAssinou,
        });
    }

    public async Task<BaseResponse<ContratoDto>> CriarAsync(CreateContratoRequest request, CancellationToken ct = default)
    {
        var aluno = await _db.Usuarios
            .Include(u => u.Plano)
            .FirstOrDefaultAsync(u => u.Id == request.AlunoId && u.Ativo, ct);

        if (aluno is null)
            return BaseResponse<ContratoDto>.Falha("Aluno não encontrado.");

        var academia = await _db.Academias.FirstOrDefaultAsync(a => a.Id == _tenant.AcademiaId, ct);
        if (academia is null)
            return BaseResponse<ContratoDto>.Falha("Academia não encontrada.");

        Matricula? matricula = null;
        if (request.MatriculaId.HasValue)
        {
            matricula = await _db.Matriculas
                .Include(m => m.Turma).ThenInclude(t => t.Modalidade)
                .FirstOrDefaultAsync(m => m.Id == request.MatriculaId.Value, ct);
        }

        string templateHtml;
        if (request.ModeloContratoId.HasValue)
        {
            var modelo = await _db.ModelosContrato.FirstOrDefaultAsync(m => m.Id == request.ModeloContratoId.Value, ct);
            templateHtml = modelo?.ConteudoHtml ?? academia.TemplateContrato ?? TemplateContratoPadrao();
        }
        else
        {
            templateHtml = academia.TemplateContrato ?? TemplateContratoPadrao();
        }

        // Cancel any existing active (non-cancelled) contracts for the same aluno+modalidade
        if (request.ModalidadeId.HasValue)
        {
            var existentes = await _db.Contratos
                .Where(c => c.AlunoId == request.AlunoId
                         && c.ModalidadeId == request.ModalidadeId.Value
                         && c.Status != StatusContrato.Cancelado)
                .ToListAsync(ct);
            foreach (var e in existentes)
                e.Status = StatusContrato.Cancelado;
        }

        var conteudo = SubstituirVariaveis(templateHtml, aluno, academia, matricula);

        var contrato = new Contrato
        {
            AlunoId = request.AlunoId,
            MatriculaId = request.MatriculaId,
            ModalidadeId = request.ModalidadeId,
            ModeloContratoId = request.ModeloContratoId,
            ConteudoHtml = conteudo,
            Status = StatusContrato.Pendente,
            TokenPublico = Guid.NewGuid(),
        };

        await _db.Contratos.AddAsync(contrato, ct);
        await _db.SaveChangesAsync(ct);

        var completo = await _db.Contratos.Include(c => c.Aluno).FirstAsync(c => c.Id == contrato.Id, ct);
        _logger.LogInformation("Contrato {ContratoId} criado para aluno {AlunoId}", contrato.Id, request.AlunoId);
        return BaseResponse<ContratoDto>.Ok(MapearDto(completo), "Contrato criado com sucesso.");
    }

    public async Task<BaseResponse<ContratoDto>> AssinarAsync(Guid id, AssinarContratoRequest request, string? ipAddress, CancellationToken ct = default)
    {
        var contrato = await _db.Contratos.Include(c => c.Aluno).FirstOrDefaultAsync(c => c.Id == id, ct);
        if (contrato is null)
            return BaseResponse<ContratoDto>.Falha("Contrato não encontrado.");

        if (contrato.Status != StatusContrato.Pendente)
            return BaseResponse<ContratoDto>.Falha("Este contrato não pode ser assinado (status atual: " + contrato.Status + ").");

        contrato.Status = StatusContrato.Assinado;
        contrato.DataAssinatura = DateTime.UtcNow;
        contrato.IpAssinatura = ipAddress;
        contrato.NomeAssinou = request.NomeCompleto;

        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("Contrato {ContratoId} assinado por {Nome} (IP: {Ip})", id, request.NomeCompleto, ipAddress);
        return BaseResponse<ContratoDto>.Ok(MapearDto(contrato), "Contrato assinado com sucesso.");
    }

    public async Task<BaseResponse<ContratoDto>> AssinarPorTokenAsync(Guid token, AssinarContratoRequest request, string? ipAddress, CancellationToken ct = default)
    {
        var contrato = await _db.Contratos
            .IgnoreQueryFilters()
            .Include(c => c.Aluno)
            .FirstOrDefaultAsync(c => c.TokenPublico == token, ct);

        if (contrato is null)
            return BaseResponse<ContratoDto>.Falha("Contrato não encontrado.");

        if (contrato.Status != StatusContrato.Pendente)
            return BaseResponse<ContratoDto>.Falha("Este contrato já foi " + (contrato.Status == StatusContrato.Assinado ? "assinado." : "cancelado."));

        contrato.Status = StatusContrato.Assinado;
        contrato.DataAssinatura = DateTime.UtcNow;
        contrato.IpAssinatura = ipAddress;
        contrato.NomeAssinou = request.NomeCompleto;

        await _db.Notificacoes.AddAsync(new Notificacao
        {
            AcademiaId = contrato.AcademiaId,
            Titulo = "📄 Contrato assinado!",
            Mensagem = $"{request.NomeCompleto} assinou o contrato de {contrato.Aluno?.Nome ?? "aluno"}.",
            Tipo = TipoNotificacao.Info,
            Lida = false,
        }, ct);

        await _db.SaveChangesAsync(ct);

        _ = _notifier.NotificarNovaNotificacaoAsync(contrato.AcademiaId, ct);

        _logger.LogInformation("Contrato {ContratoId} assinado publicamente por {Nome} (IP: {Ip})", contrato.Id, request.NomeCompleto, ipAddress);
        return BaseResponse<ContratoDto>.Ok(MapearDto(contrato), "Contrato assinado com sucesso.");
    }

    public async Task<BaseResponse> CancelarAsync(Guid id, CancellationToken ct = default)
    {
        var contrato = await _db.Contratos.FirstOrDefaultAsync(c => c.Id == id, ct);
        if (contrato is null)
            return BaseResponse.Falha("Contrato não encontrado.");

        contrato.Status = StatusContrato.Cancelado;
        await _db.SaveChangesAsync(ct);

        return BaseResponse.Ok("Contrato cancelado.");
    }

    private static string SubstituirVariaveis(string template, Usuario aluno, Academia academia, Matricula? matricula)
    {
        var hoje = DateTime.Now.ToString("dd/MM/yyyy");
        var plano = aluno.Plano?.Nome ?? aluno.TipoPlano ?? "—";
        var valor = aluno.Plano != null ? aluno.Plano.ValorMensal.ToString("C2", new System.Globalization.CultureInfo("pt-BR")) : "—";
        var modalidade = matricula?.Turma?.Modalidade?.Nome ?? "—";
        var dataInicio = matricula?.DataInicio.ToString("dd/MM/yyyy") ?? hoje;
        var dataFim = matricula?.DataFim?.ToString("dd/MM/yyyy") ?? "—";
        var nascimento = aluno.DataNascimento?.ToString("dd/MM/yyyy") ?? "—";
        var cnpj = academia.Cnpj ?? "—";

        return template
            .Replace("{{nomeAluno}}", aluno.Nome)
            .Replace("{{email}}", aluno.Email ?? "—")
            .Replace("{{telefone}}", aluno.Telefone ?? "—")
            .Replace("{{dataNascimento}}", nascimento)
            .Replace("{{plano}}", plano)
            .Replace("{{valor}}", valor)
            .Replace("{{modalidade}}", modalidade)
            .Replace("{{dataInicio}}", dataInicio)
            .Replace("{{dataFim}}", dataFim)
            .Replace("{{academia}}", academia.Nome)
            .Replace("{{cnpj}}", cnpj)
            .Replace("{{dataContrato}}", hoje);
    }

    private static string TemplateContratoPadrao() => """
        <h2>Contrato de Prestação de Serviços</h2>
        <p><strong>Academia:</strong> {{academia}} &nbsp;|&nbsp; <strong>CNPJ:</strong> {{cnpj}}</p>
        <p><strong>Data:</strong> {{dataContrato}}</p>
        <hr/>
        <h3>Dados do Aluno</h3>
        <p><strong>Nome:</strong> {{nomeAluno}}</p>
        <p><strong>E-mail:</strong> {{email}}</p>
        <p><strong>Telefone:</strong> {{telefone}}</p>
        <p><strong>Data de Nascimento:</strong> {{dataNascimento}}</p>
        <hr/>
        <h3>Plano Contratado</h3>
        <p><strong>Plano:</strong> {{plano}}</p>
        <p><strong>Modalidade:</strong> {{modalidade}}</p>
        <p><strong>Valor Mensal:</strong> {{valor}}</p>
        <p><strong>Início:</strong> {{dataInicio}}</p>
        <hr/>
        <h3>Cláusulas</h3>
        <p>1. O aluno se compromete a cumprir as normas internas da academia.</p>
        <p>2. O pagamento da mensalidade deverá ser efetuado até o vencimento acordado.</p>
        <p>3. A academia se reserva o direito de suspender o acesso em caso de inadimplência.</p>
        <p>4. O cancelamento deverá ser solicitado com 30 dias de antecedência.</p>
        <p>Ao assinar este contrato digitalmente, o aluno declara ter lido e concordado com todos os termos acima.</p>
        <hr/>
        <div style="margin-top:32px;">
          <p><strong>{{academia}}</strong></p>
          <p>CNPJ: {{cnpj}}</p>
        </div>
        """;

    private static ContratoDto MapearDto(Contrato c) => new()
    {
        Id = c.Id,
        AlunoId = c.AlunoId,
        NomeAluno = c.Aluno?.Nome ?? string.Empty,
        MatriculaId = c.MatriculaId,
        ModalidadeId = c.ModalidadeId,
        NomeModalidade = c.Modalidade?.Nome,
        Status = c.Status,
        DataAssinatura = c.DataAssinatura,
        NomeAssinou = c.NomeAssinou,
        CriadoEm = c.CriadoEm,
        TokenPublico = c.TokenPublico,
    };

    private static ContratoDetalheDto MapearDetalheDto(Contrato c) => new()
    {
        Id = c.Id,
        AlunoId = c.AlunoId,
        NomeAluno = c.Aluno?.Nome ?? string.Empty,
        MatriculaId = c.MatriculaId,
        ModalidadeId = c.ModalidadeId,
        NomeModalidade = c.Modalidade?.Nome,
        Status = c.Status,
        DataAssinatura = c.DataAssinatura,
        IpAssinatura = c.IpAssinatura,
        NomeAssinou = c.NomeAssinou,
        CriadoEm = c.CriadoEm,
        ConteudoHtml = c.ConteudoHtml,
        TokenPublico = c.TokenPublico,
    };
}
