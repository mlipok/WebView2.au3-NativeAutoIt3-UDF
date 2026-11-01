# API comparison: WebView2.au3 vs NetWebView2Lib vs au3WebDriver vs IE.au3

This document maps useful functions and concepts from three established AutoIt browser-automation approaches to the native `WebView2.au3` UDF.

Sources reviewed:

- NetWebView2Lib: https://github.com/ioa747/NetWebView2Lib
- au3WebDriver: https://github.com/mlipok/au3WebDriver (`wd_core.au3`, `wd_helper.au3`)
- standard AutoIt `IE.au3`: https://www.autoitscript.com/autoit3/docs/libfunctions/IE%20Management.htm

## Status legend

| Status | Meaning |
| --- | --- |
| FULL | The WebView2 UDF provides the same practical capability. |
| PARTIAL | The main use-case is covered, but the object model, event model or edge cases differ. |
| N/A | The source function is specific to IE COM, an external WebDriver process, or the .NET bridge and should not be emulated. |
| MISSING | Useful capability not yet implemented natively. |

## NetWebView2Lib -> WebView2.au3

| NetWebView2Lib manager property/method | WebView2.au3 equivalent | Status | Notes |
| --- | --- | --- | --- |
| `Initialize` | `_WebView2_Init` + `_WebView2_Create` | FULL | Environment initialization and HWND-hosted control creation are intentionally separate. |
| `Cleanup` | `_WebView2_Destroy`, `_WebView2_Cleanup` | FULL | Supports per-instance destroy and global cleanup. |
| `Navigate` | `_WebView2_Navigate` | FULL | |
| `NavigateToString` | `_WebView2_NavigateToString` | FULL | |
| `Reload` | `_WebView2_Reload` | FULL | |
| `Stop` | `_WebView2_Stop` | FULL | |
| `GoBack` | `_WebView2_GoBack` | FULL | |
| `GoForward` | `_WebView2_GoForward` | FULL | |
| `GetCanGoBack` | `_WebView2_CanGoBack` | FULL | |
| `GetCanGoForward` | `_WebView2_CanGoForward` | FULL | |
| `GetSource` | `_WebView2_GetSource` | FULL | |
| `GetDocumentTitle` | `_WebView2_GetDocumentTitle` | FULL | |
| `Resize` | `_WebView2_SetBounds`, `_WebView2_ResizeToParent` | FULL | |
| `SetAutoResize` | `_WebView2_ResizeToParent` called on GUI resize | PARTIAL | No parent subclassing/smart-anchor layer. |
| `ZoomFactor`, `SetZoom`, `SetZoomFactor` | `_WebView2_SetZoomFactor` | FULL | |
| `ResetZoom` | `_WebView2_ResetZoom` | FULL | |
| `WebViewSetFocus` | `_WebView2_SetFocus` | FULL | |
| `GetBrowserProcessId` | `_WebView2_GetBrowserProcessId` | FULL | |
| `IsReady` | `_WebView2_IsReady` | FULL | |
| `ExecuteScript` / `ExecuteScriptOnPage` | `_WebView2_ExecuteScript` | PARTIAL | Current public helper waits for completion; fire-and-forget form is not exposed separately. |
| `ExecuteScriptWithResult` | `_WebView2_ExecuteScript` + DOM decode helpers | FULL | WebView2 core returns JSON-encoded result; DOM helpers decode common values. |
| `AddInitializationScript` | `_WebView2_AddInitializationScript` | FULL | |
| `RemoveInitializationScript` | `_WebView2_RemoveInitializationScript` | FULL | |
| `GetHtmlSource` | `_WebView2_GetHtmlSource`, `_WebView2_DocReadHTML` | FULL | |
| `GetSelectedText` | `_WebView2_GetSelectedText` | FULL | |
| `InjectCss` | `_WebView2_InjectCss` | FULL | |
| `ClearInjectedCss` | `_WebView2_ClearInjectedCss` | FULL | |
| `ToggleAuditHighlights` | `_WebView2_HighlightElements` | PARTIAL | Explicit element highlighting instead of manager-wide audit presets. |
| `LockWebView` | `_WebView2_LockWebView` | PARTIAL | Native/DOM restrictions; bridge-specific interception differs. |
| `UnLockWebView` | `_WebView2_UnlockWebView` | PARTIAL | |
| `DisableBrowserFeatures` | `_WebView2_LockWebView` | PARTIAL | |
| `AreDevToolsEnabled` | `_WebView2_SetDevToolsEnabled` | FULL | |
| `AreDefaultContextMenusEnabled` | `_WebView2_SetDefaultContextMenusEnabled` | FULL | |
| `AreDefaultScriptDialogsEnabled` | `_WebView2_SetDefaultScriptDialogsEnabled` | FULL | |
| `IsStatusBarEnabled` | `_WebView2_SetStatusBarEnabled` | FULL | |
| `AreHostObjectsAllowed` | `_WebView2_SetHostObjectsAllowed` | FULL | This UDF does not itself expose a .NET host-object bridge. |
| `SetScriptEnabled` | `_WebView2_SetScriptEnabled` | FULL | |
| `SetWebMessageEnabled` | `_WebView2_SetWebMessageEnabled` | FULL | |
| `OpenDevToolsWindow` | `_WebView2_OpenDevToolsWindow` | FULL | |
| `ShowPrintUI`, `Print` | `_WebView2_Print` | FULL | |
| `ExportToPdf` | `_WebView2_ExportToPdfFile` / `_WebView2_ExportToPdf` | FULL | File output. |
| `PrintToPdfStream` | `_WebView2_PrintToPdfStream`, `_WebView2_ExportToPdfBinary` | FULL | Base64 and decoded `Binary` forms are available. |
| `CapturePreview` | `_WebView2_CapturePreview` | FULL | File output. |
| `CapturePreviewAsBase64` | `_WebView2_CapturePreviewAsBase64` | FULL | |
| binary screenshot payload | `_WebView2_CapturePreviewBinary` | FULL | Returns AutoIt `Binary`. |
| MHTML snapshot | `_WebView2_CaptureSnapshot`, `_WebView2_ExportToMhtmlBinary`, `_WebView2_ExportToMhtmlFile` | FULL | Both Binary and file output. |
| `CallDevToolsProtocolMethod` | `_WebView2_CallDevToolsProtocolMethod` | FULL | Raw CDP JSON result. |
| `GetCookies` | `_WebView2_GetCookies` | FULL | Raw CDP JSON. |
| `AddCookie` | `_WebView2_AddCookie` | FULL | |
| `DeleteCookie` | `_WebView2_DeleteCookie` | FULL | |
| `DeleteAllCookies` | `_WebView2_DeleteAllCookies` | FULL | |
| `ClearBrowserData` | `_WebView2_ClearBrowserData` | PARTIAL | Clears cookies/cache and top-level storage; not every profile data kind. |
| `SetUserAgent` | `_WebView2_SetUserAgent` | FULL | CDP override. |
| `SetAdBlock` | `_WebView2_SetAdBlock` | FULL | URL-pattern blocking through CDP `Network.setBlockedURLs`. |
| `AddBlockRule` | `_WebView2_AddBlockRule` | FULL | |
| `ClearBlockRules` | `_WebView2_ClearBlockRules` | FULL | |
| `GetFrameCount` | `_WebView2_GetFrameCount` | FULL | |
| `GetFrameUrl(s)` | `_WebView2_GetFrameUrl`, `_WebView2_GetFrameUrls` | FULL | |
| `GetFrameName(s)` | `_WebView2_GetFrameName`, `_WebView2_GetFrameNames` | FULL | |
| `GetFrameHtmlSource` | `_WebView2_GetFrameHtmlSource` | PARTIAL | Same-origin DOM frames only; cross-origin metadata available with `_WebView2_GetFrameTree`. |
| `GetFrame`, `GetFrameById` | `_WebView2_GetFrames`, `_WebView2_GetFrameTree` | PARTIAL | Returns tokens/metadata rather than a COM `WebView2Frame` wrapper. |
| frame `ExecuteScript*` | `_WebView2_GetFrameHtmlSource` plus CDP via `_WebView2_CallDevToolsProtocolMethod` | PARTIAL | No dedicated frame-object wrapper yet. |
| frame `PostWebMessage*` | none | MISSING | Candidate for native `ICoreWebView2Frame*` support. |
| `AddExtension` | `_WebView2_AddExtension` | PARTIAL | Runtime-dependent experimental CDP path in v0.4.0. Native `ICoreWebView2Profile7` is preferable long term. |
| `RemoveExtension` | `_WebView2_RemoveExtension` | PARTIAL | Same limitation. |
| extension enumeration | `_WebView2_GetExtensions` | PARTIAL | Same limitation. |
| `EncodeURI` / `DecodeURI` | `_WebView2_EncodeURI`, `_WebView2_DecodeURI` | FULL | |
| `EncodeB64` / `DecodeB64` | `_WebView2_EncodeBase64`, `_WebView2_DecodeBase64` | FULL | UTF-8 text. |
| `DecodeB64ToBinary` | internal `__WebView2_Base64_DecodeBinary` | PARTIAL | Used by public PDF/screenshot Binary APIs; standalone public utility is not exposed. |
| `BackColor` | none | MISSING | Candidate for `ICoreWebView2Controller2::DefaultBackgroundColor`. |
| `AreBrowserAcceleratorKeysEnabled` | none | MISSING | Candidate for newer `ICoreWebView2Settings*`. |
| `AreBrowserPopupsAllowed` | none | MISSING | Candidate for `NewWindowRequested`. |
| `AdditionalBrowserArguments` | none | MISSING | Must be supplied at environment creation through options. |
| `SetVirtualHostNameToFolderMapping` | `_WebView2_SetVirtualHostNameToFolderMapping` | IMPLEMENTED | Native `ICoreWebView2_3`; x86 and x64 mapping smoke tests passed. |
| `IsDocumentPlayingAudio` / `IsDocumentPlayingAudioChanged` | `_WebView2_GetIsDocumentPlayingAudio` / `$WEBVIEW2_EVENT_DOCUMENT_PLAYING_AUDIO_CHANGED` | IMPLEMENTED | Native `ICoreWebView2_8`; verified x86/x64 start and stop transitions. |
| `SetMuted` / `IsMuted` | none | MISSING | Mute control is separate from document-audio activity. |
| JSON parser/bind/sync methods | none | N/A | These are utility/parser features of the .NET bridge, not WebView2 hosting functionality. |

## au3WebDriver -> WebView2.au3

`au3WebDriver` controls an external browser through the W3C WebDriver protocol. `WebView2.au3` hosts the browser engine inside the AutoIt GUI, so session/transport functions intentionally do not have equivalents.

| au3WebDriver function/concept | WebView2.au3 equivalent | Status |
| --- | --- | --- |
| `_WD_Startup`, `_WD_Shutdown` | `_WebView2_Init`, `_WebView2_Cleanup` | PARTIAL |
| `_WD_CreateSession`, `_WD_DeleteSession` | `_WebView2_Create`, `_WebView2_Destroy` | PARTIAL |
| `_WD_Navigate` | `_WebView2_Navigate` | FULL |
| Back / Forward / Refresh | `_WebView2_GoBack`, `_WebView2_GoForward`, `_WebView2_Reload` | FULL |
| `_WD_ExecuteScript` | `_WebView2_ExecuteScript` | FULL |
| `_WD_FindElement` | `_WebView2_FindElement` | FULL |
| `_WD_FindElements` | `_WebView2_FindElements` | FULL |
| `_WD_ElementAction` | `_WebView2_ElementAction`, `_WebView2_ElementActionEx` | FULL for DOM actions |
| `_WD_GetElementById` helper pattern | `_WebView2_GetElementById` | FULL |
| `_WD_GetElementByName` helper pattern | `_WebView2_GetElementByName` | FULL |
| regex element lookup | `_WebView2_GetElementByRegEx` | FULL |
| element from point | `_WebView2_GetElementFromPoint` | FULL |
| set value | `_WebView2_SetElementValue` | FULL |
| element style | `_WebView2_ElementStyle` | FULL |
| dispatch DOM event | `_WebView2_DispatchEvent` | FULL |
| select/option helpers | `_WebView2_ElementSelectAction`, `_WebView2_ElementOptionSelect` | FULL |
| highlight element(s) | `_WebView2_HighlightElements` | FULL |
| click link by text | `_WebView2_LinkClickByText` | FULL |
| load wait | `_WebView2_LoadWait` | FULL |
| wait for element | `_WebView2_WaitElement` | FULL |
| wait for script condition | `_WebView2_WaitScript` | FULL |
| local/session storage | `_WebView2_Storage` | FULL |
| devicePixelRatio | `_WebView2_GetDevicePixelRatio` | FULL |
| frame count | `_WebView2_GetFrameCount` | FULL |
| fullscreen state | `_WebView2_IsFullScreen` | FULL |
| table extraction | `_WebView2_GetTable` | FULL |
| screenshot | `_WebView2_CapturePreview`, `_WebView2_CapturePreviewBinary` | FULL |
| cookies | `_WebView2_GetCookies`, `_WebView2_AddCookie`, `_WebView2_DeleteCookie`, `_WebView2_DeleteAllCookies` | FULL for common operations |
| CDP command | `_WebView2_CallDevToolsProtocolMethod` | FULL |
| frame switching / remote frame context | `_WebView2_GetFrames`, `_WebView2_GetFrameTree` | PARTIAL |
| external browser window handles/tabs | none | N/A |
| driver executable / ports / HTTP transport | none | N/A |
| capabilities / driver matching | none | N/A |
| WebDriver Actions JSON / remote input sources | DOM actions only | PARTIAL |

## Standard AutoIt IE.au3 -> WebView2.au3

The official `IE.au3` UDF exposes Internet Explorer COM objects. `WebView2.au3` deliberately returns integer WebView instance IDs and opaque DOM element tokens instead of legacy COM document/element objects.

| IE.au3 | WebView2.au3 | Status | Notes |
| --- | --- | --- | --- |
| `_IEAction` | `_WebView2_Action`, `_WebView2_ElementAction` | PARTIAL | Common element actions supported; browser-wide clipboard/edit commands are not emulated. |
| `_IEAttach` | none | N/A | WebView2 instances are created/owned by the host process. |
| `_IEBodyReadHTML` | `_WebView2_BodyReadHTML`, `_WebView2_GetBodyHTML` | FULL | |
| `_IEBodyReadText` | `_WebView2_BodyReadText`, `_WebView2_GetBodyText` | FULL | |
| `_IEBodyWriteHTML` | `_WebView2_BodyWriteHTML`, `_WebView2_SetBodyHTML` | FULL | |
| `_IECreate` | `_WebView2_Init` + `_WebView2_Create` + `_WebView2_Navigate` | PARTIAL | Embedded host model rather than separate IE window. |
| `_IECreateEmbedded` | `_WebView2_Create` | FULL for embedded use | Requires parent HWND, not `GUICtrlCreateObj`. |
| `_IEDocGetObj` | none | N/A | No legacy DOM COM object is exposed. |
| `_IEDocInsertHTML` | `_WebView2_InsertHTML` | FULL | |
| `_IEDocInsertText` | `_WebView2_InsertText` | FULL | |
| `_IEDocReadHTML` | `_WebView2_DocReadHTML`, `_WebView2_GetHtmlSource` | FULL | |
| `_IEDocWriteHTML` | `_WebView2_DocWriteHTML`, `_WebView2_NavigateToString` | FULL | |
| `_IEErrorNotify` | `_WebView2_Error_GetDescription`, tracing | PARTIAL | Explicit diagnostics rather than a global IE notification mode. |
| `_IEFormElementCheckBoxSelect` | `_WebView2_FormElementCheckBoxSelect` | FULL | |
| `_IEFormElementGetCollection` | `_WebView2_FormElementGetCollection`, `_WebView2_FormGetElements` | FULL | Returns AutoIt array/tokens. |
| `_IEFormElementGetObjByName` | `_WebView2_FormElementGetByName` | FULL | Returns token instead of COM object. |
| `_IEFormElementGetValue` | `_WebView2_FormElementGetValue` | FULL | |
| `_IEFormElementOptionSelect` | `_WebView2_FormElementOptionSelect`, `_WebView2_ElementOptionSelect` | FULL | |
| `_IEFormElementRadioSelect` | `_WebView2_FormElementRadioSelect` | FULL | |
| `_IEFormElementSetValue` | `_WebView2_FormElementSetValue` | FULL | |
| `_IEFormGetCollection` | `_WebView2_FormGetCollection`, `_WebView2_GetForms` | FULL | |
| `_IEFormGetObjByName` | `_WebView2_GetFormByName` | FULL | |
| `_IEFormImageClick` | `_WebView2_ImageClick` | FULL | |
| `_IEFormReset` | `_WebView2_FormReset` | FULL | |
| `_IEFormSubmit` | `_WebView2_FormSubmit` | FULL | |
| `_IEFrameGetCollection` | `_WebView2_FrameGetCollection`, `_WebView2_GetFrames` | FULL for frame elements | |
| `_IEFrameGetObjByName` | `_WebView2_FrameGetByName`, `_WebView2_GetFrameByName` | FULL for frame element token | |
| `_IEGetObjById` | `_WebView2_GetElementById` | FULL | |
| `_IEGetObjByName` | `_WebView2_GetElementByName` | FULL | |
| `_IEHeadInsertEventScript` | `_WebView2_HeadInsertEventScript`, `_WebView2_AddEventScript` | FULL | |
| `_IEImgClick` | `_WebView2_ImageClick` | FULL | |
| `_IEImgGetCollection` | `_WebView2_ImgGetCollection`, `_WebView2_GetImages` | FULL | |
| `_IEIsFrameSet` | `_WebView2_IsFrameSet` | FULL | |
| `_IELinkClickByIndex` | `_WebView2_LinkClickByIndex` | FULL | |
| `_IELinkClickByText` | `_WebView2_LinkClickByText` | FULL | |
| `_IELinkGetCollection` | `_WebView2_LinkGetCollection`, `_WebView2_GetLinks` | FULL | |
| `_IELoadWait` | `_WebView2_LoadWait` | FULL | Timeout is a per-call parameter. |
| `_IELoadWaitTimeout` | `_WebView2_LoadWait(..., $iTimeoutMs)` | PARTIAL | No separate global timeout setting. |
| `_IENavigate` | `_WebView2_Navigate` | FULL | |
| `_IEPropertyGet` | `_WebView2_PropertyGet`, `_WebView2_GetProperty`, `_WebView2_ElementAction` | PARTIAL | DOM properties are covered; IE window chrome properties are not. |
| `_IEPropertySet` | `_WebView2_PropertySet`, `_WebView2_SetProperty` | PARTIAL | DOM properties are covered. |
| `_IEQuit` | `_WebView2_Destroy`, `_WebView2_Cleanup` | FULL | |
| `_IETableGetCollection` | `_WebView2_TableGetCollection`, `_WebView2_GetTables` | FULL | |
| `_IETableWriteToArray` | `_WebView2_TableWriteToArray`, `_WebView2_GetTable` | FULL | |
| `_IETagNameAllGetCollection` | `_WebView2_TagNameAllGetCollection`, `_WebView2_GetAllElements` | FULL | |
| `_IETagNameGetCollection` | `_WebView2_TagNameGetCollection`, `_WebView2_GetElementsByTagName` | FULL | |
| `_IE_Example`, `_IE_Introduction`, `_IE_VersionInfo` | repository examples, README, `VERSION` | N/A | Documentation/demo utilities rather than runtime browser operations. |

## v0.4.0 additions that do not have a direct IE.au3 equivalent

- raw CDP calls;
- cookies through Chromium network APIs;
- screenshot to Base64, Binary or file;
- PDF to Base64, Binary or file;
- MHTML to string, Binary or file;
- URL-pattern ad blocking;
- Chromium extension helpers (runtime-dependent experimental path);
- initialization scripts;
- frame tree metadata including cross-origin frames;
- URI/Base64 helpers.

## Migration principle

Do not mechanically rename `_IE*` calls. IE.au3 passes COM objects between functions; `WebView2.au3` passes an integer WebView instance ID plus opaque DOM element tokens. The mapping above identifies the equivalent operation, not binary-compatible signatures.
