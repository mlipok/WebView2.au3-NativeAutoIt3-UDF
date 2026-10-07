# Contributing

Contributions are welcome, especially fixes validated with both AutoIt x86 and x64.

## Before opening a pull request

1. Keep the public API in `WebView2.au3` backward compatible unless the change is explicitly documented as breaking.
2. Keep COM lifetime changes isolated and explain every `AddRef`, wrapper lifetime, event unsubscribe and controller-close decision.
3. Run `tools\Validate-Project.ps1`.
4. Run Au3Check with warnings 1-7 against `WebView2.au3` and every changed example.
5. Smoke-test the affected examples with the installed Evergreen WebView2 Runtime.
6. Update `CHANGELOG.md`, `RELEASE_NOTES.md` and relevant files under `docs\`.

## Source layout

- `WebView2_Core.au3` — lifecycle, navigation, events and base settings.
- `WebView2_DOM.au3` — DOM token/automation layer.
- `WebView2_IECompat.au3` — migration helpers for standard `IE.au3` patterns.
- `WebView2_Advanced.au3` — CDP/cookies/capture/PDF/MHTML/frames/extensions/ad-block helpers.

New native WebView2 interface revisions should be added through a correctly ordered interface definition and `QueryInterface()` rather than modifying an older vtable layout.
