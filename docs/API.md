# WebView2.au3 public API — v0.6.0

## Lifecycle and runtime

### `_WebView2_Init([$sLoaderPath = Default[, $sUserDataFolder = ""[, $sBrowserExecutableFolder = ""[, $iTimeoutMs = 30000]]]])`
Initializes STA COM, native callback objects, the loader DLL and a shared `ICoreWebView2Environment`.

### `_WebView2_Cleanup()`
Destroys all WebView instances, releases callbacks/environment, closes the loader and balances COM initialization.

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

The decision is immediate and applies to the top-level `ICoreWebView2::PermissionRequested` event. Do not show a modal dialog or call a blocking WebView2 helper inside this callback. A separate frame-level callback is available below; neither callback exposes a deferral. Scalar decisions may be saved in the selected user-data profile. See [example 031](../examples/031_PermissionRequests.au3).

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

### `_WebView2_SetCallback($iWebView, $iEvent, $fnCallback)`
Registers an AutoIt function reference. Supported event constants:

- `$WEBVIEW2_EVENT_NAVIGATION_STARTING`
- `$WEBVIEW2_EVENT_NAVIGATION_COMPLETED`
- `$WEBVIEW2_EVENT_DOCUMENT_TITLE_CHANGED`
- `$WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED`
- `$WEBVIEW2_EVENT_DOCUMENT_PLAYING_AUDIO_CHANGED` — callback `($iWebView, $bIsPlaying)`; available through `ICoreWebView2_8`. The callback is invoked when native document-audio state changes.
- `$WEBVIEW2_EVENT_MUTED_CHANGED` — callback `($iWebView, $bMuted)`; available through `ICoreWebView2_8`. The callback is invoked when the WebView mute state changes.
- `$WEBVIEW2_EVENT_FRAME_CREATED` — callback `($iWebView, $iFrame)` when a native iframe is created. Register before navigation.
- `$WEBVIEW2_EVENT_FRAME_DESTROYED` — callback `($iWebView, $iFrame)` before that frame ID is invalidated.
- `$WEBVIEW2_EVENT_FRAME_WEB_MESSAGE_RECEIVED` — callback `($iWebView, $iFrame, $sMessage, $sSource, $bJSON)` for iframe messages.
- `$WEBVIEW2_EVENT_FRAME_NAVIGATION_STARTING` — callback `($iWebView, $iFrame, $sURI, $bUserInitiated, $bRedirected)`; return `True` to cancel that frame navigation.
- `$WEBVIEW2_EVENT_FRAME_NAVIGATION_COMPLETED` — callback `($iWebView, $iFrame, $bSuccess, $iWebError)` after a frame navigation.
- `$WEBVIEW2_EVENT_FRAME_PERMISSION_REQUESTED` — callback `($iWebView, $iFrame, $sURI, $iKind, $bUserInitiated)`. Return `ALLOW` or `DENY`, optionally as `[state, saveInProfile]`, to handle the frame request immediately. Return `DEFAULT` to let the request continue to the normal WebView2 handling path. The optional profile flag requires a compatible Runtime.
- `$WEBVIEW2_EVENT_FRAME_SCREEN_CAPTURE_STARTING` — callback `($iWebView, $iFrame)`. Return `True` to cancel that frame's screen capture request and mark it handled; return `False` to leave it to WebView2. Do not block inside the callback.
- `$WEBVIEW2_EVENT_NEW_WINDOW_REQUESTED` — callback `($iWebView, $sURI, $bUserInitiated)`; return `True` to suppress the popup, or `$WEBVIEW2_NEW_WINDOW_DEFER` to request native handoff in the host loop.

Callback signatures are documented in README.md and the examples.

### Native new-window handoff

Return `$WEBVIEW2_NEW_WINDOW_DEFER` from the `NewWindowRequested` callback. Outside that callback, call `_WebView2_NewWindow_Request_List([$iSource = Default])` to get pending request IDs, optionally `_WebView2_NewWindow_Request_GetInfo($iRequest)` to read `[source ID, URI, user-initiated flag]`, and create a fresh controller in the same environment. Call `_WebView2_NewWindow_Complete($iRequest, $iNewWebView)` **before** navigating that controller. The UDF calls native `put_NewWindow` and completes the deferral; WebView2 then navigates the target itself and preserves `window.opener` and the opener's `WindowProxy`. `_WebView2_NewWindow_Cancel($iRequest)` blocks a pending request. Destroying the source controller cancels its pending requests. The host must complete or cancel requests promptly and must not create a controller inside the native callback. [Example 023](../examples/023_NewWindowTabs.au3) demonstrates this flow.

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

Native frame support uses `ICoreWebView2_4::FrameCreated` and frame interface revisions through `ICoreWebView2Frame6` when supported by the installed Runtime. Register a frame callback before navigation to track newly created iframes. UDF tracked frame IDs are distinct from the runtime's native `FrameId`, CDP frame IDs and DOM element tokens; a destroyed tracked frame ID cannot be reused.

- `_WebView2_Frame_List($iWebView)` returns tracked active frame IDs.
- `_WebView2_Frame_GetNativeId($iFrame)` reads the runtime's `UINT32 FrameId` through `ICoreWebView2Frame5`, or returns `-1` with `@error` if the interface is unavailable.
- `_WebView2_Frame_GetName($iFrame)` reads the iframe name.
- `_WebView2_Frame_ExecuteScript($iFrame, $sScript[, $iTimeoutMs = 30000])` returns a JSON-encoded result. It shares the serialized completion channel with top-level `_WebView2_ExecuteScript()`; call it outside re-entrant event callbacks.
- `_WebView2_Frame_PostWebMessageAsJson($iFrame, $sJSON)` and `_WebView2_Frame_PostWebMessageAsString($iFrame, $sMessage)` send data to one iframe. The frame must register `window.chrome.webview.addEventListener("message", ...)`.
- `_WebView2_Frame_PostSharedBuffer($iFrame, $bData[, $sAdditionalJSON = ""])` sends nonempty binary data (under 2 GB) to one iframe through a **read-only** shared buffer. The Runtime must support `ICoreWebView2Frame4` and `ICoreWebView2Environment12`. In the iframe, handle `chrome.webview`'s `sharedbufferreceived` event, call `event.getBuffer()`, read `event.additionalData`, then call `chrome.webview.releaseBuffer(buffer)`. The function reports unsupported interfaces through `@error` and native HRESULT in `@extended`.
- `_WebView2_Frame_AddHostObjectToScriptWithOrigins($iFrame, $sName, $oHost, $aOrigins)` exposes an AutoIt-held COM `IDispatch` object only to the explicit origins in the one-dimensional array. Empty lists and `"*"` are rejected. Keep `$oHost` alive while the frame uses it. `_WebView2_Frame_RemoveHostObjectFromScript($iFrame, $sName)` removes future access; existing JavaScript references can remain valid.

`ICoreWebView2Settings::IsWebMessageEnabled` and `AreHostObjectsAllowed` must permit the corresponding operations. [Example 027](../examples/027_NativeFrames.au3) demonstrates messaging, script execution and an origin-scoped host object. [Example 028](../examples/028_NestedFrames.au3) traverses same-origin nested frames. [Example 033](../examples/033_AdvancedFrameAPIs.au3) demonstrates the newer permission, shared-buffer and capture APIs. Tracking supports up to 256 simultaneously active frames.

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
