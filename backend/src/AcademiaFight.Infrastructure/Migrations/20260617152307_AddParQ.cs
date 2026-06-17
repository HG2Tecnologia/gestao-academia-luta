using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AcademiaFight.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddParQ : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "par_qs",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    academia_id = table.Column<Guid>(type: "uuid", nullable: false),
                    aluno_id = table.Column<Guid>(type: "uuid", nullable: false),
                    r1 = table.Column<bool>(type: "boolean", nullable: false),
                    r2 = table.Column<bool>(type: "boolean", nullable: false),
                    r3 = table.Column<bool>(type: "boolean", nullable: false),
                    r4 = table.Column<bool>(type: "boolean", nullable: false),
                    r5 = table.Column<bool>(type: "boolean", nullable: false),
                    r6 = table.Column<bool>(type: "boolean", nullable: false),
                    r7 = table.Column<bool>(type: "boolean", nullable: false),
                    r8 = table.Column<bool>(type: "boolean", nullable: false),
                    r9 = table.Column<bool>(type: "boolean", nullable: false),
                    r10 = table.Column<bool>(type: "boolean", nullable: false),
                    nome_completo = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    cpf = table.Column<string>(type: "character varying(14)", maxLength: 14, nullable: false),
                    data_preenchimento = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    criado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    atualizado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_par_qs", x => x.id);
                    table.ForeignKey(
                        name: "FK_par_qs_academias_academia_id",
                        column: x => x.academia_id,
                        principalTable: "academias",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_par_qs_usuarios_aluno_id",
                        column: x => x.aluno_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_par_qs_academia_id_aluno_id",
                table: "par_qs",
                columns: new[] { "academia_id", "aluno_id" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_par_qs_aluno_id",
                table: "par_qs",
                column: "aluno_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "par_qs");
        }
    }
}
