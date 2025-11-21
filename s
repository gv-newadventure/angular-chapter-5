{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "...",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",

    // Run the function every 2 minutes
    "RemapTimerSchedule": "0 */2 * * * *",

    // Active window (local time of chosen time zone)
    "Remap_ActiveWindow_Start": "02:00",               // 2:00 AM
    "Remap_ActiveWindow_End":   "06:00",               // 6:00 AM
    "Remap_ActiveWindow_TimeZone": "Eastern Standard Time",

    // existing settings
    "Remap_BatchSize": 1000,
    "Remap_Parallelism": 4,
    "Remap_PollSeconds": 60,
    "Infrastructure__MainConnectionString": "...",
    "Infrastructure__CommandTimeoutSeconds": 120
  }
}


----------------------------------------

using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

public sealed class RemapTimer
{
    private readonly ILogger<RemapTimer> _logger;
    private readonly IConfiguration _config;
    private readonly IRemapOrchestrator _orchestrator;

    public RemapTimer(
        ILogger<RemapTimer> logger,
        IConfiguration config,
        IRemapOrchestrator orchestrator)
    {
        _logger = logger;
        _config = config;
        _orchestrator = orchestrator;
    }

    [Function("RemapTimer")]
    public async Task RunAsync(
        [TimerTrigger("%RemapTimerSchedule%")] TimerInfo timerInfo,
        CancellationToken ct)
    {
        if (!IsWithinActiveWindow(out var nowLocal, out var windowStart, out var windowEnd, out var tzId))
        {
            _logger.LogInformation(
                "RemapTimer fired at {Now} ({TimeZone}) but outside window {Start}-{End}. Skipping work.",
                nowLocal, tzId, windowStart, windowEnd);
            return;
        }

        _logger.LogInformation(
            "RemapTimer fired at {Now} ({TimeZone}) within window {Start}-{End}. Running remap batch.",
            nowLocal, tzId, windowStart, windowEnd);

        // Do ONE global cycle here (or your existing batch logic)
        await _orchestrator.RunOneGlobalCycleAsync(ct);
    }

    private bool IsWithinActiveWindow(
        out DateTime nowLocal,
        out TimeSpan windowStart,
        out TimeSpan windowEnd,
        out string timeZoneId)
    {
        timeZoneId = _config["Remap_ActiveWindow_TimeZone"] ?? "Eastern Standard Time";

        // Read configured start/end times; default if invalid
        var startStr = _config["Remap_ActiveWindow_Start"] ?? "02:00";
        var endStr   = _config["Remap_ActiveWindow_End"]   ?? "06:00";

        if (!TimeSpan.TryParse(startStr, out windowStart))
            windowStart = new TimeSpan(2, 0, 0);

        if (!TimeSpan.TryParse(endStr, out windowEnd))
            windowEnd = new TimeSpan(6, 0, 0);

        var tz = TimeZoneInfo.FindSystemTimeZoneById(timeZoneId);
        nowLocal = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, tz);
        var nowTime = nowLocal.TimeOfDay;

        bool inside;
        if (windowStart <= windowEnd)
        {
            // Normal case: e.g., 02:00–06:00
            inside = nowTime >= windowStart && nowTime < windowEnd;
        }
        else
        {
            // Overnight case: e.g., 22:00–02:00 (wraps past midnight)
            inside = nowTime >= windowStart || nowTime < windowEnd;
        }

        return inside;
    }
}
