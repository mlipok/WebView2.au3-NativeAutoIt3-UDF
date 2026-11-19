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
12. **Native frame tracking starts at subscription time.** Register a frame callback before navigation. Tracked frame IDs are invalidated when the iframe is destroyed. The tracker supports 256 active frames; name changes use `ICoreWebView2Frame`, navigation and content-loading events use `ICoreWebView2Frame2`, native `FrameId` uses `ICoreWebView2Frame5`, and nested frame creation uses `ICoreWebView2Frame7` when supported by the Runtime. Events that occurred before callback registration are not replayed.
13. **Frame host objects require explicit origins.** The UDF rejects wildcard and empty origin lists, but the host must still validate frame messages and keep the COM `IDispatch` object alive. Removing an object does not revoke JavaScript references already obtained.
14. **Frame shared buffers are sent read-only.** `_WebView2_Frame_PostSharedBuffer()` accepts binary payloads under 2 GB and posts them to a tracked frame. It does not expose a writable shared memory view or a JavaScript-to-AutoIt shared-buffer channel. The page must release the received buffer.
15. **Worker tracking starts at subscription time.** Register a worker callback before a page, iframe or worker creates another worker. The original Frame8 notification remains observational; the worker callbacks retain up to 256 simultaneous worker interfaces and expose direct JSON messages, parent IDs and destruction. IDs become invalid when workers end, their parent workers or frames are destroyed, or the owning WebView2 instance is cleaned up. Existing workers are not enumerated, and a successful JSON send does not confirm delivery. Older Runtimes without the corresponding `ICoreWebView2_29` or `ICoreWebView2Frame8` interface cannot report workers from that source.

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

- audit the current [NetWebView2Lib](https://github.com/mlipok/NetWebView2Lib) API against this native UDF, update [API_COMPARISON.md](API_COMPARISON.md) with every missing or partial capability, and prioritize native equivalents without introducing a .NET dependency;
- asynchronous/nonblocking public variants of current synchronous helpers.

PDF.js rendering in example 214 was confirmed by the user in a running WebView2 session on 2026-11-13; this does not verify its omitted upstream extraction and selection/link-lock demonstrations. Example 217 now exercises virtual-folder mapping, example 207 exercises native response metadata, and the download example exercises native download events and control. See [EXAMPLES.md](EXAMPLES.md).

## TODO: Migration from other projects

Review external ideas against the current native UDF before implementing them. These entries are proposals, not claims of API compatibility or commitments to copy third-party code. Preserve this section as the single project TODO for findings from the three monitored sources. Last reviewed: 2026-11-11.

| Source | Candidate | Current UDF state | Next review step |
| --- | --- | --- | --- |
| [Microsoft BasicAuthenticationRequested API](https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10) | Native HTTP authentication (NET-01) | Opt-in callback with immediate credentials, cancellation and bounded deferrals with host-polled timeouts. Example 050 demonstrates Basic authentication against a local AutoIt server. | See [example 050](HTTP_AUTHENTICATION_EXAMPLE.md) for the verification scope. |
| [Microsoft process-related events](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/process-related-events) | Native process diagnostics (NET-02) | Opt-in ProcessFailed callback and Environment11 failure-report path readback. Example 051 exercises renderer failure and recovery. | x86/x64 hidden renderer tests passed. Dump creation, other failure kinds and older Runtime versions remain unverified. |
| [Microsoft ContextMenuRequested API](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2_11#add_contextmenurequested) | Native context-menu inspection and customization (NET-03) | Copied context metadata, per-request suppression and one appended native command. Example 052 demonstrates copying a link address. | x86/x64 verified native command insertion and selection. Collection editing, multiple commands and deferred decisions remain outside this API. |
| [Microsoft Settings7 PDF toolbar API](https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2settings7) | Individual native PDF toolbar visibility (NET-05) | Settings7 setter/getter, 13 flags and example 049 are implemented. x86/x64 native round trips passed; interactive example behavior was confirmed. | Maintain explicit next-navigation/profile scope. Older Runtime and shared-profile GUI coverage remain unverified. |
| [AutoIt Forum WebView2 topic](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/) | Native mute getter/setter and changed callback | Implemented through `ICoreWebView2_8`; x86/x64 getter/setter, event and cleanup smoke tests passed. | Keep this migration item for provenance; monitor upstream behavior and regression reports. |
| [AutoIt Forum WebView2 topic](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/) | Permission request policy, event and response | Immediate top-level and frame `PermissionRequested` callbacks read origin, kind and user-initiated flag. A bounded native deferral registry now supports later Allow/Deny, cancellation, timeout and owner cleanup. A two-element immediate return or nonpersistent deferred response uses `PermissionRequestedEventArgs3`. No per-kind policy table is exposed. | Keep the host responsible for origin/kind checks and polling the timeout; consider a separate optional policy table later. |
| [Ralle1976/Autoit-WebView2-UDF](https://github.com/Ralle1976/Autoit-WebView2-UDF) | Runtime installation prompt helper | Runtime detection and version queries exist; the UDF does not install the Runtime. | Decide whether a separate host-level opt-in helper or documentation is appropriate. |
| [Ralle1976/Autoit-WebView2-UDF](https://github.com/Ralle1976/Autoit-WebView2-UDF) | Asynchronous script execution | The public script helper is synchronous. | Compare callback and error contracts before considering an asynchronous variant. |
| [Ralle1976/Autoit-WebView2-UDF](https://github.com/Ralle1976/Autoit-WebView2-UDF) | Local Chart.js integration example | No dedicated chart example is included. | Evaluate a standalone, offline example using existing WebView2 APIs; keep UI assets separate from the core UDF. |
| [WV2Bridge 3.1 forum post](https://www.autoitscript.com/forum/topic/213942-udf-wv2bridge-31-authenticated-promise-based-rpc-between-a-webview2-page-and-autoit-add-on-for-my-webview2-udf/#findComment-1555627) | Authenticated, promise-based page-to-AutoIt RPC with bounded requests and deferred replies | The UDF provides web messages, initialization scripts, virtual-host mapping and synchronous script execution, but no named-call/response protocol, per-view RPC authorization or flow control. Hosts currently validate origins and payloads themselves. | Review the add-on's threat model, origin checks, correlation IDs, backpressure and deferred-reply lifecycle; prototype an optional layer above the existing UDF without changing low-level message contracts. |
| [AutoIt Forum event-queue explanation](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/#findComment-1555642) | Optional queued delivery of notification events | Our UDF invokes host callbacks directly from native COM callbacks; its documentation warns against re-entrant synchronous calls, and it has no per-view event queue. | Evaluate a bounded queue for notification-only events, overflow reporting and main-loop dispatch. Keep events that require an immediate native decision synchronous, with explicit callback restrictions. |
| [AutoIt Forum dark-mode question](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/#findComment-1555638) | Host-controlled dark appearance for page content | Example 029 demonstrates CDP color-scheme emulation and experimental forced dark mode; the UDF has no dedicated native color-scheme setter. | Compare native preferred-color-scheme support with CSS or Chromium forced-dark behavior, and document that arbitrary light pages may not render correctly in dark mode. |
| [AutoIt Forum high-DPI discussion](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/page/2/#findComment-1555702) | Host process DPI-awareness helper and resize guidance | The UDF provides bounds and resize helpers but no process DPI-awareness helper or documented `WM_DPICHANGED` handling. | Assess a pre-`GUICreate` opt-in helper, manifest-already-set behavior and physical-pixel bounds when moving between monitors. |
| [AutoIt Forum WebView2 0.6.2 startup notes](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/#findComment-1555514) | Two-phase asynchronous view creation | `_WebView2_Init()` and `_WebView2_Create()` wait for native completion; there is no public start/wait pair. | Compare responsiveness, timeout and cancellation contracts before designing a nonblocking startup path. |
| [AutoIt Forum WebView2 0.6.5 environment options](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/#findComment-1555514) | Configurable environment creation options | Language, browser arguments and Windows-account SSO have pre-initialization setters; profile color scheme and tracking level and environment scroll bar style are exposed in example 042. The user confirmed the interactive example works. Tracking prevention stays enabled at the environment level. | Consider an explicit Options5 environment switch only for applications restricted to known-safe content; never disable protection by default. |
| [AutoIt Forum WebView2 0.10.0 extension announcement](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/page/2/#findComment-1555760) | Native browser-extension management | Native environment switch and profile add/list/enable/remove wrappers are implemented alongside the experimental CDP helpers; targeted x86/x64 runs verified those operations and enabled-state persistence across initialization cycles. | Confirm the sample GUI manually and review behavior with older Runtimes; the example content script ran after reloading its local page. |

For each daily review, add only a genuinely new or materially changed candidate, link its source, record the current UDF status and avoid duplicates. Proposals are reported in the ongoing project chat; implementation requires a separate task.
