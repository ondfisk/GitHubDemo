namespace MovieApi.Tests.Models;

public sealed class MovieDbContextTests : IAsyncLifetime
{
    private readonly MsSqlContainer _database = new MsSqlBuilder().WithImage("mcr.microsoft.com/mssql/server:latest").Build();

    [Fact]
    public async Task After_migration_database_contains_people()
    {
        using var context = BuildContext();

        await context.Database.MigrateAsync();

        var people = await context.People.ToListAsync();

        people.Count.Should().Be(8);
    }

    [Fact]
    public async Task After_migration_database_contains_movies()
    {
        using var context = BuildContext();

        await context.Database.MigrateAsync();

        var movies = await context.Movies.ToListAsync();

        movies.Count.Should().Be(10);
    }

    public Task InitializeAsync() => _database.StartAsync();

    public Task DisposeAsync() => _database.DisposeAsync().AsTask();

    private MovieDbContext BuildContext()
    {
        var connectionString = _database.GetConnectionString();

        var options = new DbContextOptionsBuilder<MovieDbContext>().UseSqlServer(connectionString).Options;

        return new MovieDbContext(options);
    }
}