using Microsoft.EntityFrameworkCore;
using Testcontainers.MsSql;

namespace MyApp.Tests.Features.Shared;

public sealed class AppDbContextTests : IAsyncLifetime
{
    private readonly MsSqlContainer _database = new MsSqlBuilder().Build();
    private readonly AppDbContext _context;

    public AppDbContextTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>().UseSqlServer().Options;
        _context = new AppDbContext(options);
    }

    [Fact]
    public async Task After_migration_database_contains_people()
    {
        var people = await _context.People.ToListAsync();

        people.Count.Should().Be(8);
    }

    [Fact]
    public async Task After_migration_database_contains_movies()
    {
        var movies = await _context.Movies.ToListAsync();

        movies.Count.Should().Be(10);
    }

    public async Task InitializeAsync()
    {
        await _database.StartAsync();

        _context.Database.SetConnectionString(_database.GetConnectionString());

        await _context.Database.MigrateAsync();
    }

    public async Task DisposeAsync()
    {
        await _context.DisposeAsync();
        await _database.DisposeAsync();
    }
}