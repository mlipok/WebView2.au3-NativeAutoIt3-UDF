# Contributing

Contributions are welcome, especially fixes validated with both AutoIt x86 and x64.

## Before opening a pull request

1. Keep the public API in `WebView2.au3` backward compatible unless the change is explicitly documented as breaking.
2. Keep COM lifetime changes isolated and explain every `AddRef`, wrapper lifetime, event unsubscribe and controller-close decision.
3. Follow the repository's `AGENTS.md` and any AutoIt rules it links to. Pass Tidy an explicit existing `.au3` file path as its sole argument and ensure its process exits; never invoke its file-selection dialog as a test.
4. Run `tools\Validate-Project.ps1`.
5. Run Au3Check with warnings 1-7 against `WebView2.au3` and every changed example. If the checker cannot start in a restricted environment, retry outside it and distinguish a launch failure from reported syntax errors.
6. Smoke-test affected examples with the installed Evergreen WebView2 Runtime. Test both AutoIt architectures when claiming x86 and x64 behavior.
7. Update `CHANGELOG.md` and relevant files under `docs\`. Update `RELEASE_NOTES.md` when preparing a release.

For a new interactive example, keep its test controls visible beside WebView2. When a sequence of actions needs explanation, provide a native operation log that appends and scrolls to the newest event, plus a yellow guide with the test steps, expected results and the mechanism being demonstrated. Open the main example window maximized within the Windows work area, retaining its title bar, minimize control and the taskbar. Keep modal dialogs at the size appropriate to their purpose and preserve automated smoke behavior.

## Source layout

- `WebView2_Core.au3` — lifecycle, navigation, events and base settings.
- `WebView2_DOM.au3` — DOM token/automation layer.
- `WebView2_IECompat.au3` — migration helpers for standard `IE.au3` patterns.
- `WebView2_Advanced.au3` — CDP/cookies/capture/PDF/MHTML/frames/extensions/ad-block helpers.
- `WebView2_Frame.au3` — native iframe lifecycle, parent tracking, messages and frame-specific scripts.

New native WebView2 interface revisions should be added through a correctly ordered interface definition and `QueryInterface()` rather than modifying an older vtable layout. For nested iframe changes, confirm parent IDs and per-frame script execution with [example 028](examples/028_NestedFrames.au3).

For dedicated-worker callbacks, subscribe through `ICoreWebView2Frame8` only when requested. Track each native worker with a monotonic public ID, remove its message and destruction tokens when it ends or its owner is cleaned up, and never reuse a stale ID. [Example 034](examples/034_FrameDedicatedWorker.au3) exercises frame ownership, direct JSON messaging and worker destruction. Keep user callbacks short; do not call blocking WebView2 helpers from native callbacks.
