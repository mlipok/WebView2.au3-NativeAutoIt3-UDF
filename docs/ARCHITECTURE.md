# Architecture

## Layering

```text
Application / examples
        |
        v
WebView2.au3                         public umbrella include
        |
        +--> WebView2_Core.au3       lifecycle, navigation, events, settings, script helpers
        +--> WebView2_DOM.au3        DOM automation / element tokens
        +--> WebView2_IECompat.au3   IE.au3-style migration helpers
        +--> WebView2_Advanced.au3   CDP, cookies, capture, PDF/MHTML, frames, extensions, ad block
                 |
                 +--> WebView2_Constants.au3
                 +--> WebView2_Interfaces.au3
                 +--> WebView2_CallbackObject.au3
                         |
                         v
                  WebView2Loader.dll
                         |
                         v
                   WebView2 Runtime
```

The umbrella `WebView2.au3` contains only includes. Shared public script helpers are defined in `WebView2_Core.au3` beside their internal implementations, so component files can be checked and included independently.

## Shared environment, multiple controllers

The UDF creates one `ICoreWebView2Environment` and a controller/core pair for each `_WebView2_Create()` call. Instance IDs index an internal fixed-size table. Controller creation is asynchronous; the convenience API waits while pumping the Win32 message queue so COM/WebView2 callbacks can run on the STA thread.

## COM lifetime

The lifetime model validated during v0.1.x is preserved. Borrowed WebView2 pointers wrapped by `ObjCreateInterface()` receive the required temporary/retained `AddRef()`; persistent wrappers are not manually double-released. Instance shutdown order is event unsubscribe -> `Controller.Close()` -> clear Core wrapper -> clear Controller wrapper. Global cleanup then clears the Environment wrapper, callback objects, loader DLL and COM initialization.

## COM callbacks

`WebView2_CallbackObject.au3` builds minimal in-process COM objects containing `QueryInterface`, `AddRef`, `Release`, and handler `Invoke`. Callback structures and `DllCallbackRegister()` handles stay alive until `_WebView2_Cleanup()`.

## Interface tags

`ObjCreateInterface()` method tags must exactly match COM vtable order. Base interface definitions live in `WebView2_Interfaces.au3`. New native interface revisions should be added through `QueryInterface()` rather than by inserting methods into an older vtable definition.

## DOM automation layer

`WebView2_DOM.au3` uses `_WebView2_ExecuteScript()` and stores located DOM nodes in a JavaScript registry in the current document. AutoIt receives opaque tokens such as `wv2e-1`. Navigation destroys the page registry, deliberately making old tokens stale.

## IE.au3 migration layer

`WebView2_IECompat.au3` maps common IE.au3 operations to WebView2/DOM semantics. It does not return Internet Explorer COM objects and is not a drop-in signature-compatible replacement. See `API_COMPARISON.md`.

## Advanced / CDP layer

`WebView2_Advanced.au3` uses `ICoreWebView2::CallDevToolsProtocolMethod()` for capabilities that map cleanly to Chromium CDP: screenshots, PDF, MHTML snapshots, cookies, cache, User-Agent override, network URL blocking and frame-tree metadata. Feature availability is determined by the WebView2 Runtime/CDP version; unknown methods fail through the normal UDF error path.

PDF and image CDP payloads are Base64 and are decoded to AutoIt `Binary` when a Binary API is requested. MHTML is returned by CDP as text and converted to UTF-8 `Binary` for the Binary/file variants.

## Loader architecture

AutoIt x86 loads x86 `WebView2Loader.dll`; AutoIt x64 loads x64. The repository includes both baseline loaders and setup tooling can refresh them from the pinned Microsoft.Web.WebView2 package.
