using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AcademiaFight.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddFase2Entities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "faixas",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    academia_id = table.Column<Guid>(type: "uuid", nullable: false),
                    modalidade_id = table.Column<Guid>(type: "uuid", nullable: false),
                    nome = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    cor = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    ordem = table.Column<int>(type: "integer", nullable: false),
                    requisitos_meses_minimos = table.Column<int>(type: "integer", nullable: false),
                    requisitos_presencas_minimas = table.Column<int>(type: "integer", nullable: false),
                    descricao = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    criado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    atualizado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_faixas", x => x.id);
                    table.ForeignKey(
                        name: "FK_faixas_academias_academia_id",
                        column: x => x.academia_id,
                        principalTable: "academias",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_faixas_modalidades_modalidade_id",
                        column: x => x.modalidade_id,
                        principalTable: "modalidades",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "matriculas",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    academia_id = table.Column<Guid>(type: "uuid", nullable: false),
                    aluno_id = table.Column<Guid>(type: "uuid", nullable: false),
                    turma_id = table.Column<Guid>(type: "uuid", nullable: false),
                    data_inicio = table.Column<DateOnly>(type: "date", nullable: false),
                    data_fim = table.Column<DateOnly>(type: "date", nullable: true),
                    ativo = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    criado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    atualizado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_matriculas", x => x.id);
                    table.ForeignKey(
                        name: "FK_matriculas_academias_academia_id",
                        column: x => x.academia_id,
                        principalTable: "academias",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_matriculas_turmas_turma_id",
                        column: x => x.turma_id,
                        principalTable: "turmas",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_matriculas_usuarios_aluno_id",
                        column: x => x.aluno_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "presencas",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    academia_id = table.Column<Guid>(type: "uuid", nullable: false),
                    aluno_id = table.Column<Guid>(type: "uuid", nullable: false),
                    horario_id = table.Column<Guid>(type: "uuid", nullable: false),
                    data = table.Column<DateOnly>(type: "date", nullable: false),
                    hora_checkin = table.Column<TimeOnly>(type: "time without time zone", nullable: false),
                    metodo_checkin = table.Column<int>(type: "integer", nullable: false),
                    confirmado = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    observacoes_professor = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    criado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    atualizado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_presencas", x => x.id);
                    table.ForeignKey(
                        name: "FK_presencas_academias_academia_id",
                        column: x => x.academia_id,
                        principalTable: "academias",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_presencas_horarios_horario_id",
                        column: x => x.horario_id,
                        principalTable: "horarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_presencas_usuarios_aluno_id",
                        column: x => x.aluno_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "graduacoes",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    academia_id = table.Column<Guid>(type: "uuid", nullable: false),
                    aluno_id = table.Column<Guid>(type: "uuid", nullable: false),
                    faixa_id = table.Column<Guid>(type: "uuid", nullable: false),
                    data_exame = table.Column<DateOnly>(type: "date", nullable: false),
                    aprovado = table.Column<bool>(type: "boolean", nullable: false),
                    professor_id = table.Column<Guid>(type: "uuid", nullable: false),
                    observacoes = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    certificado_url = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    criado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    atualizado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_graduacoes", x => x.id);
                    table.ForeignKey(
                        name: "FK_graduacoes_academias_academia_id",
                        column: x => x.academia_id,
                        principalTable: "academias",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_graduacoes_faixas_faixa_id",
                        column: x => x.faixa_id,
                        principalTable: "faixas",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_graduacoes_usuarios_aluno_id",
                        column: x => x.aluno_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_graduacoes_usuarios_professor_id",
                        column: x => x.professor_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_faixas_academia_id",
                table: "faixas",
                column: "academia_id");

            migrationBuilder.CreateIndex(
                name: "IX_faixas_modalidade_id_ordem",
                table: "faixas",
                columns: new[] { "modalidade_id", "ordem" });

            migrationBuilder.CreateIndex(
                name: "IX_graduacoes_academia_id",
                table: "graduacoes",
                column: "academia_id");

            migrationBuilder.CreateIndex(
                name: "IX_graduacoes_aluno_id_faixa_id",
                table: "graduacoes",
                columns: new[] { "aluno_id", "faixa_id" });

            migrationBuilder.CreateIndex(
                name: "IX_graduacoes_faixa_id",
                table: "graduacoes",
                column: "faixa_id");

            migrationBuilder.CreateIndex(
                name: "IX_graduacoes_professor_id",
                table: "graduacoes",
                column: "professor_id");

            migrationBuilder.CreateIndex(
                name: "IX_matriculas_academia_id",
                table: "matriculas",
                column: "academia_id");

            migrationBuilder.CreateIndex(
                name: "IX_matriculas_aluno_id_turma_id_ativo",
                table: "matriculas",
                columns: new[] { "aluno_id", "turma_id", "ativo" });

            migrationBuilder.CreateIndex(
                name: "IX_matriculas_turma_id",
                table: "matriculas",
                column: "turma_id");

            migrationBuilder.CreateIndex(
                name: "IX_presencas_academia_id",
                table: "presencas",
                column: "academia_id");

            migrationBuilder.CreateIndex(
                name: "IX_presencas_aluno_id_horario_id_data",
                table: "presencas",
                columns: new[] { "aluno_id", "horario_id", "data" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_presencas_horario_id",
                table: "presencas",
                column: "horario_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "graduacoes");

            migrationBuilder.DropTable(
                name: "matriculas");

            migrationBuilder.DropTable(
                name: "presencas");

            migrationBuilder.DropTable(
                name: "faixas");
        }
    }
}
