using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AcademiaFight.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddAtestadoMedico : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "atestados_medicos",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    academia_id = table.Column<Guid>(type: "uuid", nullable: false),
                    aluno_id = table.Column<Guid>(type: "uuid", nullable: false),
                    arquivo_base64 = table.Column<string>(type: "text", nullable: false),
                    arquivo_mime_type = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    arquivo_nome = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    status = table.Column<int>(type: "integer", nullable: false),
                    motivo_rejeicao = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    data_upload = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    data_validade = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    anexado_por_academia = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    anexado_por_id = table.Column<Guid>(type: "uuid", nullable: true),
                    alerta_vencimento_enviado = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    criado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    atualizado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_atestados_medicos", x => x.id);
                    table.ForeignKey(
                        name: "FK_atestados_medicos_academias_academia_id",
                        column: x => x.academia_id,
                        principalTable: "academias",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_atestados_medicos_usuarios_aluno_id",
                        column: x => x.aluno_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_atestados_medicos_academia_id_status",
                table: "atestados_medicos",
                columns: new[] { "academia_id", "status" });

            migrationBuilder.CreateIndex(
                name: "IX_atestados_medicos_aluno_id_data_validade",
                table: "atestados_medicos",
                columns: new[] { "aluno_id", "data_validade" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "atestados_medicos");
        }
    }
}
