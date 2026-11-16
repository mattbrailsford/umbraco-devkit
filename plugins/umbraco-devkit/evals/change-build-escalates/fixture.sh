#!/usr/bin/env bash
set -euo pipefail
mkdir -p src/MyPackage/Services src/MyPackage/Controllers src/MyPackage/Models
cat > CLAUDE.md <<'MD'
# My Package

## Feature workflow

Trunk branch: `main`. Plan folders live in `docs/plans/<feature-slug>/`.

## Build & test

`dotnet build` and `dotnet test`. No demo site.
MD
cat > src/MyPackage/Models/PackageSettings.cs <<'CS'
namespace MyPackage.Models;

public sealed class PackageSettings
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? ApiKey { get; set; }
}
CS
cat > src/MyPackage/Models/Profile.cs <<'CS'
namespace MyPackage.Models;

public sealed class Profile
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
}
CS
cat > src/MyPackage/Services/SettingsService.cs <<'CS'
using MyPackage.Models;

namespace MyPackage.Services;

internal sealed class SettingsService : ISettingsService
{
    private readonly ISettingsRepository _repository;
    public SettingsService(ISettingsRepository repository) => _repository = repository;

    public async Task SaveAsync(PackageSettings settings)
    {
        await _repository.SaveAsync(settings);
        // Slug is built from the name; throws on an empty name, after the save.
        settings.Name.Substring(0, 1).ToUpperInvariant();
    }
}
CS
cat > src/MyPackage/Services/ProfileService.cs <<'CS'
using MyPackage.Models;

namespace MyPackage.Services;

internal sealed class ProfileService : IProfileService
{
    private readonly IProfileRepository _repository;
    public ProfileService(IProfileRepository repository) => _repository = repository;

    public async Task SaveAsync(Profile profile)
    {
        await _repository.SaveAsync(profile);
        profile.Name.Substring(0, 1).ToUpperInvariant();
    }
}
CS
cat > src/MyPackage/Controllers/SettingsController.cs <<'CS'
using Microsoft.AspNetCore.Mvc;
using MyPackage.Models;
using MyPackage.Services;

namespace MyPackage.Controllers;

[ApiController]
[Route("umbraco/my-package/api/v1/settings")]
public sealed class SettingsController : ControllerBase
{
    private readonly ISettingsService _settings;
    public SettingsController(ISettingsService settings) => _settings = settings;

    [HttpPut]
    public async Task<IActionResult> Save(PackageSettings settings)
    {
        await _settings.SaveAsync(settings);
        return Ok();
    }
}
CS
cat > src/MyPackage/Controllers/ProfileController.cs <<'CS'
using Microsoft.AspNetCore.Mvc;
using MyPackage.Models;
using MyPackage.Services;

namespace MyPackage.Controllers;

[ApiController]
[Route("umbraco/my-package/api/v1/profiles")]
public sealed class ProfileController : ControllerBase
{
    private readonly IProfileService _profiles;
    public ProfileController(IProfileService profiles) => _profiles = profiles;

    [HttpPut]
    public async Task<IActionResult> Save(Profile profile)
    {
        await _profiles.SaveAsync(profile);
        return Ok();
    }
}
CS
