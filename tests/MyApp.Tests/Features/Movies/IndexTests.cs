using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using MyApp.Features.Movies;
using Testcontainers.MsSql;
using Index = MyApp.Features.Movies.Index;

namespace MyApp.Tests.Features.Movies;

public sealed class IndexTests : IAsyncLifetime
{
    private readonly MsSqlContainer _database = new MsSqlBuilder().Build();
    private readonly TestContext _ctx = new();

    [Fact]
    public void Table_contains_10_rows()
    {
        // Arrange
        var cut = _ctx.RenderComponent<Index>();
        cut.WaitForElement("table.table");
        var tbody = cut.Find("table.table tbody");

        // Act
        var rows = tbody.Children;

        // Assert
        rows.Length.Should().Be(10);
    }

    public async Task InitializeAsync()
    {
        await _database.StartAsync();

        _ctx.Services.AddDbContext<AppDbContext>(options => options.UseSqlServer(_database.GetConnectionString()));
        _ctx.Services.AddScoped<IMovieService, MovieService>();

        var context = _ctx.Services.GetRequiredService<AppDbContext>();
        await context.Database.MigrateAsync();
    }

    public async Task DisposeAsync()
    {
        _ctx.Dispose();
        await _database.DisposeAsync();
    }
}