{
  "Remap": {
    "CronSchedule": "*/2 * * * *",   // every 2 minutes
    "ActiveWindowStart": "02:00",
    "ActiveWindowEnd": "06:00",
    "TimeZone": "Eastern Standard Time",
    "BatchSize": 5000,
    "Parallelism": 4,
    "PollSeconds": 60
  },
  "Infrastructure": {
    "MainConnectionString": "...",
    "CommandTimeoutSeconds": 120
  }
}

-----------

dotnet add package NCrontab


--------------------------

using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using NCrontab;

public class RemapWorker : BackgroundService
{
    private readonly ILogger<RemapWorker> _logger;
    private readonly IConfiguration _config;
    private readonly IRemapOrchestrator _orchestrator;

    private CrontabSchedule _cron;
    private TimeZoneInfo _tz;
    private TimeSpan _windowStart;
    private TimeSpan _windowEnd;

    public RemapWorker(
        ILogger<RemapWorker> logger,
        IConfiguration config,
        IRemapOrchestrator orchestrator)
    {
        _logger = logger;
        _config = config;
        _orchestrator = orchestrator;

        // Load cron expression
        var cronExpr = _config["Remap:CronSchedule"] ?? "*/2 * * * *";
        _cron = CrontabSchedule.Parse(cronExpr);

        // Load active window rules
        _windowStart = TimeSpan.Parse(_config["Remap:ActiveWindowStart"] ?? "02:00");
        _windowEnd   = TimeSpan.Parse(_config["Remap:ActiveWindowEnd"]   ?? "06:00");

        var tzName    = _config["Remap:TimeZone"] ?? "Eastern Standard Time";
        _tz = TimeZoneInfo.FindSystemTimeZoneById(tzName);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("RemapWorker started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            var nowUtc = DateTime.UtcNow;
            var nowLocal = TimeZoneInfo.ConvertTimeFromUtc(nowUtc, _tz);

            if (!IsInsideWindow(nowLocal.TimeOfDay))
            {
                _logger.LogInformation(
                    "Outside active window {Start}-{End} ({TZ}). Skipping.",
                    _windowStart, _windowEnd, _tz.Id);

                await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
                continue;
            }

            // Wait until next cron tick
            var next = _cron.GetNextOccurrence(nowUtc);
            var delay = next - nowUtc;

            if (delay > TimeSpan.Zero)
                await Task.Delay(delay, stoppingToken);

            if (stoppingToken.IsCancellationRequested)
                break;

            _logger.LogInformation("Cron tick at {Time}, starting remap cycle.", nowLocal);

            try
            {
                await _orchestrator.RunOneGlobalCycleAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unhandled error in remap cycle.");
            }
        }
    }

    private bool IsInsideWindow(TimeSpan now)
    {
        if (_windowStart <= _windowEnd)
        {
            // Normal (02:00 → 06:00)
            return now >= _windowStart && now < _windowEnd;
        }
        else
        {
            // Overnight (22:00 → 02:00)
            return now >= _windowStart || now < _windowEnd;
        }
    }
}



"CronSchedule": "*/5 * * * *"    // every 5 minutes


"ActiveWindowStart": "01:00",
"ActiveWindowEnd": "04:30",
"TimeZone": "Pacific Standard Time"
