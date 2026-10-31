# WebView2.au3-NativeAutoIt3-UDF

Native Microsoft Edge WebView2 hosting for AutoIt — **pure AutoIt + Win32 WebView2 API**, without a C#/.NET bridge or registered ActiveX control.

Version: **0.5.0**  

**COM initialization note:** v0.1.5 correctly treats both `S_OK` and `S_FALSE` from `CoInitializeEx()` as success and reports actual failing HRESULT values.
WebView2 SDK loader pinned by setup tooling: **Microsoft.Web.WebView2 1.0.4191.47**

**Shutdown lifetime note:** v0.1.5 removes explicit `Release()` calls for persistent AutoIt COM wrappers and lets wrapper destruction perform the matching release after event unsubscribe and `Controller.Close()`.

## Project origin

This UDF grows out of the AutoIt Forum research thread started by **mLipok**:

- https://www.autoitscript.com/forum/topic/204362-microsoft-edge-webview2-embed-web-code-in-your-native-application/

The native AutoIt approach demonstrated by **LarsJ** is the technical starting point: `WebView2Loader.dll`, STA COM, `ObjCreateInterface()`, native WebView2 interfaces, and AutoIt COM callbacks. This repository reorganizes that approach into a reusable multi-instance UDF and updates the public API around current WebView2 concepts.

See [NOTICE.md](NOTICE.md) for attribution and third-party notes.

## Core capabilities

- native `WebView2Loader.dll` loading for x86/x64 AutoIt;
- STA COM initialization and cleanup;
- shared `ICoreWebView2Environment`;
- up to 32 sequentially-created WebView2 instances;
- create/destroy and parent-window bounds management;
- navigation to URL or an HTML string;
- back / forward / reload / stop;
- source URI and document title;
- visibility and zoom factor;
- synchronous AutoIt wrapper around asynchronous `ExecuteScript()`;
- native-to-web messages (`PostWebMessageAsString`, `PostWebMessageAsJson`);
- virtual HTTPS host to local folder mapping (`ICoreWebView2_3`);
- web-to-AutoIt `WebMessageReceived` callback;
- callbacks for navigation start/completion and title changes;
- DevTools window;
- runtime detection/version query;
- diagnostic `@error`, `@extended`, and description helpers.

## Repository layout

```text
WebView2.au3
WebView2_Constants.au3
WebView2_Interfaces.au3
WebView2_CallbackObject.au3
WebView2_Core.au3
WebView2_DOM.au3
WebView2_IECompat.au3
WebView2_Advanced.au3
examples/
    001_Basic.au3
    002_Events_JavaScript.au3
    003_MultiInstance.au3
    ...
    020_IE_Compatibility.au3
    021_Folder_PDF_SlideShow.au3
    022_Tabs.au3
    023_NewWindowTabs.au3
docs/
    API.md
    ARCHITECTURE.md
    API_COMPARISON.md
    AU3WEBDRIVER_MAPPING.md
    KNOWN_LIMITATIONS.md
tools/
    Get-WebView2Loader.ps1
    Get-WebView2Loader.cmd
    Validate-Project.ps1
bin/
    x86/
    x64/
```

## Installation

### 1. WebView2 native loader

This project archive currently includes the x86 and x64 `WebView2Loader.dll` files used by the tested baseline. To refresh them from the pinned official Microsoft.Web.WebView2 NuGet package, run:

```powershell
.\tools\Get-WebView2Loader.ps1
```

or double-click/run:

```text
tools\Get-WebView2Loader.cmd
```

The script downloads the pinned official NuGet package and refreshes:

```text
bin\x86\WebView2Loader.dll
bin\x64\WebView2Loader.dll
```

It also checks the Authenticode signature and writes SHA-256 hashes.

### 2. Make sure WebView2 Runtime is installed

Evergreen WebView2 Runtime is commonly present on current Windows systems. You can check from AutoIt:

```autoit
#include "WebView2.au3"

ConsoleWrite(_WebView2_Runtime_GetVersion() & @CRLF)
```

### 3. Basic use

```autoit
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <WindowsConstants.au3>
#include "WebView2.au3"

Local $hGUI = GUICreate("WebView2.au3", 1000, 700, -1, -1, $WS_OVERLAPPEDWINDOW)
GUISetState(@SW_SHOW, $hGUI)

If Not _WebView2_Init() Then Exit MsgBox($MB_ICONERROR, "WebView2", _WebView2_Error_GetDescription())

Local $iWebView = _WebView2_Create($hGUI)
If @error Then Exit MsgBox($MB_ICONERROR, "WebView2", _WebView2_Error_GetDescription())

_WebView2_Navigate($iWebView, "https://www.autoitscript.com/")

While True
    Switch GUIGetMsg()
        Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
            _WebView2_ResizeToParent($iWebView)
        Case $GUI_EVENT_CLOSE
            ExitLoop
    EndSwitch
WEnd

_WebView2_Cleanup()
GUIDelete($hGUI)
```

See the complete examples in [`examples/`](examples/).

Version 0.5.0 adds managed tabs: `_WebView2_Tab_Create()`, `_WebView2_Tab_Activate()`, `_WebView2_Tab_Close()` and `_WebView2_Tab_List()`. A tab ID is also its WebView2 instance ID. `_WebView2_Instance_List()` lists every live instance, including views not managed as tabs. Both list functions return an AutoIt array with the count in `[0]` and IDs in `[1..count]`. See [`022_Tabs.au3`](examples/022_Tabs.au3). For `target="_blank"` and `window.open`, register `$WEBVIEW2_EVENT_NEW_WINDOW_REQUESTED` and queue tab creation in the host loop; [`023_NewWindowTabs.au3`](examples/023_NewWindowTabs.au3) demonstrates this. Returning `True` suppresses the native popup. This URI-based example does not preserve `window.opener` semantics.

`_WebView2_SetSleepCallback()` allows an AutoIt function to replace `Sleep()` during UDF waits. If that function sets `@error`, the wait stops with `$WEBVIEW2_ERR_USER_ABORT`; `@extended` contains the function's error code. The default remains ordinary `Sleep()`. `_WebView2_SetDebugLevel()` selects NONE, ERROR, INFO or FULL console diagnostics.

[`021_Folder_PDF_SlideShow.au3`](examples/021_Folder_PDF_SlideShow.au3) selects a folder and displays its PDF files in one WebView2 window, showing each for two seconds after loading. It hides the built-in viewer toolbar and requests `view=Fit` before navigation; set `$PDF_VIEW_MODE` to `"FitH"` to fit the width instead. WebView2 stays hidden during PDF loading to avoid visible zoom changes. Close the window to stop the slideshow.

## Callbacks

Pass AutoIt function references **without quotes**:

```autoit
_WebView2_SetCallback($iWebView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _OnNavigationCompleted)
```

Supported callback shapes:

```text
NavigationStarting:
    Func Callback($iWebView, $sURI, $bUserInitiated, $bRedirected)
    Return True to cancel navigation.

NavigationCompleted:
    Func Callback($iWebView, $bSuccess, $iWebErrorStatus, $iNavigationId)

DocumentTitleChanged:
    Func Callback($iWebView, $sTitle)

WebMessageReceived:
    Func Callback($iWebView, $sMessage, $sSource, $bJSON)
```

For web-to-host messaging JavaScript can use:

```javascript
window.chrome.webview.postMessage("Hello from JavaScript");
```

## `ExecuteScript()` return value

`_WebView2_ExecuteScript()` returns the **JSON-encoded string supplied by WebView2**. For example JavaScript:

```javascript
document.title
```

can return an AutoIt string containing JSON such as:

```text
"AutoIt Forums"
```

The UDF intentionally does not silently JSON-decode that value.

## Security

Do not trust messages merely because they came through `WebMessageReceived`. If a WebView can navigate to untrusted content, validate `$sSource` before acting on messages and validate message content before using it in privileged native operations.

## Requirements

- Windows with a compatible WebView2 Runtime;
- AutoIt 3.3.18.0 or newer recommended;
- matching x86/x64 `WebView2Loader.dll` from the Microsoft.Web.WebView2 package.

## Status

v0.5.0 is an **early native UDF release**. AutoIt syntax checks, isolated checks and hidden-window tab smoke tests on x86/x64 have been run. Visible GUI behavior of the examples still needs direct testing before treating the release as production-stable; see [KNOWN_LIMITATIONS.md](docs/KNOWN_LIMITATIONS.md).

## NetWebView2Lib-inspired native API additions (0.2.0)

Version 0.2.0 adds native equivalents for a selected set of manager-style capabilities: settings control, browser PID, HTML/selection retrieval, CSS injection, print, focus, reset zoom and Lock/Unlock helpers. The implementation remains pure AutoIt + native WebView2 COM; it does not require NetWebView2Lib.dll or .NET.

Additional examples: `004_Settings.au3`, `005_Script_Result.au3`, `006_CSS_Injection.au3`, `007_Content_Selection.au3`, `008_Browser_Navigation.au3`, `009_Kiosk_Lock.au3`, `010_Zoom_Print_Focus.au3`.
## au3WebDriver-inspired DOM automation additions (0.3.0)

Version 0.3.0 adds a DOM automation layer inspired by the useful browser-automation patterns exposed by `wd_core.au3` and `wd_helper.au3`, while keeping the implementation inside the embedded WebView2 control. No WebDriver executable, TCP port, external browser session or WinHTTP transport is used.

New capabilities include:

- locator strategies for CSS, XPath, id, name, tag name, link text and partial link text;
- document-scoped opaque element tokens;
- element actions such as click, text/value, attribute/property/CSS, rect, visibility, enabled state, focus, clear and scroll-into-view;
- style mutation, event dispatch, highlighting and option/select helpers;
- `LoadWait`, `WaitElement` and `WaitScript`;
- local/session storage helpers;
- device pixel ratio, frame count and Fullscreen API state;
- table extraction to a two-dimensional AutoIt array.

The element tokens intentionally become stale after navigation, mirroring the useful stale-element behavior of remote browser automation. `_WebView2_WaitElement()` re-locates missing or stale elements on subsequent polls, including when a page replaces an element between lookup and visibility/enabled checks. Retries keep the original timeout and poll interval; other errors and user cancellation still end the wait. See [`docs/AU3WEBDRIVER_MAPPING.md`](docs/AU3WEBDRIVER_MAPPING.md).

Additional examples: `011_DOM_Automation.au3`, `012_Wait_Storage.au3`, `013_Select_Table.au3`.
## Advanced browser APIs and IE.au3 migration helpers (0.4.0)

Version 0.4.0 adds an advanced CDP-backed layer plus IE.au3-style migration helpers while preserving the stable COM lifecycle used by earlier versions.

New advanced capabilities include:

- raw Chrome DevTools Protocol calls;
- cookies, cache/browser-data helpers and User-Agent override;
- screenshots as Base64, AutoIt `Binary`, or files;
- PDF as Base64, AutoIt `Binary`, or files;
- MHTML as string, AutoIt `Binary` (UTF-8), or files;
- URL-pattern ad blocking;
- frame metadata and same-origin frame HTML;
- runtime-dependent Chromium extension helpers;
- initialization scripts;
- URI and Base64 helpers.

The IE migration layer adds body/document helpers, form/element collections, link/image/table/frame collections, property access, common actions, head insertion helpers and table-to-array aliases. It intentionally does **not** expose legacy Internet Explorer COM objects.

See [`docs/API_COMPARISON.md`](docs/API_COMPARISON.md) for the mapping from NetWebView2Lib, au3WebDriver and standard AutoIt `IE.au3`.

Additional examples: `014_Advanced_CDP.au3` through `020_IE_Compatibility.au3`.

## Copies of the GitHub examples

**The new EXAMPLES `200–221` are copies of the EXAMPLES `000–021` set from [GitHub](https://github.com/ioa747/NetWebView2Lib/tree/main/examples), adapted for the native `WebView2.au3` UDF.** The upstream set is by ioa747; the corresponding names and numbers are retained. These are functional copies/adaptations: browser integration was rewritten for the native API, and differences and missing features are documented below.

See [EXAMPLES.md](docs/EXAMPLES.md) for the source-to-copy table, Markdown usage, WIP scope and verification limits. Source license: [examples/LICENSE.upstream.txt](examples/LICENSE.upstream.txt). Bundled marked v17.0.4 retains its original copyright headers and [license](examples/JS_Lib/marked/LICENSE.md).
