using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace AcademiaFight.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddFase3Gamificacao : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "FcmToken",
                table: "usuarios",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Nivel",
                table: "usuarios",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "NivelAtualizadoEm",
                table: "usuarios",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "XpMensal",
                table: "usuarios",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "XpTotal",
                table: "usuarios",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "conquistas",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    tipo = table.Column<int>(type: "integer", nullable: false),
                    nome = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    descricao = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    icone_url = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    pontos_xp_bonus = table.Column<int>(type: "integer", nullable: false),
                    criado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    atualizado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_conquistas", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "pontos_ranking",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    academia_id = table.Column<Guid>(type: "uuid", nullable: false),
                    aluno_id = table.Column<Guid>(type: "uuid", nullable: false),
                    tipo_evento = table.Column<int>(type: "integer", nullable: false),
                    pontos = table.Column<int>(type: "integer", nullable: false),
                    referencia_id = table.Column<Guid>(type: "uuid", nullable: true),
                    data = table.Column<DateOnly>(type: "date", nullable: false),
                    criado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    atualizado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_pontos_ranking", x => x.id);
                    table.ForeignKey(
                        name: "FK_pontos_ranking_usuarios_aluno_id",
                        column: x => x.aluno_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "conquistas_aluno",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    academia_id = table.Column<Guid>(type: "uuid", nullable: false),
                    aluno_id = table.Column<Guid>(type: "uuid", nullable: false),
                    conquista_id = table.Column<Guid>(type: "uuid", nullable: false),
                    desbloqueada_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    vista_pelo_aluno = table.Column<bool>(type: "boolean", nullable: false),
                    criado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    atualizado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_conquistas_aluno", x => x.id);
                    table.ForeignKey(
                        name: "FK_conquistas_aluno_conquistas_conquista_id",
                        column: x => x.conquista_id,
                        principalTable: "conquistas",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_conquistas_aluno_usuarios_aluno_id",
                        column: x => x.aluno_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.InsertData(
                table: "conquistas",
                columns: new[] { "id", "atualizado_em", "criado_em", "descricao", "icone_url", "nome", "pontos_xp_bonus", "tipo" },
                values: new object[,]
                {
                    { new Guid("00000000-0000-0000-0001-000000000001"), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Registrou sua primeira presença na academia.", "star", "Primeiro Treino", 0, 1 },
                    { new Guid("00000000-0000-0000-0001-000000000002"), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Treinou 5 vezes em 7 dias corridos.", "fire", "Semana Perfeita", 25, 2 },
                    { new Guid("00000000-0000-0000-0001-000000000003"), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "100% de frequencia em um mes.", "trophy", "Mes Invicto", 50, 3 },
                    { new Guid("00000000-0000-0000-0001-000000000004"), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Conquistou sua primeira faixa.", "medal", "Graduado", 100, 4 },
                    { new Guid("00000000-0000-0000-0001-000000000005"), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "10 presencas consecutivas sem faltar.", "bolt", "Sequencia de 10", 30, 5 },
                    { new Guid("00000000-0000-0000-0001-000000000006"), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "50 presencas totais registradas.", "muscle", "Veterano", 80, 6 },
                    { new Guid("00000000-0000-0000-0001-000000000007"), null, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "100 presencas totais - voce e uma lenda desta academia!", "crown", "Lenda", 150, 7 }
                });

            migrationBuilder.CreateIndex(
                name: "IX_conquistas_tipo",
                table: "conquistas",
                column: "tipo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_conquistas_aluno_aluno_id_conquista_id",
                table: "conquistas_aluno",
                columns: new[] { "aluno_id", "conquista_id" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_conquistas_aluno_conquista_id",
                table: "conquistas_aluno",
                column: "conquista_id");

            migrationBuilder.CreateIndex(
                name: "IX_pontos_ranking_academia_id_aluno_id",
                table: "pontos_ranking",
                columns: new[] { "academia_id", "aluno_id" });

            migrationBuilder.CreateIndex(
                name: "IX_pontos_ranking_aluno_id_data",
                table: "pontos_ranking",
                columns: new[] { "aluno_id", "data" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "conquistas_aluno");

            migrationBuilder.DropTable(
                name: "pontos_ranking");

            migrationBuilder.DropTable(
                name: "conquistas");

            migrationBuilder.DropColumn(
                name: "FcmToken",
                table: "usuarios");

            migrationBuilder.DropColumn(
                name: "Nivel",
                table: "usuarios");

            migrationBuilder.DropColumn(
                name: "NivelAtualizadoEm",
                table: "usuarios");

            migrationBuilder.DropColumn(
                name: "XpMensal",
                table: "usuarios");

            migrationBuilder.DropColumn(
                name: "XpTotal",
                table: "usuarios");
        }
    }
}
