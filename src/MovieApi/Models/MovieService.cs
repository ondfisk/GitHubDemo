namespace MovieApi.Models;

public sealed class MovieService(MovieDbContext context) : IMovieService
{
    private readonly MovieDbContext _context = context;

    public async Task<IEnumerable<MovieDTO>> ReadAll() =>
        await _context.Movies
            .OrderBy(m => m.Title)
            .Select(static m => new MovieDTO(m.Id, m.Title, m.Director != null ? m.Director.Name : null, m.Year))
            .ToArrayAsync();
}
