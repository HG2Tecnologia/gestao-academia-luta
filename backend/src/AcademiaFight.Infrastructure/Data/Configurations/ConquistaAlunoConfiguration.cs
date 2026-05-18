using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class ConquistaAlunoConfiguration : IEntityTypeConfiguration<ConquistaAluno>
{
    public void Configure(EntityTypeBuilder<ConquistaAluno> builder)
    {
        builder.ToTable("conquistas_aluno");
        builder.HasKey(ca => ca.Id);
        builder.Property(ca => ca.Id).HasColumnName("id");
        builder.Property(ca => ca.AcademiaId).HasColumnName("academia_id").IsRequired();
        builder.Property(ca => ca.AlunoId).HasColumnName("aluno_id").IsRequired();
        builder.Property(ca => ca.ConquistaId).HasColumnName("conquista_id").IsRequired();
        builder.Property(ca => ca.DesbloqueadaEm).HasColumnName("desbloqueada_em").IsRequired();
        builder.Property(ca => ca.VistaPeloAluno).HasColumnName("vista_pelo_aluno").IsRequired();
        builder.Property(ca => ca.CriadoEm).HasColumnName("criado_em");
        builder.Property(ca => ca.AtualizadoEm).HasColumnName("atualizado_em");

        builder.HasOne(ca => ca.Aluno)
            .WithMany()
            .HasForeignKey(ca => ca.AlunoId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(ca => ca.Conquista)
            .WithMany()
            .HasForeignKey(ca => ca.ConquistaId)
            .OnDelete(DeleteBehavior.Restrict);

        // Garantir idempotência: um aluno não pode desbloquear a mesma conquista duas vezes
        builder.HasIndex(ca => new { ca.AlunoId, ca.ConquistaId }).IsUnique();
    }
}
