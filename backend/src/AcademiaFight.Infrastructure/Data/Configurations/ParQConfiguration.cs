using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class ParQConfiguration : IEntityTypeConfiguration<ParQ>
{
    public void Configure(EntityTypeBuilder<ParQ> builder)
    {
        builder.ToTable("par_qs");

        builder.HasKey(p => p.Id);
        builder.Property(p => p.Id).HasColumnName("id");
        builder.Property(p => p.AcademiaId).HasColumnName("academia_id");
        builder.Property(p => p.AlunoId).HasColumnName("aluno_id");
        builder.Property(p => p.R1).HasColumnName("r1");
        builder.Property(p => p.R2).HasColumnName("r2");
        builder.Property(p => p.R3).HasColumnName("r3");
        builder.Property(p => p.R4).HasColumnName("r4");
        builder.Property(p => p.R5).HasColumnName("r5");
        builder.Property(p => p.R6).HasColumnName("r6");
        builder.Property(p => p.R7).HasColumnName("r7");
        builder.Property(p => p.R8).HasColumnName("r8");
        builder.Property(p => p.R9).HasColumnName("r9");
        builder.Property(p => p.R10).HasColumnName("r10");
        builder.Property(p => p.NomeCompleto).HasColumnName("nome_completo").HasMaxLength(200);
        builder.Property(p => p.Cpf).HasColumnName("cpf").HasMaxLength(14);
        builder.Property(p => p.DataPreenchimento).HasColumnName("data_preenchimento");
        builder.Property(p => p.CriadoEm).HasColumnName("criado_em");
        builder.Property(p => p.AtualizadoEm).HasColumnName("atualizado_em");

        builder.HasIndex(p => new { p.AcademiaId, p.AlunoId }).IsUnique();

        builder.HasOne(p => p.Academia)
            .WithMany()
            .HasForeignKey(p => p.AcademiaId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(p => p.Aluno)
            .WithMany()
            .HasForeignKey(p => p.AlunoId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Ignore(p => p.RequerAvaliacaoMedica);
    }
}
