using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AcademiaFight.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddFirebaseUid : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "FirebaseUid",
                table: "usuarios",
                type: "text",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_usuarios_FirebaseUid",
                table: "usuarios",
                column: "FirebaseUid",
                unique: true,
                filter: "\"FirebaseUid\" IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_usuarios_FirebaseUid",
                table: "usuarios");

            migrationBuilder.DropColumn(
                name: "FirebaseUid",
                table: "usuarios");
        }
    }
}
