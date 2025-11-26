Yep, you can (and should) wire logging into the Function app host too.
Here’s a clean way to do it in your isolated Azure Functions Program.cs.

1. Add the using

At the top of Program.cs:

using Microsoft.Extensions.Logging;

2. Update your HostBuilder to configure logging

Modify your existing code like this (I’ll keep your structure and just add logging in the middle):

using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Remap.Core;
using Remap.Core.Abstractions;
using Remap.Core.Options;
using Remap.Core.Services;
using Remap.Infrastructure.Configuration;
using Remap.Infrastructure.Data;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureAppConfiguration((ctx, cfg) =>
    {
        cfg.AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
           .AddEnvironmentVariables();
    })
    .ConfigureLogging((ctx, logging) =>
    {
        // optional: remove default providers so we control exactly what we use
        logging.ClearProviders();

        // logs go to the Functions console (and to App Insights in Azure)
        logging.AddConsole();

        // choose minimum level you want
        logging.SetMinimumLevel(LogLevel.Information);
    })
    .ConfigureServices((ctx, services) =>
    {
        var configuration = ctx.Configuration;

        // your existing wiring
        services.ConfigureInfrastructureOptions(configuration.GetSection("Infrastructure"));
        services.ConfigureRemapOptions(configuration.GetSection("Remap"));

        var infra = configuration.GetSection("Infrastructure").Get<InfrastructureOptions>();
        services.AddDbContext<RemapDbContext>(options =>
        {
            options.UseSqlServer(
                infra.MainConnectionString,
                sql =>
                {
                    sql.CommandTimeout(infra.CommandTimeoutSeconds);
                });
        }, ServiceLifetime.Transient);

        services.AddScoped<IRemapRepository, SqlRemapRepository>();
        services.AddScoped<IPositionalXmlTransformer, PositionalXmlTransformer>();
        services.AddScoped<IRemapOrchestrator, RemapOrchestrator>();
    })
    .Build();

await host.RunAsync();

3. Use logging inside your Function

In your function class (isolated model), inject ILogger<YourFunctionClass>:

public class RemapTimer
{
    private readonly ILogger<RemapTimer> _logger;
    private readonly IRemapOrchestrator _orchestrator;

    public RemapTimer(ILogger<RemapTimer> logger, IRemapOrchestrator orchestrator)
    {
        _logger = logger;
        _orchestrator = orchestrator;
    }

    [Function("RemapTimer")]
    public async Task RunAsync(
        [TimerTrigger("0 */2 * * * *")] TimerInfo timer,
        CancellationToken ct)
    {
        _logger.LogInformation("RemapTimer triggered at {Time}", DateTimeOffset.Now);

        await _orchestrator.RunOneGlobalCycleAsync(ct);

        _logger.LogInformation("RemapTimer finished at {Time}", DateTimeOffset.Now);
    }
}

That’s it — now your Function app logs will show up in the local Functions console, and when deployed to Azure they’ll flow into the normal Functions logging pipeline (and Application Insights if configured).