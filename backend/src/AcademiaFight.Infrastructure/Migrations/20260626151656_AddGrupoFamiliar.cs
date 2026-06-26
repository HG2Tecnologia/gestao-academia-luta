using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AcademiaFight.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddGrupoFamiliar : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "GrupoFamiliarId",
                table: "usuarios",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "GruposFamiliares",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    AcademiaId = table.Column<Guid>(type: "uuid", nullable: false),
                    Nome = table.Column<string>(type: "text", nullable: false),
                    CriadoEm = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    AtualizadoEm = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GruposFamiliares", x => x.Id);
                    table.ForeignKey(
                        name: "FK_GruposFamiliares_academias_AcademiaId",
                        column: x => x.AcademiaId,
                        principalTable: "academias",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_usuarios_GrupoFamiliarId",
                table: "usuarios",
                column: "GrupoFamiliarId");

            migrationBuilder.CreateIndex(
                name: "IX_GruposFamiliares_AcademiaId",
                table: "GruposFamiliares",
                column: "AcademiaId");

            migrationBuilder.AddForeignKey(
                name: "FK_usuarios_GruposFamiliares_GrupoFamiliarId",
                table: "usuarios",
                column: "GrupoFamiliarId",
                principalTable: "GruposFamiliares",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_usuarios_GruposFamiliares_GrupoFamiliarId",
                table: "usuarios");

            migrationBuilder.DropTable(
                name: "GruposFamiliares");

            migrationBuilder.DropIndex(
                name: "IX_usuarios_GrupoFamiliarId",
                table: "usuarios");

            migrationBuilder.DropColumn(
                name: "GrupoFamiliarId",
                table: "usuarios");
        }
    }
}
