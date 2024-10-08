namespace MovieApi.Models;

public sealed record MovieDTO(int Id, string Title, string? Director, int Year);
