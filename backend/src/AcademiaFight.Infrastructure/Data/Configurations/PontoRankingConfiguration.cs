using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class PontoRankingConfiguration : IEntityTypeConfiguration<PontoRanking>
{
    public void Configure(EntityTypeBuilder<PontoRanking> builder)
    {
        builder.ToTable("pontos_ranking");
        builder.HasKey(p => p.Id);
        builder.Property(p => p.Id).HasColumnName("id");
        builder.Property(p => p.AcademiaId).HasColumnName("academia_id").IsRequired();
        builder.Property(p => p.AlunoId).HasColumnName("aluno_id").IsRequired();
        builder.Property(p => p.TipoEvento).HasColumnName("tipo_evento").IsRequired();
        builder.Property(p => p.Pontos).HasColumnName("pontos").IsRequired();
        builder.Property(p => p.ReferenciaId).HasColumnName("referencia_id");
        builder.Property(p => p.Data).HasColumnName("data").IsRequired();
        builder.Property(p => p.CriadoEm).HasColumnName("criado_em");
        builder.Property(p => p.AtualizadoEm).HasColumnName("atualizado_em");

        builder.HasOne(p => p.Aluno)
            .WithMany()
            .HasForeignKey(p => p.AlunoId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(p => new { p.AcademiaId, p.AlunoId });
        builder.HasIndex(p => new { p.AlunoId, p.Data });
    }
}
