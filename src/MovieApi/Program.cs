var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddHealthChecks();
builder.Services.AddScoped<IMovieService, MovieService>();

if (builder.Environment.IsDevelopment())
{
    builder.Services.AddDbContext<MovieDbContext>(options => options.UseNpgsql(builder.Configuration.GetConnectionString("Default")));
}
else
{
    builder.Services.AddDbContext<MovieDbContext>(options => options.UseNpgsql(Environment.GetEnvironmentVariable("AZURE_SQL_CONNECTIONSTRING")));
}

if (Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING") is not null)
{
    builder.Services.AddOpenTelemetry().UseAzureMonitor();
}

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.MapHealthChecks("/healthz");

app.MapGet("/movies", async (IMovieService movieService, CancellationToken cancellationToken) =>
{
    return await movieService.ReadAll(cancellationToken);
})
.WithName("GetMovies");

app.Run();
