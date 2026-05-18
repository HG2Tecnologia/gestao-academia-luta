using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class TurmaConfiguration : IEntityTypeConfiguration<Turma>
{
    public void Configure(EntityTypeBuilder<Turma> builder)
    {
        builder.ToTable("turmas");

        builder.HasKey(t => t.Id);

        builder.Property(t => t.Id).HasColumnName("id");
        builder.Property(t => t.AcademiaId).HasColumnName("academia_id").IsRequired();
        builder.Property(t => t.ModalidadeId).HasColumnName("modalidade_id").IsRequired();
        builder.Property(t => t.ProfessorId).HasColumnName("professor_id").IsRequired();
        builder.Property(t => t.Nome).HasColumnName("nome").HasMaxLength(150).IsRequired();
        builder.Property(t => t.Nivel).HasColumnName("nivel").HasMaxLength(50);
        builder.Property(t => t.CapacidadeMaxima).HasColumnName("capacidade_maxima").IsRequired();
        builder.Property(t => t.Ativo).HasColumnName("ativo").HasDefaultValue(true);
        builder.Property(t => t.CriadoEm).HasColumnName("criado_em");
        builder.Property(t => t.AtualizadoEm).HasColumnName("atualizado_em");

        builder.HasOne(t => t.Academia)
            .WithMany(a => a.Turmas)
            .HasForeignKey(t => t.AcademiaId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(t => t.Modalidade)
            .WithMany(m => m.Turmas)
            .HasForeignKey(t => t.ModalidadeId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(t => t.Professor)
            .WithMany()
            .HasForeignKey(t => t.ProfessorId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
