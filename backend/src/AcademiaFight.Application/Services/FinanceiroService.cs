using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Financeiro;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using PerfilUsuario = AcademiaFight.Domain.Enums.PerfilUsuario;

namespace AcademiaFight.Application.Services;

public class FinanceiroService : IFinanceiroService
{
    private readonly IAppDbContext _db;

    public FinanceiroService(IAppDbContext db)
    {
        _db = db;
    }

    public async Task<BaseResponse<ResumoFinanceiroDto>> GetResumoAsync(int? ano = null, int? mes = null, CancellationToken ct = default)
    {
        var hoje = DateOnly.FromDateTime(DateTime.UtcNow);
        var anoRef = ano ?? hoje.Year;
        var mesRef = mes ?? hoje.Month;
        var inicioMes = new DateOnly(anoRef, mesRef, 1);
        var fimMes = inicioMes.AddMonths(1).AddDays(-1);

        var pagamentos = await _db.Pagamentos
            .Include(p => p.Aluno)
            .ToListAsync(ct);

        var recebidoMes = pagamentos
            .Where(p => p.Status == StatusPagamento.Pago && p.DataPagamento >= inicioMes && p.DataPagamento <= fimMes)
            .Sum(p => p.Valor);

        var pendenteMes = pagamentos
            .Where(p => p.Status == StatusPagamento.Pendente && p.DataVencimento >= inicioMes && p.DataVencimento <= fimMes)
            .Sum(p => p.Valor);

        var atrasados = pagamentos
            .Where(p => (p.Status == StatusPagamento.Pendente || p.Status == StatusPagamento.Atrasado)
                        && p.DataVencimento < hoje)
            .ToList();

        var totalAtrasado = atrasados.Sum(p => p.Valor);

        var inadimplentesIds = atrasados.Select(p => p.AlunoId).Distinct().ToHashSet();

        var totalAlunos = await _db.Usuarios
            .CountAsync(u => u.Perfil == PerfilUsuario.Aluno && u.Ativo, ct);

        var inadimplentes = atrasados
            .GroupBy(p => p.AlunoId)
            .Select(g => new AlunoInadimplenteDto
            {
                AlunoId = g.Key,
                NomeAluno = g.First().Aluno.Nome,
                TotalDevido = g.Sum(p => p.Valor),
                DiasAtraso = g.Max(p => p.DataVencimento.HasValue ? (hoje.DayNumber - p.DataVencimento.Value.DayNumber) : 0),
                UltimoVencimento = g.Max(p => p.DataVencimento)?.ToString("yyyy-MM-dd"),
            })
            .OrderByDescending(i => i.TotalDevido)
            .ToList();

        var recentes = pagamentos
            .OrderByDescending(p => p.CriadoEm)
            .Take(10)
            .Select(MapDto)
            .ToList();

        return BaseResponse<ResumoFinanceiroDto>.Ok(new ResumoFinanceiroDto
        {
            TotalRecebidoMes = recebidoMes,
            TotalPendenteMes = pendenteMes,
            TotalAtrasado = totalAtrasado,
            TotalAlunos = totalAlunos,
            AlunosInadimplentes = inadimplentesIds.Count,
            AlunosEmDia = totalAlunos - inadimplentesIds.Count,
            PagamentosRecentes = recentes,
            Inadimplentes = inadimplentes,
        });
    }

    public async Task<BaseResponse<IEnumerable<PagamentoDto>>> ListarAsync(
        Guid? alunoId, string? status, int? ano, int? mes, int page, int pageSize, CancellationToken ct = default)
    {
        var query = _db.Pagamentos.Include(p => p.Aluno).AsQueryable();

        if (alunoId.HasValue)
            query = query.Where(p => p.AlunoId == alunoId.Value);

        if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<StatusPagamento>(status, true, out var s))
            query = query.Where(p => p.Status == s);

        if (ano.HasValue && mes.HasValue)
        {
            var inicio = new DateOnly(ano.Value, mes.Value, 1);
            var fim = inicio.AddMonths(1).AddDays(-1);
            query = query.Where(p => p.DataVencimento >= inicio && p.DataVencimento <= fim);
        }

        var itens = await query
            .OrderByDescending(p => p.CriadoEm)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        return BaseResponse<IEnumerable<PagamentoDto>>.Ok(itens.Select(MapDto));
    }

    public async Task<BaseResponse<IEnumerable<PagamentoDto>>> ListarPorAlunoAsync(Guid alunoId, CancellationToken ct = default)
    {
        var itens = await _db.Pagamentos
            .Include(p => p.Aluno)
            .Where(p => p.AlunoId == alunoId)
            .OrderByDescending(p => p.CriadoEm)
            .ToListAsync(ct);

        return BaseResponse<IEnumerable<PagamentoDto>>.Ok(itens.Select(MapDto));
    }

    public async Task<BaseResponse<PagamentoDto>> CriarAsync(CreatePagamentoDto dto, CancellationToken ct = default)
    {
        var pagamento = new Pagamento
        {
            AlunoId = dto.AlunoId,
            Tipo = (TipoPagamento)dto.Tipo,
            Status = (StatusPagamento)dto.Status,
            Valor = dto.Valor,
            Descricao = dto.Descricao,
            DataVencimento = ParseDate(dto.DataVencimento),
            DataPagamento = ParseDate(dto.DataPagamento),
            FormaPagamento = dto.FormaPagamento,
            Observacoes = dto.Observacoes,
        };

        _db.Pagamentos.Add(pagamento);
        await _db.SaveChangesAsync(ct);

        await _db.Pagamentos.Entry(pagamento).Reference(p => p.Aluno).LoadAsync(ct);
        return BaseResponse<PagamentoDto>.Ok(MapDto(pagamento));
    }

    public async Task<BaseResponse<PagamentoDto>> AtualizarAsync(Guid id, UpdatePagamentoDto dto, CancellationToken ct = default)
    {
        var pagamento = await _db.Pagamentos.Include(p => p.Aluno).FirstOrDefaultAsync(p => p.Id == id, ct);
        if (pagamento is null) return BaseResponse<PagamentoDto>.Falha("Pagamento não encontrado.");

        pagamento.Status = (StatusPagamento)dto.Status;
        pagamento.DataPagamento = ParseDate(dto.DataPagamento);
        pagamento.FormaPagamento = dto.FormaPagamento;
        pagamento.Observacoes = dto.Observacoes;

        await _db.SaveChangesAsync(ct);
        return BaseResponse<PagamentoDto>.Ok(MapDto(pagamento));
    }

    public async Task<BaseResponse<bool>> DeletarAsync(Guid id, CancellationToken ct = default)
    {
        var pagamento = await _db.Pagamentos.FirstOrDefaultAsync(p => p.Id == id, ct);
        if (pagamento is null) return BaseResponse<bool>.Falha("Pagamento não encontrado.");

        _db.Pagamentos.Remove(pagamento);
        await _db.SaveChangesAsync(ct);
        return BaseResponse<bool>.Ok(true);
    }

    public async Task<BaseResponse<int>> GerarCobrancasMensaisAsync(CancellationToken ct = default)
    {
        var hoje = DateOnly.FromDateTime(DateTime.UtcNow);
        var inicioMes = new DateOnly(hoje.Year, hoje.Month, 1);
        var fimMes = inicioMes.AddMonths(1).AddDays(-1);

        var alunos = await _db.Usuarios
            .Where(u => u.Perfil == PerfilUsuario.Aluno && u.Ativo && u.PlanoId != null && u.DiaVencimento != null)
            .Include(u => u.Plano)
            .ToListAsync(ct);

        if (alunos.Count == 0)
            return BaseResponse<int>.Ok(0);

        var alunoIds = alunos.Select(a => a.Id).ToList();

        var jaExistem = await _db.Pagamentos
            .Where(p => alunoIds.Contains(p.AlunoId)
                     && p.Tipo == TipoPagamento.Mensalidade
                     && p.DataVencimento >= inicioMes
                     && p.DataVencimento <= fimMes)
            .Select(p => p.AlunoId)
            .ToListAsync(ct);

        var jaExistemSet = jaExistem.ToHashSet();
        var diasNoMes = DateTime.DaysInMonth(hoje.Year, hoje.Month);
        var gerados = 0;

        foreach (var aluno in alunos)
        {
            if (jaExistemSet.Contains(aluno.Id)) continue;

            var dia = Math.Clamp(aluno.DiaVencimento!.Value, 1, diasNoMes);
            var vencimento = new DateOnly(hoje.Year, hoje.Month, dia);
            var status = vencimento < hoje ? StatusPagamento.Atrasado : StatusPagamento.Pendente;

            _db.Pagamentos.Add(new Pagamento
            {
                AlunoId = aluno.Id,
                Tipo = TipoPagamento.Mensalidade,
                Status = status,
                Valor = aluno.Plano!.ValorMensal,
                Descricao = $"Mensalidade {inicioMes:MMMM/yyyy}",
                DataVencimento = vencimento,
            });
            gerados++;
        }

        if (gerados > 0)
            await _db.SaveChangesAsync(ct);

        return BaseResponse<int>.Ok(gerados);
    }

    private static PagamentoDto MapDto(Pagamento p) => new()
    {
        Id = p.Id,
        AlunoId = p.AlunoId,
        NomeAluno = p.Aluno?.Nome ?? string.Empty,
        TelefoneAluno = p.Aluno?.Telefone,
        Tipo = p.Tipo.ToString(),
        Status = p.Status.ToString(),
        Valor = p.Valor,
        Descricao = p.Descricao,
        DataVencimento = p.DataVencimento?.ToString("yyyy-MM-dd"),
        DataPagamento = p.DataPagamento?.ToString("yyyy-MM-dd"),
        FormaPagamento = p.FormaPagamento,
        Observacoes = p.Observacoes,
        CriadoEm = p.CriadoEm,
    };

    public async Task<BaseResponse<RelatorioAnualDto>> GetRelatorioAnualAsync(int ano, CancellationToken ct = default)
    {
        var hoje = DateOnly.FromDateTime(DateTime.UtcNow);

        // Pagamentos do ano
        var inicioAno = new DateOnly(ano, 1, 1);
        var fimAno = new DateOnly(ano, 12, 31);

        var pagamentos = await _db.Pagamentos
            .Include(p => p.Aluno)
            .Where(p => p.DataVencimento >= inicioAno && p.DataVencimento <= fimAno
                     || p.DataPagamento >= inicioAno && p.DataPagamento <= fimAno)
            .ToListAsync(ct);

        var receitaMensal = Enumerable.Range(1, 12).Select(mes =>
        {
            var inicioMes = new DateOnly(ano, mes, 1);
            var fimMes = inicioMes.AddMonths(1).AddDays(-1);

            var recebido = pagamentos
                .Where(p => p.Status == StatusPagamento.Pago
                         && p.DataPagamento >= inicioMes && p.DataPagamento <= fimMes)
                .Sum(p => p.Valor);

            var pendente = pagamentos
                .Where(p => p.Status == StatusPagamento.Pendente
                         && p.DataVencimento >= inicioMes && p.DataVencimento <= fimMes)
                .Sum(p => p.Valor);

            var atrasado = pagamentos
                .Where(p => (p.Status == StatusPagamento.Atrasado
                          || (p.Status == StatusPagamento.Pendente && p.DataVencimento < hoje))
                         && p.DataVencimento >= inicioMes && p.DataVencimento <= fimMes)
                .Sum(p => p.Valor);

            return new ReceitaMensalDto { Ano = ano, Mes = mes, Recebido = recebido, Pendente = pendente, Atrasado = atrasado };
        }).ToList();

        // Presenças do ano
        var presencas = await _db.Presencas
            .Where(p => p.Data >= inicioAno && p.Data <= fimAno)
            .Select(p => new { p.Data, p.AlunoId })
            .ToListAsync(ct);

        var frequenciaMensal = Enumerable.Range(1, 12).Select(mes =>
        {
            var doMes = presencas.Where(p => p.Data.Year == ano && p.Data.Month == mes).ToList();
            return new FrequenciaMensalDto
            {
                Ano = ano, Mes = mes,
                TotalPresencas = doMes.Count,
                AlunosUnicos = doMes.Select(p => p.AlunoId).Distinct().Count()
            };
        }).ToList();

        // Inadimplentes atuais
        var atrasados = await _db.Pagamentos
            .Include(p => p.Aluno)
            .Where(p => (p.Status == StatusPagamento.Pendente || p.Status == StatusPagamento.Atrasado)
                     && p.DataVencimento < hoje)
            .ToListAsync(ct);

        var inadimplentes = atrasados
            .GroupBy(p => p.AlunoId)
            .Select(g => new AlunoInadimplenteDto
            {
                AlunoId = g.Key,
                NomeAluno = g.First().Aluno?.Nome ?? string.Empty,
                TotalDevido = g.Sum(p => p.Valor),
                DiasAtraso = g.Max(p => p.DataVencimento.HasValue ? (hoje.DayNumber - p.DataVencimento.Value.DayNumber) : 0),
                UltimoVencimento = g.Max(p => p.DataVencimento)?.ToString("yyyy-MM-dd"),
            })
            .OrderByDescending(i => i.TotalDevido)
            .ToList();

        var totalAlunos = await _db.Usuarios
            .CountAsync(u => u.Perfil == PerfilUsuario.Aluno && u.Ativo, ct);

        return BaseResponse<RelatorioAnualDto>.Ok(new RelatorioAnualDto
        {
            Ano = ano,
            TotalRecebidoAno = receitaMensal.Sum(r => r.Recebido),
            TotalAlunosAtivos = totalAlunos,
            TotalInadimplentes = inadimplentes.Count,
            ReceitaMensal = receitaMensal,
            FrequenciaMensal = frequenciaMensal,
            Inadimplentes = inadimplentes,
        });
    }

    private static DateOnly? ParseDate(string? val) =>
        DateOnly.TryParse(val, out var d) ? d : null;
}
