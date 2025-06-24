using Microsoft.EntityFrameworkCore;
using NSwag.Generation.Processors.Security;
using NSwag;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using System.Diagnostics.Metrics;
using Weather.API.Data;
using Weather.API.Models;
using NSwag.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();

builder.Services.AddOpenApiDocument((configure, serviceProvider) =>
{
    configure.Title = "Weather API";
});

// Setup SQLite with EF Core
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite("Data Source=weather.db"));

// Add OpenTelemetry
builder.Services.AddOpenTelemetry(builder.Configuration);

var app = builder.Build();

app.UseOpenApi();
app.UseSwaggerUi();

app.MapControllers();

// Add middleware to increment the counter for each request to the weather controller
app.Use(async (context, next) =>
{
    var path = context.Request.Path.Value?.ToLower();
    if (path?.Contains("/weather") == true)
    {
        OpenTelemetryExtensions.IncrementWeatherRequestCounter();
    }
    await next();
});

// Ensure the database is created and migrations are applied
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    dbContext.Database.EnsureCreated();
}

// Run the app
app.Run();

// Extension method to configure OpenTelemetry
public static class OpenTelemetryExtensions
{
    private static readonly Meter Meter = new("Weather.API", "1.0.0");
    private static readonly Counter<int> WeatherRequestCounter = Meter.CreateCounter<int>("weather.api.requests");
    
    public static void IncrementWeatherRequestCounter()
    {
        WeatherRequestCounter.Add(1);
    }

    public static IServiceCollection AddOpenTelemetry(this IServiceCollection services, IConfiguration configuration)
    {
        var projectName = configuration.GetValue<string>("ProjectName") ?? "Weather";
        var serviceName = configuration.GetValue<string>("ServiceName") ?? "API";
        var serviceName_Source = $"{projectName}.{serviceName}";

        services
            .AddOpenTelemetry()
            .WithMetrics(opt =>

                opt
                    .SetResourceBuilder(ResourceBuilder.CreateDefault().AddService(serviceName_Source))
                    .AddAspNetCoreInstrumentation()
                    .AddRuntimeInstrumentation()
                    .AddProcessInstrumentation()
                    .AddOtlpExporter(opts =>
                    {
                        opts.Endpoint = new Uri("http://otel-collector:4317");
                    })
            );


        return services;
    }
}
