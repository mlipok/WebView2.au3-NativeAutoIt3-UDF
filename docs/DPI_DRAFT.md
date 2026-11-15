# DPI draft for example 043

This local draft adds an opt-in process DPI helper and a window DPI readback helper. The process helper must run before `GUICreate`, `WebView2_Init` or any other operation that creates a window. Production hosts should prefer a DPI manifest. A host whose process awareness has already been set to another mode must not assume this helper can change it.

Example 043 handles `WM_DPICHANGED` with Windows' suggested rectangle, then resizes the native WebView2 controller in the ordinary AutoIt GUI loop. This keeps the COM call out of the window procedure. The sample logs the native DPI and client dimensions, opens with a title and taskbar visible, and includes a yellow test procedure.

## Validation boundary

Au3Check 3.3.18.0 reported zero errors and zero warnings for the public include and example 043. The sample is marked WIP until a visible run moves the window between monitors with different scale factors and verifies maximize/restore on both monitors. No existing example or parent `Z:` UDF copy was changed.

Sources: [process awareness](https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-setprocessdpiawarenesscontext), [DPI change message](https://learn.microsoft.com/windows/win32/hidpi/wm-dpichanged), [window DPI](https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-getdpiforwindow).
