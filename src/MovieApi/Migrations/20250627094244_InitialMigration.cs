using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace MovieApi.Migrations
{
    /// <inheritdoc />
    public partial class InitialMigration : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "People",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_People", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Movies",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Title = table.Column<string>(type: "character varying(250)", maxLength: 250, nullable: false),
                    DirectorId = table.Column<int>(type: "integer", nullable: true),
                    Year = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Movies", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Movies_People_DirectorId",
                        column: x => x.DirectorId,
                        principalTable: "People",
                        principalColumn: "Id");
                });

            migrationBuilder.InsertData(
                table: "People",
                columns: new[] { "Id", "Name" },
                values: new object[,]
                {
                    { 1, "Frank Darabont" },
                    { 2, "Francis Ford Coppola" },
                    { 3, "Christopher Nolan" },
                    { 4, "Sidney Lumet" },
                    { 5, "Steven Spielberg" },
                    { 6, "Peter Jackson" },
                    { 7, "Quentin Tarantino" },
                    { 8, "Sergio Leone" }
                });

            migrationBuilder.InsertData(
                table: "Movies",
                columns: new[] { "Id", "DirectorId", "Title", "Year" },
                values: new object[,]
                {
                    { 1, 1, "The Shawshank Redemption", 1994 },
                    { 2, 2, "The Godfather", 1972 },
                    { 3, 3, "The Dark Knight", 2008 },
                    { 4, 1, "The Godfather Part II", 1974 },
                    { 5, 4, "12 Angry Men", 1957 },
                    { 6, 5, "Schindler's List", 1993 },
                    { 7, 6, "The Lord of the Rings: The Return of the King", 2003 },
                    { 8, 7, "Pulp Fiction", 1994 },
                    { 9, 6, "The Lord of the Rings: The Fellowship of the Ring", 2001 },
                    { 10, 8, "The Good, the Bad and the Ugly", 1966 }
                });

            migrationBuilder.CreateIndex(
                name: "IX_Movies_DirectorId",
                table: "Movies",
                column: "DirectorId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Movies");

            migrationBuilder.DropTable(
                name: "People");
        }
    }
}
