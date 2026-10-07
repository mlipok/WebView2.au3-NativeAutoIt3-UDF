# WebView2Loader.dll

This archive currently includes architecture-specific `WebView2Loader.dll` binaries matching the project baseline.

To refresh them from the pinned official Microsoft.Web.WebView2 NuGet package, run from the project root:

```powershell
.\tools\Get-WebView2Loader.ps1
```

The tool installs:

```text
bin\x86\WebView2Loader.dll
bin\x64\WebView2Loader.dll
```

The AutoIt UDF automatically selects `x86` or `x64` from `@AutoItX64`.
