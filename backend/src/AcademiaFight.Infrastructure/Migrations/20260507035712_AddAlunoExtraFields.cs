using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AcademiaFight.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddAlunoExtraFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ContatoEmergenciaNome",
                table: "usuarios",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ContatoEmergenciaTelefone",
                table: "usuarios",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateOnly>(
                name: "DataNascimento",
                table: "usuarios",
                type: "date",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Telefone",
                table: "usuarios",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TipoPlano",
                table: "usuarios",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ContatoEmergenciaNome",
                table: "usuarios");

            migrationBuilder.DropColumn(
                name: "ContatoEmergenciaTelefone",
                table: "usuarios");

            migrationBuilder.DropColumn(
                name: "DataNascimento",
                table: "usuarios");

            migrationBuilder.DropColumn(
                name: "Telefone",
                table: "usuarios");

            migrationBuilder.DropColumn(
                name: "TipoPlano",
                table: "usuarios");
        }
    }
}
