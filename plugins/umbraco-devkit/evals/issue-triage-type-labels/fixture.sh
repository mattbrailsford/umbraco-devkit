#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# Umbraco.Community.Bookings

An Umbraco package (C#, Lit backoffice) for booking rooms at venues.

## Issue tracker

- Type: GitHub Issues
- Location: this repo, `jodean/Umbraco.Community.Bookings`
- Access: `gh`
- Type labels: default
- State labels: default
- Feature requests: issues
MD
mkdir -p src/Umbraco.Community.Bookings/Services src/Umbraco.Community.Bookings/Export
cat > src/Umbraco.Community.Bookings/Services/BookingService.cs <<'CS'
namespace Umbraco.Community.Bookings.Services;

internal sealed class BookingService : IBookingService
{
    private readonly IBookingRepository _repository;

    public BookingService(IBookingRepository repository) => _repository = repository;

    public async Task<Attempt<Booking?, BookingOperationStatus>> CreateAsync(BookingRequest request)
    {
        // Rooms are free when no booking overlaps the requested slot.
        var overlapping = await _repository.GetOverlappingAsync(request.RoomKey, request.Start, request.End);
        if (overlapping.Any())
        {
            return Attempt.FailWithStatus<Booking?, BookingOperationStatus>(BookingOperationStatus.RoomTaken, null);
        }

        var booking = new Booking(Guid.NewGuid(), request.RoomKey, request.Start, request.End, request.GuestKey);
        await _repository.SaveAsync(booking);
        return Attempt.SucceedWithStatus<Booking?, BookingOperationStatus>(BookingOperationStatus.Success, booking);
    }
}
CS
cat > src/Umbraco.Community.Bookings/Services/BookingRepository.cs <<'CS'
namespace Umbraco.Community.Bookings.Services;

internal sealed class BookingRepository : IBookingRepository
{
    private readonly IEFCoreScopeProvider<BookingsDbContext> _scopeProvider;

    public BookingRepository(IEFCoreScopeProvider<BookingsDbContext> scopeProvider) => _scopeProvider = scopeProvider;

    public async Task<IEnumerable<Booking>> GetOverlappingAsync(Guid roomKey, DateTime start, DateTime end)
    {
        using var scope = _scopeProvider.CreateScope();
        return await scope.ExecuteWithContextAsync(async db =>
            await db.Bookings
                .Where(b => b.RoomKey == roomKey && b.Start < end && b.End > start)
                .ToListAsync());
    }

    public async Task SaveAsync(Booking booking)
    {
        using var scope = _scopeProvider.CreateScope();
        await scope.ExecuteWithContextAsync<Task>(async db =>
        {
            db.Bookings.Add(booking);
            await db.SaveChangesAsync();
        });
        scope.Complete();
    }
}
CS
cat > src/Umbraco.Community.Bookings/Export/BookingCsvExporter.cs <<'CS'
namespace Umbraco.Community.Bookings.Export;

// Exports a venue's bookings as CSV from the backoffice Bookings dashboard.
internal sealed class BookingCsvExporter
{
    public string Export(IEnumerable<Booking> bookings)
    {
        var sb = new StringBuilder("Room,Start,End,Guest\n");
        foreach (var b in bookings)
        {
            sb.AppendLine($"{b.RoomName},{b.Start:O},{b.End:O},{b.GuestName}");
        }
        return sb.ToString();
    }
}
CS
cat > ISSUE-301.md <<'MD'
# #301 Export bookings to iCal so venue staff can see them in Outlook

Opened by: hannelore-k (not a maintainer) · Labels: none · 0 comments

We use Bookings for our three meeting venues. Staff keep asking to see the bookings in their
Outlook calendars. The CSV export works but they have to re-type everything.

Could you add an iCal (.ics) export, or better, a feed URL Outlook can subscribe to?
MD
cat > ISSUE-302.md <<'MD'
# #302 Two guests can book the same room at the same time

Opened by: torben-dk (not a maintainer) · Labels: none · 0 comments

Umbraco 17.1, Bookings 3.2.0, SQL Server, two web servers behind a load balancer.

Twice this month two guests ended up booked into the same room for overlapping slots. Both
bookings were made within a second or two of each other from the public booking form. The
backoffice shows both bookings with no warning.
MD
