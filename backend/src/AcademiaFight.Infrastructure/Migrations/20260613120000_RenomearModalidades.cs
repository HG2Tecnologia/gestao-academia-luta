using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AcademiaFight.Infrastructure.Migrations
{
    public partial class RenomearModalidades : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                UPDATE modalidades SET nome = 'Jiu Jitsu'
                WHERE nome ILIKE '%jiu-jitsu%adulto%' OR nome ILIKE '%jiu jitsu%adulto%';

                UPDATE modalidades SET nome = 'Jiu Jitsu (Infantil)'
                WHERE nome ILIKE '%jiu-jitsu%infanto%' OR nome ILIKE '%jiu jitsu%infanto%'
                   OR nome ILIKE '%jiu-jitsu%juvenil%' OR nome ILIKE '%jiu jitsu%juvenil%';

                UPDATE modalidades SET nome = 'Luta Livre Esportiva'
                WHERE nome = 'Luta Livre';
            ");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                UPDATE modalidades SET nome = 'Jiu-Jitsu Brasileiro — Adulto'
                WHERE nome = 'Jiu Jitsu';

                UPDATE modalidades SET nome = 'Jiu-Jitsu Brasileiro — Infanto-Juvenil'
                WHERE nome = 'Jiu Jitsu (Infantil)';

                UPDATE modalidades SET nome = 'Luta Livre'
                WHERE nome = 'Luta Livre Esportiva';
            ");
        }
    }
}
