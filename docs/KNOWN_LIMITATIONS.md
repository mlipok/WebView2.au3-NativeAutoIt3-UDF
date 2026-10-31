# Known limitations — v0.5.0

1. **Full GUI testing is still required.** Isolated Windows tests have run; they do not establish every host application scenario. See [EXAMPLES.md](EXAMPLES.md) for the current example verification boundary.
2. **The synchronous string-result path is serialized.** `_WebView2_ExecuteScript()` and synchronous CDP helpers share one completion channel; do not issue overlapping synchronous calls from re-entrant callbacks.
3. **Controller creation is serialized.** `_WebView2_Create()` waits for each asynchronous controller creation before another create begins.
4. **DOM element tokens are document-scoped.** Navigating to a new top-level document makes previously returned tokens stale.
5. **Top-level DOM helpers cannot bypass browser same-origin rules.** Cross-origin frame metadata is available through CDP, but DOM HTML access is restricted.
6. **Extension helpers are runtime-dependent.** v0.4.0 uses the experimental Chromium CDP Extensions domain. Native WebView2 profile extension interfaces are preferred for a future revision.
7. **Ad blocking is URL-pattern blocking, not cosmetic filtering.** `_WebView2_SetAdBlock()` uses CDP `Network.setBlockedURLs`; it does not implement EasyList parsing or DOM cosmetic rules.
8. **ClearBrowserData is intentionally conservative.** It clears cookies, network cache and current-origin local/session storage, not every possible profile data kind.
9. **MHTML Binary encoding is UTF-8.** `_WebView2_ExportToMhtmlBinary()` converts the MHTML string returned by CDP to UTF-8 bytes; `_WebView2_ExportToMhtmlFile()` writes the same bytes.
10. **No automatic WebView2 Runtime installer.** Runtime detection is provided; application deployment remains the host application's responsibility.
11. **Web message security belongs to the host application.** Validate message origin and payload before invoking privileged native actions.

## Recommended validation pass on Windows

```text
Au3Check WebView2.au3 and every example
Run examples with AutoIt x86
Run examples with AutoIt x64
Verify Navigate/NavigateToString
Verify resize/maximize/restore
Verify ExecuteScript and WebMessageReceived
Create/destroy several sequential instances
Create two simultaneous instances
Run Init -> Create -> Cleanup twice in one process
Verify screenshot Base64/Binary/file
Verify PDF Base64/Binary/file
Verify MHTML string/Binary/file
Verify cookies/CDP/frame helpers
Verify shutdown after using advanced helpers
```

## Not yet implemented

Managed tabs are separate WebView2 controllers. The UDF does not provide Edge's native tab strip or automatic selection of another tab when the active one closes. `NewWindowRequested` can be intercepted through `_WebView2_SetCallback`; the host must queue URI-based tab creation outside the callback. This does not supply the new tab through `put_NewWindow`, so JavaScript `window.opener`/`WindowProxy` semantics are not preserved. Hidden-window x86/x64 tab smoke tests passed; the visible tab example still requires interactive GUI testing.

A user-supplied sleep callback can cancel a wait by setting `@error`. In that case the UDF reports `$WEBVIEW2_ERR_USER_ABORT`; default waits are unaffected.

Useful candidates for later releases include:

- native `ICoreWebView2Frame*` wrappers and frame messaging/script objects;
- native `ICoreWebView2Profile7` extension management;
- download events and download control;
- full `NewWindowRequested` deferral / `put_NewWindow` handoff and opener semantics;
- permissions and script-dialog callbacks;
- audit the current [NetWebView2Lib](https://github.com/mlipok/NetWebView2Lib) API against this native UDF, update [API_COMPARISON.md](API_COMPARISON.md) with every missing or partial capability, and prioritize native equivalents without introducing a .NET dependency;
- accelerator-key settings and default background color through newer interface revisions;
- audio mute state through the appropriate newer CoreWebView2 revision;
- asynchronous/nonblocking public variants of current synchronous helpers.

The functional GitHub example copies have explicit WIP entries for downloads, HTTP response tracking, PDF.js and the older virtual-folder example. See [EXAMPLES.md](EXAMPLES.md).
