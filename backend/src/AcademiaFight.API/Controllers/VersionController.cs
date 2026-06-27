using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/version")]
[AllowAnonymous]
public class VersionController : ControllerBase
{
    private readonly IConfiguration _config;

    public VersionController(IConfiguration config)
    {
        _config = config;
    }

    [HttpGet]
    public IActionResult Get([FromQuery] string? platform)
    {
        var section = _config.GetSection("AppVersion");
        var currentVersion = platform?.ToLower() switch
        {
            "android" => section["AndroidCurrentVersion"] ?? section["CurrentVersion"] ?? "1.0.0",
            "ios"     => section["IosCurrentVersion"]     ?? section["CurrentVersion"] ?? "1.0.0",
            _         => section["CurrentVersion"] ?? "1.0.0"
        };
        return Ok(new
        {
            minVersion = section["MinVersion"] ?? "1.0.0",
            currentVersion,
            forceUpdate = bool.TryParse(section["ForceUpdate"], out var f) && f,
            iosUrl = section["IosUrl"] ?? "",
            androidUrl = section["AndroidUrl"] ?? ""
        });
    }
}
