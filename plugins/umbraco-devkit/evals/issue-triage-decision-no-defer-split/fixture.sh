#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# Umbraco.Community.Bookings

An Umbraco package (C#, Lit backoffice). Other packages build on its public API.

## Version lines

| Line | Integration branch | Release branch | Phase |
|---|---|---|---|
| Umbraco 17 | `v17/dev` | `v17/main` | Active: features and fixes |

## Issue tracker

- Type: GitHub Issues
- Location: this repo, `jodean/Umbraco.Community.Bookings`
- Access: `gh`
- State labels: the defaults
MD
mkdir -p src/Umbraco.Community.Bookings/Api src/Umbraco.Community.Bookings.Testing
cat > src/Umbraco.Community.Bookings/Api/IBookingsApi.cs <<'CS'
namespace Umbraco.Community.Bookings.Api;

// Public facade other packages call. Package validation blocks breaking changes to it.
public interface IBookingsApi
{
    Task<Booking?> GetBookingAsync(Guid key);
    Task<Venue?> GetVenueAsync(Guid key);
    Task<IEnumerable<Venue>> GetVenuesAsync();
}
CS
cat > src/Umbraco.Community.Bookings.Testing/VenueBuilder.cs <<'CS'
namespace Umbraco.Community.Bookings.Testing;

// Test helper shipped for other packages' tests. Rooms must be built by hand today.
public class VenueBuilder
{
    private string _name = "Test venue";

    public VenueBuilder WithName(string name) { _name = name; return this; }

    public Venue Build() => new Venue(Guid.NewGuid(), _name, rooms: []);
}
CS
cat > ISSUE-214.md <<'MD'
# #214 Let packages reach guests through IBookingsApi, and build rooms in tests

Opened by: jodean (maintainer) · Labels: state/needs-decision

Packages that extend Bookings need guest details, but `IBookingsApi` has no guest methods, so
they resolve the internal `IGuestService` from DI, which we don't support. Their tests also
have to hand-build every room on a venue, because `VenueBuilder` has no way to add rooms.

Asks:
1. Add `GetGuestAsync(Guid key)` and `GetGuestsForBookingAsync(Guid bookingKey)` to
   `IBookingsApi`.
2. Add room building to `VenueBuilder` (`WithRoom(...)`, `WithRooms(count)`), so tests can
   build a venue with rooms in one line.

---

## Notes for the decision (issue-triage, 3 days ago)

- **Need:** packages reach guests through the supported API, and their tests build venues with
  rooms quickly.
- **Size:** small for the API part (two methods that call `IGuestService`). Medium for the
  test part: `VenueBuilder` needs a `RoomBuilder`, and the shape of `WithRoom(...)` isn't
  settled.
- **Risk:** adding members to a public interface breaks package validation for anyone who
  implements it. Default interface methods avoid that.
- **Other ways:** expose guests through a separate `IGuestsApi` instead of widening
  `IBookingsApi`. For tests, a `RoomBuilder` used on its own instead of `VenueBuilder` methods.
- **Questions first:** all guest methods, or only the two asked for? Should room building
  live on `VenueBuilder` or in a separate `RoomBuilder`?
- **Depends on:** nothing.
- **Suggestion:** split this in two. Add guests to `IBookingsApi` via default interface
  methods in the next minor. Track room building in tests as its own decision.

---

## Since the notes

- 2 new thumbs-up reactions.
- No new comments.
MD
