# Known limitations — v0.6.0

1. **Full GUI testing is still required.** Isolated Windows tests have run; they do not establish every host application scenario. See [EXAMPLES.md](EXAMPLES.md) for the current example verification boundary.
2. **The synchronous string-result path is serialized.** `_WebView2_ExecuteScript()` and synchronous CDP helpers share one completion channel; do not issue overlapping synchronous calls from re-entrant callbacks.
3. **Controller creation is serialized.** `_WebView2_Create()` waits for each asynchronous controller creation before another create begins.
4. **DOM element tokens are document-scoped.** Navigating to a new top-level document makes previously returned tokens stale.
5. **Top-level DOM helpers cannot bypass browser same-origin rules.** Cross-origin frame metadata is available through CDP, but DOM HTML access is restricted.
6. **Extension helpers are runtime-dependent.** The v0.4.0 helpers use the experimental Chromium CDP Extensions domain. Native profile extension management is available separately through opt-in `ICoreWebView2Profile7` wrappers and requires a compatible WebView2 Runtime; see [Native profile extensions](API.md#native-profile-extensions).
7. **Ad blocking is URL-pattern blocking, not cosmetic filtering.** `_WebView2_SetAdBlock()` uses CDP `Network.setBlockedURLs`; it does not implement EasyList parsing or DOM cosmetic rules.
8. **ClearBrowserData is intentionally conservative.** It clears cookies, network cache and current-origin local/session storage, not every possible profile data kind.
9. **MHTML Binary encoding is UTF-8.** `_WebView2_ExportToMhtmlBinary()` converts the MHTML string returned by CDP to UTF-8 bytes; `_WebView2_ExportToMhtmlFile()` writes the same bytes.
10. **No automatic WebView2 Runtime installer.** Runtime detection is provided; application deployment remains the host application's responsibility.
11. **Web message security belongs to the host application.** Validate message origin and payload before invoking privileged native actions.
12. **Native frame tracking starts at subscription time.** Register a frame callback before navigation. Tracked frame IDs are invalidated when the iframe is destroyed. The tracker supports 256 active frames; navigation events use `ICoreWebView2Frame2`, native `FrameId` uses `ICoreWebView2Frame5`, and nested frame creation uses `ICoreWebView2Frame7` when supported by the Runtime.
13. **Frame host objects require explicit origins.** The UDF rejects wildcard and empty origin lists, but the host must still validate frame messages and keep the COM `IDispatch` object alive. Removing an object does not revoke JavaScript references already obtained.
14. **Frame shared buffers are sent read-only.** `_WebView2_Frame_PostSharedBuffer()` accepts binary payloads under 2 GB and posts them to a tracked frame. It does not expose a writable shared memory view or a JavaScript-to-AutoIt shared-buffer channel. The page must release the received buffer.

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

Managed tabs are separate WebView2 controllers. The UDF does not provide Edge's native tab strip or automatic selection of another tab when the active one closes. Native `NewWindowRequested` deferral and `put_NewWindow` handoff are available for fresh controllers in the same environment; `window.opener` and the opener's `WindowProxy` passed targeted x86/x64 smoke tests. The visible tab example still requires interactive GUI testing.

A user-supplied sleep callback can cancel a wait by setting `@error`. In that case the UDF reports `$WEBVIEW2_ERR_USER_ABORT`; default waits are unaffected.

Useful candidates for later releases include:

- review later frame capabilities beyond `ICoreWebView2Frame7`; immediate `Frame3` permission decisions, read-only `Frame4` shared buffers, `Frame5` native IDs, `Frame6` screen-capture cancellation, and `Frame7` direct-child tracking are implemented;
- deferred permission handling and script-dialog callbacks; immediate top-level and frame-level permission decisions are implemented;
- audit the current [NetWebView2Lib](https://github.com/mlipok/NetWebView2Lib) API against this native UDF, update [API_COMPARISON.md](API_COMPARISON.md) with every missing or partial capability, and prioritize native equivalents without introducing a .NET dependency;
- accelerator-key settings and default background color through newer interface revisions;
- asynchronous/nonblocking public variants of current synchronous helpers.

The functional GitHub example copies retain an explicit WIP entry for PDF.js. Example 217 now exercises virtual-folder mapping, example 207 exercises native response metadata, and the download example exercises native download events and control. See [EXAMPLES.md](EXAMPLES.md).

## TODO: Migration from other projects

Review external ideas against the current native UDF before implementing them. These entries are proposals, not claims of API compatibility or commitments to copy third-party code. Preserve this section as the single project TODO for findings from the three monitored sources. Last reviewed: 2026-11-11.

| Source | Candidate | Current UDF state | Next review step |
| --- | --- | --- | --- |
| [AutoIt Forum WebView2 topic](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/) | Native mute getter/setter and changed callback | Implemented through `ICoreWebView2_8`; x86/x64 getter/setter, event and cleanup smoke tests passed. | Keep this migration item for provenance; monitor upstream behavior and regression reports. |
| [AutoIt Forum WebView2 topic](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/) | Permission request policy, event and response | Immediate top-level and frame `PermissionRequested` callbacks read origin, kind and user-initiated flag and return Default/Allow/Deny. A two-element return can disable profile persistence through `PermissionRequestedEventArgs3`. No deferral or per-kind policy table is exposed. | Design a bounded deferred-decision lifecycle separately; retain the immediate callbacks for fast policy decisions. |
| [AutoIt Forum WebView2 topic](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/) | Native fullscreen-change event | `_WebView2_IsFullScreen()` provides a state read; no native change callback is exposed. | Compare native event behavior with the existing state helper. |
| [Ralle1976/Autoit-WebView2-UDF](https://github.com/Ralle1976/Autoit-WebView2-UDF) | Runtime installation prompt helper | Runtime detection and version queries exist; the UDF does not install the Runtime. | Decide whether a separate host-level opt-in helper or documentation is appropriate. |
| [Ralle1976/Autoit-WebView2-UDF](https://github.com/Ralle1976/Autoit-WebView2-UDF) | Asynchronous script execution | The public script helper is synchronous. | Compare callback and error contracts before considering an asynchronous variant. |
| [Ralle1976/Autoit-WebView2-UDF](https://github.com/Ralle1976/Autoit-WebView2-UDF) | Local Chart.js integration example | No dedicated chart example is included. | Evaluate a standalone, offline example using existing WebView2 APIs; keep UI assets separate from the core UDF. |
| [WV2Bridge 3.1 forum post](https://www.autoitscript.com/forum/topic/213942-udf-wv2bridge-31-authenticated-promise-based-rpc-between-a-webview2-page-and-autoit-add-on-for-my-webview2-udf/#findComment-1555627) | Authenticated, promise-based page-to-AutoIt RPC with bounded requests and deferred replies | The UDF provides web messages, initialization scripts, virtual-host mapping and synchronous script execution, but no named-call/response protocol, per-view RPC authorization or flow control. Hosts currently validate origins and payloads themselves. | Review the add-on's threat model, origin checks, correlation IDs, backpressure and deferred-reply lifecycle; prototype an optional layer above the existing UDF without changing low-level message contracts. |
| [AutoIt Forum event-queue explanation](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/#findComment-1555642) | Optional queued delivery of notification events | Our UDF invokes host callbacks directly from native COM callbacks; its documentation warns against re-entrant synchronous calls, and it has no per-view event queue. | Evaluate a bounded queue for notification-only events, overflow reporting and main-loop dispatch. Keep events that require an immediate native decision synchronous, with explicit callback restrictions. |
| [AutoIt Forum dark-mode question](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/#findComment-1555638) | Host-controlled dark appearance for page content | Example 029 demonstrates CDP color-scheme emulation and experimental forced dark mode; the UDF has no dedicated native color-scheme setter. | Compare native preferred-color-scheme support with CSS or Chromium forced-dark behavior, and document that arbitrary light pages may not render correctly in dark mode. |
| [AutoIt Forum high-DPI discussion](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/page/2/#findComment-1555702) | Host process DPI-awareness helper and resize guidance | The UDF provides bounds and resize helpers but no process DPI-awareness helper or documented `WM_DPICHANGED` handling. | Assess a pre-`GUICreate` opt-in helper, manifest-already-set behavior and physical-pixel bounds when moving between monitors. |
| [AutoIt Forum WebView2 0.6.2 startup notes](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/#findComment-1555514) | Two-phase asynchronous view creation | `_WebView2_Init()` and `_WebView2_Create()` wait for native completion; there is no public start/wait pair. | Compare responsiveness, timeout and cancellation contracts before designing a nonblocking startup path. |
| [AutoIt Forum WebView2 0.6.5 environment options](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/#findComment-1555514) | Configurable environment creation options | The UDF supports user-data and browser-executable folders at initialization and a per-view user-agent setter; only the browser-extension switch from the upstream options set is exposed. | Compare Microsoft interface versions and option lifetimes; prioritize language, arguments, single sign-on, tracking prevention and scrollbar style for concrete host use cases. |
| [AutoIt Forum WebView2 0.10.0 extension announcement](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/page/2/#findComment-1555760) | Native browser-extension management | Native environment switch and profile add/list/enable/remove wrappers are implemented alongside the experimental CDP helpers; targeted x86/x64 runs verified those operations and enabled-state persistence across initialization cycles. | Confirm the sample GUI manually and review behavior with older Runtimes; the example content script ran after reloading its local page. |

For each daily review, add only a genuinely new or materially changed candidate, link its source, record the current UDF status and avoid duplicates. Proposals are reported in the ongoing project chat; implementation requires a separate task.
