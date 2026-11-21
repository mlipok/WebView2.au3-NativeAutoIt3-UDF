# WebView2.au3 public API — v0.6.0

## Profile-wide browsing data

Call `_WebView2_ClearProfileBrowsingData($iView, $iKinds, $fnCallback[, $vStart = Default[, $vEnd = Default]])` to clear selected kinds in the profile used by a view. Combine `$WEBVIEW2_BROWSING_DATA_*` flags with `BitOR()`. For example, combine `COOKIES` and `LOCAL_STORAGE` to clear both. This affects all origins and other views sharing that profile. The existing `_WebView2_ClearBrowserData()` keeps its previous behavior.

Omit both bounds to clear the selected kinds regardless of age. For a time range, pass both bounds as numeric UTC Unix seconds, including fractions if needed. The start is inclusive and the end is exclusive.

A True return means WebView2 accepted the request. The asynchronous callback `($iView, $iHRESULT)` reports completion, with zero indicating success. A False return indicates a synchronous validation or start failure. Inspect `@error` and, for native HRESULT failures, `@extended`. One operation can be pending per initiating view. WebView2 may continue clearing after that view is closed, at which point its callback is discarded.

Requires [ICoreWebView2Profile2](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2profile2). See [example 055](../examples/055_ProfileBrowsingData.au3) for an isolated two-origin demonstration.

## Navigation start metadata

Inside an existing top-level or frame navigation-start callback, call `_WebView2_GetNavigationStartingMetadata($iView)` with the view ID supplied to that callback. The arguments and cancellation returns of `$WEBVIEW2_EVENT_NAVIGATION_STARTING` and `$WEBVIEW2_EVENT_FRAME_NAVIGATION_STARTING` are unchanged.

The result is an AutoIt array with these fields:

| Index constant | Value |
| --- | --- |
| `$WEBVIEW2_NAVIGATION_METADATA_ID` | Native navigation ID. Compare top-level IDs with the existing `NavigationCompleted` ID. |
| `$WEBVIEW2_NAVIGATION_METADATA_KIND` | Native integer: `$WEBVIEW2_NAVIGATION_KIND_RELOAD`, `$WEBVIEW2_NAVIGATION_KIND_BACK_OR_FORWARD`, or `$WEBVIEW2_NAVIGATION_KIND_NEW_DOCUMENT`. Older Runtime versions may return `Null`. |
| `$WEBVIEW2_NAVIGATION_METADATA_HEADERS` | Two-dimensional array of `[name, value]` rows in native iteration order. An empty array means that the Runtime supplied no rows. |

An unavailable field is `Null`. The function returns `Null` with `$WEBVIEW2_ERR_INVALID_INSTANCE` for an invalid view or `$WEBVIEW2_ERR_NO_MATCH` when the specified view has no active navigation-start callback. The returned array can be retained after the callback. It is a read-only snapshot of the Runtime's event data and may differ from the complete request sent over the network.

See [example 054](../examples/054_NavigationMetadata.au3), [navigation-start arguments](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2navigationstartingeventargs), and [the navigation kind interface](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2navigationstartingeventargs3).

## Native source, zoom, and focus events

Register each event with `_WebView2_SetCallback($iView, $iEvent, $fnCallback)`. Re-registering the same event replaces its AutoIt callback. The UDF removes its native subscriptions before closing the view.

| Event constant | Callback parameters | Meaning |
| --- | --- | --- |
| `$WEBVIEW2_EVENT_SOURCE_CHANGED` | `($iView, $sURI, $bIsNewDocument)` | Top-level source URI changed. The native flag is false for a same-document fragment navigation. |
| `$WEBVIEW2_EVENT_ZOOM_FACTOR_CHANGED` | `($iView, $fZoomFactor)` | The controller reports a zoom change. A factor of 1.0 is 100%. |
| `$WEBVIEW2_EVENT_GOT_FOCUS` | `($iView)` | Focus entered the WebView2 controller. |
| `$WEBVIEW2_EVENT_LOST_FOCUS` | `($iView)` | Focus left the WebView2 controller. |

Source changes and navigation completion are separate. For example, a reload of the same URI may complete without a source change. A direct `_WebView2_SetZoomFactor()` call updates the controller immediately and does not generate the native zoom event. Focus changes between elements inside WebView2 do not leave the controller. Keep callbacks brief and schedule blocking work outside them.

See [example 053](../examples/053_NativeViewEvents.au3), [Microsoft's core events](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2#add_sourcechanged), and [controller events](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2controller).

## Native context menus

Register `_WebView2_SetCallback($iView, $WEBVIEW2_EVENT_CONTEXT_MENU_REQUESTED, _OnMenu)` to inspect native context-menu requests for one view. Registration requires `ICoreWebView2_11`. Keep the view's default context menus enabled when using this event.

The request callback receives `($iView, $aContext)`. The copied array has these indices:

| Index constant | Value |
| --- | --- |
| `$WEBVIEW2_CONTEXT_MENU_KIND` | Native target kind. Compare with the `$WEBVIEW2_CONTEXT_MENU_TARGET_*` constants. |
| `$WEBVIEW2_CONTEXT_MENU_X`, `$WEBVIEW2_CONTEXT_MENU_Y` | Runtime coordinates relative to the WebView bounds. |
| `$WEBVIEW2_CONTEXT_MENU_PAGE_URI`, `$WEBVIEW2_CONTEXT_MENU_FRAME_URI` | Document and child-frame URIs. The frame URI is empty for the main frame. |
| `$WEBVIEW2_CONTEXT_MENU_LINK_URI` | Link destination, if available. A linked image can have a link URI too. |
| `$WEBVIEW2_CONTEXT_MENU_SELECTION_TEXT` | Selected text, if available. |
| `$WEBVIEW2_CONTEXT_MENU_MAIN_FRAME` | Boolean main-frame flag. |

Return `Default` or `False` to keep the native menu, `True` to suppress it for this request, or `[caption, selectionCallback]` to append one native command through `ICoreWebView2Environment9`. Invalid descriptors and failed insertions leave the standard menu available. WebView2 calls `selectionCallback($iView, $aContext)` only when the custom command is selected. It receives the copied context from that request. Check the page URI, frame and link destination before enabling an application command. Keep callbacks brief and queue GUI or blocking work for the main loop.

This API supports one appended command per request. See [example 052](../examples/052_ContextMenu.au3) and [Microsoft's context-menu event](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2_11#add_contextmenurequested).

## Native process diagnostics

Register `_WebView2_SetCallback($iView, $WEBVIEW2_EVENT_PROCESS_FAILED, _OnProcessFailed)` for an individual view. The callback receives `($iView, $iKind, $vReason, $vExitCode, $vDescription)`. Compare the kind and reason with the `$WEBVIEW2_PROCESS_FAILED_KIND_*` and `$WEBVIEW2_PROCESS_FAILED_REASON_*` constants. The optional fields are `Null` when the Runtime cannot provide them. A successfully read description may be empty.

`_WebView2_GetFailureReportFolderPath()` reads the diagnostic directory of the active environment via `ICoreWebView2Environment11`. On failure it returns an empty string and sets `@error`, with the native HRESULT in `@extended` when available. The directory may contain older reports or no dump for the current event.

Schedule recovery after the callback returns. A top-level renderer exit can often be recovered by navigating again. A browser process exit requires recreating the affected WebViews. See [example 051](../examples/051_ProcessFailed.au3) and [Microsoft's process-related events guidance](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/process-related-events).

## Native HTTP authentication

Register `_WebView2_SetCallback($iWebView, $WEBVIEW2_EVENT_BASIC_AUTHENTICATION_REQUESTED, $fnCallback)` before protected navigation. The optional native subscription uses `ICoreWebView2_10`; unsupported Runtimes return a query error/HRESULT. Existing views without this subscription keep normal Runtime behavior.

The callback receives `($iWebView, $iRequest, $sURI, $sChallenge)`. Return a one-dimensional two-string `[user, password]` array to supply credentials, `$WEBVIEW2_AUTH_CANCEL` to cancel, or `$WEBVIEW2_AUTH_DEFER` to answer later. Invalid return values and callback errors cancel the request; the UDF does not fall back to an unexpected default credential dialog. Do not show modal UI or run blocking WebView2 calls inside the callback. Queue UI creation for the main AutoIt loop.

- `_WebView2_Authentication_Request_List($iWebView = -1)` returns a 2D array: `[0][0]` is the count; rows 1..count have request ID, owning view, requesting URI and challenge. `-1` lists all owners. No credentials or native pointers are exposed. Invalid filters return 0 with `INVALID_PARAMETER` or `INVALID_INSTANCE` in `@error`.
- `_WebView2_Authentication_Request_Respond($iRequest, $sUser = "", $sPassword = "", $bCancel = False)` completes a pending request. Credentials must be strings of at most 4096 characters each without embedded NUL; both strings empty is rejected. `True` in `$bCancel` ignores credential parameters. Success means native completion, not server acceptance. Failure returns False with `INVALID_PARAMETER`, `NO_MATCH`, or `HRESULT`; `@extended` contains a native HRESULT when applicable. Invalid input leaves the request pending; an attempted native response consumes it even if native completion fails.
- `_WebView2_Authentication_Request_Expire($iTimeoutMs = 30000)` cancels overdue requests and returns their consumed count. Call it from the host loop; no background timer is installed. A nonpositive/noninteger timeout sets `INVALID_PARAMETER`; native completion failure sets `HRESULT` and the first HRESULT in `@extended`.

The process-wide registry holds at most 32 native deferrals. IDs increase monotonically and become invalid after response, expiration, a new top-level navigation, view destruction or cleanup. If the registry or a deferral is unavailable, the registered handler cancels the request. Expiration is an explicit host policy; do not leave deferred requests unpolled. The registry stores metadata and retained event/deferral objects, not credential strings. WebView2 may cache credentials; the API does not promise secure memory erasure or automatic credential persistence.

Validate the actual requesting URI/challenge before providing credentials; a proxy challenge can identify the proxy URI rather than the page URI. Use HTTPS for real remote Basic authentication. This feature is separate from HTML login forms and Windows-account SSO. The native event also documents other authentication schemes, but the example tests Basic only; proxy/Digest/NTLM are not certified by these tests.

See [example 050](../examples/050_HttpAuthentication.au3), [its guide](HTTP_AUTHENTICATION_EXAMPLE.md) and [Microsoft's authentication event](https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10).

## Native PDF toolbar visibility

`_WebView2_SetHiddenPdfToolbarItems($iWebView, $iItems = 0)` hides the selected native PDF toolbar controls. Combine `$WEBVIEW2_PDF_TOOLBAR_ITEMS_*` flags with `BitOR`. Zero (`NONE`) restores default controls; `ALL` combines the 13 defined flags. The setter accepts integers from 0 through `0x1FFF` and returns `True` on success. `_WebView2_GetHiddenPdfToolbarItems($iWebView)` reads the actual native bitmask; zero is also a valid success value, so check `@error` immediately.

| Flag suffix | Value |
| --- | --- |
| `SAVE` | `0x0001` |
| `PRINT` | `0x0002` |
| `SAVE_AS` | `0x0004` |
| `ZOOM_IN` | `0x0008` |
| `ZOOM_OUT` | `0x0010` |
| `ROTATE` | `0x0020` |
| `FIT_PAGE` | `0x0040` |
| `PAGE_LAYOUT` | `0x0080` |
| `BOOKMARKS` | `0x0100` |
| `PAGE_SELECTOR` | `0x0200` |
| `SEARCH` | `0x0400` |
| `FULL_SCREEN` | `0x0800` |
| `MORE_SETTINGS` | `0x1000` |

Both functions use `ICoreWebView2Settings7`. They report invalid instance, native HRESULT or DLL-call errors through `@error`, with the underlying HRESULT in `@extended` where available. The setter additionally rejects invalid masks with `$WEBVIEW2_ERR_INVALID_PARAMETER`. An older Runtime without Settings7 fails explicitly; there is no fallback that silently changes PDF.js or URL fragments.

**Changes apply on the next navigation** and to views sharing the same environment and profile. The setter does not navigate automatically. Readback confirms the configured native value, not whether a specific Runtime displays that toolbar item. This customizes the built-in PDF viewer, not PDF.js, and does not prevent saving/printing through other routes.

```autoit
Local $iHide = BitOR($WEBVIEW2_PDF_TOOLBAR_ITEMS_PRINT, $WEBVIEW2_PDF_TOOLBAR_ITEMS_SAVE, $WEBVIEW2_PDF_TOOLBAR_ITEMS_SAVE_AS)
If _WebView2_SetHiddenPdfToolbarItems($iWebView, $iHide) Then
    Local $iActual = _WebView2_GetHiddenPdfToolbarItems($iWebView)
    If Not @error And $iActual = $iHide Then _WebView2_Navigate($iWebView, $sPdfURL)
EndIf
```

See [example 049](../examples/049_PdfToolbar.au3) and [Microsoft's native contract](https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2settings7).

## Local draft: host DPI helpers

`_WebView2_DPI_SetProcessPerMonitorV2()` requests Per Monitor v2 awareness before any host UI exists. It returns `True` when the request succeeds or the current thread already reports that context; otherwise it returns `False` with `@error`. An application manifest is the preferred production setting. `_WebView2_DPI_GetWindowDpi($hWnd)` returns the current native DPI for a host window. Handle `WM_DPICHANGED` in the host GUI and pass physical client coordinates to `_WebView2_SetBounds()` after the window change. See [example 043](../examples/043_HighDPI.au3).

## Local draft: asynchronous top-level script execution

`_WebView2_ExecuteScriptAsyncStart($iWebView, $sJavaScript)` starts a native script and returns a positive request ID. `_WebView2_ExecuteScriptAsyncPoll($iRequest, ByRef $sJSON)` returns `0` while pending, `1` with raw WebView2 JSON in `$sJSON` when complete, or `-1` with `@error` and native HRESULT in `@extended` on failure. Polling consumes a completed ID. `_WebView2_ExecuteScriptAsyncForget($iRequest)` discards a completed result or abandons a pending one; it does not cancel native execution. The registry is bounded at 32 requests. The existing synchronous API is unchanged. See [example 044](../examples/044_AsyncScript.au3). This draft requires x86/x64 lifecycle validation before integration.

## Local draft: notification queue

`_WebView2_EventQueue_Enable($iWebView[, $iCapacity = 32])` opts one view into queued delivery for navigation completion, document title changes and top-level web messages. `Dispatch($iWebView[, $iMaximum = 32])` invokes existing registered callbacks from the ordinary AutoIt GUI loop. `GetStats($iWebView)` returns `[queued, dropped, capacity]`; a full queue rejects the newest notification and increments `dropped`. `Disable($iWebView)` discards pending records and restores direct callback delivery. The capacity and dispatch maximum are each limited to 64. Permission, dialog, new-window and other native-decision events remain direct. See [example 045](../examples/045_EventQueue.au3). This local draft requires runtime validation before integration.

## Lifecycle and runtime

### `_WebView2_Init([$sLoaderPath = Default[, $sUserDataFolder = ""[, $sBrowserExecutableFolder = ""[, $iTimeoutMs = 30000]]]])`
Initializes STA COM, native callback objects, the loader DLL and a shared `ICoreWebView2Environment`.

### `_WebView2_Cleanup()`
Destroys all WebView instances, releases callbacks/environment, closes the loader and balances COM initialization.

### Environment creation options

Call these setters before `_WebView2_Init()`. They configure the next shared environment, not an individual view. All return `True` on success or `False` with `@error` for invalid arguments or an already initialized environment. `_WebView2_Cleanup()` clears the options.

- `_WebView2_Environment_SetLanguage($sLanguage)` sets a BCP 47 language tag such as `pl-PL`, affecting browser UI and the `Accept-Language` header. Pass `""` for the Runtime default.
- `_WebView2_Environment_SetAdditionalBrowserArguments($sArguments)` supplies Chromium command-line switches. Pass `""` to clear them. The Runtime may ignore switches that conflict with WebView2; do not put secrets in arguments.
- `_WebView2_Environment_SetOSPrimaryAccountSSO($bEnable)` opts into using the Windows primary account for eligible Microsoft identity resources. The default is `False`; this setting does not sign in to arbitrary websites. A local page cannot demonstrate authentication.

These options share the creation object already used by native extensions, so the extension switch can be enabled in the same initialization. See [example 040](../examples/040_EnvironmentOptions.au3).

### Profile appearance and privacy

- `_WebView2_Profile_GetPreferredColorScheme($iWebView)` and `_WebView2_Profile_SetPreferredColorScheme($iWebView, $iScheme)` use native `ICoreWebView2Profile` values `$WEBVIEW2_PREFERRED_COLOR_AUTO` (0), `LIGHT` (1), and `DARK` (2). The setting affects browser UI and the page's `prefers-color-scheme` media query. It applies to all WebViews sharing that profile.
- `_WebView2_Profile_GetTrackingPreventionLevel($iWebView)` and `_WebView2_Profile_SetTrackingPreventionLevel($iWebView, $iLevel)` use native `ICoreWebView2Profile3` values `$WEBVIEW2_TRACKING_PREVENTION_NONE` (0), `BASIC` (1), `BALANCED` (2), and `STRICT` (3). The level is persisted in the user-data profile. The UDF leaves environment-level tracking prevention enabled by default; `NONE` disables protection for that profile. A setter returning success confirms the native property update, not that any particular network request was blocked.
- `_WebView2_Environment_SetScrollBarStyle($iStyle)` selects `$WEBVIEW2_SCROLLBAR_STYLE_DEFAULT` (0) or `$WEBVIEW2_SCROLLBAR_STYLE_FLUENT_OVERLAY` (1) through `ICoreWebView2EnvironmentOptions8`. Call before `_WebView2_Init()`; this creation option cannot change within an existing environment. Fluent overlay requires WebView2 Runtime 125 or later. Set the page's CSS `color-scheme` to let the scroll bar follow light/dark colors.

Getters return the native integer value or `-1` with `@error`; setters return `True` or `False` with `@error` and native HRESULT in `@extended` where applicable. See [example 042](../examples/042_AppearanceAndPrivacy.au3). Its interactive behavior was confirmed by the user; no network tracker-blocking test was performed.

### `_WebView2_Runtime_IsInstalled([$sLoaderPath = Default])`
Returns `True` if the loader can query a compatible WebView2 Runtime.

### `_WebView2_Runtime_GetVersion([$sLoaderPath = Default])`
Returns the Runtime version string or `""` on failure.

### `_WebView2_SetSleepCallback([$fnSleep = Default])`
Replaces internal wait pauses with an AutoIt function accepting milliseconds. Pass `Default` to restore `Sleep()`. A callback that sets `@error` stops the wait with `$WEBVIEW2_ERR_USER_ABORT`; its original error is returned in `@extended`.

### `_WebView2_SetDebugLevel($iLevel)`
Controls console diagnostics using `$WEBVIEW2_DEBUG_NONE`, `$WEBVIEW2_DEBUG_ERROR`, `$WEBVIEW2_DEBUG_INFO` or `$WEBVIEW2_DEBUG_FULL`.

## Instance management

### `_WebView2_Create($hWndParent[, $iLeft = 0[, $iTop = 0[, $iWidth = -1[, $iHeight = -1[, $iTimeoutMs = 30000]]]]])`
Creates a controller and WebView inside an existing HWND. `-1` width/height fill the remaining client area. Returns an integer instance ID.

### `_WebView2_Destroy($iWebView)`
Unsubscribes events, closes the controller and releases an instance slot.

### `_WebView2_Instance_List()`
Returns all live instance IDs. The one-dimensional array stores the count in `[0]` and IDs in `[1..count]`.

### `_WebView2_Tab_Create($hWndParent[, $sURI = "about:blank"[, $iLeft = 0[, $iTop = 0[, $iWidth = -1[, $iHeight = -1[, $iTimeoutMs = 30000]]]]]])`
Creates a WebView2 controller managed as a tab and returns its ID. The ID is also a normal WebView2 instance ID.

### `_WebView2_Tab_Activate($iTab)` / `_WebView2_Tab_Close($iTab)`
Activates a tab within its parent window or closes it. Closing the active tab does not select a replacement.

### `_WebView2_Tab_List([$hWndParent = Default])`
Lists live managed tabs for one parent window or all parents. The array uses the same count-first format as `_WebView2_Instance_List()`.

### `_WebView2_SetBounds($iWebView, $iLeft, $iTop, $iWidth, $iHeight)`
Sets controller bounds.

### `_WebView2_ResizeToParent($iWebView[, $iLeft = 0[, $iTop = 0]])`
Resizes the view to the parent client rectangle.

### `_WebView2_SetVisible($iWebView[, $bVisible = True])`
Sets controller visibility.

### `_WebView2_SetDefaultBackgroundColor($iWebView, $iRGB[, $iAlpha = 255])`
Sets the native controller color beneath web content. Supply RGB as `0xRRGGBB`; alpha must be `255` (opaque) or `0` (transparent). Returns `True` on success or `False` with `@error` and, when available, the native HRESULT in `@extended`. An opaque page background hides this color. Setting the color after controller creation can allow an initial white flash. See [example 039](../examples/039_DefaultBackgroundColor.au3).

### `_WebView2_GetDefaultBackgroundColor($iWebView)`
Reads the controller color as `0xRRGGBB`; on success, `@extended` contains alpha (`0` or `255`). On failure, returns `-1` with `@error`; `@extended` then contains the native HRESULT when available. Example 039 verifies the result after every change.

### `_WebView2_SetZoomFactor($iWebView[, $fZoomFactor = 1.0])`
Sets zoom, where `1.0` is 100%.

## Navigation

- `_WebView2_Navigate($iWebView, $sURI)`
- `_WebView2_NavigateToString($iWebView, $sHTML)`
- `_WebView2_Reload($iWebView)`
- `_WebView2_Stop($iWebView)`
- `_WebView2_GoBack($iWebView)`
- `_WebView2_GoForward($iWebView)`
- `_WebView2_CanGoBack($iWebView)`
- `_WebView2_CanGoForward($iWebView)`

`NavigateToString()` follows WebView2's own size/origin limitations.

### `_WebView2_SetVirtualHostNameToFolderMapping($iWebView, $sHostName, $sFolderPath[, $iAccessKind = $WEBVIEW2_HOST_RESOURCE_ACCESS_DENY])`
Maps an existing local folder to `https://<host>/` in one WebView2 instance through `ICoreWebView2_3`. Call it before navigation. Returns `True` on success, or `False` with `@error` for invalid instance/parameters or a native HRESULT (`@extended`). No local HTTP server is needed. Cross-origin modes are `$WEBVIEW2_HOST_RESOURCE_ACCESS_DENY` (default), `$WEBVIEW2_HOST_RESOURCE_ACCESS_ALLOW`, and `$WEBVIEW2_HOST_RESOURCE_ACCESS_DENY_CORS`. The host name excludes scheme and path; use an absolute folder path. See [example 026](../examples/026_VirtualHostMapping.au3).

## Document data and scripting

### `_WebView2_GetSource($iWebView)`
Returns the current top-level URI.

### `_WebView2_GetDocumentTitle($iWebView)`
Returns the current document title.

### `_WebView2_ExecuteScript($iWebView, $sJavaScript[, $iTimeoutMs = 30000])`
Starts asynchronous WebView2 `ExecuteScript()` and waits while pumping the Win32 message queue. Returns WebView2's JSON-encoded result. v0.1.5 serializes script executions across all UDF instances.

### `_WebView2_JavaScriptStringLiteral($sValue)`
Returns a quoted and escaped JavaScript string literal for safely inserting text into script source.

### `_WebView2_JSONStringDecode($sValue)`
Decodes a JSON-encoded string result, preserving the decoder's `@error` and `@extended`. Use only when the script result is expected to be a string.

## Web messaging

### Permission requests

Register `_WebView2_SetCallback($iWebView, $WEBVIEW2_EVENT_PERMISSION_REQUESTED, $fnCallback)` before loading content. The callback receives `($iWebView, $sURI, $iKind, $bUserInitiated)` and returns `$WEBVIEW2_PERMISSION_STATE_DEFAULT` (0), `$WEBVIEW2_PERMISSION_STATE_ALLOW` (1), or `$WEBVIEW2_PERMISSION_STATE_DENY` (2). It may instead return a two-element array `[state, saveInProfile]`; `False` in the second element prevents this decision from being saved, provided the Runtime supports `ICoreWebView2PermissionRequestedEventArgs3`. `$sURI` is the requesting origin. Compare it with an exact trusted origin and inspect `$iKind` before granting access. `$WEBVIEW2_PERMISSION_KIND_GEOLOCATION` is 3; `$WEBVIEW2_PERMISSION_KIND_NOTIFICATIONS` is 4. An invalid callback result, callback error, or unavailable required interface leaves the Runtime's default handling in place.

The callback can also return `$WEBVIEW2_PERMISSION_DEFER` (-1) for either a top-level or tracked-frame request. Return promptly; do not show a modal dialog or call a blocking WebView2 helper inside the callback. After it returns, call `_WebView2_Permission_Request_List([$iWebView])`, then `_WebView2_Permission_Request_GetInfo($iRequest)` to read `[view ID, frame ID (0 for the top level), origin, kind, user-initiated]`. Call `_WebView2_Permission_Request_Respond($iRequest, $WEBVIEW2_PERMISSION_STATE_ALLOW|$WEBVIEW2_PERMISSION_STATE_DENY[, $bSaveInProfile = False])` or `_WebView2_Permission_Request_Cancel($iRequest)` from the host loop. Pending IDs become invalid after a response, cancellation, frame destruction or view destruction. The queue holds at most 64 requests; overflow is denied. Poll `_WebView2_Permission_Request_Expire([$iTimeoutMs = 15000])` to deny unanswered requests; timeout processing requires the host loop to keep running. The default nonpersistent response requires `PermissionRequestedEventArgs3`; if the Runtime lacks it, a response may fail and the host must cancel or destroy the view. Frame requests set `Handled` before acquiring the native deferral to avoid a duplicate top-level callback. Scalar immediate decisions may still be saved in the selected user-data profile. See [example 031](../examples/031_PermissionRequests.au3).

### `_WebView2_PostWebMessageAsString($iWebView, $sMessage)`
Posts native-host text to the web content.

### `_WebView2_PostWebMessageAsJson($iWebView, $sJSON)`
Posts native-host JSON to the web content.

Web content can send messages to AutoIt using:

```javascript
window.chrome.webview.postMessage(value);
```

## DevTools

### `_WebView2_OpenDevToolsWindow($iWebView)`
Opens Chromium DevTools for the selected view.

## Events

### Full-screen HTML element

`_WebView2_GetContainsFullScreenElement($iWebView)` reads the native `ICoreWebView2` property. It returns `True` when a page element fills the WebView, `False` when none does, or `False` with `@error` on failure (`@extended` carries the native HRESULT when available). This state does not mean that the AutoIt window is borderless or fills the monitor. It differs from `_WebView2_IsFullScreen()`, which evaluates `document.fullscreenElement` in the top-level page.

Register `$WEBVIEW2_EVENT_CONTAINS_FULLSCREEN_ELEMENT_CHANGED` with `_WebView2_SetCallback()` to receive `($iWebView, $bContainsFullScreenElement)` when the native state changes. The callback is observational; return promptly and handle GUI layout in the normal message loop. [Example 041](../examples/041_FullScreenElement.au3) demonstrates the native `True`/`False` transition in a visible WebView2 session.

### Browser accelerator keys

`_WebView2_SetBrowserAcceleratorKeysEnabled($iWebView[, $bEnabled = True])` controls WebView2's browser-specific shortcuts, including F5, Ctrl+P and F12. It requires `ICoreWebView2Settings3`; an unavailable native interface returns `False` with `@error` and an HRESULT in `@extended` when available. Changes may take effect on the next top-level navigation. Text editing shortcuts are not disabled by this switch.

For selective handling, register `_WebView2_SetCallback($iWebView, $WEBVIEW2_EVENT_ACCELERATOR_KEY_PRESSED, $fnCallback)`. The callback receives `($iWebView, $iKeyEventKind, $iVirtualKey, $iKeyEventLParam)` and must return promptly. Return `True` to mark that event handled and prevent the browser action, or `False` to leave it to WebView2. The event fires even when browser shortcuts are globally disabled. Key kinds are `$WEBVIEW2_KEY_EVENT_KIND_KEY_DOWN`, `_KEY_UP`, `_SYSTEM_KEY_DOWN` and `_SYSTEM_KEY_UP`. Use Win32 key state when a Ctrl or Alt modifier matters. See [example 037](../examples/037_AcceleratorKeys.au3).

### `_WebView2_SetCallback($iWebView, $iEvent, $fnCallback)`
Registers an AutoIt function reference. Supported event constants:

- `$WEBVIEW2_EVENT_NAVIGATION_STARTING`
- `$WEBVIEW2_EVENT_NAVIGATION_COMPLETED`
- `$WEBVIEW2_EVENT_DOCUMENT_TITLE_CHANGED`
- `$WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED`
- `$WEBVIEW2_EVENT_ACCELERATOR_KEY_PRESSED` — callback described above; return `True` to handle that key event.
- `$WEBVIEW2_EVENT_CONTAINS_FULLSCREEN_ELEMENT_CHANGED` — callback `($iWebView, $bContainsFullScreenElement)` for a native full-screen element state change.
- `$WEBVIEW2_EVENT_DOCUMENT_PLAYING_AUDIO_CHANGED` — callback `($iWebView, $bIsPlaying)`; available through `ICoreWebView2_8`. The callback is invoked when native document-audio state changes.
- `$WEBVIEW2_EVENT_MUTED_CHANGED` — callback `($iWebView, $bMuted)`; available through `ICoreWebView2_8`. The callback is invoked when the WebView mute state changes.
- `$WEBVIEW2_EVENT_FRAME_CREATED` — callback `($iWebView, $iFrame)` when a native iframe is created. Register before navigation.
- `$WEBVIEW2_EVENT_FRAME_DESTROYED` — callback `($iWebView, $iFrame)` before that frame ID is invalidated.
- `$WEBVIEW2_EVENT_FRAME_WEB_MESSAGE_RECEIVED` — callback `($iWebView, $iFrame, $sMessage, $sSource, $bJSON)` for iframe messages.
- `$WEBVIEW2_EVENT_FRAME_NAVIGATION_STARTING` — callback `($iWebView, $iFrame, $sURI, $bUserInitiated, $bRedirected)`; return `True` to cancel that frame navigation.
- `$WEBVIEW2_EVENT_FRAME_NAVIGATION_COMPLETED` — callback `($iWebView, $iFrame, $bSuccess, $iWebError)` after a frame navigation.
- `$WEBVIEW2_EVENT_FRAME_NAME_CHANGED` — callback `($iWebView, $iFrame, $sName)` after the iframe changes `window.name`.
- `$WEBVIEW2_EVENT_FRAME_CONTENT_LOADING` — callback `($iWebView, $iFrame, $bIsErrorPage, $iNavigationId)` before the iframe content loads.
- `$WEBVIEW2_EVENT_FRAME_DOM_CONTENT_LOADED` — callback `($iWebView, $iFrame, $iNavigationId)` after the iframe HTML has been parsed. Compare the navigation IDs to associate the two loading stages.
- `$WEBVIEW2_EVENT_FRAME_PERMISSION_REQUESTED` — callback `($iWebView, $iFrame, $sURI, $iKind, $bUserInitiated)`. Return `ALLOW` or `DENY`, optionally as `[state, saveInProfile]`, to handle the frame request immediately. Return `$WEBVIEW2_PERMISSION_DEFER` to finish it later through the pending-request API above. Return `DEFAULT` to let the request continue to the normal WebView2 handling path. The optional profile flag requires a compatible Runtime.
- `$WEBVIEW2_EVENT_FRAME_SCREEN_CAPTURE_STARTING` — callback `($iWebView, $iFrame)`. Return `True` to cancel that frame's screen capture request and mark it handled; return `False` to leave it to WebView2. Do not block inside the callback.
- `$WEBVIEW2_EVENT_FRAME_DEDICATED_WORKER_CREATED` — callback `($iWebView, $iFrame, $sScriptURI)` when that iframe creates a dedicated worker. Register before worker creation. The URI is the fully qualified script address. This is an observational `ICoreWebView2Frame8` event; it does not retain a worker handle or cover workers created directly by the top-level page. No callback is raised on a Runtime without Frame8 support. Keep the callback short.
- `$WEBVIEW2_EVENT_WORKER_CREATED` — callback `($iWebView, $iFrame, $iWorker, $sScriptURI)` after a page-, iframe- or worker-owned dedicated worker has been registered and assigned a public worker ID. This leaves the three-argument Frame8 callback unchanged.
- `$WEBVIEW2_EVENT_WORKER_WEB_MESSAGE_RECEIVED` — callback `($iWebView, $iFrame, $iWorker, $sJSON, $sSource)` for raw JSON posted through `self.chrome.webview.postMessage()` in the worker. Validate the source URI and payload in the host.
- `$WEBVIEW2_EVENT_WORKER_DESTROYING` — callback `($iWebView, $iFrame, $iWorker, $sScriptURI)` when WebView2 reports that the worker is ending. Its ID is invalid before this callback runs. Host cleanup does not synthesize this event.
- `$WEBVIEW2_EVENT_NEW_WINDOW_REQUESTED` — callback `($iWebView, $sURI, $bUserInitiated)`; return `True` to suppress the popup, or `$WEBVIEW2_NEW_WINDOW_DEFER` to request native handoff in the host loop.
- `$WEBVIEW2_EVENT_DOWNLOAD_STARTING` — callback `($iWebView, $iDownload, $sURI, $sSuggestedPath, $sMimeType)`; return a policy described below.
- `$WEBVIEW2_EVENT_DOWNLOAD_PROGRESS` — callback `($iWebView, $iDownload, $iBytesReceived, $iTotalBytes)`.
- `$WEBVIEW2_EVENT_DOWNLOAD_STATE_CHANGED` — callback `($iWebView, $iDownload, $iState, $iInterruptReason)`.
- `$WEBVIEW2_EVENT_WEB_RESOURCE_RESPONSE_RECEIVED` — callback `($iWebView, $sURI, $sMethod, $iStatusCode, $sReasonPhrase)`. Register before navigation to receive native response metadata for the document and its resources. The event is observational: it does not intercept or modify responses. Keep the callback short and avoid synchronous browser calls inside it. Resource URLs can contain sensitive query values; filter or redact them before logging.

Callback signatures are documented in README.md and the examples.

[Example 207](../examples/207-HTTP_StatusCodeTracking.au3) maps local assets to a virtual HTTPS host and reports 200 responses for its HTML, CSS and JavaScript without Internet access. Enter an external HTTP URL in the example's address field to inspect other status codes when online.

### Native new-window handoff

Return `$WEBVIEW2_NEW_WINDOW_DEFER` from the `NewWindowRequested` callback. Outside that callback, call `_WebView2_NewWindow_Request_List([$iSource = Default])` to get pending request IDs, optionally `_WebView2_NewWindow_Request_GetInfo($iRequest)` to read `[source ID, URI, user-initiated flag]`, and create a fresh controller in the same environment. Call `_WebView2_NewWindow_Complete($iRequest, $iNewWebView)` **before** navigating that controller. The UDF calls native `put_NewWindow` and completes the deferral; WebView2 then navigates the target itself and preserves `window.opener` and the opener's `WindowProxy`. `_WebView2_NewWindow_Cancel($iRequest)` blocks a pending request. Destroying the source controller cancels its pending requests. The host must complete or cancel requests promptly and must not create a controller inside the native callback. [Example 023](../examples/023_NewWindowTabs.au3) demonstrates this flow.

### Native downloads

Register `_WebView2_SetCallback($iWebView, $WEBVIEW2_EVENT_DOWNLOAD_STARTING, $fn)` before triggering a download. The callback receives `($iWebView, $iDownload, $sURI, $sSuggestedPath, $sMimeType)` and may return:

- `Default` to keep the Runtime's normal path and download UI;
- `$WEBVIEW2_DOWNLOAD_CANCEL` to deny the download before saving;
- `$WEBVIEW2_DOWNLOAD_DEFER` to decide outside the native callback;
- `[$sAbsolutePath, $bHideDefaultUI]` to choose a destination and optionally hide WebView2's download UI.

The UDF rejects an existing destination or a nonabsolute path by cancelling an immediate request. WebView2 can overwrite an existing file when given its path, so applications should create unique names and validate the download source before accepting it. The starting callback is synchronous: return promptly and do not invoke blocking WebView2 helpers in it.

For deferred policy, return `$WEBVIEW2_DOWNLOAD_DEFER`, then inspect `_WebView2_Download_Pending_List($iWebView)` in the host loop. Call `_WebView2_Download_Complete($iDownload[, $sPath = Default[, $bHideDefaultUI = False]])` to allow the request, or `_WebView2_Download_Cancel($iDownload)` to reject it. A custom path must be absolute and must not already exist. An invalid path leaves the request pending so the host can retry. Complete or cancel promptly; destroying the view cancels pending requests. Pending requests occupy the bounded download registry and cannot be replaced by a new request.

`$WEBVIEW2_EVENT_DOWNLOAD_PROGRESS` receives `($iWebView, $iDownload, $iBytesReceived, $iTotalBytes)`. Total bytes can be `-1` when unknown. `$WEBVIEW2_EVENT_DOWNLOAD_STATE_CHANGED` receives `($iWebView, $iDownload, $iState, $iInterruptReason)`. State constants are `$WEBVIEW2_DOWNLOAD_STATE_IN_PROGRESS`, `$WEBVIEW2_DOWNLOAD_STATE_INTERRUPTED`, and `$WEBVIEW2_DOWNLOAD_STATE_COMPLETED`.

`_WebView2_Download_List($iWebView)` returns tracked IDs. `_WebView2_Download_GetInfo($iDownload)` returns `[URI, file path, MIME type, received bytes, total bytes, state, interrupt reason]`. `_WebView2_Download_Pause($iDownload)` pauses an active transfer; WebView2 reports the pause as interrupted with reason `USER_PAUSED`. `_WebView2_Download_CanResume($iDownload)` reports whether the operation can resume, and `_WebView2_Download_Resume($iDownload)` resumes it. `_WebView2_Download_Cancel($iDownload)` cancels an active or deferred operation. The registry retains at most 64 active/recent operations across all views; completed entries are replaced by new downloads when full, and all entries are released when their view is destroyed. See [example 206](../examples/206-DownloadDemo.au3).

### JavaScript dialogs

Register `_WebView2_SetCallback($iWebView, $WEBVIEW2_EVENT_SCRIPT_DIALOG_OPENING, $fn)` before navigation. Registration disables WebView2's default JavaScript dialogs for that instance. The callback receives `($iWebView, $sURI, $iKind, $sMessage, $sDefaultText)` for `alert`, `confirm`, `prompt`, or `beforeunload`. Validate the page URI before granting a request. Return `$WEBVIEW2_SCRIPT_DIALOG_CANCEL`, `$WEBVIEW2_SCRIPT_DIALOG_ACCEPT`, or `$WEBVIEW2_SCRIPT_DIALOG_DEFER`. A prompt callback may return `[$WEBVIEW2_SCRIPT_DIALOG_ACCEPT, $sResultText]`. The callback must return promptly; do not show a modal dialog or call synchronous WebView2 helpers inside it.

For deferred decisions, poll `_WebView2_ScriptDialog_Request_List([$iWebView])` from the AutoIt event loop. `_WebView2_ScriptDialog_Request_GetInfo($iRequest)` returns `[view ID, URI, kind, message, default text]`. Answer with `_WebView2_ScriptDialog_Request_Respond($iRequest, $WEBVIEW2_SCRIPT_DIALOG_ACCEPT[, $sResultText])` or `_WebView2_ScriptDialog_Request_Cancel($iRequest)`. `_WebView2_ScriptDialog_Request_Expire([$iTimeoutMs = 15000])` cancels old requests when the host calls it. The UDF completes outstanding deferrals when their view is destroyed. At most 32 requests may be pending; if that limit is reached, a new dialog is dismissed. `alert` simply closes on completion. [Example 036](../examples/036_ScriptDialogs.au3) provides a manual `beforeunload` Leave/Stay scenario. A user-run WebView2 session on 2026-11-15 logged two deferred `beforeunload` requests and their Stay/Leave responses; its architecture was not recorded.

## Diagnostics

- `_WebView2_Error_GetDescription()`
- `_WebView2_Error_GetCode()`
- `_WebView2_Error_GetExtended()`

On failure, public functions normally set `@error` to a `$WEBVIEW2_ERR_*` constant and `@extended` to a relevant HRESULT or secondary error value.


## Added in 0.2.0

### State and process
- `_WebView2_IsReady($iWebView)`
- `_WebView2_GetBrowserProcessId($iWebView)`

### Settings
- `_WebView2_SetScriptEnabled()`
- `_WebView2_SetWebMessageEnabled()`
- `_WebView2_SetDefaultScriptDialogsEnabled()`
- `_WebView2_SetStatusBarEnabled()`
- `_WebView2_SetDevToolsEnabled()`
- `_WebView2_SetDefaultContextMenusEnabled()`
- `_WebView2_SetHostObjectsAllowed()`
- `_WebView2_SetZoomControlEnabled()`
- `_WebView2_SetBuiltInErrorPageEnabled()`

### Page helpers
- `_WebView2_GetHtmlSource()`
- `_WebView2_GetSelectedText()`
- `_WebView2_InjectCss()` / `_WebView2_ClearInjectedCss()`
- `_WebView2_Print()`
- `_WebView2_SetFocus()`
- `_WebView2_ResetZoom()`
- `_WebView2_LockWebView()` / `_WebView2_UnlockWebView()`
## Added in 0.3.0 — DOM automation

### Locator constants
- `$WEBVIEW2_LOCATOR_BY_CSS_SELECTOR`
- `$WEBVIEW2_LOCATOR_BY_XPATH`
- `$WEBVIEW2_LOCATOR_BY_ID`
- `$WEBVIEW2_LOCATOR_BY_NAME`
- `$WEBVIEW2_LOCATOR_BY_TAG_NAME`
- `$WEBVIEW2_LOCATOR_BY_LINK_TEXT`
- `$WEBVIEW2_LOCATOR_BY_PARTIAL_LINK_TEXT`

### Element discovery
- `_WebView2_FindElement($iWebView, $sStrategy, $sSelector)`
- `_WebView2_FindElements($iWebView, $sStrategy, $sSelector)`
- `_WebView2_GetElementById($iWebView, $sId)`
- `_WebView2_GetElementByName($iWebView, $sName)`
- `_WebView2_GetElementByRegEx($iWebView, $sAttribute, $sPattern[, $sFlags = ""])`
- `_WebView2_GetElementFromPoint($iWebView, $iX, $iY)`

Element discovery returns opaque document-scoped tokens. Navigating to another document invalidates old tokens and produces `$WEBVIEW2_ERR_STALE_ELEMENT` when they are reused.

### Element interaction
- `_WebView2_ElementAction()` — `ATTRIBUTE`, `CLEAR`, `CLICK`, `CLICKBUBBLE`, `CSS`, `DISPLAYED`, `ENABLED`, `FOCUS`, `HTML`, `NAME`, `PROPERTY`, `RECT`, `SCROLLINTOVIEW`, `SELECTED`, `TEXT`, `VALUE`
- `_WebView2_ElementActionEx()` — `HIDE`, `SHOW`, `REMOVE`, `DISABLE`, `ENABLE`
- `_WebView2_SetElementValue()`
- `_WebView2_ElementStyle()`
- `_WebView2_DispatchEvent()`
- `_WebView2_HighlightElements()`
- `_WebView2_LinkClickByText()`

### SELECT and TABLE
- `_WebView2_ElementSelectAction()` — `SELECTINDEX`, `SELECTVALUE`, `SELECTTEXT`, `SELECTALL`, `DESELECTALL`, `SELECTEDINDEX`, `OPTIONCOUNT`
- `_WebView2_ElementOptionSelect()`
- `_WebView2_GetTable()` — returns a two-dimensional AutoIt array

### Waiting and browser document helpers
- `_WebView2_LoadWait()`
- `_WebView2_WaitElement()` - retries missing elements; other find/action errors return immediately with their original `@error` and `@extended`.
- `_WebView2_WaitScript()`
- `_WebView2_Storage()` — `LOCAL` / `SESSION` with `GET`, `SET`, `REMOVE`, `CLEAR`, `LENGTH`, `KEY`
- `_WebView2_GetDevicePixelRatio()`
- `_WebView2_GetFrameCount()`
- `_WebView2_IsFullScreen()`

These functions are implemented with `ICoreWebView2::ExecuteScript()` inside the hosted document, not through the W3C WebDriver HTTP protocol.
## Added in 0.4.0 — advanced/CDP layer

### DevTools Protocol and initialization scripts
- `_WebView2_CallDevToolsProtocolMethod()`
- `_WebView2_AddInitializationScript()`
- `_WebView2_RemoveInitializationScript()`

### Persistent CSS

- `_WebView2_AddPersistentCss($iWebView, $sCss[, $iTimeoutMs = 30000])` registers nonempty CSS for future top-level HTML documents in the given WebView. It returns an opaque native registration ID or an empty string with @error on failure. Wait for the result before navigating. Call it from the host loop because registration waits for native completion. A cancelled or timed-out registration is rolled back on native completion. If completion is still pending after the additional rollback wait of up to one second, close the view to discard its pending registration before navigating.
- `_WebView2_RemovePersistentCss($iWebView, $sId)` asks WebView2 to unregister the returned ID. Use the same WebView instance and treat IDs as opaque. The function returns True when WebView2 accepts the request. Separate calls register separate styles, even when the CSS text matches.

Registration and removal take effect on a fresh document. Removal leaves style elements already inserted in loaded documents. Navigate or reload to see the difference. The Runtime's page policies, including Content Security Policy, can limit application of the style. The existing `_WebView2_InjectCss()` helper continues to apply CSS to the current document. See [example 057](../examples/057_PersistentCss.au3) and the [native script registration reference](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2#addscripttoexecuteondocumentcreated).

### Screenshot / preview
- `_WebView2_CapturePreviewAsBase64()`
- `_WebView2_CapturePreviewBinary()`
- `_WebView2_CapturePreview()` — file output

### PDF
- `_WebView2_PrintToPdfStream()` — Base64 payload retained for compatibility
- `_WebView2_ExportToPdfBinary()` — decoded AutoIt `Binary`
- `_WebView2_ExportToPdfFile()` — file output
- `_WebView2_ExportToPdf()` — compatibility alias for file output

### MHTML
- `_WebView2_CaptureSnapshot()` — MHTML string / optional file
- `_WebView2_ExportToMhtmlBinary()` — UTF-8 AutoIt `Binary`
- `_WebView2_ExportToMhtmlFile()` — file output using the same binary payload

### Cookies and browser data
- `_WebView2_GetCookies()`
- `_WebView2_AddCookie()`
- `_WebView2_DeleteCookie()`
- `_WebView2_DeleteAllCookies()`
- `_WebView2_ClearCache()`
- `_WebView2_ClearBrowserData()`
- `_WebView2_SetUserAgent()`

### Ad blocking
- `_WebView2_SetAdBlock()`
- `_WebView2_AddBlockRule()`
- `_WebView2_ClearBlockRules()`

### Frames

The existing CDP helpers return frame metadata and same-origin HTML: `_WebView2_GetFrameTree()`, `_WebView2_GetFrameUrls()` / `_WebView2_GetFrameUrl()`, `_WebView2_GetFrameNames()` / `_WebView2_GetFrameName()`, and `_WebView2_GetFrameHtmlSource()`.

Native frame support uses `ICoreWebView2_4::FrameCreated` for top-level iframes and `ICoreWebView2Frame7::FrameCreated` for each tracked frame's direct children when supported by the installed Runtime. Register a frame callback before navigation to track newly created iframes at every depth. UDF tracked frame IDs are distinct from the runtime's native `FrameId`, CDP frame IDs and DOM element tokens; a destroyed tracked frame ID cannot be reused.

`NameChanged` comes from `ICoreWebView2Frame`; `ContentLoading` and `DOMContentLoaded` come from `ICoreWebView2Frame2`. Register the corresponding callbacks before navigation to observe the first document. `ContentLoading` precedes scripts injected at document creation, while `DOMContentLoaded` reports that HTML parsing has completed. Neither callback implies that all resources have finished loading. Keep these callbacks short; do not call the synchronous script helper from them. [Example 027](../examples/027_NativeFrames.au3) logs the three events and reloads its iframe.

- `_WebView2_Frame_List($iWebView)` returns tracked active frame IDs.
- `_WebView2_Frame_GetParentId($iFrame)` returns the tracked parent frame ID, zero for a top-level iframe, or `-1` with `@error` for an invalid frame. Build a hierarchy by joining these IDs with `_WebView2_Frame_List()`; IDs are not zero-based sibling indexes.
- `_WebView2_Frame_GetNativeId($iFrame)` reads the runtime's `UINT32 FrameId` through `ICoreWebView2Frame5`, or returns `-1` with `@error` if the interface is unavailable.
- `_WebView2_Frame_GetName($iFrame)` reads the iframe name.
- `_WebView2_Frame_ExecuteScript($iFrame, $sScript[, $iTimeoutMs = 30000])` returns a JSON-encoded result. It shares the serialized completion channel with top-level `_WebView2_ExecuteScript()`; call it outside re-entrant event callbacks.
- `_WebView2_Frame_PostWebMessageAsJson($iFrame, $sJSON)` and `_WebView2_Frame_PostWebMessageAsString($iFrame, $sMessage)` send data to one iframe. The frame must register `window.chrome.webview.addEventListener("message", ...)`.
- `_WebView2_Frame_PostSharedBuffer($iFrame, $bData[, $sAdditionalJSON = ""])` sends nonempty binary data (under 2 GB) to one iframe through a **read-only** shared buffer. The Runtime must support `ICoreWebView2Frame4` and `ICoreWebView2Environment12`. In the iframe, handle `chrome.webview`'s `sharedbufferreceived` event, call `event.getBuffer()`, read `event.additionalData`, then call `chrome.webview.releaseBuffer(buffer)`. The function reports unsupported interfaces through `@error` and native HRESULT in `@extended`.
- `_WebView2_Frame_AddHostObjectToScriptWithOrigins($iFrame, $sName, $oHost, $aOrigins)` exposes an AutoIt-held COM `IDispatch` object only to the explicit origins in the one-dimensional array. Empty lists and `"*"` are rejected. Keep `$oHost` alive while the frame uses it. `_WebView2_Frame_RemoveHostObjectFromScript($iFrame, $sName)` removes future access; existing JavaScript references can remain valid.

`ICoreWebView2Settings::IsWebMessageEnabled` and `AreHostObjectsAllowed` must permit the corresponding operations. [Example 027](../examples/027_NativeFrames.au3) demonstrates messaging, script execution and an origin-scoped host object. [Example 028](../examples/028_NestedFrames.au3) validates the native parent hierarchy and changes labels through individual frame objects. [Example 033](../examples/033_AdvancedFrameAPIs.au3) demonstrates the newer permission, shared-buffer and capture APIs. [Example 034](../examples/034_FrameDedicatedWorker.au3) observes a worker started by its iframe. [Example 035](../examples/035_WorkerHierarchy.au3) also tracks page-owned and worker-owned workers. Tracking supports up to 256 simultaneously active frames. On a Runtime without `ICoreWebView2Frame7`, top-level tracking remains available, but descendant tracking is unavailable.

### Dedicated worker hierarchy

Register at least one `$WEBVIEW2_EVENT_WORKER_*` callback before creating workers. The UDF subscribes through `ICoreWebView2Frame8` for iframe-owned workers, `ICoreWebView2_29` for main-document workers, and `ICoreWebView2DedicatedWorker` for workers created by another tracked worker. The Runtime must support each interface for its corresponding source. `_WebView2_Worker_List($iWebView)` returns active public worker IDs (or an empty array). `_WebView2_Worker_GetParentId($iWorker)` returns the immediate parent worker ID, or zero for a worker created by a document; an invalid or stale ID sets `$WEBVIEW2_ERR_INVALID_PARAMETER`. The existing worker callbacks retain their signatures: their frame argument is zero for the main document and positive for a tracked iframe. A worker-created child inherits that original document's frame ID.

`_WebView2_Worker_PostWebMessageAsJson($iWorker, $sJSON)` sends JSON directly to one active worker. The worker receives it through `self.chrome.webview.addEventListener('message', ...)`; it can reply through `self.chrome.webview.postMessage(...)`. `IsWebMessageEnabled` must be true. The send returns `True` when WebView2 accepts it, not when the worker processes it. On invalid or stale ID, the send returns `False` with `$WEBVIEW2_ERR_INVALID_PARAMETER`; a native failure sets `$WEBVIEW2_ERR_HRESULT` and passes its HRESULT through `@extended`.

Worker IDs are positive, monotonic and distinct from frame IDs. The registry holds up to 256 simultaneously active workers and removes subscriptions on native destruction, frame destruction and view cleanup. Releasing a parent also invalidates its tracked descendants. Once removed, an ID cannot be used to send more messages. The original `$WEBVIEW2_EVENT_FRAME_DEDICATED_WORKER_CREATED` callback keeps its existing three-argument shape and does not by itself retain workers. Workers created before callback registration are not enumerated. Keep native callbacks short and avoid synchronous WebView2 calls in them. [Example 034](../examples/034_FrameDedicatedWorker.au3) demonstrates the original iframe flow; [example 035](../examples/035_WorkerHierarchy.au3) compares page, iframe and worker ownership. Targeted `--smoke` runs passed under AutoIt x86 and x64 for both examples; visible button sequences still need manual GUI verification.

### Extensions
- `_WebView2_AddExtension()`
- `_WebView2_RemoveExtension()`
- `_WebView2_GetExtensions()`

The original extension helpers use a runtime-dependent experimental CDP path. The native profile API below is a separate option; the original function contracts are unchanged.

### Native profile extensions

Call `_WebView2_NativeExtensions_EnableForEnvironment()` before `_WebView2_Init()`. The option applies to the environment being created; it cannot be changed after initialization. A persistent user-data folder passed to `_WebView2_Init()` retains installed extensions and their enabled state across runs. The folder containing an unpacked extension must remain available and unchanged.

- `_WebView2_NativeExtension_Add($iWebView, $sFolder)` installs a folder containing `manifest.json` and returns its extension ID.
- `_WebView2_NativeExtension_List($iWebView)` returns an array of extension IDs, names and enabled states.
- `_WebView2_NativeExtension_SetEnabled($iWebView, $sId, $bEnabled)` changes the enabled state.
- `_WebView2_NativeExtension_Remove($iWebView, $sId)` removes the extension from the profile.

These functions use `ICoreWebView2_13`, `ICoreWebView2Profile7` and `ICoreWebView2EnvironmentOptions6`, not the experimental CDP Extensions domain. They return `@error`/`@extended` for unsupported interfaces, native HRESULTs and timeouts. Only unpacked extensions are supported. Extensions whose manifest expects browser toolbar UI may load without that UI in WebView2. See [example 032](../examples/032_NativeExtensions.au3).

### IE.au3 migration helpers

Version 0.4.0 adds WebView2-native counterparts for common `IE.au3` patterns, including `_WebView2_Action`, `_WebView2_BodyReadHTML`, `_WebView2_BodyReadText`, `_WebView2_BodyWriteHTML`, form/form-element collections, link/image/table/frame/tag collections, property get/set, head insertion, and `_WebView2_TableWriteToArray`.

See `API_COMPARISON.md` for exact mapping and limitations.

## JSON string decoding and large export results

JSON string values are decoded once, including escaped backslashes, Unicode UTF-16 code units and surrogate pairs. Unquoted values retain their pass-through behavior. The CDP string-property reader scans closing quotes instead of recursively matching the complete value, avoiding the previous large Base64/MHTML failure. Public signatures and return types are unchanged. Run `tools/Smoke-JsonStrings.au3` for the regression cases.

### `_WebView2_GetIsDocumentPlayingAudio($iWebView)`
Returns `True` while the document is playing audio, or `False` when it is not. Both are successful results with `@error = 0`; check `@error` to distinguish an unsupported interface or native failure. The value may be `True` while audio is muted. See [example 025](../examples/025_AudioState.au3).

### `_WebView2_GetIsMuted($iWebView)`
Returns `True` when all WebView2 audio output is muted, or `False` otherwise. Both are successful results with `@error = 0`. On failure it returns `False` with `@error`; `@extended` contains a native HRESULT when available.

### `_WebView2_SetIsMuted($iWebView, $bMuted)`
Sets the native mute property through `ICoreWebView2_8`. Pass `True` to mute or `False` to unmute. Returns `True` on success, or `False` with `@error` for an invalid instance/parameter or native failure. Muting does not stop playback, so `IsDocumentPlayingAudio` can remain `True`. See [example 025](../examples/025_AudioState.au3).
