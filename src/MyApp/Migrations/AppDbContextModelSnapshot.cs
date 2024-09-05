﻿// <auto-generated />
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using MyApp.Features.Shared;

#nullable disable

namespace MyApp.Migrations
{
    [DbContext(typeof(AppDbContext))]
    partial class AppDbContextModelSnapshot : ModelSnapshot
    {
        protected override void BuildModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "9.0.0-preview.6.24327.4")
                .HasAnnotation("Relational:MaxIdentifierLength", 128);

            SqlServerModelBuilderExtensions.UseIdentityColumns(modelBuilder);

            modelBuilder.Entity("MyApp.Features.Shared.Movie", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<int?>("DirectorId")
                        .HasColumnType("int");

                    b.Property<double>("Rating")
                        .HasColumnType("float");

                    b.Property<string>("Title")
                        .IsRequired()
                        .HasMaxLength(250)
                        .HasColumnType("nvarchar(250)");

                    b.Property<int>("Year")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.HasIndex("DirectorId");

                    b.ToTable("Movies");

                    b.HasData(
                        new
                        {
                            Id = 1,
                            DirectorId = 1,
                            Rating = 9.3000000000000007,
                            Title = "The Shawshank Redemption",
                            Year = 1994
                        },
                        new
                        {
                            Id = 2,
                            DirectorId = 2,
                            Rating = 9.1999999999999993,
                            Title = "The Godfather",
                            Year = 1972
                        },
                        new
                        {
                            Id = 3,
                            DirectorId = 3,
                            Rating = 9.0,
                            Title = "The Dark Knight",
                            Year = 2008
                        },
                        new
                        {
                            Id = 4,
                            DirectorId = 1,
                            Rating = 9.0,
                            Title = "The Godfather Part II",
                            Year = 1974
                        },
                        new
                        {
                            Id = 5,
                            DirectorId = 4,
                            Rating = 9.0,
                            Title = "12 Angry Men",
                            Year = 1957
                        },
                        new
                        {
                            Id = 6,
                            DirectorId = 5,
                            Rating = 8.9000000000000004,
                            Title = "Schindler's List",
                            Year = 1993
                        },
                        new
                        {
                            Id = 7,
                            DirectorId = 6,
                            Rating = 8.9000000000000004,
                            Title = "The Lord of the Rings: The Return of the King",
                            Year = 2003
                        },
                        new
                        {
                            Id = 8,
                            DirectorId = 7,
                            Rating = 8.9000000000000004,
                            Title = "Pulp Fiction",
                            Year = 1994
                        },
                        new
                        {
                            Id = 9,
                            DirectorId = 6,
                            Rating = 8.8000000000000007,
                            Title = "The Lord of the Rings: The Fellowship of the Ring",
                            Year = 2001
                        },
                        new
                        {
                            Id = 10,
                            DirectorId = 8,
                            Rating = 8.8000000000000007,
                            Title = "The Good, the Bad and the Ugly",
                            Year = 1966
                        });
                });

            modelBuilder.Entity("MyApp.Features.Shared.Person", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("nvarchar(100)");

                    b.HasKey("Id");

                    b.ToTable("People");

                    b.HasData(
                        new
                        {
                            Id = 1,
                            Name = "Frank Darabont"
                        },
                        new
                        {
                            Id = 2,
                            Name = "Francis Ford Coppola"
                        },
                        new
                        {
                            Id = 3,
                            Name = "Christopher Nolan"
                        },
                        new
                        {
                            Id = 4,
                            Name = "Sidney Lumet"
                        },
                        new
                        {
                            Id = 5,
                            Name = "Steven Spielberg"
                        },
                        new
                        {
                            Id = 6,
                            Name = "Peter Jackson"
                        },
                        new
                        {
                            Id = 7,
                            Name = "Quentin Tarantino"
                        },
                        new
                        {
                            Id = 8,
                            Name = "Sergio Leone"
                        });
                });

            modelBuilder.Entity("MyApp.Features.Shared.Movie", b =>
                {
                    b.HasOne("MyApp.Features.Shared.Person", "Director")
                        .WithMany("DirectedMovies")
                        .HasForeignKey("DirectorId");

                    b.Navigation("Director");
                });

            modelBuilder.Entity("MyApp.Features.Shared.Person", b =>
                {
                    b.Navigation("DirectedMovies");
                });
#pragma warning restore 612, 618
        }
    }
}
