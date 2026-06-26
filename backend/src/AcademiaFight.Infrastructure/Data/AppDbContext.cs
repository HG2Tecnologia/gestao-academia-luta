using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Entities.Base;
using AcademiaFight.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace AcademiaFight.Infrastructure.Data;

public class AppDbContext : DbContext, IAppDbContext
{
    private readonly ITenantContext _tenantContext;

    public AppDbContext(DbContextOptions<AppDbContext> options, ITenantContext tenantContext)
        : base(options)
    {
        _tenantContext = tenantContext;
    }

    public DbSet<Academia> Academias => Set<Academia>();
    public DbSet<Usuario> Usuarios => Set<Usuario>();
    public DbSet<Funcionario> Funcionarios => Set<Funcionario>();
    public DbSet<Modalidade> Modalidades => Set<Modalidade>();
    public DbSet<Turma> Turmas => Set<Turma>();
    public DbSet<Horario> Horarios => Set<Horario>();
    public DbSet<Matricula> Matriculas => Set<Matricula>();
    public DbSet<Presenca> Presencas => Set<Presenca>();
    public DbSet<Faixa> Faixas => Set<Faixa>();
    public DbSet<Graduacao> Graduacoes => Set<Graduacao>();
    public DbSet<PontoRanking> PontosRanking => Set<PontoRanking>();
    public DbSet<Conquista> Conquistas => Set<Conquista>();
    public DbSet<ConquistaAluno> ConquistasAluno => Set<ConquistaAluno>();
    public DbSet<Pagamento> Pagamentos => Set<Pagamento>();
    public DbSet<Plano> Planos => Set<Plano>();
    public DbSet<Contrato> Contratos => Set<Contrato>();
    public DbSet<ModeloContrato> ModelosContrato => Set<ModeloContrato>();
    public DbSet<Notificacao> Notificacoes => Set<Notificacao>();
    public DbSet<RankingCustom> RankingsCustom => Set<RankingCustom>();
    public DbSet<LancamentoPonto> LancamentosPonto => Set<LancamentoPonto>();
    public DbSet<AtestadoMedico> AtestadosMedicos => Set<AtestadoMedico>();
    public DbSet<Noticia> Noticias => Set<Noticia>();
    public DbSet<ParQ> ParQs => Set<ParQ>();
    public DbSet<GrupoFamiliar> GruposFamiliares => Set<GrupoFamiliar>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);

        modelBuilder.Entity<Usuario>()
            .HasQueryFilter(u => u.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<Funcionario>()
            .HasQueryFilter(f => f.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<Modalidade>()
            .HasQueryFilter(m => m.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<Turma>()
            .HasQueryFilter(t => t.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<Horario>()
            .HasQueryFilter(h => h.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<Matricula>()
            .HasQueryFilter(m => m.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<Presenca>()
            .HasQueryFilter(p => p.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<Faixa>()
            .HasQueryFilter(f => f.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<Graduacao>()
            .HasQueryFilter(g => g.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<PontoRanking>()
            .HasQueryFilter(p => p.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<ConquistaAluno>()
            .HasQueryFilter(ca => ca.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<Pagamento>()
            .HasQueryFilter(p => p.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<Pagamento>()
            .Property(p => p.Valor)
            .HasPrecision(10, 2);

        modelBuilder.Entity<Plano>()
            .HasQueryFilter(p => p.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<Plano>()
            .Property(p => p.ValorMensal)
            .HasPrecision(10, 2);

        modelBuilder.Entity<Plano>()
            .Property(p => p.TaxaMatricula)
            .HasPrecision(10, 2);

        modelBuilder.Entity<Contrato>()
            .HasQueryFilter(c => c.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<ModeloContrato>()
            .HasQueryFilter(m => m.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<Notificacao>()
            .HasQueryFilter(n => n.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<RankingCustom>()
            .HasQueryFilter(r => r.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<LancamentoPonto>()
            .HasQueryFilter(l => l.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<AtestadoMedico>()
            .HasQueryFilter(a => a.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<Noticia>()
            .HasQueryFilter(n => n.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<ParQ>()
            .HasQueryFilter(p => p.AcademiaId == _tenantContext.AcademiaId);

        modelBuilder.Entity<Usuario>()
            .HasOne(u => u.Plano)
            .WithMany(p => p.Alunos)
            .HasForeignKey(u => u.PlanoId)
            .OnDelete(DeleteBehavior.SetNull);

        // Conquista não tem filtro de tenant — catálogo global
    }

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        var entradas = ChangeTracker.Entries()
            .Where(e => e.State is EntityState.Added or EntityState.Modified);

        foreach (var entrada in entradas)
        {
            if (entrada.State == EntityState.Added && _tenantContext.IsSet)
            {
                var propriedadeAcademiaId = entrada.Properties
                    .FirstOrDefault(p => p.Metadata.Name == "AcademiaId");

                if (propriedadeAcademiaId is not null
                    && propriedadeAcademiaId.CurrentValue is Guid guid
                    && guid == Guid.Empty)
                {
                    propriedadeAcademiaId.CurrentValue = _tenantContext.AcademiaId;
                }
            }

            if (entrada.Entity is EntityBase entidade && entrada.State == EntityState.Modified)
            {
                entidade.AtualizadoEm = DateTime.UtcNow;
            }
        }

        return await base.SaveChangesAsync(cancellationToken);
    }
}
