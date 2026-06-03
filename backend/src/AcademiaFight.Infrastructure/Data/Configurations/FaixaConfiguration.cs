using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class FaixaConfiguration : IEntityTypeConfiguration<Faixa>
{
    public void Configure(EntityTypeBuilder<Faixa> builder)
    {
        builder.ToTable("faixas");

        builder.HasKey(f => f.Id);

        builder.Property(f => f.Id).HasColumnName("id");
        builder.Property(f => f.AcademiaId).HasColumnName("academia_id").IsRequired();
        builder.Property(f => f.ModalidadeId).HasColumnName("modalidade_id").IsRequired();
        builder.Property(f => f.Nome).HasColumnName("nome").HasMaxLength(100).IsRequired();
        builder.Property(f => f.Cor).HasColumnName("cor").HasMaxLength(20).IsRequired();
        builder.Property(f => f.Ordem).HasColumnName("ordem").IsRequired();
        builder.Property(f => f.RequisitosMesesMinimos).HasColumnName("requisitos_meses_minimos");
        builder.Property(f => f.RequisitosPresencasMinimas).HasColumnName("requisitos_presencas_minimas");
        builder.Property(f => f.Descricao).HasColumnName("descricao").HasMaxLength(500);
        builder.Property(f => f.TemGraus).HasColumnName("tem_graus").HasDefaultValue(false);
        builder.Property(f => f.MaxGraus).HasColumnName("max_graus").HasDefaultValue(4);
        builder.Property(f => f.CorBarra).HasColumnName("cor_barra").HasMaxLength(20).HasDefaultValue("#000000");
        builder.Property(f => f.CriadoEm).HasColumnName("criado_em");
        builder.Property(f => f.AtualizadoEm).HasColumnName("atualizado_em");

        builder.HasOne(f => f.Academia)
            .WithMany()
            .HasForeignKey(f => f.AcademiaId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(f => f.Modalidade)
            .WithMany(m => m.Faixas)
            .HasForeignKey(f => f.ModalidadeId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(f => new { f.ModalidadeId, f.Ordem });
    }
}
