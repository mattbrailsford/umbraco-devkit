#!/usr/bin/env bash
set -euo pipefail
d=src/Umbraco.Community.ReadingTime

mkdir -p $d

cat > $d/Umbraco.Community.ReadingTime.csproj <<'EOF'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Core" Version="[17.0.0, 18)" />
  </ItemGroup>
</Project>
EOF

cat > $d/ReadingTimeComposer.cs <<'EOF'
using Umbraco.Cms.Core.Composing;
using Umbraco.Cms.Core.DependencyInjection;

namespace Umbraco.Community.ReadingTime;

public class ReadingTimeComposer : IComposer
{
    public void Compose(IUmbracoBuilder builder) => builder.AddReadingTime();
}
EOF

cat > $d/UmbracoBuilderExtensions.cs <<'EOF'
using Microsoft.Extensions.DependencyInjection;
using Umbraco.Cms.Core.DependencyInjection;
using Umbraco.Cms.Core.Notifications;

namespace Umbraco.Community.ReadingTime;

public static class UmbracoBuilderExtensions
{
    public static IUmbracoBuilder AddReadingTime(this IUmbracoBuilder builder)
    {
        builder.Services.Configure<ReadingTimeSettings>(
            builder.Config.GetSection(ReadingTimeSettings.SectionName));
        builder.Services.AddSingleton<IReadingTimeCalculator, ReadingTimeCalculator>();
        builder.AddNotificationHandler<ContentSavingNotification, ReadingTimeSavingHandler>();
        return builder;
    }
}
EOF

cat > $d/ReadingTimeSettings.cs <<'EOF'
namespace Umbraco.Community.ReadingTime;

public class ReadingTimeSettings
{
    public const string SectionName = "ReadingTime";

    public int WordsPerMinute { get; set; } = 200;

    public string SourcePropertyAlias { get; set; } = "bodyText";

    public string TargetPropertyAlias { get; set; } = "readingTime";
}
EOF

cat > $d/ReadingTimeCalculator.cs <<'EOF'
using System.Text.RegularExpressions;
using Microsoft.Extensions.Options;

namespace Umbraco.Community.ReadingTime;

public interface IReadingTimeCalculator
{
    int Minutes(string? text);
}

internal sealed partial class ReadingTimeCalculator(IOptions<ReadingTimeSettings> settings) : IReadingTimeCalculator
{
    public int Minutes(string? text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return 0;
        }

        var words = Words().Matches(Tags().Replace(text, " ")).Count;
        return (int)Math.Ceiling(words / (double)settings.Value.WordsPerMinute);
    }

    [GeneratedRegex("<[^>]+>")]
    private static partial Regex Tags();

    [GeneratedRegex(@"\S+")]
    private static partial Regex Words();
}
EOF

cat > $d/ReadingTimeSavingHandler.cs <<'EOF'
using Microsoft.Extensions.Options;
using Umbraco.Cms.Core.Events;
using Umbraco.Cms.Core.Notifications;

namespace Umbraco.Community.ReadingTime;

internal sealed class ReadingTimeSavingHandler(
    IReadingTimeCalculator calculator,
    IOptions<ReadingTimeSettings> settings) : INotificationHandler<ContentSavingNotification>
{
    public void Handle(ContentSavingNotification notification)
    {
        var options = settings.Value;
        foreach (var content in notification.SavedEntities)
        {
            if (!content.HasProperty(options.SourcePropertyAlias) || !content.HasProperty(options.TargetPropertyAlias))
            {
                continue;
            }

            var text = content.GetValue<string>(options.SourcePropertyAlias);
            content.SetValue(options.TargetPropertyAlias, calculator.Minutes(text));
        }
    }
}
EOF

cat > $d/Properties.cs <<'EOF'
using System.Runtime.CompilerServices;

[assembly: InternalsVisibleTo("Umbraco.Community.ReadingTime.Tests.Integration")]
EOF

