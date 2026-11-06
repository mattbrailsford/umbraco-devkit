#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# MyCompany.Flows

An Umbraco 17 package (C# plus a Lit backoffice client) for building automated flows: a
trigger, then a chain of actions. Each action type has a settings modal in the flow editor.
Trunk branch: `main`.

## Demo site

`demo/MyCompany.Flows.Demo`, run with `dotnet run`. Backoffice at https://localhost:44310.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`. Closed
plans move to `docs/archive/plans/<feature-slug>/`. Ideas live in `docs/ideas/`.
MD
mkdir -p docs/plans/create-element-action src/MyCompany.Flows/Actions \
  src/MyCompany.Flows/Client/src/actions/send-email
cat > docs/plans/create-element-action/README.md <<'MD'
# Create element action

Read these in order:

1. [x] [BRIEF.md](./BRIEF.md) — a flow action that creates a library element
2. [ ] [ARCHITECTURE.md](./ARCHITECTURE.md) — <pending>
3. [ ] [SPEC.md](./SPEC.md) — <pending>
4. [ ] [STORIES.md](./STORIES.md) — <pending>
5. [ ] [PLAN.md](./PLAN.md) — <pending>

What was built: [BUILD-LOG.md](./BUILD-LOG.md) · Why things changed: [DECISION-LOG.md](./DECISION-LOG.md)
MD
cat > docs/plans/create-element-action/BRIEF.md <<'MD'
# Brief

## Problem

Flows can send emails and update content, but can't create a library element. Teams that
collect submissions (event sign-ups, testimonials) want a flow to turn each one into an
element they can reuse across pages.

## Who

Implementers who build flows for editors.

## Success

A "Create element" action in the flow editor. Its settings modal has:

- **Element type** (required): chosen with the backoffice's usual document type picker,
  limited to element types.
- **Property values**: the element's property values, entered with the same editors the
  element type uses, so implementers fill them in like content. A value can also come from
  the flow's trigger data.

When the flow runs, the action creates the element from those settings.

## Out of scope

Updating or deleting elements. Creating anything other than an element.
MD
cat > docs/plans/create-element-action/DECISION-LOG.md <<'MD'
# Decision log
MD
cat > src/MyCompany.Flows/Actions/IFlowAction.cs <<'CS'
namespace MyCompany.Flows.Actions;

public interface IFlowAction
{
    string Alias { get; }

    Task<FlowActionResult> ExecuteAsync(FlowContext context, IReadOnlyDictionary<string, object?> settings, CancellationToken cancellationToken);
}
CS
cat > src/MyCompany.Flows/Actions/SendEmailAction.cs <<'CS'
namespace MyCompany.Flows.Actions;

internal sealed class SendEmailAction(IEmailSender emailSender) : IFlowAction
{
    public string Alias => "MyCompany.Flows.Action.SendEmail";

    public async Task<FlowActionResult> ExecuteAsync(FlowContext context, IReadOnlyDictionary<string, object?> settings, CancellationToken cancellationToken)
    {
        var to = settings["to"] as string;
        if (string.IsNullOrWhiteSpace(to))
        {
            return FlowActionResult.Failed("No recipient.");
        }

        await emailSender.SendAsync(to, (string?)settings["subject"] ?? "", (string?)settings["body"] ?? "", cancellationToken);
        return FlowActionResult.Succeeded();
    }
}
CS
cat > src/MyCompany.Flows/Client/src/actions/send-email/manifest.ts <<'TS'
export const manifests: Array<UmbExtensionManifest> = [
  {
    type: 'flowAction',
    alias: 'MyCompany.Flows.Action.SendEmail',
    name: 'Send email',
    meta: {
      label: 'Send email',
      icon: 'icon-message',
      settings: [
        { alias: 'to', label: 'To', propertyEditorUiAlias: 'Umb.PropertyEditorUi.TextBox', validation: { mandatory: true } },
        { alias: 'subject', label: 'Subject', propertyEditorUiAlias: 'Umb.PropertyEditorUi.TextBox' },
        { alias: 'body', label: 'Body', propertyEditorUiAlias: 'Umb.PropertyEditorUi.TextArea' },
      ],
    },
  },
];
TS
