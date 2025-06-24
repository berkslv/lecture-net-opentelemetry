using Microsoft.EntityFrameworkCore;
using Weather.API.Models;

namespace Weather.API.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<WeatherForecast> WeatherForecasts { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Seed some initial weather data
        modelBuilder.Entity<WeatherForecast>().HasData(
            new WeatherForecast
            {
                Id = 1,
                Date = DateTime.Now.AddDays(1),
                TemperatureC = 20,
                Summary = "Mild"
            },
            new WeatherForecast
            {
                Id = 2,
                Date = DateTime.Now.AddDays(2),
                TemperatureC = 30,
                Summary = "Warm"
            },
            new WeatherForecast
            {
                Id = 3,
                Date = DateTime.Now.AddDays(3),
                TemperatureC = 10,
                Summary = "Cool"
            },
            new WeatherForecast
            {
                Id = 4,
                Date = DateTime.Now.AddDays(4),
                TemperatureC = 15,
                Summary = "Mild"
            },
            new WeatherForecast
            {
                Id = 5,
                Date = DateTime.Now.AddDays(5),
                TemperatureC = 0,
                Summary = "Freezing"
            }
        );

        base.OnModelCreating(modelBuilder);
    }
}