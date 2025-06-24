using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Weather.API.Data;
using Weather.API.Models;

namespace Weather.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class WeatherController : ControllerBase
    {
        private readonly AppDbContext _dbContext;

        public WeatherController(AppDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<WeatherForecast>>> GetWeatherForecasts()
        {
            return await _dbContext.WeatherForecasts.ToListAsync();
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<WeatherForecast>> GetWeatherForecast(int id)
        {
            var forecast = await _dbContext.WeatherForecasts.FindAsync(id);

            if (forecast == null)
            {
                return NotFound();
            }

            return forecast;
        }

        [HttpPost]
        public async Task<ActionResult<WeatherForecast>> CreateWeatherForecast(WeatherForecast forecast)
        {
            _dbContext.WeatherForecasts.Add(forecast);
            await _dbContext.SaveChangesAsync();

            return CreatedAtAction(nameof(GetWeatherForecast), new { id = forecast.Id }, forecast);
        }
    }
}