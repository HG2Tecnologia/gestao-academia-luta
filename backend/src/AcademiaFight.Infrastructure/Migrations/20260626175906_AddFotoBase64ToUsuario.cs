using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AcademiaFight.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddFotoBase64ToUsuario : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "FotoBase64",
                table: "usuarios",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "FotoBase64",
                table: "usuarios");
        }
    }
}
