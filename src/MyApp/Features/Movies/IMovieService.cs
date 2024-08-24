namespace MyApp.Features.Movies;

public interface IMovieService
{
    Task<IEnumerable<MovieDTO>> ReadAll();
}