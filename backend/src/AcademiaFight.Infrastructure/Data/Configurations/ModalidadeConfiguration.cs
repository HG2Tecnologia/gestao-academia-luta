using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class ModalidadeConfiguration : IEntityTypeConfiguration<Modalidade>
{
    public void Configure(EntityTypeBuilder<Modalidade> builder)
    {
        builder.ToTable("modalidades");

        builder.HasKey(m => m.Id);

        builder.Property(m => m.Id).HasColumnName("id");
        builder.Property(m => m.AcademiaId).HasColumnName("academia_id").IsRequired();
        builder.Property(m => m.Nome).HasColumnName("nome").HasMaxLength(150).IsRequired();
        builder.Property(m => m.Descricao).HasColumnName("descricao").HasMaxLength(500);
        builder.Property(m => m.Ativo).HasColumnName("ativo").HasDefaultValue(true);
        builder.Property(m => m.SistemaFaixasJson).HasColumnName("sistema_faixas_json").HasColumnType("jsonb");
        builder.Property(m => m.CriadoEm).HasColumnName("criado_em");
        builder.Property(m => m.AtualizadoEm).HasColumnName("atualizado_em");

        builder.HasOne(m => m.Academia)
            .WithMany(a => a.Modalidades)
            .HasForeignKey(m => m.AcademiaId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
