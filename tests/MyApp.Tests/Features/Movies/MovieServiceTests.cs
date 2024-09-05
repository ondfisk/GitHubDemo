using Microsoft.EntityFrameworkCore;
using MyApp.Features.Movies;

namespace MyApp.Tests.Features.Movies;

public sealed class MovieServiceTests : IAsyncLifetime
{
    private readonly SqliteConnection _connection;
    private readonly AppDbContext _context;
    private readonly MovieService _service;

    public MovieServiceTests()
    {
        _connection = new SqliteConnection("Filename=:memory:");
        var builder = new DbContextOptionsBuilder<AppDbContext>().UseSqlite(_connection);
        _context = new AppDbContext(builder.Options);
        _service = new MovieService(_context);
    }

    [Fact]
    public async Task ReadAll_should_return_all_movies()
    {
        var movies = await _service.ReadAll();

        movies.Count().Should().Be(10);
    }

    [Fact]
    public async Task ReadAll_should_map_all_properties()
    {
        var movies = await _service.ReadAll();

        var pulpFiction = new MovieDTO(8, "Pulp Fiction", "Quentin Tarantino", 1994, 8.9);

        movies.Should().Contain(pulpFiction);
    }

    public async Task InitializeAsync()
    {
        await _connection.OpenAsync();
        await _context.Database.EnsureCreatedAsync();
    }

    public async Task DisposeAsync()
    {
        await _context.DisposeAsync();
        await _connection.DisposeAsync();
    }
}