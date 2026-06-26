using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace AcademiaFight.Application.Interfaces;

public interface IAppDbContext
{
    DbSet<Academia> Academias { get; }
    DbSet<Usuario> Usuarios { get; }
    DbSet<Funcionario> Funcionarios { get; }
    DbSet<Modalidade> Modalidades { get; }
    DbSet<Turma> Turmas { get; }
    DbSet<Horario> Horarios { get; }
    DbSet<Matricula> Matriculas { get; }
    DbSet<Presenca> Presencas { get; }
    DbSet<Faixa> Faixas { get; }
    DbSet<Graduacao> Graduacoes { get; }
    DbSet<PontoRanking> PontosRanking { get; }
    DbSet<Conquista> Conquistas { get; }
    DbSet<ConquistaAluno> ConquistasAluno { get; }
    DbSet<Pagamento> Pagamentos { get; }
    DbSet<Plano> Planos { get; }
    DbSet<Contrato> Contratos { get; }
    DbSet<ModeloContrato> ModelosContrato { get; }
    DbSet<Notificacao> Notificacoes { get; }
    DbSet<RankingCustom> RankingsCustom { get; }
    DbSet<LancamentoPonto> LancamentosPonto { get; }
    DbSet<AtestadoMedico> AtestadosMedicos { get; }
    DbSet<Noticia> Noticias { get; }
    DbSet<ParQ> ParQs { get; }
    DbSet<GrupoFamiliar> GruposFamiliares { get; }
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
