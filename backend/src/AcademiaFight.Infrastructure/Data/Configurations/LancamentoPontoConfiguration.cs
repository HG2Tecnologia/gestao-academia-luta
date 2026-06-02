using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class LancamentoPontoConfiguration : IEntityTypeConfiguration<LancamentoPonto>
{
    public void Configure(EntityTypeBuilder<LancamentoPonto> builder)
    {
        builder.ToTable("lancamentos_ponto");
        builder.HasKey(l => l.Id);
        builder.Property(l => l.Id).HasColumnName("id");
        builder.Property(l => l.RankingCustomId).HasColumnName("ranking_custom_id").IsRequired();
        builder.Property(l => l.AlunoId).HasColumnName("aluno_id").IsRequired();
        builder.Property(l => l.AcademiaId).HasColumnName("academia_id").IsRequired();
        builder.Property(l => l.Pontos).HasColumnName("pontos").IsRequired();
        builder.Property(l => l.Descricao).HasColumnName("descricao").HasMaxLength(300).IsRequired();
        builder.Property(l => l.RegistradoPorId).HasColumnName("registrado_por_id").IsRequired();
        builder.Property(l => l.Data).HasColumnName("data").IsRequired();
        builder.Property(l => l.CriadoEm).HasColumnName("criado_em");
        builder.Property(l => l.AtualizadoEm).HasColumnName("atualizado_em");

        builder.HasOne(l => l.Aluno)
            .WithMany()
            .HasForeignKey(l => l.AlunoId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(l => l.RegistradoPor)
            .WithMany()
            .HasForeignKey(l => l.RegistradoPorId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(l => new { l.RankingCustomId, l.AlunoId });
        builder.HasIndex(l => new { l.AcademiaId, l.AlunoId });
    }
}
