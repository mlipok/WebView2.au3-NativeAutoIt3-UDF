# Example 024: Blazor Calendar in native AutoIt WebView2

This is a standalone Blazor WebAssembly application hosted by `024_BlazorCalendar.au3`. It uses the existing native WebView2 UDF plus `_WebView2_SetVirtualHostNameToFolderMapping`; it does not need an HTTP server, a .NET desktop host, a database, or a remote API. The vendored [Blazor-Calendar](https://github.com/tossnet/Blazor-Calendar) library is MIT-licensed; see `LICENSE.BlazorCalendar.txt`. The fork used for review is [mlipok/Blazor-Calendar](https://github.com/mlipok/Blazor-Calendar). The example changes its host adapter only, not the vendored calendar library.

## Run and rebuild

Install WebView2 Runtime and place the matching x86/x64 `WebView2Loader.dll` in the UDF's `bin` folder. Run `examples/024_BlazorCalendar.au3` with AutoIt x86 or x64. Keep `examples/024_BlazorCalendar/published` beside it. The host maps this folder to `https://autoit-calendar.example/`, then navigates to `index.html`. All application files are local. The Year, Month, Week and Reload sample events buttons are in the AutoIt window; the calendar also has view and period controls.

To rebuild the bundled WASM output, install .NET SDK 10 and run `dotnet publish CalendarHost/CalendarHost.csproj -c Release -o publish`. Copy the generated `publish/wwwroot` contents into `published`. `CalendarHost` references the vendored `BlazorCalendar` source. The checked-in `published` files allow running the example without the SDK. The source snapshot used here is upstream commit `9ae813d`.

## JSON bridge, version 1

Both directions use WebView2 object messages. The web app first sends `{"type":"ready","protocolVersion":1,"timeZone":"Europe/Warsaw"}`. AutoIt then sends `initialize` with `requestId`, `timeZone`, `view` (`year`, `month`, `week`), `date`, and `events`. It may later send `setEvents`, `setDate`, or `setView`. Every accepted command produces `{"type":"ack","requestId":"...","view":"weekly","eventCount":3}`. Invalid input or runtime faults produce `{"type":"error","requestId":"...","code":"INVALID_MESSAGE","message":"..."}` (other codes are possible).

An event is `{ "id": 101, "title": "Planning", "start": "2026-10-13T09:00:00+02:00", "end": "2026-10-13T10:30:00+02:00", "allDay": false, "color": "#3984c6" }`. `end` is **exclusive**. The calendar sends `rangeSelected` with `startInclusive` and `endExclusive`, `eventClicked` with `eventId`, and `dayDoubleClicked` with `date`. Selection uses 15-minute slots. All timestamps use ISO 8601 with seconds and an explicit offset matching `Europe/Warsaw`; offset changes for daylight saving time are validated. Ambiguous or invalid local times are reported as errors. All-day event bounds must be local midnights; the adapter converts the exclusive end to the library's inclusive display boundary.

The host accepts messages only from the mapped origin, limits message length, reports them in its status line and console, and never persists them. Moving events is disabled. Text selection and page dragging are suppressed; range selection inside the calendar remains enabled. Overlapping sample events appear in the week view. Calendar day labels use Polish locale and weeks start on Monday. The year view shows January through December.

## Verification

`dotnet publish` completed with zero errors. Au3Check completed with zero errors and warnings for the example and the three modified UDF modules. The native mapping and ready/ack exchange ran with both x86 and x64 AutoIt. In a visible x64 WebView2 window, year/month/week views, Polish headers, overlapping events, a 15-minute range, double-click, event-click ID, and an all-day event were observed. The all-day display correction and January–December year view were rebuilt after those observations and require a final visible recheck. This is separate from compile success. No physical network-disconnect test has yet been performed; the asset bundle and virtual host mapping do not reference remote application resources.
