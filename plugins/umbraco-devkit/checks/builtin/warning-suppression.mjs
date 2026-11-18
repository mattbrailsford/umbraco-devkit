// A compiler warning, analyzer or type check turned off with no reason next to it. Sometimes
// right, but never silently: a reason on the same line or the line above passes the check, and
// the reviewer judges it.

const RULES = [
  {
    files: /\.cs$/i,
    hit: /^\s*#pragma\s+warning\s+disable\b|^\s*#nullable\s+disable\b/,
    reason: (t) => /\/\/\s*\S+\s+\S+/.test(t),
  },
  {
    files: /\.cs$/i,
    hit: /\bSuppressMessage(Attribute)?\s*\(/,
    reason: (t) => /\bJustification\s*=\s*"[^"\s][^"]*"/.test(t),
    noPrevious: true,
  },
  {
    files: /\.(csproj|props|targets)$/i,
    hit: /<NoWarn>|<WarningsNotAsErrors>|<TreatWarningsAsErrors>\s*false|<WarningLevel>\s*0|<Nullable>\s*disable|<RunAnalyzers[^>]*>\s*false|<EnforceCodeStyleInBuild>\s*false/i,
    reason: (t) => /<!--\s*\S+\s+\S+/.test(t),
  },
  {
    files: /(^|\/)\.editorconfig$/,
    hit: /^\s*dotnet_diagnostic\.\S+\.severity\s*=\s*(none|silent|suggestion)\b/i,
    reason: () => false,
  },
  {
    files: /\.(ts|tsx|js|mjs)$/i,
    hit: /@ts-(ignore|nocheck|expect-error)\b/,
    reason: (t) => /@ts-(ignore|nocheck|expect-error)\b:?\s*\S+\s+\S+/.test(t),
  },
  {
    files: /\.(ts|tsx|js|mjs)$/i,
    hit: /\beslint-disable(-next-line|-line)?\b/,
    reason: (t) => /\s--\s*\S/.test(t),
    noPrevious: true,
  },
  {
    files: /(^|\/)tsconfig[^/]*\.json$/i,
    hit: /"(strict|noImplicitAny|strictNullChecks)"\s*:\s*false/,
    reason: (t) => /\/\/\s*\S+\s+\S+/.test(t),
  },
];

const COMMENT_LINE = /^\s*(\/\/|#|;|<!--|\/\*|\*)/;

export default {
  name: "warning-suppression",
  files: (path) => RULES.some((r) => r.files.test(path)),
  checkFile({ path, added, text }) {
    const all = text === null ? [] : text.split(/\r?\n/);
    const rules = RULES.filter((r) => r.files.test(path));
    const findings = [];
    for (const l of added) {
      const rule = rules.find((r) => r.hit.test(l.text));
      if (!rule || rule.reason(l.text)) continue;
      const previous = all[l.line - 2] ?? "";
      if (!rule.noPrevious && COMMENT_LINE.test(previous) && !rule.hit.test(previous)) continue;
      findings.push({ line: l.line, message: "warning or check turned off with no reason; fix the cause, or give the reason next to it" });
    }
    return findings;
  },
};
