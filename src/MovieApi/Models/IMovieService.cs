namespace MovieApi.Models;

public interface IMovieService
{
    Task<IEnumerable<MovieDTO>> ReadAll(CancellationToken cancellationToken = default);
}