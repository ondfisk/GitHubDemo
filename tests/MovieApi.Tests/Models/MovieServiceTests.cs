namespace MovieApi.Tests.Models;

public class MovieServiceTests : IAsyncLifetime
{
    private SqliteConnection _connection;
    private MovieDbContext _context;
    private MovieService _service;

    public MovieServiceTests()
    {
        _connection = new SqliteConnection("Filename=:memory:");
        var builder = new DbContextOptionsBuilder<MovieDbContext>().UseSqlite(_connection);
        _context = new MovieDbContext(builder.Options);
        _service = new MovieService(_context);
    }

    [Fact]
    public async Task ReadAll_should_return_all_movies()
    {
        var movies = await _service.ReadAll();

        Assert.Equal(10, movies.Count());
    }

    [Fact]
    public async Task ReadAll_should_map_all_properties()
    {
        var movies = await _service.ReadAll();

        var pulpFiction = new MovieDTO(8, "Pulp Fiction", "Quentin Tarantino", 1994);

        Assert.Contains(pulpFiction, movies);
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
