# DPI handling in example 043

This module adds an opt-in process DPI helper and a window DPI readback helper. The process helper must run before `GUICreate`, `WebView2_Init` or any other operation that creates a window. Production hosts should prefer a DPI manifest. A host whose process awareness has already been set to another mode must not assume this helper can change it.

Example 043 handles `WM_DPICHANGED` with Windows' suggested rectangle, then resizes the native WebView2 controller in the ordinary AutoIt GUI loop. This keeps the COM call out of the window procedure. The sample logs the native DPI and client dimensions, opens with a title and taskbar visible, and includes a yellow test procedure.

## Validation boundary

The reported same-monitor Windows scale change produced DPI 96 at 100% and DPI 168 at 175%. Changing the current monitor scale is sufficient to trigger this test; moving between monitors is an additional scenario. Screenshots also exposed overlapping native controls and broken snap layout. The revised example disables automatic control docking, calculates panel bounds and font sizes from current DPI/client size, and places WebView2 in a separate owned WebView-only host with `WS_EX_NOREDIRECTIONBITMAP`. Its geometry is synchronized on movement, resizing and DPI changes. The revised visual layout was confirmed interactively on 2026-11-16.

Au3Check 3.3.18.0 reported zero errors and zero warnings for the public include and example 043. Same-monitor scale changes and the corrected layout have been confirmed. A separate mixed-monitor sequence has not been independently recorded.

Sources: [process awareness](https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-setprocessdpiawarenesscontext), [DPI change message](https://learn.microsoft.com/windows/win32/hidpi/wm-dpichanged), [window DPI](https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-getdpiforwindow).
