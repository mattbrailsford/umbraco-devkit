# Umbraco Devkit

A Claude Code plugin for the whole life of an Umbraco package or backoffice extension:
setting it up, building features, fixing bugs, running the issue tracker, reviewing pull
requests, upgrading to a new CMS major, and publishing. C# / .NET backend, EF Core
persistence, Lit + UUI backoffice frontend.

Three things run through all of it:

- **Every code change is reviewed.** One agent builds, a read-only reviewer checks the diff,
  build, and tests before anything is committed. Features, fixes, and upgrades all go
  through it.
- **Umbraco knowledge, loaded when it's needed.** Skills for the C#, EF Core, and Lit + UUI
  idioms Umbraco itself uses, read against the real CMS source and docs for the version you
  target.
- **It asks before it touches git or your tracker.** Plans and drafts stay on disk until you
  say yes.

**This is a foundation, not a finished house.** Drop it into a new package or add-on and
build on it as the project grows.

## Get started

**1. Install.** From inside your Umbraco project:

```bash
# This devkit.
claude plugin marketplace add https://github.com/mattbrailsford/umbraco-devkit --scope project
claude plugin install umbraco-devkit@umbraco-devkit --scope project

# The official Umbraco backoffice extension-point skills.
claude plugin marketplace add https://github.com/umbraco/Umbraco-CMS-Backoffice-Skills.git#main --scope project
claude plugin install umbraco-cms-backoffice-skills@umbraco-backoffice-marketplace --scope project
```

The second plugin, the official
[Umbraco Backoffice Skills](https://github.com/umbraco/Umbraco-CMS-Backoffice-Skills), covers
the individual backoffice extension points; this devkit works alongside it.

The backoffice skills follow the CMS major. `#main` is the latest major. If your project
targets an older one, swap `#main` for `#v<major>/main` (for example `#v17/main`). The
backoffice API changes between majors, so the wrong line gives confidently wrong code.

You can also run the same commands inside Claude Code as `/plugin marketplace add ...` and
`/plugin install ...`.

**Optional:** the same marketplace has a testing plugin, with more patterns for backoffice
tests: mocked API responses, trees, entity actions and test data builders.

```bash
claude plugin install umbraco-cms-backoffice-testing-skills@umbraco-backoffice-marketplace --scope project
```

This devkit doesn't need it. `umbraco-dotnet-testing` and `umbraco-backoffice-testing` cover
the setup a package's tests need, and where the two disagree on package names, environment
variables or setup, follow this devkit's skills.

**Optional:** copy [`settings.example.json`](./settings.example.json) to your project's
`.claude/settings.json` and uncomment the permissions and hooks you want. It isn't installed
with the plugin, because what to allow is your call.

**2. Set up the project.** Inside Claude Code, run `/project-init`. It's a wizard that asks
before each step. Run it again any time to fill gaps. When it's done, open `CLAUDE.md` and
check the **Stack** section: the CMS version(s) you target and the database(s) you support
should be filled in, with no `TODO` left. Many skills and the reviewer's checks depend on
them.

**3. Ask for what you want.** Describe it ("add a dashboard that...", "why does saving fail
when...", "triage the new issues") and the right skill picks it up. Or run one yourself from
the tables below.

## What you can do

### Set up

| I want to... | Run |
|---|---|
| Set up a project for this devkit: `CLAUDE.md`, ports, lint, tests, CMS source and docs | [`/project-init`](plugins/umbraco-devkit/skills/project-init/SKILL.md) |
| Push a new package to GitHub for the first time: README, LICENSE, CONTRIBUTING, Dependabot | [`/github-init`](plugins/umbraco-devkit/skills/github-init/SKILL.md) |

### Build a feature

Four steps, each writing its own files in the feature's folder, `docs/plans/<feature-slug>/`.
Re-run any step to refine its files. Once the PR is merged, `/feature-close` moves the folder
to `docs/archive/plans/`, so `docs/plans/` only holds live work.

Not ready to plan yet? Ask Claude to write the idea up in `docs/ideas/` and commit it;
`/feature-explore` can start from it later.

| Step | Run |
|---|---|
| What are we building, and for whom? | [`/feature-explore`](plugins/umbraco-devkit/skills/feature-explore/SKILL.md) |
| Extension points, data model, API, mockups of new screens | [`/feature-design`](plugins/umbraco-devkit/skills/feature-design/SKILL.md) |
| Stories and an ordered task list | [`/feature-plan`](plugins/umbraco-devkit/skills/feature-plan/SKILL.md) |
| Stress-test a big or risky plan before you build it (optional) | [`/feature-interrogate`](plugins/umbraco-devkit/skills/feature-interrogate/SKILL.md) |
| Build, review, and commit, task by task | [`/feature-build`](plugins/umbraco-devkit/skills/feature-build/SKILL.md) |
| See the assumptions and workarounds worth a human look | [`/decision-review`](plugins/umbraco-devkit/skills/decision-review/SKILL.md) |
| Archive a plan once its PR is merged, or the plan is dropped | [`/feature-close`](plugins/umbraco-devkit/skills/feature-close/SKILL.md) |

### Fix something

| I want to... | Run |
|---|---|
| Make a small, obvious fix, still reviewed | [`/quick-fix`](plugins/umbraco-devkit/skills/quick-fix/SKILL.md) |
| Find and prove why something is broken, then route the fix | [`/investigate-bug`](plugins/umbraco-devkit/skills/investigate-bug/SKILL.md) |
| Port a merged change to another version line, still reviewed | [`/change-backport`](plugins/umbraco-devkit/skills/change-backport/SKILL.md) |

### Work the issue tracker

| I want to... | Run |
|---|---|
| Work open issues from new to fixed, one stage at a time | [`/issue-backlog`](plugins/umbraco-devkit/skills/issue-backlog/SKILL.md) |
| Classify and duplicate-check new issues (report only) | [`/issue-triage`](plugins/umbraco-devkit/skills/issue-triage/SKILL.md) |
| Send one triaged issue to the right fix | [`/issue-resolve`](plugins/umbraco-devkit/skills/issue-resolve/SKILL.md) |

### Pull requests

| I want to... | Run |
|---|---|
| Write the PR description: choices to check first, then screenshots and diagrams | [`/pr-describe`](plugins/umbraco-devkit/skills/pr-describe/SKILL.md) |
| Review a PR from outside the core team | [`/pr-review`](plugins/umbraco-devkit/skills/pr-review/SKILL.md) |
| Try a PR yourself on the demo site, with a click-through list | [`/pr-demo`](plugins/umbraco-devkit/skills/pr-demo/SKILL.md) |
| Review dependencies: Dependabot PRs, security alerts, and what's out of date | [`/dependency-review`](plugins/umbraco-devkit/skills/dependency-review/SKILL.md) |

### Upgrade and publish

| I want to... | Run |
|---|---|
| Move to a new Umbraco major, task by task, still reviewed | [`/major-upgrade`](plugins/umbraco-devkit/skills/major-upgrade/SKILL.md) |
| Get a finished package listed on the Umbraco Marketplace | [`/umbraco-marketplace`](plugins/umbraco-devkit/skills/umbraco-marketplace/SKILL.md) |

### Read a doc

| I want to... | Run |
|---|---|
| See a plan file or folder as GitHub will show it, refreshing as it changes, and comment on it for Claude to fix ("show me the brief") | [`/markdown-preview`](plugins/umbraco-devkit/skills/markdown-preview/SKILL.md) |

### Learn from a session

| I want to... | Run |
|---|---|
| Report a mistake a skill should have caught, from the project where it happened | [`/skill-report`](plugins/umbraco-devkit/skills/skill-report/SKILL.md) |
| Capture what a session taught you, even when nothing was the devkit's fault | [`/project-retro`](plugins/umbraco-devkit/skills/project-retro/SKILL.md) |

## What works in the background

You don't run these. The skills above and the agents load them when the work needs them.

**Agents:**

| Agent | What it does |
|---|---|
| [`builder`](plugins/umbraco-devkit/agents/builder.md) | Builds one task at a time |
| [`reviewer`](plugins/umbraco-devkit/agents/reviewer.md) | Checks every diff, read-only, before it's committed |
| [`issue-triager`](plugins/umbraco-devkit/agents/issue-triager.md) | Reads and classifies tracker issues, read-only |

**Umbraco knowledge:**

| Skill | What it covers |
|---|---|
| [`umbraco-extensibility`](plugins/umbraco-devkit/skills/umbraco-extensibility/SKILL.md) | Composers, collection builders, notification handlers |
| [`umbraco-package-conventions`](plugins/umbraco-devkit/skills/umbraco-package-conventions/SKILL.md) | Naming, visibility, safe public API changes |
| [`umbraco-backoffice-conventions`](plugins/umbraco-devkit/skills/umbraco-backoffice-conventions/SKILL.md) | Package-level frontend setup, OpenAPI clients, build order |
| [`umbraco-backoffice-ux`](plugins/umbraco-devkit/skills/umbraco-backoffice-ux/SKILL.md) | How a backoffice screen should look and behave |
| [`umbraco-performance`](plugins/umbraco-devkit/skills/umbraco-performance/SKILL.md) | Caching, tree traversal, and keeping hot paths fast |
| [`umbraco-env-sync`](plugins/umbraco-devkit/skills/umbraco-env-sync/SKILL.md) | Moving a package's own data between environments with Umbraco Deploy or uSync |
| [`umbraco-dependencies`](plugins/umbraco-devkit/skills/umbraco-dependencies/SKILL.md) | Which dependencies must match the CMS, which ship to sites, which are dev-only |
| [`ef-core-data`](plugins/umbraco-devkit/skills/ef-core-data/SKILL.md) | SQL Server + SQLite, migrations, repositories |
| [`umbraco-cms-source`](plugins/umbraco-devkit/skills/umbraco-cms-source/SKILL.md) | Read the CMS source at the version you target |
| [`umbraco-docs`](plugins/umbraco-devkit/skills/umbraco-docs/SKILL.md) | Read the official docs for the version you target |
| [`umbraco-security`](plugins/umbraco-devkit/skills/umbraco-security/SKILL.md) | What Umbraco provides for security, on the server and in the backoffice |
| [`umbraco-dotnet-testing`](plugins/umbraco-devkit/skills/umbraco-dotnet-testing/SKILL.md) | C# integration tests on Umbraco's test package, so they exercise the package |
| [`umbraco-backoffice-testing`](plugins/umbraco-devkit/skills/umbraco-backoffice-testing/SKILL.md) | Backoffice element tests and Playwright end-to-end tests on Umbraco's helpers |

**General craft:**

| Skill | What it covers |
|---|---|
| [`bdd-specs`](plugins/umbraco-devkit/skills/bdd-specs/SKILL.md), [`user-stories`](plugins/umbraco-devkit/skills/user-stories/SKILL.md) | Stories with acceptance criteria, turned into tests |
| [`diagrams`](plugins/umbraco-devkit/skills/diagrams/SKILL.md) | Hand-placed SVG diagrams and charts for plans and PRs, in light and dark |
| [`git-workflow`](plugins/umbraco-devkit/skills/git-workflow/SKILL.md) | Commits, branches, and asking before touching `main` |
| [`plain-writing`](plugins/umbraco-devkit/skills/plain-writing/SKILL.md) | How every document a person reads gets written |

## How it works

[docs/HOW-IT-WORKS.md](./docs/HOW-IT-WORKS.md) covers the plan folder, ideas and the archive,
the review gate, project memory, branches and worktrees, and what to build on top.

## How the skills are tested

Each skill has evals: realistic requests run with and without the plugin, to show the skill
changes the result. [docs/EVAL-COVERAGE.md](./docs/EVAL-COVERAGE.md) shows which skills and
which of their sections have evals, with the latest scores. How evals are written, run and
kept current is in [`write-skill-eval`](./.claude/skills/write-skill-eval/SKILL.md). If a skill
misses something, run `/skill-report` in the project where it happened, or [open a "skill
missed" issue](../../issues/new?template=skill-missed.yml) by hand.

## Contributing

Issues and PRs welcome. This repo follows its own
[`git-workflow`](plugins/umbraco-devkit/skills/git-workflow/SKILL.md) skill.
[CLAUDE.md](./CLAUDE.md) has the repo layout, the checks to run, and the rules for naming and
editing skills.

## License

[MIT](./LICENSE)

## Credits

Based on [Rob Conery's `claude-playbook`](https://bigmachine.io/freebies/claude-playbook)
starter template, adapted for Umbraco package and backoffice extension development.
