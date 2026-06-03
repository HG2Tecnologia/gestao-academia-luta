using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class GraduacaoConfiguration : IEntityTypeConfiguration<Graduacao>
{
    public void Configure(EntityTypeBuilder<Graduacao> builder)
    {
        builder.ToTable("graduacoes");

        builder.HasKey(g => g.Id);

        builder.Property(g => g.Id).HasColumnName("id");
        builder.Property(g => g.AcademiaId).HasColumnName("academia_id").IsRequired();
        builder.Property(g => g.AlunoId).HasColumnName("aluno_id").IsRequired();
        builder.Property(g => g.FaixaId).HasColumnName("faixa_id").IsRequired();
        builder.Property(g => g.DataExame).HasColumnName("data_exame").IsRequired();
        builder.Property(g => g.Aprovado).HasColumnName("aprovado").IsRequired();
        builder.Property(g => g.ProfessorId).HasColumnName("professor_id").IsRequired();
        builder.Property(g => g.Grau).HasColumnName("grau").HasDefaultValue(0);
        builder.Property(g => g.Observacoes).HasColumnName("observacoes").HasMaxLength(1000);
        builder.Property(g => g.CertificadoUrl).HasColumnName("certificado_url").HasMaxLength(500);
        builder.Property(g => g.CriadoEm).HasColumnName("criado_em");
        builder.Property(g => g.AtualizadoEm).HasColumnName("atualizado_em");

        builder.HasOne(g => g.Academia)
            .WithMany()
            .HasForeignKey(g => g.AcademiaId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(g => g.Aluno)
            .WithMany()
            .HasForeignKey(g => g.AlunoId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(g => g.Faixa)
            .WithMany(f => f.Graduacoes)
            .HasForeignKey(g => g.FaixaId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(g => g.Professor)
            .WithMany()
            .HasForeignKey(g => g.ProfessorId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(g => new { g.AlunoId, g.FaixaId });
    }
}
