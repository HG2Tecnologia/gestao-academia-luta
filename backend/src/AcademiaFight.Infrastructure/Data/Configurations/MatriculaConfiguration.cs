using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class MatriculaConfiguration : IEntityTypeConfiguration<Matricula>
{
    public void Configure(EntityTypeBuilder<Matricula> builder)
    {
        builder.ToTable("matriculas");

        builder.HasKey(m => m.Id);

        builder.Property(m => m.Id).HasColumnName("id");
        builder.Property(m => m.AcademiaId).HasColumnName("academia_id").IsRequired();
        builder.Property(m => m.AlunoId).HasColumnName("aluno_id").IsRequired();
        builder.Property(m => m.TurmaId).HasColumnName("turma_id").IsRequired();
        builder.Property(m => m.DataInicio).HasColumnName("data_inicio").IsRequired();
        builder.Property(m => m.DataFim).HasColumnName("data_fim");
        builder.Property(m => m.Ativo).HasColumnName("ativo").HasDefaultValue(true);
        builder.Property(m => m.CriadoEm).HasColumnName("criado_em");
        builder.Property(m => m.AtualizadoEm).HasColumnName("atualizado_em");

        builder.HasOne(m => m.Academia)
            .WithMany()
            .HasForeignKey(m => m.AcademiaId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(m => m.Turma)
            .WithMany(t => t.Matriculas)
            .HasForeignKey(m => m.TurmaId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(m => m.Aluno)
            .WithMany()
            .HasForeignKey(m => m.AlunoId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(m => new { m.AlunoId, m.TurmaId, m.Ativo });
    }
}
