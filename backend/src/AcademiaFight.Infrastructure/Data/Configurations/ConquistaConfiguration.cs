using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class ConquistaConfiguration : IEntityTypeConfiguration<Conquista>
{
    public void Configure(EntityTypeBuilder<Conquista> builder)
    {
        builder.ToTable("conquistas");
        builder.HasKey(c => c.Id);
        builder.Property(c => c.Id).HasColumnName("id");
        builder.Property(c => c.Tipo).HasColumnName("tipo").IsRequired();
        builder.Property(c => c.Nome).HasColumnName("nome").HasMaxLength(100).IsRequired();
        builder.Property(c => c.Descricao).HasColumnName("descricao").HasMaxLength(300).IsRequired();
        builder.Property(c => c.IconeUrl).HasColumnName("icone_url").HasMaxLength(200).IsRequired();
        builder.Property(c => c.PontosXpBonus).HasColumnName("pontos_xp_bonus").IsRequired();
        builder.Property(c => c.CriadoEm).HasColumnName("criado_em");
        builder.Property(c => c.AtualizadoEm).HasColumnName("atualizado_em");

        builder.HasIndex(c => c.Tipo).IsUnique();

        // Seed do catálogo global de conquistas (datas estáticas — sem DateTime.UtcNow)
        var seedDate = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);
        builder.HasData(
            new Conquista { Id = new Guid("00000000-0000-0000-0001-000000000001"), Tipo = TipoConquista.PrimeiroTreino, Nome = "Primeiro Treino",  Descricao = "Registrou sua primeira presença na academia.",              IconeUrl = "star", PontosXpBonus = 0,   CriadoEm = seedDate },
            new Conquista { Id = new Guid("00000000-0000-0000-0001-000000000002"), Tipo = TipoConquista.SemanaPerfeira, Nome = "Semana Perfeita",  Descricao = "Treinou 5 vezes em 7 dias corridos.",                       IconeUrl = "fire", PontosXpBonus = 25,  CriadoEm = seedDate },
            new Conquista { Id = new Guid("00000000-0000-0000-0001-000000000003"), Tipo = TipoConquista.MesInvicto,    Nome = "Mes Invicto",      Descricao = "100% de frequencia em um mes.",                             IconeUrl = "trophy", PontosXpBonus = 50, CriadoEm = seedDate },
            new Conquista { Id = new Guid("00000000-0000-0000-0001-000000000004"), Tipo = TipoConquista.Graduado,      Nome = "Graduado",         Descricao = "Conquistou sua primeira faixa.",                            IconeUrl = "medal", PontosXpBonus = 100, CriadoEm = seedDate },
            new Conquista { Id = new Guid("00000000-0000-0000-0001-000000000005"), Tipo = TipoConquista.Sequencia10,   Nome = "Sequencia de 10",  Descricao = "10 presencas consecutivas sem faltar.",                     IconeUrl = "bolt",  PontosXpBonus = 30,  CriadoEm = seedDate },
            new Conquista { Id = new Guid("00000000-0000-0000-0001-000000000006"), Tipo = TipoConquista.Veterano50,    Nome = "Veterano",         Descricao = "50 presencas totais registradas.",                          IconeUrl = "muscle", PontosXpBonus = 80, CriadoEm = seedDate },
            new Conquista { Id = new Guid("00000000-0000-0000-0001-000000000007"), Tipo = TipoConquista.Lenda100,      Nome = "Lenda",            Descricao = "100 presencas totais - voce e uma lenda desta academia!",  IconeUrl = "crown", PontosXpBonus = 150, CriadoEm = seedDate }
        );
    }
}
