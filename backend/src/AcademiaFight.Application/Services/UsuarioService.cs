using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Aluno;
using AcademiaFight.Application.DTOs.Usuario;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace AcademiaFight.Application.Services;

public class UsuarioService : IUsuarioService
{
    private readonly IAppDbContext _db;
    private readonly IPasswordHasher _hasher;

    public UsuarioService(IAppDbContext db, IPasswordHasher hasher)
    {
        _db = db;
        _hasher = hasher;
    }

    public async Task<BaseResponse<IEnumerable<UsuarioResumoDto>>> ListarProfessoresAsync(CancellationToken ct = default)
    {
        var professores = await _db.Usuarios
            .Where(u => u.Ativo && (u.Perfil == PerfilUsuario.Professor || u.Perfil == PerfilUsuario.Admin))
            .OrderBy(u => u.Nome)
            .Select(u => new UsuarioResumoDto { Id = u.Id, Nome = u.Nome, Email = u.Email })
            .ToListAsync(ct);

        return BaseResponse<IEnumerable<UsuarioResumoDto>>.Ok(professores);
    }

    public async Task<BaseResponse<PagedResult<AlunoDto>>> ListarAlunosAsync(
        string? nome, bool? ativo, int page, int pageSize, CancellationToken ct = default)
    {
        var query = _db.Usuarios.Where(u => u.Perfil == PerfilUsuario.Aluno);

        if (!string.IsNullOrWhiteSpace(nome))
            query = query.Where(u => u.Nome.ToLower().Contains(nome.ToLower()));

        if (ativo.HasValue)
            query = query.Where(u => u.Ativo == ativo.Value);

        var total = await query.CountAsync(ct);

        var alunosBase = await query
            .OrderBy(u => u.Nome)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new { u.Id, u.Nome, u.Email, u.Telefone, u.TipoPlano, u.PlanoId, u.DiaVencimento, u.Ativo, u.XpTotal, u.Nivel, u.CriadoEm, u.DataNascimento, PlanoNome = u.Plano != null ? u.Plano.Nome : null })
            .ToListAsync(ct);

        var ids = alunosBase.Select(a => a.Id).ToList();

        var turmasPorAluno = await _db.Matriculas
            .Where(m => ids.Contains(m.AlunoId) && m.Ativo)
            .Select(m => new { m.AlunoId, TurmaNome = m.Turma.Nome })
            .ToListAsync(ct);

        var graduacoes = await _db.Graduacoes
            .Where(g => ids.Contains(g.AlunoId) && g.Aprovado)
            .Select(g => new { g.AlunoId, FaixaNome = g.Faixa.Nome, FaixaCor = g.Faixa.Cor, FaixaCorBarra = g.Faixa.CorBarra, FaixaTemGraus = g.Faixa.TemGraus, FaixaMaxGraus = g.Faixa.MaxGraus, FaixaOrdem = g.Faixa.Ordem, g.Grau })
            .ToListAsync(ct);

        var pagamentos = await _db.Pagamentos
            .Where(p => ids.Contains(p.AlunoId) && p.Status != Domain.Enums.StatusPagamento.Cancelado)
            .Select(p => new { p.AlunoId, p.Status })
            .ToListAsync(ct);

        var turmasDict = turmasPorAluno
            .GroupBy(t => t.AlunoId)
            .ToDictionary(g => g.Key, g => g.Select(t => t.TurmaNome).ToList());

        var faixaDict = graduacoes
            .GroupBy(g => g.AlunoId)
            .ToDictionary(g => g.Key, g => g.OrderByDescending(x => x.FaixaOrdem).ThenByDescending(x => x.Grau).First());

        var pagamentosDict = pagamentos
            .GroupBy(p => p.AlunoId)
            .ToDictionary(g => g.Key, g => g.Select(p => p.Status).ToList());

        var atestados = await _db.AtestadosMedicos
            .Where(a => ids.Contains(a.AlunoId))
            .Select(a => new { a.AlunoId, a.Status, a.DataValidade })
            .ToListAsync(ct);

        var atestadoDict = atestados.ToDictionary(a => a.AlunoId);

        var itens = alunosBase.Select(u => new AlunoDto
        {
            Id = u.Id,
            Nome = u.Nome,
            Email = u.Email,
            Telefone = u.Telefone,
            TipoPlano = u.TipoPlano,
            PlanoId = u.PlanoId,
            PlanoNome = u.PlanoNome,
            DiaVencimento = u.DiaVencimento,
            Ativo = u.Ativo,
            XpTotal = u.XpTotal,
            Nivel = u.Nivel.ToString(),
            CriadoEm = u.CriadoEm,
            DataNascimento = u.DataNascimento?.ToString("yyyy-MM-dd"),
            Turmas = turmasDict.GetValueOrDefault(u.Id, []),
            FaixaAtualNome = faixaDict.TryGetValue(u.Id, out var f) ? f.FaixaNome : null,
            FaixaAtualCor = faixaDict.TryGetValue(u.Id, out var f2) ? f2.FaixaCor : null,
            FaixaAtualCorBarra = faixaDict.TryGetValue(u.Id, out var f4) ? f4.FaixaCorBarra : "#000000",
            FaixaAtualTemGraus = faixaDict.TryGetValue(u.Id, out var f5) ? f5.FaixaTemGraus : false,
            FaixaAtualMaxGraus = faixaDict.TryGetValue(u.Id, out var f6) ? f6.FaixaMaxGraus : 4,
            GrauAtual = faixaDict.TryGetValue(u.Id, out var f3) ? f3.Grau : 0,
            SituacaoFinanceira = ResolverSituacaoFinanceira(pagamentosDict.GetValueOrDefault(u.Id)),
            StatusAtestado = atestadoDict.TryGetValue(u.Id, out var at) ? at.Status : null,
            AtestadoValidade = atestadoDict.TryGetValue(u.Id, out var at2) ? at2.DataValidade : null,
        }).ToList();

        return BaseResponse<PagedResult<AlunoDto>>.Ok(new PagedResult<AlunoDto>
        {
            Itens = itens,
            TotalItens = total,
            Pagina = page,
            TamanhoPagina = pageSize,
        });
    }

    public async Task<BaseResponse<AlunoDto>> ObterAlunoPorIdAsync(Guid id, CancellationToken ct = default)
    {
        var u = await _db.Usuarios
            .Include(x => x.Plano)
            .FirstOrDefaultAsync(x => x.Id == id && x.Perfil == PerfilUsuario.Aluno, ct);
        if (u is null) return BaseResponse<AlunoDto>.Falha("Aluno não encontrado.");

        var turmas = await _db.Matriculas
            .Where(m => m.AlunoId == id && m.Ativo)
            .Select(m => m.Turma.Nome)
            .ToListAsync(ct);

        var turmasDetalhes = await _db.Matriculas
            .Where(m => m.AlunoId == id && m.Ativo)
            .Select(m => new TurmaResumoDto
            {
                Nome = m.Turma.Nome,
                ModalidadeId = m.Turma.ModalidadeId,
                NomeModalidade = m.Turma.Modalidade.Nome,
                TotalPresencas = _db.Presencas
                    .Join(_db.Horarios, p => p.HorarioId, h => h.Id, (p, h) => new { p.AlunoId, h.TurmaId })
                    .Count(x => x.AlunoId == id && x.TurmaId == m.TurmaId),
            })
            .ToListAsync(ct);

        var faixa = await _db.Graduacoes
            .Where(g => g.AlunoId == id && g.Aprovado)
            .OrderByDescending(g => g.Faixa.Ordem)
            .ThenByDescending(g => g.Grau)
            .Select(g => new { FaixaNome = g.Faixa.Nome, FaixaCor = g.Faixa.Cor, FaixaCorBarra = g.Faixa.CorBarra, FaixaTemGraus = g.Faixa.TemGraus, FaixaMaxGraus = g.Faixa.MaxGraus, g.Grau })
            .FirstOrDefaultAsync(ct);

        var statuses = await _db.Pagamentos
            .Where(p => p.AlunoId == id && p.Status != Domain.Enums.StatusPagamento.Cancelado)
            .Select(p => p.Status)
            .ToListAsync(ct);

        var dto = MapearAlunoDto(u);
        dto.Turmas = turmas;
        dto.TurmasDetalhes = turmasDetalhes;
        dto.FaixaAtualNome = faixa?.FaixaNome;
        dto.FaixaAtualCor = faixa?.FaixaCor;
        dto.FaixaAtualCorBarra = faixa?.FaixaCorBarra;
        dto.FaixaAtualTemGraus = faixa?.FaixaTemGraus ?? false;
        dto.FaixaAtualMaxGraus = faixa?.FaixaMaxGraus ?? 4;
        dto.GrauAtual = faixa?.Grau ?? 0;
        dto.PlanoNome = u.Plano?.Nome;
        dto.SituacaoFinanceira = ResolverSituacaoFinanceira(statuses);
        return BaseResponse<AlunoDto>.Ok(dto);
    }

    public async Task<BaseResponse<AlunoDto>> CriarAlunoAsync(CreateAlunoDto request, Guid academiaId, CancellationToken ct = default)
    {
        var academia = await _db.Academias.FindAsync([academiaId], ct);
        if (academia is null)
            return BaseResponse<AlunoDto>.Falha("Academia não encontrada.");

        if (academia.PlanoTipo == PlanoAcademia.Gratuito)
        {
            var totalAlunos = await _db.Usuarios
                .CountAsync(u => u.AcademiaId == academiaId && u.Perfil == PerfilUsuario.Aluno && u.Ativo, ct);
            if (totalAlunos >= PlanoLimites.MaxAlunosGratuito)
                return BaseResponse<AlunoDto>.Falha(
                    $"Limite de {PlanoLimites.MaxAlunosGratuito} alunos atingido no plano gratuito.",
                    PlanoLimites.CodigoLimitePlano);
        }

        var aluno = new Usuario
        {
            AcademiaId = academiaId,
            Nome = request.Nome,
            Email = string.IsNullOrWhiteSpace(request.Email) ? null : request.Email,
            SenhaHash = string.Empty,
            Perfil = PerfilUsuario.Aluno,
            Ativo = true,
            Telefone = request.Telefone,
            DataNascimento = ParseDate(request.DataNascimento),
            ContatoEmergenciaNome = request.ContatoEmergenciaNome,
            ContatoEmergenciaTelefone = request.ContatoEmergenciaTelefone,
            TipoPlano = request.TipoPlano,
            PlanoId = request.PlanoId,
            DiaVencimento = request.DiaVencimento,
        };

        _db.Usuarios.Add(aluno);
        await _db.SaveChangesAsync(ct);

        if (request.PlanoId.HasValue && request.DiaVencimento.HasValue)
        {
            var plano = await _db.Planos.FindAsync([request.PlanoId.Value], ct);
            if (plano is not null)
                await GerarPagamentosIniciaisAsync(aluno.Id, plano.ValorMensal, request.DiaVencimento.Value, ct);
        }

        return BaseResponse<AlunoDto>.Ok(MapearAlunoDto(aluno));
    }

    private async Task GerarPagamentosIniciaisAsync(Guid alunoId, decimal valorMensal, int diaVencimento, CancellationToken ct)
    {
        var hoje = DateOnly.FromDateTime(DateTime.UtcNow);
        const int mesesPrevisao = 12;

        for (int i = 0; i < mesesPrevisao; i++)
        {
            var refDate = hoje.AddMonths(i);
            var diasNoMes = DateTime.DaysInMonth(refDate.Year, refDate.Month);
            var dia = Math.Clamp(diaVencimento, 1, diasNoMes);
            var vencimento = new DateOnly(refDate.Year, refDate.Month, dia);

            StatusPagamento status;
            if (i == 0)
                status = vencimento < hoje ? StatusPagamento.Atrasado : StatusPagamento.Pendente;
            else
                status = StatusPagamento.Previsto;

            var descricao = new DateOnly(refDate.Year, refDate.Month, 1).ToString("MMMM/yyyy",
                new System.Globalization.CultureInfo("pt-BR"));

            _db.Pagamentos.Add(new Pagamento
            {
                AlunoId = alunoId,
                Tipo = TipoPagamento.Mensalidade,
                Status = status,
                Valor = valorMensal,
                Descricao = $"Mensalidade {char.ToUpper(descricao[0]) + descricao[1..]}",
                DataVencimento = vencimento,
            });
        }

        await _db.SaveChangesAsync(ct);
    }

    public async Task<BaseResponse<AlunoDto>> AtualizarAlunoAsync(Guid id, UpdateAlunoDto request, CancellationToken ct = default)
    {
        var aluno = await _db.Usuarios.FirstOrDefaultAsync(x => x.Id == id && x.Perfil == PerfilUsuario.Aluno, ct);
        if (aluno is null) return BaseResponse<AlunoDto>.Falha("Aluno não encontrado.");

        aluno.Nome = request.Nome;
        aluno.Email = string.IsNullOrWhiteSpace(request.Email) ? null : request.Email;
        aluno.Telefone = string.IsNullOrWhiteSpace(request.Telefone) ? aluno.Telefone : request.Telefone;
        aluno.DataNascimento = ParseDate(request.DataNascimento);
        aluno.ContatoEmergenciaNome = request.ContatoEmergenciaNome;
        aluno.ContatoEmergenciaTelefone = request.ContatoEmergenciaTelefone;
        aluno.TipoPlano = request.TipoPlano;
        aluno.PlanoId = request.PlanoId;
        aluno.DiaVencimento = request.DiaVencimento;
        aluno.Ativo = request.Ativo;

        await _db.SaveChangesAsync(ct);
        return BaseResponse<AlunoDto>.Ok(MapearAlunoDto(aluno));
    }

    public async Task<BaseResponse<AlunoDto>> ToggleAtivoAlunoAsync(Guid id, bool ativo, CancellationToken ct = default)
    {
        var aluno = await _db.Usuarios.FirstOrDefaultAsync(x => x.Id == id && x.Perfil == PerfilUsuario.Aluno, ct);
        if (aluno is null) return BaseResponse<AlunoDto>.Falha("Aluno não encontrado.");
        aluno.Ativo = ativo;

        if (!ativo)
        {
            // Cancel all future Previsto payments — they don't represent real revenue anymore
            var hoje = DateOnly.FromDateTime(DateTime.UtcNow);
            var futuros = await _db.Pagamentos
                .Where(p => p.AlunoId == id
                         && p.Status == AcademiaFight.Domain.Enums.StatusPagamento.Previsto
                         && p.DataVencimento > hoje)
                .ToListAsync(ct);
            foreach (var p in futuros)
                p.Status = AcademiaFight.Domain.Enums.StatusPagamento.Cancelado;
        }

        await _db.SaveChangesAsync(ct);
        return BaseResponse<AlunoDto>.Ok(MapearAlunoDto(aluno));
    }

    public async Task<BaseResponse<IEnumerable<AniversarianteDto>>> ListarAniversariantesAsync(int mes, CancellationToken ct = default)
    {
        var hoje = DateTime.UtcNow;
        var diaMinimo = mes == hoje.Month ? hoje.Day : 1;
        var alunos = await _db.Usuarios
            .Where(u => u.Perfil == PerfilUsuario.Aluno && u.Ativo && u.DataNascimento != null
                     && u.DataNascimento.Value.Month == mes
                     && u.DataNascimento.Value.Day >= diaMinimo)
            .OrderBy(u => u.DataNascimento!.Value.Day)
            .Select(u => new AniversarianteDto
            {
                Id = u.Id,
                Nome = u.Nome,
                DiaNascimento = u.DataNascimento!.Value.Day,
                MesNascimento = u.DataNascimento.Value.Month,
            })
            .ToListAsync(ct);

        return BaseResponse<IEnumerable<AniversarianteDto>>.Ok(alunos);
    }

    private static AlunoDto MapearAlunoDto(Usuario u) => new()
    {
        Id = u.Id,
        Nome = u.Nome,
        Email = u.Email,
        Telefone = u.Telefone,
        DataNascimento = u.DataNascimento?.ToString("yyyy-MM-dd"),
        ContatoEmergenciaNome = u.ContatoEmergenciaNome,
        ContatoEmergenciaTelefone = u.ContatoEmergenciaTelefone,
        TipoPlano = u.TipoPlano,
        PlanoId = u.PlanoId,
        PlanoNome = u.Plano?.Nome,
        DiaVencimento = u.DiaVencimento,
        Ativo = u.Ativo,
        XpTotal = u.XpTotal,
        Nivel = u.Nivel.ToString(),
        CriadoEm = u.CriadoEm,
        Turmas = [],
    };

    private static DateOnly? ParseDate(string? val) =>
        DateOnly.TryParse(val, out var d) ? d : null;

    private static string? ResolverSituacaoFinanceira(List<Domain.Enums.StatusPagamento>? statuses)
    {
        if (statuses is null || statuses.Count == 0) return null;
        if (statuses.Any(s => s == Domain.Enums.StatusPagamento.Atrasado)) return "Inadimplente";
        if (statuses.Any(s => s == Domain.Enums.StatusPagamento.Pendente)) return "Pendente";
        return "EmDia";
    }

    public async Task<BaseResponse<MeuPerfilDto>> ObterMeuPerfilAsync(Guid usuarioId, CancellationToken ct = default)
    {
        var usuario = await _db.Usuarios.FindAsync([usuarioId], ct);
        if (usuario is null)
            return BaseResponse<MeuPerfilDto>.Falha("Usuário não encontrado.");

        return BaseResponse<MeuPerfilDto>.Ok(new MeuPerfilDto
        {
            Id = usuario.Id,
            Nome = usuario.Nome,
            Email = usuario.Email,
            Telefone = usuario.Telefone,
            Perfil = usuario.Perfil.ToString(),
        });
    }

    public async Task<BaseResponse<MeuPerfilDto>> AtualizarMeuPerfilAsync(
        Guid usuarioId, AtualizarMeuPerfilRequest request, CancellationToken ct = default)
    {
        var usuario = await _db.Usuarios.FindAsync([usuarioId], ct);
        if (usuario is null)
            return BaseResponse<MeuPerfilDto>.Falha("Usuário não encontrado.");

        if (string.IsNullOrWhiteSpace(request.Nome))
            return BaseResponse<MeuPerfilDto>.Falha("Nome é obrigatório.");

        usuario.Nome = request.Nome.Trim();
        usuario.Telefone = string.IsNullOrWhiteSpace(request.Telefone) ? null : request.Telefone.Trim();
        await _db.SaveChangesAsync(ct);

        return BaseResponse<MeuPerfilDto>.Ok(new MeuPerfilDto
        {
            Id = usuario.Id,
            Nome = usuario.Nome,
            Email = usuario.Email,
            Telefone = usuario.Telefone,
            Perfil = usuario.Perfil.ToString(),
        });
    }

    public async Task<BaseResponse> RegistrarFcmTokenAsync(Guid usuarioId, string token, CancellationToken ct = default)
    {
        var usuario = await _db.Usuarios.FindAsync([usuarioId], ct);
        if (usuario is null)
            return BaseResponse.Falha("Usuário não encontrado.");

        usuario.FcmToken = string.IsNullOrWhiteSpace(token) ? null : token.Trim();
        await _db.SaveChangesAsync(ct);
        return BaseResponse.Ok("Token FCM registrado.");
    }

    public async Task<BaseResponse> ExcluirMinhaContaAsync(Guid usuarioId, CancellationToken ct = default)
    {
        var usuario = await _db.Usuarios.FindAsync([usuarioId], ct);
        if (usuario is null)
            return BaseResponse.Falha("Usuário não encontrado.");

        // Anonimiza os dados pessoais em vez de deletar o registro,
        // preservando integridade referencial (matrículas, pagamentos, presenças).
        usuario.Nome = "Conta Excluída";
        usuario.Email = null;
        usuario.Telefone = null;
        usuario.DataNascimento = null;
        usuario.ContatoEmergenciaNome = null;
        usuario.ContatoEmergenciaTelefone = null;
        usuario.SenhaHash = string.Empty;
        usuario.RefreshToken = null;
        usuario.RefreshTokenExpiry = null;
        usuario.FcmToken = null;
        usuario.Ativo = false;

        await _db.SaveChangesAsync(ct);
        return BaseResponse.Ok("Conta excluída com sucesso.");
    }
}
