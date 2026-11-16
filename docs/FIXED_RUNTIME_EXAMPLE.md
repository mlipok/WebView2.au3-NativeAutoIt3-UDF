# Example 047: local Fixed Version Runtime

The example downloads Microsoft WebView2 Fixed Version Runtime **157.0.4341.60**. It chooses the x64 package for x64 AutoIt and x86 for x86 AutoIt using `@AutoItX64`; the loader DLL must match too. The URLs are pinned to that version, not a latest-version lookup. Update both URLs and the version together when maintaining the example.

## Procedure

1. Start `examples/047_RuntimeCheck.au3` and click **Download Fixed Runtime**. Follow byte/progress messages in the green log. The GUI remains responsive during downloading and extraction.
2. Wait for signature, version and architecture verification to finish and for **Fixed Runtime is ready**. The extracted folder and CAB remain under `%LOCALAPPDATA%\WebView2.au3\Examples\047_FixedRuntime\157.0.4341.60\<architecture>` on a local fixed disk. Repeated downloads extract to new folders and do not overwrite a running Runtime. Files are retained for offline use and diagnosis.
3. Click **Preview Fixed Runtime**. The log must identify the browser folder and version; the blue offline preview should appear. The third argument of `_WebView2_Init` supplies the extracted directory containing `msedgewebview2.exe`.
4. Click **Start preview** to recreate the environment with the default Runtime. Each mode and architecture has a separate profile. Fixed preview also works with `--simulate-missing`, because simulation applies to default Runtime detection only.
5. During another download click **Cancel download**. The incomplete CAB is not extracted. Retry to download it again. Extraction cannot be cancelled; closing the example while extraction is active lets the helper finish.
6. After preparing the Runtime, disconnect Internet access and retry **Preview Fixed Runtime**. No download is needed for this action. Windows signature verification during preparation may require certificate/revocation access, depending on the machine's certificate cache and policy.

No system installer, registry registration or automatic Runtime update is performed. The CAB is large. The application owner must keep Fixed Runtime versions updated. Prepared Runtime folders must stay on a local disk; network locations are unsupported. On Windows 10, Fixed Runtime 120+ requires additional AppContainer read/execute ACLs described by Microsoft. This example does not change ACLs automatically; the recorded tests were on the current Windows 11 machine.

## Implementation and validation

`047-PrepareFixedRuntime.ps1` uses Windows `expand.exe`, then validates `msedgewebview2.exe`'s Authenticode signature, expected Microsoft signer, version and PE machine. The ready marker is written only after all checks pass. Failed extraction leaves its files for diagnosis and does not publish that folder as ready. Runtime executables retain the Microsoft distribution terms supplied with the package; they are not covered by the UDF's MIT license.

Actual x64 and x86 packages were downloaded, extracted and validated. Separate hidden AutoIt probes initialized WebView2 with each extracted path and read back a local page title; both exited 0. These probes do not confirm the example's button interactions, progress display, cancellation or window appearance. Interactive operation was subsequently confirmed on 2026-11-16.

Sources: [Microsoft Fixed Version distribution instructions](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/distribution#the-fixed-version-runtime-distribution-mode), [official Runtime downloads](https://developer.microsoft.com/en-us/microsoft-edge/webview2/#download-section).
