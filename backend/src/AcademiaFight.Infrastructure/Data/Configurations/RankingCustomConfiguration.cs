using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class RankingCustomConfiguration : IEntityTypeConfiguration<RankingCustom>
{
    public void Configure(EntityTypeBuilder<RankingCustom> builder)
    {
        builder.ToTable("rankings_custom");
        builder.HasKey(r => r.Id);
        builder.Property(r => r.Id).HasColumnName("id");
        builder.Property(r => r.AcademiaId).HasColumnName("academia_id").IsRequired();
        builder.Property(r => r.Nome).HasColumnName("nome").HasMaxLength(100).IsRequired();
        builder.Property(r => r.Descricao).HasColumnName("descricao").HasMaxLength(500);
        builder.Property(r => r.IncluirPresencas).HasColumnName("incluir_presencas").IsRequired();
        builder.Property(r => r.IncluirPontosManuais).HasColumnName("incluir_pontos_manuais").IsRequired();
        builder.Property(r => r.PesoPresencas).HasColumnName("peso_presencas").IsRequired();
        builder.Property(r => r.PesoManuais).HasColumnName("peso_manuais").IsRequired();
        builder.Property(r => r.VisivelParaAluno).HasColumnName("visivel_para_aluno").IsRequired();
        builder.Property(r => r.Ativo).HasColumnName("ativo").IsRequired();
        builder.Property(r => r.CriadoEm).HasColumnName("criado_em");
        builder.Property(r => r.AtualizadoEm).HasColumnName("atualizado_em");

        builder.HasOne(r => r.Academia)
            .WithMany()
            .HasForeignKey(r => r.AcademiaId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(r => r.Lancamentos)
            .WithOne(l => l.RankingCustom)
            .HasForeignKey(l => l.RankingCustomId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(r => new { r.AcademiaId, r.Ativo });
    }
}
