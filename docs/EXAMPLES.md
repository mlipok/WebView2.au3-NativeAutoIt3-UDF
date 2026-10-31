# Examples and upstream copy/adaptation

**The new EXAMPLES `200–221` are copies of the EXAMPLES `000–021` set from [GitHub](https://github.com/ioa747/NetWebView2Lib/tree/main/examples), adapted for the native `WebView2.au3` UDF.** The upstream set is by ioa747; the corresponding names and numbers are retained. These are functional copies/adaptations: browser integration was rewritten for the native API, and differences and missing features are documented below.

Source snapshot: local `NetWebView2Lib-main/examples` supplied by the user. Source links use GitHub `main` and can change independently of this local snapshot. This project does not require the source project runtime. The upstream MIT license is preserved in `examples/LICENSE.upstream.txt`.

## Standalone mini projects

Each runnable example in `200–221` is a standalone mini project with its own window, initialization, controllers, event handling, actions, and cleanup. There is no shared `_ExampleSupport.au3` or mode switch that runs all examples. The scripts include `../WebView2.au3` and standard AutoIt UDFs directly.

Each `assets/native/NNN.html` page belongs to its corresponding example; `209-Auditor.au3` also has `assets/native/audit.js`. Both `204` variants use their own `204.html` page. The `219` family keeps local Markdown assets and the marked library. `219-mdMsgBox_Example.au3` includes `219-mdMsgBox.au3`, as in the upstream pair. That file is the Markdown message-box library, not a shared support module for the other examples.

Ordinary examples have separate profiles under `%LocalAppData%\WebView2.au3\Examples\<example-name>`. When moving a mini project, take its `.au3` file and assigned assets, and adjust the path to your own UDF and loader installation.

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
| [006-DownloadDemo.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/006-DownloadDemo.au3) | [206-DownloadDemo.au3](../examples/206-DownloadDemo.au3) | **WIP** — Default browser download demo; native progress, cancellation and download policy are missing. |
| [007-HTTP_StatusCodeTracking.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/007-HTTP_StatusCodeTracking.au3) | [207-HTTP_StatusCodeTracking.au3](../examples/207-HTTP_StatusCodeTracking.au3) | **WIP** — Fetch status demo subject to CORS; native document/resource HTTP response tracking is missing. |
| [008-JavaScript.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/008-JavaScript.au3) | [208-JavaScript.au3](../examples/208-JavaScript.au3) | Ready for manual verification — console.log/warn/error redirected to AutoIt through web messages. |
| [009-Auditor.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/009-Auditor.au3) | [209-Auditor.au3](../examples/209-Auditor.au3) | Ready for manual verification — DOM audit (title/headings/links/image alt), dark CSS and heading outlines. Upstream ad-block/pop-up/CSV audit controls are not all ported. |
| [010-NavigationBar.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/010-NavigationBar.au3) | [210-NavigationBar.au3](../examples/210-NavigationBar.au3) | Ready for manual verification — Native address/back/forward/reload/stop toolbar; local-file opening, zoom buttons and DevTools. The zoom buttons track their own requested factor; Ctrl+wheel changes are not read back. |
| [011-TwinWebView.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/011-TwinWebView.au3) | [211-TwinWebView.au3](../examples/211-TwinWebView.au3) | Ready for manual verification — Twin controllers and selection messages; selection search navigates the left panel. The upstream extension picker and domain-restricted search are not ported. |
| [012-GetCookies.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/012-GetCookies.au3) | [212-GetCookies.au3](../examples/212-GetCookies.au3) | Ready for manual verification — CDP cookie list, save and restore in an isolated example profile. JSON contains session data. |
| [013-jsonTree.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/013-jsonTree.au3) | [213-jsonTree.au3](../examples/213-jsonTree.au3) | Ready for manual verification — Expandable native-JavaScript JSON tree, editing input, search and sorting-independent tree rendering. |
| [014-pdfJS-Static_PDF_Viewer.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/014-pdfJS-Static_PDF_Viewer.au3) | [214-pdfJS-Static_PDF_Viewer.au3](../examples/214-pdfJS-Static_PDF_Viewer.au3) | **WIP** — PDF.js viewer and worker are bundled and local PDFs are routed through PDF.js. Runtime navigation failed in the current Windows session, so rendering remains unverified. The upstream extraction and selection/link-lock demonstrations are not included. |
| [015-CSV_Viewer.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/015-CSV_Viewer.au3) | [215-CSV_Viewer.au3](../examples/215-CSV_Viewer.au3) | Ready for manual verification — CSV parser with quoted commas/quotes/newlines; read-only table and column sorting. |
| [016-CSV_Editor.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/016-CSV_Editor.au3) | [216-CSV_Editor.au3](../examples/216-CSV_Editor.au3) | Ready for manual verification — CSV editing, sorting, add/remove row and UTF-8 save. |
| [017-MappedFolder.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/017-MappedFolder.au3) | [217-MappedFolder.au3](../examples/217-MappedFolder.au3) | **WIP** — WIP entry with working file:/// directory navigation; virtual-host mapping is now available in the UDF; this older example has not yet been adapted to it. |
| [018-BasicFramesDemo.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/018-BasicFramesDemo.au3) | [218-BasicFramesDemo.au3](../examples/218-BasicFramesDemo.au3) | Ready for manual verification — Two same-origin frames, CDP frame tree/names and frame HTML. |
| [019-MarkdownViewer.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/019-MarkdownViewer.au3) | [219-MarkdownViewer.au3](../examples/219-MarkdownViewer.au3) | Ready for manual verification — Live Markdown editor/preview; see the detailed section below. |
| [019-mdMsgBox.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/019-mdMsgBox.au3) | [219-mdMsgBox.au3](../examples/219-mdMsgBox.au3) | Ready for manual verification — Markdown message-box helper; explicit AutoIt parameters replace the upstream command-line flags. Upstream colors, DPI/options and Font Awesome helpers are not ported. |
| [019-mdMsgBox_Example.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/019-mdMsgBox_Example.au3) | [219-mdMsgBox_Example.au3](../examples/219-mdMsgBox_Example.au3) | Ready for manual verification — Caller example: native buttons and an automatic timeout; uses the local message-box helper. |
| [020-NavigationInterception.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/020-NavigationInterception.au3) | [220-NavigationInterception.au3](../examples/220-NavigationInterception.au3) | Ready for manual verification — Cancel external user HTTP navigation and queue opening in the default browser; allow local navigation. |
| [021-ModernSidebarUI.au3](https://github.com/ioa747/NetWebView2Lib/blob/main/examples/021-ModernSidebarUI.au3) | [221-ModernSidebarUI.au3](../examples/221-ModernSidebarUI.au3) | Ready for manual verification — HTML sidebar buttons send selection to the native status control. |

`#WIP - Work in Progress` is written as an AutoIt comment (`; #WIP - Work in Progress`) at the top of incomplete scripts; a bare `#WIP` is not a valid AutoIt directive.

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
- [`023_NewWindowTabs.au3`](../examples/023_NewWindowTabs.au3) demonstrates handling `target="_blank"` and `window.open` by queuing a URI and opening an app-managed tab. This does not preserve JavaScript opener semantics.

## 025_AudioState.au3

[Example 025](../examples/025_AudioState.au3) is a self-contained native audio-state demo inspired by [Gianni's question on the AutoIt Forum](https://www.autoitscript.com/forum/topic/213932-udf-webview2-%E2%80%94-a-modern-chromium-browser-inside-your-autoit-gui-pure-autoit-no-dll-to-ship/#findComment-1555567). Click **Start tone** or **Stop tone** in the embedded page: the AutoIt label receives ICoreWebView2_8::IsDocumentPlayingAudioChanged through the UDF callback. **Read current state** calls _WebView2_GetIsDocumentPlayingAudio() for comparison. The HTML and Web Audio oscillator are embedded in the .au3 file; no network or extra assets are needed. An isolated x86 and x64 WebView2 smoke test confirmed the native True and False transitions and cleanup. Direct interaction with the visible example window remains to be checked.
