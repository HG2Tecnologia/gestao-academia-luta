using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class AcademiaConfiguration : IEntityTypeConfiguration<Academia>
{
    public void Configure(EntityTypeBuilder<Academia> builder)
    {
        builder.ToTable("academias");

        builder.HasKey(a => a.Id);

        builder.Property(a => a.Id).HasColumnName("id");
        builder.Property(a => a.Nome).HasColumnName("nome").HasMaxLength(200).IsRequired();
        builder.Property(a => a.Subdominio).HasColumnName("subdominio").HasMaxLength(100).IsRequired();
        builder.Property(a => a.LogoUrl).HasColumnName("logo_url").HasMaxLength(500);
        builder.Property(a => a.Email).HasColumnName("email").HasMaxLength(200).IsRequired();
        builder.Property(a => a.Telefone).HasColumnName("telefone").HasMaxLength(20);
        builder.Property(a => a.Ativo).HasColumnName("ativo").HasDefaultValue(true);
        builder.Property(a => a.CriadoEm).HasColumnName("criado_em");
        builder.Property(a => a.AtualizadoEm).HasColumnName("atualizado_em");

        builder.HasIndex(a => a.Subdominio).IsUnique();
        builder.HasIndex(a => a.Email).IsUnique();
    }
}
