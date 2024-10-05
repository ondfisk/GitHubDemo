namespace MovieApi.Models;

public sealed class MovieDbContext(DbContextOptions<MovieDbContext> options) : DbContext(options)
{
    public DbSet<Movie> Movies => Set<Movie>();
    public DbSet<Person> People => Set<Person>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Movie>()
            .HasOne(m => m.Director)
            .WithMany(p => p.DirectedMovies)
            .HasForeignKey(m => m.DirectorId);

        modelBuilder.Entity<Movie>()
            .Property(m => m.Title)
            .HasMaxLength(250);

        modelBuilder.Entity<Person>()
            .Property(p => p.Name)
            .HasMaxLength(100);

        modelBuilder.Entity<Person>().HasData(
            new Person { Id = 1, Name = "Frank Darabont" },
            new Person { Id = 2, Name = "Francis Ford Coppola" },
            new Person { Id = 3, Name = "Christopher Nolan" },
            new Person { Id = 4, Name = "Sidney Lumet" },
            new Person { Id = 5, Name = "Steven Spielberg" },
            new Person { Id = 6, Name = "Peter Jackson" },
            new Person { Id = 7, Name = "Quentin Tarantino" },
            new Person { Id = 8, Name = "Sergio Leone" }
        );

        modelBuilder.Entity<Movie>().HasData(
            new Movie { Id = 1, Title = "The Shawshank Redemption", DirectorId = 1, Year = 1994 },
            new Movie { Id = 2, Title = "The Godfather", DirectorId = 2, Year = 1972 },
            new Movie { Id = 3, Title = "The Dark Knight", DirectorId = 3, Year = 2008 },
            new Movie { Id = 4, Title = "The Godfather Part II", DirectorId = 1, Year = 1974 },
            new Movie { Id = 5, Title = "12 Angry Men", DirectorId = 4, Year = 1957 },
            new Movie { Id = 6, Title = "Schindler's List", DirectorId = 5, Year = 1993 },
            new Movie { Id = 7, Title = "The Lord of the Rings: The Return of the King", DirectorId = 6, Year = 2003 },
            new Movie { Id = 8, Title = "Pulp Fiction", DirectorId = 7, Year = 1994 },
            new Movie { Id = 9, Title = "The Lord of the Rings: The Fellowship of the Ring", DirectorId = 6, Year = 2001 },
            new Movie { Id = 10, Title = "The Good, the Bad and the Ugly", DirectorId = 8, Year = 1966 }
        );
    }
}
