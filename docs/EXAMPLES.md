# Examples and upstream copy/adaptation

**The new EXAMPLES `200–221` are copies of the EXAMPLES `000–021` set from [GitHub](https://github.com/ioa747/NetWebView2Lib/tree/main/examples), adapted for the native `WebView2.au3` UDF.** The upstream set is by ioa747; the corresponding names and numbers are retained. These are functional copies/adaptations: browser integration was rewritten for the native API, and differences and missing features are documented below.

Source snapshot: local `NetWebView2Lib-main/examples` supplied by the user. Source links use GitHub `main` and can change independently of this local snapshot. This project does not require the source project runtime. The upstream MIT license is preserved in `examples/LICENSE.upstream.txt`.

## Standalone mini projects

### Window layout and interactive checks

Runnable examples open maximized within the Windows work area, retaining the title bar, minimize control and visible taskbar. Examples 200–218 and 220–221 maximize before showing their main windows, avoiding a visible resize during startup. These adaptations and examples 024–034 use a three-panel layout where it supports an interactive test: the native AutoIt operation log is on the left, WebView2 remains on the right, and a yellow guide below the view lists actions, expected results and the mechanism being demonstrated. The log appends new entries at the bottom and scrolls to the newest one. Example 034 places its yellow guide inside the page beneath its iframe; the other adapted examples use a native read-only guide control.

Examples 001–023 and 219 retain their established browser, tab or Markdown-focused layouts, while their main windows open maximized. `219-mdMsgBox.au3` is a reusable modal dialog, and `219-mdMsgBox_Example.au3` invokes it; the modal dialog retains its fixed message-box layout. Automated `--smoke` paths retain their existing behavior. The new visual layout has not been manually verified across all examples.

Each runnable example in `200–221` is a standalone mini project with its own window, initialization, controllers, event handling, actions, and cleanup. There is no shared `_ExampleSupport.au3` or mode switch that runs all examples. The scripts include `../WebView2.au3` and standard AutoIt UDFs directly.

Each `assets/native/NNN.html` page belongs to its corresponding example; `209-Auditor.au3` also has `assets/native/audit.js`. Both `204` variants use their own `204.html` page. The `219` family keeps local Markdown assets and the marked library. `219-mdMsgBox_Example.au3` includes `219-mdMsgBox.au3`, as in the upstream pair. That file is the Markdown message-box library, not a shared support module for the other examples.

Ordinary examples have separate profiles under `%LocalAppData%\WebView2.au3\Examples\<example-name>`. When moving a mini project, take its `.au3` file and assigned assets, and adjust the path to your own UDF and loader installation.

Examples 001–022 and 025 now also select individual profiles under this directory. Their embedded views are sized from the maximized window's current client area at creation and updated on resize or restore; tab examples resize the tab bar and every live WebView2 tab. This keeps example profiles away from the portable AutoIt executable directory.

## Source → local copy

| GitHub source example | Local copy/adaptation | Status and scope |
| --- | --- | --- |
| [000-NetJson.Parser.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/000-NetJson.Parser.au3) | [200-NetJson.Parser.au3](../examples/200-NetJson.Parser.au3) | Ready for manual verification — JSON parse/stringify, paths, set/delete, flatten; browser-native JSON instead of a managed parser. Advanced JSONPath filters are not ported. |
| [001-BasicDemo.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/001-BasicDemo.au3) | [201-BasicDemo.au3](../examples/201-BasicDemo.au3) | Ready for manual verification — Native ↔ web messages and editable Unicode text. |
| [002-Html_Gui.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/002-Html_Gui.au3) | [202-Html_Gui.au3](../examples/202-Html_Gui.au3) | Ready for manual verification — HTML form validation and sending fields to AutoIt. |
| [003-Multi-Basic.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/003-Multi-Basic.au3) | [203-Multi-Basic.au3](../examples/203-Multi-Basic.au3) | Ready for manual verification — Two independent WebView2 controllers in one window; the upstream separate-window arrangement is adapted to two panes. |
| [004-FileViewerDemo.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/004-FileViewerDemo.au3) | [204-FileViewerDemo.au3](../examples/204-FileViewerDemo.au3) | Ready for manual verification — Local PDF/image/HTML viewer. The Loop variant cycles files of the selected extension every three seconds. |
| [004-FileViewerDemo_Loop.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/004-FileViewerDemo_Loop.au3) | [204-FileViewerDemo_Loop.au3](../examples/204-FileViewerDemo_Loop.au3) | Ready for manual verification — Local PDF/image/HTML viewer. The Loop variant cycles files of the selected extension every three seconds. |
| [005-SaveDemo.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/005-SaveDemo.au3) | [205-SaveDemo.au3](../examples/205-SaveDemo.au3) | Ready for manual verification — HTML/PDF/MHTML export; PDF/MHTML Binary and PNG Binary covered by the x86 smoke test. |
| [006-DownloadDemo.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/006-DownloadDemo.au3) | [206-DownloadDemo.au3](../examples/206-DownloadDemo.au3) | Interactive controls download the [GitHub main-branch ZIP](https://codeload.github.com/mlipok/WebView2.au3-NativeAutoIt3-UDF/zip/refs/heads/main) to Documents, deny it, defer destination selection, pause, resume or cancel it. Native progress and state are displayed. This path needs internet access. Offline `--smoke`, `--smoke-deny`, `--smoke-cancel`, `--smoke-defer`, `--smoke-defer-cancel` and `--smoke-pause` modes exercise a local generated file; `--smoke-remote` checks ZIP download and signature online. |
| [007-HTTP_StatusCodeTracking.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/007-HTTP_StatusCodeTracking.au3) | [207-HTTP_StatusCodeTracking.au3](../examples/207-HTTP_StatusCodeTracking.au3) | Native `WebResourceResponseReceived` callback reports method, URL, status code and reason for mapped local HTML, CSS and JavaScript. The local smoke test needs no Internet or CORS-dependent fetch. Enter an external URL to inspect other status codes when online. |
| [008-JavaScript.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/008-JavaScript.au3) | [208-JavaScript.au3](../examples/208-JavaScript.au3) | Ready for manual verification — console.log/warn/error redirected to AutoIt through web messages. |
| [009-Auditor.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/009-Auditor.au3) | [209-Auditor.au3](../examples/209-Auditor.au3) | Ready for manual verification — DOM audit (title/headings/links/image alt), dark CSS and heading outlines. Upstream ad-block/pop-up/CSV audit controls are not all ported. |
| [010-NavigationBar.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/010-NavigationBar.au3) | [210-NavigationBar.au3](../examples/210-NavigationBar.au3) | Ready for manual verification — Native address/back/forward/reload/stop toolbar; local-file opening, zoom buttons and DevTools. The zoom buttons track their own requested factor; Ctrl+wheel changes are not read back. |
| [011-TwinWebView.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/011-TwinWebView.au3) | [211-TwinWebView.au3](../examples/211-TwinWebView.au3) | Ready for manual verification — Twin controllers and selection messages; selection search navigates the left panel. The upstream extension picker and domain-restricted search are not ported. |
| [012-GetCookies.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/012-GetCookies.au3) | [212-GetCookies.au3](../examples/212-GetCookies.au3) | Ready for manual verification — CDP cookie list, save and restore in an isolated example profile. JSON contains session data. |
| [013-jsonTree.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/013-jsonTree.au3) | [213-jsonTree.au3](../examples/213-jsonTree.au3) | Ready for manual verification — Expandable native-JavaScript JSON tree, editing input, search and sorting-independent tree rendering. |
| [014-pdfJS-Static_PDF_Viewer.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/014-pdfJS-Static_PDF_Viewer.au3) | [214-pdfJS-Static_PDF_Viewer.au3](../examples/214-pdfJS-Static_PDF_Viewer.au3) | PDF.js viewer and worker are bundled and local PDFs are routed through PDF.js. The user confirmed PDF display in a running WebView2 session on 2026-11-13. The upstream extraction and selection/link-lock demonstrations are not included. |
| [015-CSV_Viewer.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/015-CSV_Viewer.au3) | [215-CSV_Viewer.au3](../examples/215-CSV_Viewer.au3) | Ready for manual verification — CSV parser with quoted commas/quotes/newlines; read-only table and column sorting. |
| [016-CSV_Editor.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/016-CSV_Editor.au3) | [216-CSV_Editor.au3](../examples/216-CSV_Editor.au3) | Ready for manual verification — CSV editing, sorting, add/remove row and UTF-8 save. |
| [017-MappedFolder.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/017-MappedFolder.au3) | [217-MappedFolder.au3](../examples/217-MappedFolder.au3) | Maps a local folder to `https://udf-virtual-host.example/`, loads HTML, CSS and JavaScript, and can remap the host to a selected file's folder. |
| [018-BasicFramesDemo.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/018-BasicFramesDemo.au3) | [218-BasicFramesDemo.au3](../examples/218-BasicFramesDemo.au3) | Ready for manual verification — Two same-origin frames, CDP frame tree/names and frame HTML. |
| [019-MarkdownViewer.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/019-MarkdownViewer.au3) | [219-MarkdownViewer.au3](../examples/219-MarkdownViewer.au3) | Ready for manual verification — Live Markdown editor/preview; see the detailed section below. |
| [019-mdMsgBox.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/019-mdMsgBox.au3) | [219-mdMsgBox.au3](../examples/219-mdMsgBox.au3) | Ready for manual verification — Markdown message-box helper; explicit AutoIt parameters replace the upstream command-line flags. Upstream colors, DPI/options and Font Awesome helpers are not ported. |
| [019-mdMsgBox_Example.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/019-mdMsgBox_Example.au3) | [219-mdMsgBox_Example.au3](../examples/219-mdMsgBox_Example.au3) | Ready for manual verification — Caller example: native buttons and an automatic timeout; uses the local message-box helper. |
| [020-NavigationInterception.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/020-NavigationInterception.au3) | [220-NavigationInterception.au3](../examples/220-NavigationInterception.au3) | Ready for manual verification — Cancel external user HTTP navigation and queue opening in the default browser; allow local navigation. |
| [021-ModernSidebarUI.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/021-ModernSidebarUI.au3) | [221-ModernSidebarUI.au3](../examples/221-ModernSidebarUI.au3) | Ready for manual verification — HTML sidebar buttons send selection to the native status control. |

`#WIP - Work in Progress` is written as an AutoIt comment (`; #WIP - Work in Progress`) at the top of incomplete scripts; a bare `#WIP` is not a valid AutoIt directive.

[Example 217](../examples/217-MappedFolder.au3) maps `examples/assets/native/` to the shared virtual HTTPS host and opens `217.html`. Its relative stylesheet, script and second HTML page load through the same mapping. **Open mapped file** selects a local file, remaps that file's parent folder to the host and navigates to the encoded filename; **Local page** restores the bundled folder. The selected folder becomes available to pages running at that host, so choose trusted content. No local server or Internet access is required for bundled files. Run with `--smoke` for the bundled page's origin, CSS, JavaScript and message checks.

The bundled-page `--smoke` check passed with x86 and x64 AutoIt. Those runs do not exercise the file-selection dialog or a user-selected folder.

## 219-MarkdownViewer.au3

Run `examples/219-MarkdownViewer.au3` with AutoIt x86 or x64. The matching loader must be present under `bin/x86` or `bin/x64`; an installed WebView2 Runtime is also required. Keep `assets/markdown/` and `JS_Lib/marked/` beside the example. The marked parser is bundled locally; no network download is needed to render Markdown. Remote links or images can still use the network.

- New/open/save/save-as; open/save dialogs start in Documents. A Markdown path can be passed as the first command-line argument.
- Native text editor and live preview; updates are debounced for 250 ms and replace preview content without navigating again. The preview builds an always-expanded contents tree from Markdown headings; selecting a heading scrolls to it. The bundled `assets/markdown/sample.md` supplies the initial document and demonstrates nested sections.
- Drag the splitter, choose editor/both/preview mode, adjust editor font and preview zoom. The toolbar wraps in a narrow window.
- Bold/italic/underline/code/list formatting and copying rendered HTML to the clipboard.
- Relative images use the opened Markdown file's folder. The preview shell is written to a per-process temporary folder to provide a local-file origin.
- PDF and MHTML export use explicit buttons and save dialogs. Dirty documents prompt before new/open/close.
- Script/event-handler HTML is removed before previewing; external HTTP links are queued outside callbacks and opened in the default browser. This is an example sanitizer, not a general HTML security library.

The example profile is `%LocalAppData%\WebView2.au3\MarkdownViewer`. Smoke tests use a unique profile under `%TEMP%`, export only to their per-process temporary directory and do not clear the user's Edge cookies. Temporary test directories remain available for inspection.

## Verification boundary (2026-09-29)

The Markdown viewer passed x86 and x64 runtime checks for Markdown/Unicode, selection wrapping, save/read-back, relative PNG images, window bounds/zoom and PDF/MHTML Binary/file output. The initial prototype set of 24 runnable copies, before extraction into standalone mini projects, passed x86 startup, local page checks and web messaging. This includes startup of the four WIP demonstrations; it does **not** verify their missing features. `219-mdMsgBox.au3` is an include helper and is exercised by its caller example.

Subsequent changes hardened JSON decoding and added native button-event/DOM-text regression checks. Final GUI reruns after extraction into standalone mini projects and the complete new-set x64 run remain pending. Do not treat those final paths as runtime-verified. Pure JSON regression checks and static validation results are recorded in [STATIC_VALIDATION.txt](../STATIC_VALIDATION.txt). No automated extension installation/removal was attempted.

Use `--smoke` as the first argument for the runnable copies to repeat their automated checks in a normal Windows session. Run `tools/Smoke-JsonStrings.au3` for the JSON regression without opening a GUI.

## Existing examples: three-digit names

- `01_Basic.au3` → [`001_Basic.au3`](../examples/001_Basic.au3); existing behavior retained.
- `02_Events_JavaScript.au3` → [`002_Events_JavaScript.au3`](../examples/002_Events_JavaScript.au3); existing behavior retained.
- `03_MultiInstance.au3` → [`003_MultiInstance.au3`](../examples/003_MultiInstance.au3); existing behavior retained.
- `04_Settings.au3` → [`004_Settings.au3`](../examples/004_Settings.au3); existing behavior retained.
- `05_Script_Result.au3` → [`005_Script_Result.au3`](../examples/005_Script_Result.au3); existing behavior retained.
- `06_CSS_Injection.au3` → [`006_CSS_Injection.au3`](../examples/006_CSS_Injection.au3); existing behavior retained.
- `07_Content_Selection.au3` → [`007_Content_Selection.au3`](../examples/007_Content_Selection.au3); existing behavior retained.
- `08_Browser_Navigation.au3` → [`008_Browser_Navigation.au3`](../examples/008_Browser_Navigation.au3); existing behavior retained.
- `09_Kiosk_Lock.au3` → [`009_Kiosk_Lock.au3`](../examples/009_Kiosk_Lock.au3); existing behavior retained.
- `10_Zoom_Print_Focus.au3` → [`010_Zoom_Print_Focus.au3`](../examples/010_Zoom_Print_Focus.au3); existing behavior retained.
- `11_DOM_Automation.au3` → [`011_DOM_Automation.au3`](../examples/011_DOM_Automation.au3); existing behavior retained.
- [`030_XPathElements.au3`](../examples/030_XPathElements.au3) extends the DOM automation examples with XPath locators. It answers the [AutoIt Forum question](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/#findComment-1555698) using a local form with sample values. The AutoIt **Find and fill by XPath** button finds and fills two fields, leaving the result at `Waiting...`. The page's **Show values** button then displays the filled values. No real login or network request is involved. The `--smoke` option passed under x86 and x64 AutoIt and verified both stages and cleanup. Visible button interaction still requires manual GUI verification. This uses an existing UDF feature; no DOM API change is needed.
- [`031_PermissionRequests.au3`](../examples/031_PermissionRequests.au3) shows DENY and ALLOW buttons for geolocation at an exact mapped HTTPS origin. Its callback leaves both decisions out of the profile, so the buttons work in either order.
- `12_Wait_Storage.au3` → [`012_Wait_Storage.au3`](../examples/012_Wait_Storage.au3); existing behavior retained.
- `13_Select_Table.au3` → [`013_Select_Table.au3`](../examples/013_Select_Table.au3); existing behavior retained.
- `14_Advanced_CDP.au3` → [`014_Advanced_CDP.au3`](../examples/014_Advanced_CDP.au3); existing behavior retained.
- `15_Cookies.au3` → [`015_Cookies.au3`](../examples/015_Cookies.au3); existing behavior retained.
- `16_Export_PDF_MHTML.au3` → [`016_Export_PDF_MHTML.au3`](../examples/016_Export_PDF_MHTML.au3); existing behavior retained.
- `17_Frames.au3` → [`017_Frames.au3`](../examples/017_Frames.au3); existing behavior retained.
- `18_AdBlock.au3` → [`018_AdBlock.au3`](../examples/018_AdBlock.au3); existing behavior retained.
- `19_Extensions.au3` → [`019_Extensions.au3`](../examples/019_Extensions.au3); existing behavior retained.
- `20_IE_Compatibility.au3` → [`020_IE_Compatibility.au3`](../examples/020_IE_Compatibility.au3); existing behavior retained.
- `21_Folder_PDF_SlideShow.au3` → [`021_Folder_PDF_SlideShow.au3`](../examples/021_Folder_PDF_SlideShow.au3); existing behavior retained.
- `22_Tabs.au3` → [`022_Tabs.au3`](../examples/022_Tabs.au3); existing behavior retained.
- [`023_NewWindowTabs.au3`](../examples/023_NewWindowTabs.au3) defers `target="_blank"` and `window.open`, creates a fresh app-managed tab outside the native callback, and hands its controller to WebView2 before navigation. The `--smoke` mode verifies `window.opener` and the source `WindowProxy` under x86 and x64 without using the internet.

## 024_BlazorCalendar.au3

[Example 024](../examples/024_BlazorCalendar.au3) is a standalone native AutoIt host for a locally published Blazor WebAssembly calendar. It is separate from the 200–221 GitHub example adaptations. The calendar library is vendored under its MIT license from [tossnet/Blazor-Calendar](https://github.com/tossnet/Blazor-Calendar). The [example guide](../examples/024_BlazorCalendar/README.md) contains the build/run steps, JSON protocol, time-zone rules, and live test evidence. Pass `--smoke` to check local WebAssembly readiness and the sample JSON acknowledgment. The example does not access a database or remote API.

Examples 024, 026–028, 031–033 and 206 use `https://udf-virtual-host.example/` as their local virtual origin. Each example maps its own folder and uses a separate WebView2 profile, so running one example does not expose another example's files or saved origin state.

## 025_AudioState.au3

[Example 025](../examples/025_AudioState.au3) is a self-contained native audio and mute-state demo inspired by [Gianni's question on the AutoIt Forum](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/#findComment-1555567). Run it with AutoIt and the matching x86 or x64 WebView2Loader.dll available through the normal UDF loader search. The HTML and Web Audio oscillator are embedded in the `.au3` file; no network connection or additional assets are needed.

- Click **Start tone** inside WebView2. This page gesture starts the oscillator and the `Audio` label changes to `playing` through `$WEBVIEW2_EVENT_DOCUMENT_PLAYING_AUDIO_CHANGED`.
- Click the native **Mute** and **Unmute** buttons. They call `_WebView2_SetIsMuted()`; `$WEBVIEW2_EVENT_MUTED_CHANGED` updates the `Mute` label. Muting does not stop the oscillator, so the `Audio` label can still show `playing`.
- Click **Read state** to query `_WebView2_GetIsDocumentPlayingAudio()` and `_WebView2_GetIsMuted()` directly. Click **Stop tone** in WebView2 to stop playback. Closing the window releases the event subscriptions and WebView2 instance.

## 026_VirtualHostMapping.au3

[Example 026](../examples/026_VirtualHostMapping.au3) is a standalone demonstration of `_WebView2_SetVirtualHostNameToFolderMapping()`. Keep the `026_VirtualHostMapping` folder beside the `.au3` file and run the script with AutoIt. It maps that folder to `https://udf-virtual-host.example/`, then loads `index.html`, `site.css` and `site.js` through WebView2. The status label reports the page's ready message; clicking **Send a message to AutoIt** reports a second message. **Reload local page** repeats navigation, and the embedded view resizes with the AutoIt window. No local HTTP server or Internet connection is needed. Pass `--smoke` to exit automatically after the page sends its ready message, or after a 15-second timeout. The exact example passed x86 and x64 AutoIt smoke runs: its mapped page loaded the local JavaScript, confirmed the stylesheet was present, sent its ready message, and cleaned up. Button interaction and visual resize still require a direct GUI run.

## 027_NativeFrames.au3

[Example 027](../examples/027_NativeFrames.au3) tracks a native iframe, receives its ready message, sends JSON to it, executes a script in its context, and attaches a COM host object for one allowed origin. Keep the `027_NativeFrames` folder beside the script. Run with AutoIt and use **Send JSON to frame** and **Run frame script**. The `--smoke` option exits when the iframe reports readiness or after 10 seconds. The host-object handshake and visible controls require runtime verification.

## 028_NestedFrames.au3

[Example 028](../examples/028_NestedFrames.au3) opens maximized within the desktop work area, keeping the title bar and taskbar visible, and displays 15 nested iframes in four levels: 1 + 2 + 6 + 6. Each third-level frame contains one fourth-level frame, so the example has no extra off-screen siblings. Keep the `028_NestedFrames` folder beside the script. The local pages are mapped to `https://udf-virtual-host.example/`; no network connection is needed. **List all frames** writes the CDP frame tree, zero-based child paths, UDF tracked IDs, native `FrameId` values, parent IDs and names to the console. The example also counts native frame navigation start/completion callbacks. **Update next frame label** lists native frames, selects the first unchanged label by frame name and adds `_v2` through that frame's script context; each click changes one label. **Update FRAME_0_1_1 to v3** locates the name in the CDP tree and native frame list, then adds `_v3` to that frame if missing. Each update button darkens and becomes unavailable while its action runs, then returns to its normal state. UDF IDs are distinct from child indexes. The `--smoke` mode checks all 15 native frames and their parent hierarchy, the two update flows, frame navigation callbacks and a native ID; visible rendering and resize still require a GUI run.

## 029_DarkAppearance.au3

[Example 029](../examples/029_DarkAppearance.au3), inspired by the [AutoIt Forum appearance discussion](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/#findComment-1555696), compares a page that responds to `prefers-color-scheme` with fixed light content. **Prefer light** and **Prefer dark** use the existing CDP `Emulation.setEmulatedMedia` method. **Force dark** and **Stop forcing** toggle the experimental `Emulation.setAutoDarkModeOverride` method. The HTML is embedded in the AutoIt script, so the example needs no Internet connection or extra assets. Pass `--smoke` to verify that the page observes both preferred schemes and that the automatic-darkening CDP calls complete. The smoke run passed under x86 and x64 AutoIt with successful cleanup. Visual quality and button interaction still require a manual GUI check. This example demonstrates existing UDF capabilities and does not add a native color-scheme API. Automatic darkening may produce poor colors on some pages.

## 031_PermissionRequests.au3

[Example 031](../examples/031_PermissionRequests.au3) loads [its local page](../examples/031_PermissionRequests/index.html) through a virtual HTTPS host. Click **Deny geolocation** or **Allow geolocation**. AutoIt checks the exact requesting origin and permission kind, then returns `[DENY, False]` or `[ALLOW, False]` so the Runtime does not save the decision. The page reports refusal, a location-provider error, or latitude, longitude and reported accuracy when coordinates are available. `--smoke` exercised DENY followed by ALLOW under x86 and x64 AutoIt and confirmed two separate native callbacks. On this computer the host allowed the second request, but the location provider returned an error; the test does not establish that coordinates can be obtained. The example uses a temporary profile to isolate it from earlier permissions. The visible two-button interaction has not been checked manually.

## 032_NativeExtensions.au3

[Example 032](../examples/032_NativeExtensions.au3) installs the unpacked local extension in [032-extension](../examples/assets/native/032-extension/manifest.json), lists the profile's extensions and enables, disables or removes only the sample extension. The controls are ordered **List**, **Remove**, **Install sample**, **Disable**, **Enable**, **Reload page**; their colors distinguish listing (yellow), installation/enabling (green), removal/disabling (red), and reloading (blue). The resizable window opens at 700 x 370, matching the compact page content. It maps the local page to `https://udf-virtual-host.example/`; the manifest content-script match uses the same origin. The native AutoIt label reports the profile extension state; the WebView2 page contains no duplicate status banner. Installing, enabling, disabling or removing the extension does not reload the page. The top status says **RELOAD to take effect**; click **Reload page** to apply the content-script change to the current document. The only element changed inside WebView2 is a framed message: it uses larger, bold text and a white interior on load, and the active extension's content script changes its text and interior to light pastel blue when it runs after reload. The example uses a persistent profile so extension and enabled state can be checked after restarting. WebView2 removes an installed unpacked extension when its folder content changes; after updating these example assets, click **Install sample** again and then **Reload page** ([Microsoft API reference](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2profile7#addbrowserextension)). Enable the native option before `_WebView2_Init()`. Targeted x86/x64 runs confirmed native add/list/enable/disable/remove and persistent enabled state. An isolated x64 run confirmed that disabling changes the AutoIt status immediately, requests a reload, and prevents the content script from running after reloading. The full visible button sequence has not been checked manually under both architectures.

## 033_AdvancedFrameAPIs.au3

[Example 033](../examples/033_AdvancedFrameAPIs.au3) uses the local `033_AdvancedFrameAPIs` pages through a virtual HTTPS host. Start the script and click **Send read-only buffer to frame** to send UTF-8 bytes and JSON metadata directly to the iframe. The iframe reads them from `sharedbufferreceived` and reports the text back to AutoIt. Its **Request geolocation** button exercises an immediate frame-level deny policy without saving it to the profile. Its **Request screen capture** button exercises the frame-level cancellation callback. No external service is required; a separate temporary profile is used. Targeted `--smoke` runs passed in x86 and x64 for buffer delivery and geolocation denial. Screen-capture cancellation requires an interactive check.

## 034_FrameDedicatedWorker.au3

[Example 034](../examples/034_FrameDedicatedWorker.au3) demonstrates how an AutoIt host can track a **dedicated Web Worker created inside an iframe**, exchange JSON directly with it, and observe when it ends. A worker runs JavaScript separately from the page's main script context; it is neither another iframe nor another WebView2 instance.

The left-hand read-only Win32 EDIT control keeps a timestamped operation log and scrolls to the newest entry. A blank line and a `'<button>' was clicked` entry separate each manual action from the previous one. Beneath the blue iframe, a yellow information panel explains why sending after termination must fail and why the earlier `"sum":5` log entry is the evidence for the direct AutoIt-to-worker JSON channel.

Here, **iframe** means the `frame.html` page embedded in the main `index.html` page. The iframe's JavaScript creates the dedicated worker, owns it and exchanges messages with it through `postMessage()`. The worker has no visual rectangle or DOM of its own: "inside the iframe" describes who created and communicates with it, not another visible frame nested in the page. **Tracked** means the UDF has registered that iframe and assigned it a public frame ID, so AutoIt can associate the native worker-created notification with the correct iframe.

### What happens when you run it

1. AutoIt opens a resizable window, creates WebView2 with an isolated temporary profile, and maps the local `034_FrameDedicatedWorker` folder to `https://udf-virtual-host.example/`. The example needs no Internet or local HTTP server.
2. AutoIt registers frame-created, frame-message and worker-lifecycle callbacks, then loads `index.html`. That page contains one iframe, `frame.html`. The UDF tracks the iframe and gives it a public frame ID. When the iframe sends `ready`, AutoIt records that it can start a worker there.
3. Click **Create worker in iframe**. AutoIt calls `_WebView2_Frame_ExecuteScript()` for that particular frame to invoke `startWorker()`. The iframe creates `new Worker('worker.js')` and sends it `ping`. The worker replies to the iframe, which displays the reply. Independently, WebView2 raises `ICoreWebView2Frame8::DedicatedWorkerCreated`; the UDF assigns a worker ID and reports its owner frame ID and full script URI.
4. The worker sends a `ready` JSON message directly to AutoIt through `self.chrome.webview.postMessage()`. After AutoIt receives it, click **Send JSON to worker**. `_WebView2_Worker_PostWebMessageAsJson()` sends `{ "kind": "add", "requestId": 1, "values": [2, 3] }` directly to that worker, which replies with JSON containing `"sum": 5`. The native status label reports the result.
5. Click **Terminate worker**. AutoIt asks the iframe to terminate its own worker. The native `Destroying` callback invalidates the worker ID, removes its event subscriptions and reports the event. `_WebView2_Worker_List()` then returns no active workers, and another send to that ID fails. Closing the WebView2 instance also releases any remaining worker subscriptions without pretending that a native destruction event occurred.

### What changed in the UDF

The original three-argument `$WEBVIEW2_EVENT_FRAME_DEDICATED_WORKER_CREATED` callback remains compatible. New worker-created, JSON-message and destroying callbacks expose a separate public worker ID and retain its native interface only while it is active. The UDF subscribes through `ICoreWebView2Frame8` when the Runtime supports it, including for frames that were already tracked when callbacks were registered. The worker registry and subscriptions are cleaned up when the worker, frame or instance ends. Register before worker creation; earlier workers are not enumerated. Workers started by the top-level page are outside this example and API.

Use `--smoke` to create one worker, confirm that the active-worker list contains its ID, send JSON after its ready message, confirm its reply and native destruction, and verify that its ID becomes invalid. `--smoke-late` registers the callbacks after the iframe is already tracked. Both modes exit on completion or a 15-second timeout. Targeted `--smoke` runs passed under AutoIt x86 and x64, and `--smoke-late` passed under x64. The visible button sequence and resize behavior were not checked interactively. See [STATIC_VALIDATION.txt](../STATIC_VALIDATION.txt) for the detailed validation record.
