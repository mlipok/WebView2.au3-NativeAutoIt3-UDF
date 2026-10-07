# au3WebDriver → WebView2.au3 mapping

Version 0.3.0 reviewed the public function families in `wd_core.au3` and `wd_helper.au3` and selected concepts that are appropriate for an **embedded WebView2 document**.

## Directly useful concepts implemented natively

| au3WebDriver concept | WebView2.au3 native equivalent |
| --- | --- |
| Navigate / Back / Forward / Refresh / URL / Title | Existing `_WebView2_Navigate`, history helpers, `_WebView2_GetSource`, `_WebView2_GetDocumentTitle` |
| Execute JavaScript | `_WebView2_ExecuteScript` |
| Find element(s) | `_WebView2_FindElement`, `_WebView2_FindElements` |
| Get element by id / name | `_WebView2_GetElementById`, `_WebView2_GetElementByName` |
| Element action | `_WebView2_ElementAction`, `_WebView2_ElementActionEx` |
| Set element value | `_WebView2_SetElementValue` |
| Element style | `_WebView2_ElementStyle` |
| Dispatch DOM event | `_WebView2_DispatchEvent` |
| Select / option helpers | `_WebView2_ElementSelectAction`, `_WebView2_ElementOptionSelect` |
| Highlight element(s) | `_WebView2_HighlightElements` |
| Link click by text | `_WebView2_LinkClickByText` |
| Wait for page / element / script | `_WebView2_LoadWait`, `_WebView2_WaitElement`, `_WebView2_WaitScript` |
| localStorage / sessionStorage | `_WebView2_Storage` |
| Device pixel ratio | `_WebView2_GetDevicePixelRatio` |
| Frame count | `_WebView2_GetFrameCount` |
| Fullscreen state | `_WebView2_IsFullScreen` |
| Read table | `_WebView2_GetTable` |

## Existing WebView2-native features that already cover similar needs

- Browser PID: `_WebView2_GetBrowserProcessId`
- HTML source: `_WebView2_GetHtmlSource`
- Browser navigation state: `_WebView2_CanGoBack`, `_WebView2_CanGoForward`
- Print UI: `_WebView2_Print`
- DevTools: `_WebView2_OpenDevToolsWindow`

## Intentionally not emulated

The following are specific to remote/external WebDriver operation and are not appropriate to emulate inside an embedded control:

- WebDriver executable startup/shutdown and console visibility
- HTTP session creation/deletion/status and port management
- capabilities JSON and driver/browser matching
- external browser attachment
- WebDriver window handles and remote tab switching
- WebDriver action JSON helpers
- WebDriver binary update/download/version management

## Candidates for future native WebView2 interfaces

Some au3WebDriver features are useful, but should be implemented through actual WebView2 APIs rather than JavaScript or WebDriver emulation:

- Cookies → `ICoreWebView2CookieManager`
- Screenshot / capture preview → newer `ICoreWebView2_*` capture APIs
- Print to PDF → newer print/PDF interfaces
- CDP commands → WebView2 DevTools Protocol methods/events
- Downloads → WebView2 download events
- Frame objects → `ICoreWebView2Frame*`
- Script dialogs / permissions → corresponding WebView2 events
