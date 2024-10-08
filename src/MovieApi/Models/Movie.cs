namespace MovieApi.Models;

public class Movie
{
    public int Id { get; set; }
    public required string Title { get; set; }
    public int? DirectorId { get; set; }
    public Person? Director { get; set; }
    public int Year { get; set; }
}
