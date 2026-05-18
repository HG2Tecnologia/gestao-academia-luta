using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using System.Text.Json;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class FuncionarioConfiguration : IEntityTypeConfiguration<Funcionario>
{
    public void Configure(EntityTypeBuilder<Funcionario> builder)
    {
        builder.ToTable("funcionarios");

        builder.HasKey(f => f.Id);

        builder.Property(f => f.Id).HasColumnName("id");
        builder.Property(f => f.AcademiaId).HasColumnName("academia_id").IsRequired();
        builder.Property(f => f.UsuarioId).HasColumnName("usuario_id").IsRequired();
        builder.Property(f => f.Cargo).HasColumnName("cargo").HasMaxLength(100).IsRequired();
        builder.Property(f => f.DataAdmissao).HasColumnName("data_admissao").IsRequired();
        builder.Property(f => f.CriadoEm).HasColumnName("criado_em");
        builder.Property(f => f.AtualizadoEm).HasColumnName("atualizado_em");

        // Armazenar Permissoes como JSONB no PostgreSQL
        builder.Property(f => f.Permissoes)
            .HasColumnName("permissoes")
            .HasColumnType("jsonb")
            .HasConversion(
                v => JsonSerializer.Serialize(v, (JsonSerializerOptions?)null),
                v => JsonSerializer.Deserialize<Dictionary<string, bool>>(v, (JsonSerializerOptions?)null)
                     ?? new Dictionary<string, bool>());

        builder.HasOne(f => f.Academia)
            .WithMany(a => a.Funcionarios)
            .HasForeignKey(f => f.AcademiaId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(f => f.Usuario)
            .WithMany()
            .HasForeignKey(f => f.UsuarioId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
