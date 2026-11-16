# Offline Chart.js example 048

Run `examples/048_ChartJS.au3` with AutoIt 3.3.18.0 or newer and WebView2 Runtime available. Matching loader DLLs belong in `bin/x86` and `bin/x64`. No server, database or Internet access is needed: the example maps its local assets to `https://udf-virtual-host.example/index.html` using the existing native UDF.

## Manual test

The **Chart type** ComboBox offers Bar, Line, Pie, Doughnut, Radar, Polar area, Scatter, Bubble and Mixed (bar + line). Switching type preserves current sample values. Scatter maps the three labels to X=1,2,3 with the sample values as Y. Bubble adds deterministic radii 6,9,12. Mixed displays the same values as bars and a line. Pie/doughnut use proportions, while radar/polar charts use radial axes. Clickable elements are reported as **Data item Alpha/Beta/Gamma** for every type.

1. Wait for the ready log and three bars: Alpha=10, Beta=20, Gamma=30.
2. Click **Update values**. Values become 35, 15, 45, and the page returns an `updated` JSON acknowledgement.
3. Click each bar. The green log groups a `[YYYY-MM-DD HH:MM:SS] [WebView2]: Data item <label> was clicked.` entry with the selected value. Clicking a blank area should produce no data-selection message.
4. Click **Read chart data** and compare JSON values to the bars. **Reset values** restores the original data.
5. Resize, maximize and restore the window. Check canvas fit and the absence of an overlay from native controls.
6. Repeat after disconnecting from the Internet. All chart scripts and sample data are local.

## How it works

Chart.js renders a canvas with deterministic sample data. AutoIt calls the page's `setSample()` or `readChart()` function through the existing ExecuteScript API. The page returns ready/update JSON messages and sends selected-bar data only from a browser-trusted canvas click. The host accepts messages from the expected local page URL. These messages cause logging only; they do not execute host commands. Animation is disabled to make updates and smoke readback deterministic. The standalone example uses the same separate owned WebView-only host as examples 044–047; native controls remain in the main window.

Chart.js 4.5.1 is bundled locally with its upstream MIT license. See [asset notice](../examples/assets/native/048-chart/NOTICE.md) for the source, pinned build and SHA-256. Inspiration for considering a chart example came from the Ralle1976 project comparison; this implementation does not include its chart extension code or use a CDN at runtime. No core UDF API was changed.

## Validation boundary

`--smoke` creates hidden windows, waits for Chart.js ready, updates to `[35,15,45]` and reads the values and version back. It passed under AutoIt x64 and x86. This confirms page initialization and both message/script directions, but not visible rendering, real mouse selection or interactive resize. Interactive behavior, including type selection, has subsequently been confirmed. Programmatic smoke actions are not logged as user clicks.
