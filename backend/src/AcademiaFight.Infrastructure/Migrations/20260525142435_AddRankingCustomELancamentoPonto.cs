using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AcademiaFight.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddRankingCustomELancamentoPonto : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "rankings_custom",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    academia_id = table.Column<Guid>(type: "uuid", nullable: false),
                    nome = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    descricao = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    incluir_presencas = table.Column<bool>(type: "boolean", nullable: false),
                    incluir_pontos_manuais = table.Column<bool>(type: "boolean", nullable: false),
                    peso_presencas = table.Column<int>(type: "integer", nullable: false),
                    peso_manuais = table.Column<int>(type: "integer", nullable: false),
                    visivel_para_aluno = table.Column<bool>(type: "boolean", nullable: false),
                    ativo = table.Column<bool>(type: "boolean", nullable: false),
                    criado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    atualizado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_rankings_custom", x => x.id);
                    table.ForeignKey(
                        name: "FK_rankings_custom_academias_academia_id",
                        column: x => x.academia_id,
                        principalTable: "academias",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "lancamentos_ponto",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    ranking_custom_id = table.Column<Guid>(type: "uuid", nullable: false),
                    aluno_id = table.Column<Guid>(type: "uuid", nullable: false),
                    academia_id = table.Column<Guid>(type: "uuid", nullable: false),
                    pontos = table.Column<int>(type: "integer", nullable: false),
                    descricao = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    registrado_por_id = table.Column<Guid>(type: "uuid", nullable: false),
                    data = table.Column<DateOnly>(type: "date", nullable: false),
                    criado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    atualizado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_lancamentos_ponto", x => x.id);
                    table.ForeignKey(
                        name: "FK_lancamentos_ponto_rankings_custom_ranking_custom_id",
                        column: x => x.ranking_custom_id,
                        principalTable: "rankings_custom",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_lancamentos_ponto_usuarios_aluno_id",
                        column: x => x.aluno_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_lancamentos_ponto_usuarios_registrado_por_id",
                        column: x => x.registrado_por_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_lancamentos_ponto_academia_id_aluno_id",
                table: "lancamentos_ponto",
                columns: new[] { "academia_id", "aluno_id" });

            migrationBuilder.CreateIndex(
                name: "IX_lancamentos_ponto_aluno_id",
                table: "lancamentos_ponto",
                column: "aluno_id");

            migrationBuilder.CreateIndex(
                name: "IX_lancamentos_ponto_ranking_custom_id_aluno_id",
                table: "lancamentos_ponto",
                columns: new[] { "ranking_custom_id", "aluno_id" });

            migrationBuilder.CreateIndex(
                name: "IX_lancamentos_ponto_registrado_por_id",
                table: "lancamentos_ponto",
                column: "registrado_por_id");

            migrationBuilder.CreateIndex(
                name: "IX_rankings_custom_academia_id_ativo",
                table: "rankings_custom",
                columns: new[] { "academia_id", "ativo" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "lancamentos_ponto");

            migrationBuilder.DropTable(
                name: "rankings_custom");
        }
    }
}
