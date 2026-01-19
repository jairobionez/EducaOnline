using EducaOnline.Bff.Configurations;
using EducaOnline.WebAPI.Core.Identidade;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog((context, configuration) =>
{
    configuration
        .ReadFrom.Configuration(context.Configuration)
        .Enrich.FromLogContext()
        .WriteTo.Console()
        .WriteTo.File("logs/log-.txt", rollingInterval: RollingInterval.Day);
});

var environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT");
builder.Configuration
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json", true, true)
    .AddJsonFile($"appsettings.{environment}.json", true, true)
    .AddEnvironmentVariables();

if (builder.Environment.IsDevelopment())
    builder.Configuration.AddUserSecrets<Program>();

builder.Services
    .AddApiConfiguration(builder.Configuration)
    .AddJwtConfiguration(builder.Configuration)
    .AddDependenceInjectionConfiguration()
    .AddSwaggerConfiguration()
    .AddMessageBusConfiguration(builder.Configuration);


var app = builder.Build();
app
    .UseSwaggerConfiguration()
    .UseApiConfiguration();

app.MapHealthChecks("/health");
app.MapHealthChecks("/health/ready");

app.Run();
