using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AcademiaFight.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddModalidadeIdToContrato : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ModalidadeId",
                table: "Contratos",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Contratos_ModalidadeId",
                table: "Contratos",
                column: "ModalidadeId");

            migrationBuilder.AddForeignKey(
                name: "FK_Contratos_modalidades_ModalidadeId",
                table: "Contratos",
                column: "ModalidadeId",
                principalTable: "modalidades",
                principalColumn: "id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Contratos_modalidades_ModalidadeId",
                table: "Contratos");

            migrationBuilder.DropIndex(
                name: "IX_Contratos_ModalidadeId",
                table: "Contratos");

            migrationBuilder.DropColumn(
                name: "ModalidadeId",
                table: "Contratos");
        }
    }
}
