# Notices and attribution

## AutoIt WebView2 research

This project is based on the technical direction developed in the AutoIt Forum topic:

- **Microsoft Edge - WebView2, embed web code in your native application**
- Topic started by **mLipok** on 2020-11-12
- https://www.autoitscript.com/forum/topic/204362-microsoft-edge-webview2-embed-web-code-in-your-native-application/

The native AutoIt implementation work by **LarsJ** demonstrated the core techniques used here: loading `WebView2Loader.dll`, STA COM initialization, `ObjCreateInterface()`, WebView2 interface description tags, and COM callback objects. Related AutoIt callback/ObjectFromTag research by LarsJ and trancexx informed the callback architecture.

The implementation in this repository is organized as a new reusable UDF rather than a verbatim copy of the forum examples.

## Microsoft WebView2

`WebView2Loader.dll`, WebView2 Runtime, interface names, GUIDs and API semantics are Microsoft WebView2 technology.

The current project archive includes architecture-specific `WebView2Loader.dll` binaries carried forward from the tested project baseline. `tools/Get-WebView2Loader.ps1` can refresh them from the pinned Microsoft.Web.WebView2 NuGet package. Microsoft's license applies to those binaries.

Microsoft WebView2 documentation:

- https://learn.microsoft.com/microsoft-edge/webview2/
- https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/
- https://www.nuget.org/packages/Microsoft.Web.WebView2/

The Microsoft package's own license applies to files obtained from that package.
## au3WebDriver API inspiration

Version 0.3.0 reviewed the public behavior and function families of the MIT-licensed `au3WebDriver` project, especially `wd_core.au3` and `wd_helper.au3`, to identify browser-automation concepts that are also useful for an embedded WebView2 control. The implementation in this repository is newly written for WebView2 and does not copy the WebDriver HTTP transport or driver-process implementation.

- https://github.com/mlipok/au3WebDriver
- Upstream project: https://github.com/Danp2/au3WebDriver
- au3WebDriver license: MIT
- Primary author/maintainer credited by upstream: Dan Pollak (Danp2); mLipok is also credited upstream for contributions and feedback.


## Copies of the GitHub examples

**The new EXAMPLES `200–221` are copies of the EXAMPLES `000–021` set from [GitHub](https://github.com/ioa747/NetWebView2Lib/tree/main/examples), adapted for the native `WebView2.au3` UDF.** The upstream set is by ioa747; the corresponding names and numbers are retained. These are functional copies/adaptations: browser integration was rewritten for the native API, and differences and missing features are documented below.

See [EXAMPLES.md](docs/EXAMPLES.md) for the source-to-copy table, Markdown usage, WIP scope and verification limits. Source license: [examples/LICENSE.upstream.txt](examples/LICENSE.upstream.txt). Bundled marked v17.0.4 retains its original copyright headers and [license](examples/JS_Lib/marked/LICENSE.md).

## PDF.js example asset

`examples/assets/pdfjs/` is a copy of the PDF.js distribution supplied with the upstream example snapshot. PDF.js is Copyright Mozilla Foundation and contributors and is licensed under Apache License 2.0; see [its bundled LICENSE](examples/assets/pdfjs/LICENSE).
