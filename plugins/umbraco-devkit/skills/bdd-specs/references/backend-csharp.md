# BDD specs — Backend: C#

## *Contents*

- Matching the project's framework and assertion library
- The shape: Feature > Scenario > Specification (with a worked NUnit example)
- New specs pending by default
- File / naming

**Detect and match the project's actual test framework and assertion library — don't import
new ones to follow this skill.** NUnit with its own `Assert.That` is shown as the default
because Umbraco CMS uses it, and so do Umbraco's test helper packages (`Umbraco.Cms.Tests`,
`Umbraco.Cms.Tests.Integration`). xUnit is equally valid if the project already uses it.

- **Test framework** — if the project uses xUnit, map the same shape onto its terms: a plain
  class instead of `[TestFixture]`, `[Fact]` instead of `[Test]`, the constructor for
  per-test arrange instead of `[SetUp]`, `IClassFixture<T>` instead of `[OneTimeSetUp]`.
- **Assertion library** — use a fluent library (Shouldly, FluentAssertions) if the project
  already has one; native assertions are fine otherwise — don't add a dependency just for
  syntax.

## The shape: Feature > Scenario > Specification

NUnit (and xUnit) don't have JavaScript's nested `describe` blocks, so the three levels need
a C# structure to map onto. Two real options — pick based on the scenario's shape, not
precedent alone:

- **Flat class, descriptive method names, grouped by region** — one test class per feature
  area, `[Test]` methods named `Method_Scenario_ExpectedResult`. Good fit when scenarios
  share the same arrange, or the project's existing tests already look like this.
- **Nested `Given...` classes per scenario** — arrange once in the nested class's `[SetUp]`
  method (NUnit runs it fresh before each test), making "what does this scenario assume" a single,
  unmissable place to look. Reach for it whenever a feature has several scenarios with
  meaningfully different setups:

  ```csharp
  public class AtomicCreateOrderWithShippingProfileTests
  {
      [TestFixture]
      public class GivenAValidShippingProfileAlias
      {
          [SetUp] public void SetUp() { /* arrange once, per test method */ }
          [Test] public void CreatesTheOrder() { /* ... */ }
      }
  }
  ```

  - For **expensive** shared arrange (a real database, a running Umbraco), use
    `[OneTimeSetUp]`, or inherit `UmbracoIntegrationTest` from `Umbraco.Cms.Tests.Integration`
    with a per-fixture database, instead of re-arranging per test. `umbraco-integration-testing` covers
    what that test host leaves out compared to a real site.
  - Do **not** fall back to a private `Arrange...()` helper called at the top of every test
    method — that hides the scenario's precondition inside a method body instead of the
    `[SetUp]` where it's the first thing a reader sees.

Pick whichever of the two matches (or extends) what the project's tests already look like;
don't mix both schemes in the same test class.

- **Feature** → one test class, named after the feature, e.g. `AtomicCreateOrderEntitlementsTests`.
- **Scenario** → either a `#region` grouping (flat style) or a nested `Given...` class.
- **Specification** → one `[Test]` (or one `[TestCase]`), exactly one assertion.
- **Mocks** → use **Moq** (or the project's existing mocking library) for collaborators the
  spec doesn't own.

```csharp
// STORY-014 — Atomic create of an order with its default shipping profile
public class AtomicCreateOrderWithShippingProfileTests
{
    [TestFixture]
    public class GivenAValidShippingProfileAlias
    {
        private Order _order = null!;
        private ShippingProfile _shippingProfile = null!;

        [SetUp]
        public void SetUp()
        {
            _shippingProfile = new ShippingProfileBuilder().WithCarrierAlias("standard-post").Build();
            _order = new OrderBuilder().WithReference("ORD-1").WithShippingProfile(_shippingProfile).Build();
        }

        [Test]
        public void CreatesTheOrder()
        {
            Assert.That(_order, Is.Not.Null);
        }

        [Test]
        public void LinksTheShippingProfileByAlias()
        {
            Assert.That(_order.ShippingProfileAlias, Is.EqualTo(_shippingProfile.Alias));
        }
    }

    [TestFixture]
    public class GivenAShippingProfileAliasThatDoesNotExist
    {
        private Mock<IShippingProfileLookup> _shippingProfileLookup = null!;
        private OrderService _service = null!;

        [SetUp]
        public void SetUp()
        {
            _shippingProfileLookup = new Mock<IShippingProfileLookup>();
            _shippingProfileLookup
                .Setup(x => x.FindByAliasAsync("missing"))
                .ReturnsAsync((ShippingProfile?)null);
            _service = new OrderService(_shippingProfileLookup.Object);
        }

        [Test]
        public void ThrowsShippingProfileNotFoundException()
        {
            Assert.ThrowsAsync<ShippingProfileNotFoundException>(
                () => _service.CreateOrderAsync(new OrderBuilder().WithShippingProfileAlias("missing").Build()));
        }
    }
}
```

**New specs pending by default** — mark each new `[Test]` with `[Ignore("Pending")]` (xUnit:
`[Fact(Skip = "Pending")]`) until a `builder` task makes it pass. The runner reports them as
skipped, not failed, and the builder removes the marker when it activates them.

**File / naming:** one test class per Feature, named for the feature, never for the story id.
Put the story id in a single comment at the top of the file — the only place it appears.
