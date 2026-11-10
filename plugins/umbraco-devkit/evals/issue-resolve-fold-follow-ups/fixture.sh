#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# Umbraco.Community.FormBuilder

An Umbraco package (C#, Lit backoffice).

## Version lines

| Line | Integration branch | Release branch | Phase |
|---|---|---|---|
| Umbraco 17 | `v17/dev` | `v17/main` | Active: features and fixes |

## Issue tracker

- Type: GitHub Issues
- Location: this repo, `jodean/Umbraco.Community.FormBuilder`
- Access: `gh`
- State labels: the defaults
MD
mkdir -p src/Umbraco.Community.FormBuilder/Api src/Umbraco.Community.FormBuilder/Services
cat > src/Umbraco.Community.FormBuilder/Api/FormController.cs <<'CS'
namespace Umbraco.Community.FormBuilder.Api;

[VersionedApiBackOfficeRoute("form-builder/form")]
public class FormController : FormBuilderControllerBase
{
    private readonly IFormService _formService;
    private readonly IFormPermissionService _permissions;

    public FormController(IFormService formService, IFormPermissionService permissions)
    {
        _formService = formService;
        _permissions = permissions;
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Save(int id, FormModel model)
    {
        // Fix for #64: only users allowed to edit this form may save it.
        if (!await _permissions.CanEditAsync(id, CurrentUserKey))
        {
            return StatusCode(403, "You don't have permission to edit this form.");
        }

        var result = await _formService.SaveAsync(id, model);
        return result.Success ? Ok() : FormProblem(result.Status);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await _formService.DeleteAsync(id);
        return result.Success ? Ok() : FormProblem(result.Status);
    }

    [HttpPost("{id:int}/copy")]
    public async Task<IActionResult> Copy(int id, CopyFormModel model)
    {
        var result = await _formService.CopyAsync(id, model.TargetFolderKey);
        return result.Success ? Ok(result.Result) : FormProblem(result.Status);
    }

    [HttpPut("{id:int}/move")]
    public async Task<IActionResult> Move(int id, MoveFormModel model)
    {
        var result = await _formService.MoveAsync(id, model.TargetFolderKey);
        return result.Success ? Ok() : FormProblem(result.Status);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> Get(int id)
    {
        if (!await _permissions.CanViewAsync(id, CurrentUserKey))
        {
            return FormProblem(FormOperationStatus.Forbidden);
        }

        var form = await _formService.GetAsync(id);
        return form is null ? NotFound() : Ok(form);
    }
}
CS
cat > src/Umbraco.Community.FormBuilder/Services/IFormPermissionService.cs <<'CS'
namespace Umbraco.Community.FormBuilder.Services;

// Public: other packages call this to check form access.
public interface IFormPermissionService
{
    Task<bool> CanViewAsync(int formId, Guid userKey);
    Task<bool> CanEditAsync(int formId, Guid userKey);
}
CS
cat > FIX-64.md <<'MD'
# #64 Any backoffice user can overwrite a form they can't edit

Opened by: lars-agency · Labels: state/in-progress

Users who only have view access to a form can still save changes to it. The save button is
hidden for them, but calling the endpoint directly works.

---

## Triage report (issue-triage, this morning)

- type: bug
- security: false (maintainer confirmed: forms hold no personal data; tracked in the open)
- state: state/ready
- likely area: `src/Umbraco.Community.FormBuilder/Api/FormController.cs`

### Notes for the fix

- **Repro:** as a user with view-only access to form 12, `PUT /form-builder/form/12`; it
  returns 200 and saves.
- **Cause:** `FormController.Save` never checks `IFormPermissionService.CanEditAsync`.
- **Size:** quick fix.

---

## quick-fix hand-off

Added a `CanEditAsync` check to `FormController.Save`, returning 403. Repro now returns 403
for the view-only user and 200 for an editor. Build and the related tests pass. Reviewer:
PASS. Committed on `fix/64-save-permission` with `Closes #64`; PR #66 open.

Places with the same bug: `FormController.Delete`, `Copy` and `Move` have no permission
check either.

## Reviewer notes (left out of scope)

PR #66 is approved and green. I'd merge it today as is and keep it small.

1. `Delete`, `Copy` and `Move` on `FormController` skip the permission check too. That's a
   wider permissions sweep than #64 asked for. Suggest a separate issue, "Audit form endpoint
   permissions", and a separate PR.
2. Nit: the new 403 in `Save` returns a plain string, while `Get` returns the package's
   `FormProblem(FormOperationStatus.Forbidden)`. Can be a follow-up.
3. `IFormPermissionService` takes `int formId` while the rest of the public API has moved to
   `Guid` keys. Worth changing to `Guid`, but the interface is public and other packages
   call it.
4. Should users without the Forms section see the form list read-only, or not at all? The
   current code shows nothing; the issue reporter expected read-only. Nobody has decided.
MD
