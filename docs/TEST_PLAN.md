# SoulSign — Test Plan

Testing strategy for the SoulSign iOS app, organised as a testing pyramid:
many fast unit tests, a layer of integration tests, and a few high-value
end-to-end UI tests. All run in CI on every push and pull request.

```
        /   UI / E2E   \      5 tests  — launch + navigate the real app
       /  Integration   \    ~7 tests  — services over a mocked URLSession
      /    Unit tests     \  ~26 tests — pure logic, models, localization
```

## Targets

| Target | Type | What it covers |
|---|---|---|
| `SoulSignTests` | Unit + Integration | Business logic, models, services (mocked network) |
| `SoulSignUITests` | UI / E2E | Real app launch and navigation flows |

Run locally:

```bash
xcodebuild test -workspace SoulSign.xcworkspace -scheme SoulSign \
  -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

## Coverage by area

### Unit (fast, deterministic, no I/O)

- **DestinyMatrix** — numerology reduction (`reduce` only collapses values > 22),
  determinism, and a known-date fixture that matches the rendered chart.
- **TarotDeck** — 78-card integrity: 22 Major + 56 Minor, 14 per suit, unique
  ids and image names, non-empty content, per-suit meanings differ (regression
  guard), and the daily card is stable within a day.
- **AppLanguage / Translations** — all 9 languages present; every language has
  exactly the same keys as English (catches missing translations); no empty
  values; format keys keep their `%@`; Ukrainian short code is `UA`.
- **LocalizationManager** — real value, English fallback, key fallback, `%@`
  argument formatting.
- **UserProfile** — initials (first two words), first name, coordinates
  presence rules, Codable round-trip, id-based equality.
- **ProfileStore** — add / update / remove persist and reload, against an
  isolated `UserDefaults` suite.

### Integration (mocked `URLSession`, no real API calls)

- **ClaudeService** — builds the correct request (URL, method, headers, model,
  messages), parses `content[0].text`, throws on non-200, throws on malformed
  bodies.
- **AffirmationService** — parses the nested JSON response into
  `AffirmationResponse`, returns nil on malformed data, and appends the
  language instruction for non-English requests.

Network isolation is provided by `MockURLProtocol`, plus small testability
seams: `ClaudeService(session:)` and `AffirmationService.session` are
injectable, defaulting to `.shared` in production.

### UI / E2E (drives the real app on a simulator)

- Home shows all four feature tiles.
- Navigate to Tarot Today (nav bar appears).
- Navigate to Affirmations (regression guard for the iPad blank-screen bug —
  a Back button must appear, proving the screen actually rendered).
- Language picker opens and lists languages.
- Natal Chart tile opens the People screen.

UI tests use launch arguments for determinism: `-hasSeenWelcome YES`,
`-soulsign_language_v1 en`, and `-uitest-reset` (an app hook, active only under
that flag, that clears saved profiles for a clean start).

## What we deliberately skip

- SwiftUI view layout / pixel rendering (covered by manual review + screenshots).
- Third-party SDK internals (GoogleMaps/GooglePlaces, Lottie).
- Live Claude API calls — intentionally mocked to keep CI fast, free, and
  non-flaky. The prompt *content* is out of scope for automated assertion.

## Known gaps / future work

- `SoulSignViewModel` and `TarotViewModel` prompt construction is only
  indirectly covered; could add unit tests asserting the language instruction
  and RWS-meaning are included in the prompt.
- Snapshot tests for the share cards (`AffirmationShareCard`, `TarotShareCard`,
  `NatalChartPDFPage`) would guard the rendered output.
- Deep-link / notification-tap navigation is not yet E2E tested.

## CI

`.github/workflows/tests.yml` runs the full suite on `macos-15` for every push
to `main` and every pull request: it creates a placeholder `Secrets.xcconfig`,
runs `pod install`, picks an available simulator, and runs `xcodebuild test`
with code signing disabled. The `.xcresult` bundle is uploaded as an artifact.
