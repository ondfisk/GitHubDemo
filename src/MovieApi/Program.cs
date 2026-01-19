var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHealthChecks();
builder.Services.AddScoped<IMovieService, MovieService>();

if (builder.Environment.IsDevelopment())
{
    builder.Services.AddDbContext<MovieDbContext>(options => options.UseNpgsql(builder.Configuration.GetConnectionString("Default")));
}
else
{
    var dataSourceBuilder = new NpgsqlDataSourceBuilder(Environment.GetEnvironmentVariable("AZURE_POSTGRESQL_CONNECTIONSTRING"));
    if (string.IsNullOrWhiteSpace(dataSourceBuilder.ConnectionStringBuilder.Password))
    {
        var credentials = new DefaultAzureCredential();
        dataSourceBuilder.UsePeriodicPasswordProvider(
            async (_, cancellationToken) =>
            {
                var accessToken = await credentials.GetTokenAsync(new TokenRequestContext(["https://ossrdbms-aad.database.windows.net/.default"]), cancellationToken);
                return accessToken.Token;
            },
            TimeSpan.FromHours(23),
            TimeSpan.FromSeconds(10)
        );
    }
    var dataSource = dataSourceBuilder.Build();
    builder.Services.AddDbContext<MovieDbContext>(options => options.UseNpgsql(dataSource));
}

if (Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING") is not null)
{
    builder.Services.AddOpenTelemetry().UseAzureMonitor();
}

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapHealthChecks("/healthz");

app.MapGet("/movies", async (IMovieService movieService, CancellationToken cancellationToken) =>
{
    return await movieService.ReadAll(cancellationToken);
})
.WithName("GetMovies");

app.Run();
