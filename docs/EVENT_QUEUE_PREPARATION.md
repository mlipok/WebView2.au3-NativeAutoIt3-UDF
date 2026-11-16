# Local draft 3: bounded notification queue

## Current boundary

`_WebView2_SetCallback()` stores AutoIt callback references per view. `WebView2_Core.au3` invokes notification callbacks directly from native COM callbacks. The documented rule is to keep them short and avoid re-entrant synchronous WebView2 calls. An optional queue can move only notifications to an explicit application-controlled dispatch point.

## Proposed public contract

The local prototype adds `_WebView2_EventQueue_Enable($iWebView, $iCapacity = 32)`, `_WebView2_EventQueue_Dispatch($iWebView, $iMaximum = 32)`, `_WebView2_EventQueue_GetStats($iWebView)` and `_WebView2_EventQueue_Disable($iWebView)`; direct callbacks remain the default. Dispatch calls registered AutoIt callbacks from the ordinary GUI loop and returns a count. Capacity and per-call maximum are bounded to 64. Queue storage is per view generation; destroying a view discards only its events. Each record copies primitive values, source URL and JSON string before the native event args become invalid. No native event-args pointer is retained in the queue.

The implemented first safe event set is navigation completion, title change and web message received. Audio/mute/full-screen state and worker/frame *observational* notifications are candidates for a later extension after their argument and lifetime contracts are checked. Navigation starting with cancellation, permissions, JavaScript dialogs, new windows, accelerator keys, download starting, and other decision events remain direct. Worker destruction requires copying the worker ID before invalidation; callbacks must see a documented state.

## Backpressure

When the queue is full, reject the newest notification, increment a dropped counter and expose it through `GetStats`. Never silently discard a decision event. The first dispatch after overflow should report the number dropped through an explicit status result; it must not fabricate a browser event. Preserve FIFO order for one view. Processing one view must not starve another; applications choose per-loop dispatch budgets.

## Acceptance checks before integration

1. A burst of more than capacity notifications preserves the first queued records, reports the exact dropped count and never grows memory past its bound.
2. Two views keep independent order and counters; destroying/recreating one cannot deliver its old records.
3. A direct permission or dialog callback still answers WebView2 synchronously or through its existing native deferral.
4. Dispatch is reentrancy guarded; callbacks may enqueue later notifications without recursively dispatching them.
5. Existing callback delivery is unchanged unless queue mode is explicitly enabled.

The opt-in implementation and example 045 passed the bounded FIFO/overflow smoke under x86 and x64. The interactive example and corrected visual layout have been confirmed. View-reuse and callback-triggered destruction remain additional lifecycle checks.
