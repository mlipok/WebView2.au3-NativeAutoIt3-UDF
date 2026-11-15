# Local draft 2: nonblocking operations

## Current boundary

`_WebView2_ExecuteScript()` starts native `ExecuteScript` and waits on one process-wide completion channel: `ScriptBusy`, `ScriptDone`, HRESULT and result in `WebView2_Core.au3`. Its callback object is currently shared. `_WebView2_Create()` similarly waits on a single pending controller slot. Reusing either callback for overlapping requests would allow a late completion to satisfy the wrong request. This branch implements the first bounded script-request phase; controller creation remains a separate design task.

## Proposed first public addition

Keep the existing synchronous helper unchanged. `_WebView2_ExecuteScriptAsyncStart($iWebView, $sJavaScript)` returns a positive, monotonic request ID; `_WebView2_ExecuteScriptAsyncPoll($iRequest, ByRef $sJSON)` returns `0` while pending, `1` on successful completion and `-1` with `@error`/`@extended` on failure; `_WebView2_ExecuteScriptAsyncForget($iRequest)` abandons a pending result. The result remains the JSON string returned by WebView2, including JSON `null` for a script with no result. Each active request has its own native callback object, so reuse of a numeric view slot cannot impersonate it.

Use one native callback object per active request slot, not the existing process-wide callback. Retain its vtable and `DllCallback` handles until global cleanup. An abandoned pending record is not reused until its native callback arrives. Cleanup closes views, invalidates the request registry, then releases callback resources. The native callback only stores HRESULT and JSON; it does not invoke user code. `Poll` is called in the AutoIt event loop and never pumps messages recursively.

The prototype registry has 32 slots for pending or completed but unconsumed requests. It rejects new starts when full with `$WEBVIEW2_ERR_BUSY`. It does not silently overwrite results. Once a result has been consumed, a second poll returns invalid-request. Native `ExecuteScript` cancellation is unavailable through this interface. If a host abandons a request that never completes, its slot stays occupied until global cleanup; this avoids miscorrelation.

## Separate startup phase

Only after script request lifetimes are proven, split controller creation into `_WebView2_CreateAsyncStart(...)` and `_WebView2_CreateAsyncPoll(...)`. Today `PendingCreateSlot` is a single global and `__WebView2_ControllerCompleted_Invoke` assumes that slot. A new create registry must correlate callback objects with the parent HWND and reserved view slot, handle parent-window destruction, and ensure `NewWindowRequested` handoff remains valid. Environment initialization is a separate phase with its own callback and timeout; it should not be conflated with controller readiness.

## Acceptance checks before integration

1. Two overlapping script requests on separate views complete in reverse order and return to the correct IDs.
2. A request forgotten before completion cannot be mistaken for a later request.
3. Destroying a view or cleaning up while one request is pending releases native and AutoIt callback resources without a crash.
4. An invalid script produces a WebView2 JSON result or native HRESULT according to the native contract, without blocking GUI input.
5. Existing `_WebView2_ExecuteScript()` and frame script calls retain their current contract.

Keep this candidate local until those checks run under x86 and x64 AutoIt. Example 044 is WIP, and the new API is not ready for publication.
