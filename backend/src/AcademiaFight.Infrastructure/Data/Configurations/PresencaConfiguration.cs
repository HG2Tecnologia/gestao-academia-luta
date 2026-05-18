using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class PresencaConfiguration : IEntityTypeConfiguration<Presenca>
{
    public void Configure(EntityTypeBuilder<Presenca> builder)
    {
        builder.ToTable("presencas");

        builder.HasKey(p => p.Id);

        builder.Property(p => p.Id).HasColumnName("id");
        builder.Property(p => p.AcademiaId).HasColumnName("academia_id").IsRequired();
        builder.Property(p => p.AlunoId).HasColumnName("aluno_id").IsRequired();
        builder.Property(p => p.HorarioId).HasColumnName("horario_id").IsRequired();
        builder.Property(p => p.Data).HasColumnName("data").IsRequired();
        builder.Property(p => p.HoraCheckin).HasColumnName("hora_checkin").IsRequired();
        builder.Property(p => p.MetodoCheckin).HasColumnName("metodo_checkin").IsRequired();
        builder.Property(p => p.Confirmado).HasColumnName("confirmado").HasDefaultValue(true);
        builder.Property(p => p.ObservacoesProfessor).HasColumnName("observacoes_professor").HasMaxLength(500);
        builder.Property(p => p.CriadoEm).HasColumnName("criado_em");
        builder.Property(p => p.AtualizadoEm).HasColumnName("atualizado_em");

        builder.HasOne(p => p.Academia)
            .WithMany()
            .HasForeignKey(p => p.AcademiaId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(p => p.Aluno)
            .WithMany()
            .HasForeignKey(p => p.AlunoId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(p => p.Horario)
            .WithMany(h => h.Presencas)
            .HasForeignKey(p => p.HorarioId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(p => new { p.AlunoId, p.HorarioId, p.Data }).IsUnique();
    }
}
