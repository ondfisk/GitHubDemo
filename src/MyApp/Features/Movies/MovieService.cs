using Microsoft.EntityFrameworkCore;
using MyApp.Features.Shared;

namespace MyApp.Features.Movies;

public class MovieService(AppDbContext context) : IMovieService
{
    private readonly AppDbContext _context = context;

    public async Task<IEnumerable<MovieDTO>> ReadAll() =>
        await _context.Movies
            .OrderBy(m => m.Title)
            .Select(static m => new MovieDTO(m.Id, m.Title, m.Director != null ? m.Director.Name : null, m.Year))
            .ToArrayAsync();
}
