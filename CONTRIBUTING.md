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

For a new example in which the user clicks through several steps and observes the results, keep its test controls visible beside WebView2. Provide a native operation log that appends and scrolls to the newest event, plus a yellow guide with the test steps, expected results and the mechanism being demonstrated. Preserve the purpose-built layout of CSV, PDF and other viewers, editors, complex full-browser examples, and examples that run an automated sequence without step-by-step user interaction. Use `0xE2F0E4` for a read-only log EDIT, size it from the actual client height immediately after maximizing, and update it on window resize. Do not apply the log color to user-editable content or the yellow guide. Open the main example window maximized within the Windows work area, retaining its title bar, minimize control and the taskbar. Keep modal dialogs at the size appropriate to their purpose and preserve automated smoke behavior.

When logging a button action, separate it from the preceding activity and use `[YYYY-MM-DD HH:MM:SS] [AutoIt|WebView2]: <visible button caption> was clicked.` Use `AutoIt` for native controls. Use `WebView2` only for an explicit browser-trusted click notification from the expected local page; a result message or native callback does not prove which button was clicked. Distinguish programmatic smoke actions from browser-trusted clicks.

If an example promises a visible dialog or pop-up, show an interactive window and identify the button that opens it. Explain whether it is WebView2's browser dialog or an AutoIt-owned replacement. A native callback recorded only in the log is a request or event, not a visible dialog. Confirm the window in a focused runtime check before reporting it as verified.

## Source layout

- `WebView2_Core.au3` — lifecycle, navigation, events and base settings.
- `WebView2_DOM.au3` — DOM token/automation layer.
- `WebView2_IECompat.au3` — migration helpers for standard `IE.au3` patterns.
- `WebView2_Advanced.au3` — CDP/cookies/capture/PDF/MHTML/frames/extensions/ad-block helpers.
- `WebView2_Frame.au3` — native iframe lifecycle, parent tracking, messages and frame-specific scripts.

New native WebView2 interface revisions should be added through a correctly ordered interface definition and `QueryInterface()` rather than modifying an older vtable layout. For nested iframe changes, confirm parent IDs and per-frame script execution with [example 028](examples/028_NestedFrames.au3).

For dedicated-worker callbacks, subscribe through `ICoreWebView2Frame8` only when requested. Track each native worker with a monotonic public ID, remove its message and destruction tokens when it ends or its owner is cleaned up, and never reuse a stale ID. [Example 034](examples/034_FrameDedicatedWorker.au3) exercises frame ownership, direct JSON messaging and worker destruction. Keep user callbacks short; do not call blocking WebView2 helpers from native callbacks.
