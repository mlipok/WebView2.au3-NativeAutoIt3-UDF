# Changelog

## Unreleased — 2026-09-29

- Establish English as the project language and translate project-owned example UI, HTML, and newly added documentation while retaining deliberate Unicode fixtures.
- Normalize existing example filenames to three digits; update documentation and project validation paths.
- Add functional copies/adaptations of the GitHub examples 000–021 as 200–221, with explicit upstream attribution and WIP status where capabilities remain incomplete.
- Keep the new runnable examples as standalone mini projects with their own lifecycle and actions; no shared example support module.
- Add the local marked-based Markdown viewer and native Markdown message box.
- Fix large CDP string extraction and decode JSON escapes exactly once, including Unicode and literal backslash paths.
- Add JSON regression coverage and document the runtime verification boundary.


## 0.5.0 - 2026-09-27

- Added managed tabs with create, activate, close and list operations, plus a list of all live WebView2 instances.
- Added configurable wait callbacks; callback `@error` is reported as `$WEBVIEW2_ERR_USER_ABORT` and the callback error is retained in `@extended`.
- Added diagnostic levels, console output and a common error-recording helper.
- Retried transient native window-handle and visibility errors during managed tab creation and activation.
- Normalized UDF and example functions to one `Return` point and documented command variants in function headers.
- Preserved helper `@error/@extended` through direct forwarding functions, including IE-style aliases.
- Kept existing public function signatures and previously assigned error-code numbers.

## 0.4.0 - 2026-09-21

- Added `WebView2_Advanced.au3` with raw CDP calls, initialization scripts, cookies, browser-data helpers, User-Agent override, URL-pattern ad blocking, frame metadata, screenshot capture and runtime-dependent extension helpers.
- Added screenshot output as Base64, AutoIt `Binary`, and file.
- Added PDF output as Base64, AutoIt `Binary`, and file.
- Added MHTML output as string, UTF-8 AutoIt `Binary`, and file.
- Added `WebView2_IECompat.au3` with WebView2-native helpers covering the practical migration surface of standard `IE.au3`.
- Added examples 14-20 for CDP, cookies, PDF/MHTML, frames, ad blocking, extensions and IE.au3 migration.
- Added `docs/API_COMPARISON.md` mapping NetWebView2Lib, au3WebDriver and IE.au3 to the native WebView2 UDF.
- Preserved the stable v0.1.5+ COM lifetime/shutdown model.


## 0.3.0 - 2026-09-20

- Added `WebView2_DOM.au3`, a native DOM automation layer inspired by applicable `au3WebDriver` core/helper patterns.
- Added CSS/XPath/id/name/tag/link locator strategies and opaque document-scoped element tokens.
- Added element actions, style access, event dispatch, highlighting, select/option helpers and table extraction.
- Added `LoadWait`, `WaitElement`, `WaitScript`, local/session storage, devicePixelRatio, frame count and Fullscreen API helpers.
- Added examples 11-13 for DOM automation, wait/storage and select/table workflows.
- Added explicit mapping documentation explaining which au3WebDriver concepts are applicable to embedded WebView2 and which remain intentionally out of scope.
- Corrected the internal JavaScript string-literal escaping helper so backslashes, quotes, CR/LF and TAB are escaped using AutoIt string semantics.

## 0.2.0 - 2026-09-16

- Expanded the native API with selected capabilities inspired by NetWebView2Lib.
- Added ICoreWebView2Settings support for script, web-message, status bar, DevTools, context-menu, script-dialog, host-object, zoom-control and built-in error-page settings.
- Added IsReady, browser PID, reset zoom, print, HTML source, selected text, CSS injection/clear and focus helpers.
- Added conservative LockWebView / UnlockWebView helpers.
- Added seven feature-focused examples comparable to common NetWebView2Lib demos.
- Preserved the stable COM lifetime and shutdown behavior established in 0.1.5.

All notable project changes are documented here.

## 0.1.5 - 2026-09-16

### Fixed
- Removed explicit `Release()` calls for persistent Environment, Controller, and Core AutoIt COM wrappers to prevent double-release during shutdown.
- Disposal order is now event unsubscribe -> `Controller.Close()` -> clear Core wrapper -> clear Controller wrapper.
- Global cleanup now clears the Environment wrapper before deleting callback objects and calling `CoUninitialize()`.
- Added detailed `DISPOSE` and `CLEANUP` tracing around every shutdown stage.
- Event subscription tokens are cleared immediately after successful unsubscribe.
- No public API changes.

## 0.1.5 - 2026-09-16

### Fixed
- Added a temporary `AddRef()` for borrowed WebView2 EventArgs pointers wrapped with `ObjCreateInterface()` in NavigationStarting, NavigationCompleted, and WebMessageReceived callbacks.
- Added detailed callback tracing to isolate native callback/lifetime failures and user-callback boundaries.
- No public API changes.

## 0.1.3 - 2026-09-16

### Fixed
- Replaced `_WinAPI_CoInitialize()` result handling with direct `CoInitializeEx()` HRESULT handling.
- Treats both `S_OK` and `S_FALSE` as successful COM initialization.
- Uses `FAILED(HRESULT)` semantics (negative signed HRESULT) so `RPC_E_CHANGED_MODE` and other failures remain errors.
- Balances every successful `CoInitializeEx()` call, including `S_FALSE`, with `CoUninitialize()` during `_WebView2_Cleanup()`.
- COM initialization diagnostics now include the HRESULT value in hexadecimal form.

## 0.1.1 - 2026-09-16

### Fixed
- Added an internal Win32 `MSG` structure definition used by the message pump; fixes AU3Check error for undeclared `$tagMSG`.
- Made `WebView2_Core.au3` include its own internal dependencies so it can be checked directly with AU3Check.
- Made `WebView2_CallbackObject.au3` include `WebView2_Constants.au3` directly for standalone AU3Check validation.

## [0.1.0] - 2026-09-16

### Added

- First reusable `WebView2.au3` UDF package based on the native AutoIt WebView2 approach.
- Shared WebView2 environment with multi-instance controller management.
- Runtime detection and runtime version query.
- Navigation, HTML-string navigation, history, reload and stop.
- Bounds, resize-to-parent, visibility and zoom operations.
- Source URI and document title accessors.
- Synchronous wrapper for WebView2 `ExecuteScript()` using Win32 message pumping.
- Native-to-web string/JSON messages.
- NavigationStarting, NavigationCompleted, DocumentTitleChanged and WebMessageReceived callbacks.
- DevTools command.
- x86/x64 loader discovery.
- Official NuGet loader acquisition helper pinned to Microsoft.Web.WebView2 1.0.4191.47.
- GitHub-style examples, API documentation, architecture notes and third-party attribution.
