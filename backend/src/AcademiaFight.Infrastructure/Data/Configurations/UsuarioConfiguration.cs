using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AcademiaFight.Infrastructure.Data.Configurations;

public class UsuarioConfiguration : IEntityTypeConfiguration<Usuario>
{
    public void Configure(EntityTypeBuilder<Usuario> builder)
    {
        builder.ToTable("usuarios");

        builder.HasKey(u => u.Id);

        builder.Property(u => u.Id).HasColumnName("id");
        builder.Property(u => u.AcademiaId).HasColumnName("academia_id").IsRequired();
        builder.Property(u => u.Nome).HasColumnName("nome").HasMaxLength(200).IsRequired();
        builder.Property(u => u.Email).HasColumnName("email").HasMaxLength(200).IsRequired(false);
        builder.Property(u => u.SenhaHash).HasColumnName("senha_hash").IsRequired();
        builder.Property(u => u.Perfil).HasColumnName("perfil").IsRequired();
        builder.Property(u => u.Ativo).HasColumnName("ativo").HasDefaultValue(true);
        builder.Property(u => u.UltimoLogin).HasColumnName("ultimo_login");
        builder.Property(u => u.RefreshToken).HasColumnName("refresh_token").HasMaxLength(500);
        builder.Property(u => u.RefreshTokenExpiry).HasColumnName("refresh_token_expiry");
        builder.Property(u => u.ResetPasswordToken).HasColumnName("reset_password_token").HasMaxLength(100);
        builder.Property(u => u.ResetPasswordTokenExpiry).HasColumnName("reset_password_token_expiry");
        builder.Property(u => u.CriadoEm).HasColumnName("criado_em");
        builder.Property(u => u.AtualizadoEm).HasColumnName("atualizado_em");

        // Índice parcial: unicidade só quando e-mail não é nulo (permite múltiplos alunos sem e-mail)
        builder.HasIndex(u => new { u.Email, u.AcademiaId })
            .IsUnique()
            .HasFilter("email IS NOT NULL");

        builder.HasOne(u => u.Academia)
            .WithMany(a => a.Usuarios)
            .HasForeignKey(u => u.AcademiaId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
