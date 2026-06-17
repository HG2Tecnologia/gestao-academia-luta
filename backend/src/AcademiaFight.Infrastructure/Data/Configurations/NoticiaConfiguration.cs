using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class NoticiaConfiguration : IEntityTypeConfiguration<Noticia>
{
    public void Configure(EntityTypeBuilder<Noticia> builder)
    {
        builder.ToTable("noticias");

        builder.HasKey(n => n.Id);
        builder.Property(n => n.Id).HasColumnName("id");
        builder.Property(n => n.AcademiaId).HasColumnName("academia_id").IsRequired();
        builder.Property(n => n.Titulo).HasColumnName("titulo").HasMaxLength(200).IsRequired();
        builder.Property(n => n.Resumo).HasColumnName("resumo").HasMaxLength(500).IsRequired();
        builder.Property(n => n.Conteudo).HasColumnName("conteudo");
        builder.Property(n => n.ImagemBase64).HasColumnName("imagem_base64").HasColumnType("TEXT");
        builder.Property(n => n.Publicada).HasColumnName("publicada").HasDefaultValue(false);
        builder.Property(n => n.PublicadaEm).HasColumnName("publicada_em");
        builder.Property(n => n.AutorId).HasColumnName("autor_id");
        builder.Property(n => n.CriadoEm).HasColumnName("criado_em");
        builder.Property(n => n.AtualizadoEm).HasColumnName("atualizado_em");

        builder.HasOne(n => n.Academia).WithMany().HasForeignKey(n => n.AcademiaId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne(n => n.Autor).WithMany().HasForeignKey(n => n.AutorId).OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(n => new { n.AcademiaId, n.PublicadaEm });
    }
}
