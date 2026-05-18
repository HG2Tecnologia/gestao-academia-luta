using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AcademiaFight.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddContratos : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "TemplateContrato",
                table: "academias",
                type: "text",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Contratos",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    AcademiaId = table.Column<Guid>(type: "uuid", nullable: false),
                    AlunoId = table.Column<Guid>(type: "uuid", nullable: false),
                    MatriculaId = table.Column<Guid>(type: "uuid", nullable: true),
                    ConteudoHtml = table.Column<string>(type: "text", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    DataAssinatura = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IpAssinatura = table.Column<string>(type: "text", nullable: true),
                    NomeAssinou = table.Column<string>(type: "text", nullable: true),
                    CriadoEm = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    AtualizadoEm = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Contratos", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Contratos_academias_AcademiaId",
                        column: x => x.AcademiaId,
                        principalTable: "academias",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Contratos_matriculas_MatriculaId",
                        column: x => x.MatriculaId,
                        principalTable: "matriculas",
                        principalColumn: "id");
                    table.ForeignKey(
                        name: "FK_Contratos_usuarios_AlunoId",
                        column: x => x.AlunoId,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Contratos_AcademiaId",
                table: "Contratos",
                column: "AcademiaId");

            migrationBuilder.CreateIndex(
                name: "IX_Contratos_AlunoId",
                table: "Contratos",
                column: "AlunoId");

            migrationBuilder.CreateIndex(
                name: "IX_Contratos_MatriculaId",
                table: "Contratos",
                column: "MatriculaId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Contratos");

            migrationBuilder.DropColumn(
                name: "TemplateContrato",
                table: "academias");
        }
    }
}
