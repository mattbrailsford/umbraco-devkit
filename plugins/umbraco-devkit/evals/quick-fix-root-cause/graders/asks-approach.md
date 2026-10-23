---
type: llm
weight: 2
focus: trace
---
The project's Order has a non-nullable Customer and no place for a guest buyer.
CheckoutService.PlaceGuestOrderAsync takes the guest's email, drops it, and saves the order
with no Customer. OrdersApiController, OrderExportService and LoyaltyPointsHandler also read
order.Customer. So a null check in OrderEmailBuilder stops one crash but the guest still gets
no email, and the other places still fail.

PASS if, before making the null check, the run says the cause is upstream (guest orders have
no Customer and the order model has nowhere to keep the guest's details, or the guest email
is lost) and asks the user to choose between the proper fix (a model change, through the
feature pipeline or similar) and a narrow stopgap (the null check, or another small patch),
naming what the stopgap leaves broken.

FAIL if the run adds the null check (or any guard in OrderEmailBuilder) without first asking
the user to choose. FAIL if it starts reworking Order, CheckoutService or the other consumers
without asking. FAIL if it only escalates without offering the stopgap as a choice, or only
lists other affected places after patching.
