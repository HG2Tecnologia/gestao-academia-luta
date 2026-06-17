using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AcademiaFight.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddNoticias : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "NoticiasAtivas",
                table: "academias",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateTable(
                name: "noticias",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    academia_id = table.Column<Guid>(type: "uuid", nullable: false),
                    titulo = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    resumo = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    conteudo = table.Column<string>(type: "text", nullable: true),
                    imagem_base64 = table.Column<string>(type: "TEXT", nullable: true),
                    publicada = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    publicada_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    autor_id = table.Column<Guid>(type: "uuid", nullable: true),
                    criado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    atualizado_em = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_noticias", x => x.id);
                    table.ForeignKey(
                        name: "FK_noticias_academias_academia_id",
                        column: x => x.academia_id,
                        principalTable: "academias",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_noticias_usuarios_autor_id",
                        column: x => x.autor_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_noticias_academia_id_publicada_em",
                table: "noticias",
                columns: new[] { "academia_id", "publicada_em" });

            migrationBuilder.CreateIndex(
                name: "IX_noticias_autor_id",
                table: "noticias",
                column: "autor_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "noticias");

            migrationBuilder.DropColumn(
                name: "NoticiasAtivas",
                table: "academias");
        }
    }
}
