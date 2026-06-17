using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class AtestadoMedicoConfiguration : IEntityTypeConfiguration<AtestadoMedico>
{
    public void Configure(EntityTypeBuilder<AtestadoMedico> builder)
    {
        builder.ToTable("atestados_medicos");

        builder.HasKey(a => a.Id);

        builder.Property(a => a.Id).HasColumnName("id");
        builder.Property(a => a.AcademiaId).HasColumnName("academia_id").IsRequired();
        builder.Property(a => a.AlunoId).HasColumnName("aluno_id").IsRequired();
        builder.Property(a => a.ArquivoBase64).HasColumnName("arquivo_base64").IsRequired();
        builder.Property(a => a.ArquivoMimeType).HasColumnName("arquivo_mime_type").HasMaxLength(100).IsRequired();
        builder.Property(a => a.ArquivoNome).HasColumnName("arquivo_nome").HasMaxLength(255);
        builder.Property(a => a.Status).HasColumnName("status").IsRequired();
        builder.Property(a => a.MotivoRejeicao).HasColumnName("motivo_rejeicao").HasMaxLength(500);
        builder.Property(a => a.DataUpload).HasColumnName("data_upload").IsRequired();
        builder.Property(a => a.DataValidade).HasColumnName("data_validade").IsRequired();
        builder.Property(a => a.AnexadoPorAcademia).HasColumnName("anexado_por_academia").HasDefaultValue(false);
        builder.Property(a => a.AnexadoPorId).HasColumnName("anexado_por_id");
        builder.Property(a => a.AlertaVencimentoEnviado).HasColumnName("alerta_vencimento_enviado").HasDefaultValue(false);
        builder.Property(a => a.CriadoEm).HasColumnName("criado_em");
        builder.Property(a => a.AtualizadoEm).HasColumnName("atualizado_em");

        builder.HasOne(a => a.Academia)
            .WithMany()
            .HasForeignKey(a => a.AcademiaId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(a => a.Aluno)
            .WithMany()
            .HasForeignKey(a => a.AlunoId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(a => new { a.AlunoId, a.DataValidade });
        builder.HasIndex(a => new { a.AcademiaId, a.Status });
    }
}
