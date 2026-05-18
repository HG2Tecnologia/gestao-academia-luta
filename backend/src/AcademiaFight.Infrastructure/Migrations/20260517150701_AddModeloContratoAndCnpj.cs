using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AcademiaFight.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddModeloContratoAndCnpj : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ModeloContratoId",
                table: "Contratos",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "TokenPublico",
                table: "Contratos",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<string>(
                name: "Cnpj",
                table: "academias",
                type: "text",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ModelosContrato",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    AcademiaId = table.Column<Guid>(type: "uuid", nullable: false),
                    Nome = table.Column<string>(type: "text", nullable: false),
                    ConteudoHtml = table.Column<string>(type: "text", nullable: false),
                    CriadoEm = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    AtualizadoEm = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ModelosContrato", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ModelosContrato_academias_AcademiaId",
                        column: x => x.AcademiaId,
                        principalTable: "academias",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Contratos_ModeloContratoId",
                table: "Contratos",
                column: "ModeloContratoId");

            migrationBuilder.CreateIndex(
                name: "IX_ModelosContrato_AcademiaId",
                table: "ModelosContrato",
                column: "AcademiaId");

            migrationBuilder.AddForeignKey(
                name: "FK_Contratos_ModelosContrato_ModeloContratoId",
                table: "Contratos",
                column: "ModeloContratoId",
                principalTable: "ModelosContrato",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Contratos_ModelosContrato_ModeloContratoId",
                table: "Contratos");

            migrationBuilder.DropTable(
                name: "ModelosContrato");

            migrationBuilder.DropIndex(
                name: "IX_Contratos_ModeloContratoId",
                table: "Contratos");

            migrationBuilder.DropColumn(
                name: "ModeloContratoId",
                table: "Contratos");

            migrationBuilder.DropColumn(
                name: "TokenPublico",
                table: "Contratos");

            migrationBuilder.DropColumn(
                name: "Cnpj",
                table: "academias");
        }
    }
}
