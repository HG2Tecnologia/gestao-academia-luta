using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AcademiaFight.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddCatracaDeviceUserId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CatracaDeviceUserId",
                table: "usuarios",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_usuarios_AcademiaId_CatracaDeviceUserId",
                table: "usuarios",
                columns: new[] { "AcademiaId", "CatracaDeviceUserId" },
                unique: true,
                filter: "\"CatracaDeviceUserId\" IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_usuarios_AcademiaId_CatracaDeviceUserId",
                table: "usuarios");

            migrationBuilder.DropColumn(
                name: "CatracaDeviceUserId",
                table: "usuarios");
        }
    }
}
