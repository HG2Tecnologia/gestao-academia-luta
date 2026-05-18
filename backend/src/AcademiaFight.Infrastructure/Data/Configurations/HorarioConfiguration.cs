using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class HorarioConfiguration : IEntityTypeConfiguration<Horario>
{
    public void Configure(EntityTypeBuilder<Horario> builder)
    {
        builder.ToTable("horarios");

        builder.HasKey(h => h.Id);

        builder.Property(h => h.Id).HasColumnName("id");
        builder.Property(h => h.AcademiaId).HasColumnName("academia_id").IsRequired();
        builder.Property(h => h.TurmaId).HasColumnName("turma_id").IsRequired();
        builder.Property(h => h.DiaSemana).HasColumnName("dia_semana").IsRequired();
        builder.Property(h => h.HoraInicio).HasColumnName("hora_inicio").IsRequired();
        builder.Property(h => h.HoraFim).HasColumnName("hora_fim").IsRequired();
        builder.Property(h => h.Sala).HasColumnName("sala").HasMaxLength(50);
        builder.Property(h => h.CriadoEm).HasColumnName("criado_em");
        builder.Property(h => h.AtualizadoEm).HasColumnName("atualizado_em");

        builder.HasOne(h => h.Academia)
            .WithMany()
            .HasForeignKey(h => h.AcademiaId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(h => h.Turma)
            .WithMany(t => t.Horarios)
            .HasForeignKey(h => h.TurmaId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
