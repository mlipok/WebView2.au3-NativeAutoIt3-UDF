# Release Notes - 0.5.0

Version 0.5.0 adds managed WebView2 tabs, instance enumeration, configurable waits and diagnostic levels. Existing public function signatures and error-code numbers remain unchanged.

## Added in 0.5.0

- `_WebView2_Tab_Create()`, `_WebView2_Tab_Activate()`, `_WebView2_Tab_Close()` and `_WebView2_Tab_List()`.
- `_WebView2_Instance_List()` for all live instances, including views outside the tab manager.
- `_WebView2_SetSleepCallback()` and `$WEBVIEW2_ERR_USER_ABORT` for user-controlled cancellation during waits.
- `_WebView2_SetDebugLevel()` with NONE, ERROR, INFO and FULL levels.
- Correct `@error/@extended` forwarding from helper calls previously returned directly.
- `examples/022_Tabs.au3`.

## Validation for 0.5.0

Tidy and Au3Check completed for the UDF and examples. Isolated AutoIt probes confirmed empty lists and callback cancellation on x86 and x64. Hidden-window native WebView2 tests created, activated, listed and closed two tabs on both architectures. Visible GUI behavior remains to be tested interactively.

## Previous version: 0.4.0

Version 0.4.0 extends the pure AutoIt + native WebView2 UDF with advanced Chromium/CDP capabilities and migration helpers for standard `IE.au3`.

## Added

- `WebView2_Advanced.au3` and `WebView2_IECompat.au3`.
- Raw `CallDevToolsProtocolMethod`.
- Cookies, cache/browser-data helpers and User-Agent override.
- Screenshot output to Base64, AutoIt `Binary`, or file.
- PDF output to Base64, AutoIt `Binary`, or file.
- MHTML output to string, UTF-8 AutoIt `Binary`, or file.
- URL-pattern ad blocker.
- Frame-tree metadata plus same-origin frame HTML helpers.
- Runtime-dependent extension helpers.
- Initialization scripts.
- IE.au3-style body/document/form/link/image/table/frame/property/action helpers.
- Examples 14-20.
- `docs/API_COMPARISON.md` comparing the UDF with NetWebView2Lib, au3WebDriver and standard AutoIt `IE.au3`.

## Compatibility

Existing public APIs remain available. `_WebView2_ExportToPdf()` remains as a compatibility alias for `_WebView2_ExportToPdfFile()`.

## Important

The project was statically validated in this environment, but Windows AutoIt/Au3Check and WebView2 x86/x64 smoke tests still need to be run locally before treating v0.4.0 as production-stable.
