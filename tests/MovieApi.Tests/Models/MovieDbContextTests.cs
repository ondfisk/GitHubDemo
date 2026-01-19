namespace MovieApi.Tests.Models;

public sealed class MovieDbContextTests : IAsyncLifetime
{
    private readonly PostgreSqlContainer _database = new PostgreSqlBuilder("postgres:18").Build();

    [Fact]
    public async Task After_migration_database_contains_people()
    {
        using var context = BuildContext();

        await context.Database.MigrateAsync(TestContext.Current.CancellationToken);

        var people = await context.People.ToListAsync(TestContext.Current.CancellationToken);

        Assert.Equal(8, people.Count);
    }

    [Fact]
    public async Task After_migration_database_contains_movies()
    {
        using var context = BuildContext();

        await context.Database.MigrateAsync(TestContext.Current.CancellationToken);

        var movies = await context.Movies.ToListAsync(TestContext.Current.CancellationToken);

        Assert.Equal(10, movies.Count);
    }

    public async ValueTask InitializeAsync()
    {
        await _database.StartAsync();
    }

    public async ValueTask DisposeAsync()
    {
        await _database.DisposeAsync();
        GC.SuppressFinalize(this);
    }

    private MovieDbContext BuildContext()
    {
        var connectionString = _database.GetConnectionString();

        var options = new DbContextOptionsBuilder<MovieDbContext>().UseNpgsql(connectionString).Options;

        return new MovieDbContext(options);
    }
}