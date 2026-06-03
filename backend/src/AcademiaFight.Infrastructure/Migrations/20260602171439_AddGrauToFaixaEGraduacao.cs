using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AcademiaFight.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddGrauToFaixaEGraduacao : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "grau",
                table: "graduacoes",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "cor_barra",
                table: "faixas",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "#000000");

            migrationBuilder.AddColumn<int>(
                name: "max_graus",
                table: "faixas",
                type: "integer",
                nullable: false,
                defaultValue: 4);

            migrationBuilder.AddColumn<bool>(
                name: "tem_graus",
                table: "faixas",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "grau",
                table: "graduacoes");

            migrationBuilder.DropColumn(
                name: "cor_barra",
                table: "faixas");

            migrationBuilder.DropColumn(
                name: "max_graus",
                table: "faixas");

            migrationBuilder.DropColumn(
                name: "tem_graus",
                table: "faixas");
        }
    }
}
