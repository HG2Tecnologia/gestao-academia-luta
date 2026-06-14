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
    public IActionResult Get()
    {
        var section = _config.GetSection("AppVersion");
        return Ok(new
        {
            minVersion = section["MinVersion"] ?? "1.0.0",
            currentVersion = section["CurrentVersion"] ?? "1.0.0",
            forceUpdate = bool.TryParse(section["ForceUpdate"], out var f) && f,
            iosUrl = section["IosUrl"] ?? "",
            androidUrl = section["AndroidUrl"] ?? ""
        });
    }
}
