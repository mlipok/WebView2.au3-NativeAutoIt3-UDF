[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Errors = New-Object System.Collections.Generic.List[string]

$RequiredFiles = @(
    "examples\200-NetJson.Parser.au3",
    "examples\201-BasicDemo.au3",
    "examples\202-Html_Gui.au3",
    "examples\203-Multi-Basic.au3",
    "examples\204-FileViewerDemo.au3",
    "examples\204-FileViewerDemo_Loop.au3",
    "examples\205-SaveDemo.au3",
    "examples\206-DownloadDemo.au3",
    "examples\207-HTTP_StatusCodeTracking.au3",
    "examples\208-JavaScript.au3",
    "examples\209-Auditor.au3",
    "examples\210-NavigationBar.au3",
    "examples\211-TwinWebView.au3",
    "examples\212-GetCookies.au3",
    "examples\213-jsonTree.au3",
    "examples\214-pdfJS-Static_PDF_Viewer.au3",
    "examples\215-CSV_Viewer.au3",
    "examples\216-CSV_Editor.au3",
    "examples\217-MappedFolder.au3",
    "examples\218-BasicFramesDemo.au3",
    "examples\219-MarkdownViewer.au3",
    "examples\023_NewWindowTabs.au3",
    "examples\219-mdMsgBox.au3",
    "examples\219-mdMsgBox_Example.au3",
    "examples\220-NavigationInterception.au3",
    "examples\221-ModernSidebarUI.au3",
    "examples\assets\markdown\viewer.html",
    "examples\assets\markdown\viewer.js",
    "examples\assets\markdown\viewer.css",
    "examples\assets\markdown\sample.md",
    "examples\JS_Lib\marked\marked.umd.js",
    "examples\JS_Lib\marked\marked.umd.min.js",
    "examples\assets\native\audit.js",
    "examples\JS_Lib\marked\marked-LICENSE.md",
    "examples\LICENSE.upstream.txt",
    "docs\EXAMPLES.md",
    "tools\Smoke-JsonStrings.au3",
    "examples\assets\native\200.html",
    "examples\assets\native\201.html",
    "examples\assets\native\202.html",
    "examples\assets\native\203.html",
    "examples\assets\native\204.html",
    "examples\assets\native\205.html",
    "examples\assets\native\206.html",
    "examples\assets\native\207.html",
    "examples\assets\native\208.html",
    "examples\assets\native\209.html",
    "examples\assets\native\210.html",
    "examples\assets\native\211.html",
    "examples\assets\native\212.html",
    "examples\assets\native\213.html",
    "examples\assets\native\214.html",
    "examples\assets\native\215.html",
    "examples\assets\native\216.html",
    "examples\assets\native\217.html",
    "examples\assets\native\218.html",
    "examples\assets\native\220.html",
    "examples\assets\native\221.html",
    "WebView2.au3",
    "WebView2_Constants.au3",
    "WebView2_Interfaces.au3",
    "WebView2_CallbackObject.au3",
    "WebView2_Core.au3",
    "WebView2_DOM.au3",
    "WebView2_IECompat.au3",
    "WebView2_Advanced.au3",
    "docs\API_COMPARISON.md",
    "examples\001_Basic.au3",
    "examples\016_Export_PDF_MHTML.au3",
    "examples\020_IE_Compatibility.au3"
)

foreach ($RelativePath in $RequiredFiles) {
    $FullPath = Join-Path $ProjectRoot $RelativePath
    if (-not (Test-Path $FullPath)) {
        $Errors.Add("Missing: $RelativePath")
    }
}

foreach ($Example in Get-ChildItem -LiteralPath (Join-Path $ProjectRoot "examples") -File -Filter "*.au3") {
    if ($Example.Name -match '^\d' -and $Example.Name -notmatch '^\d{3}[_-]') {
        $Errors.Add("Example filename requires a three-digit prefix: $($Example.Name)")
    }
}

foreach ($Arch in @("x86", "x64")) {
    $Loader = Join-Path $ProjectRoot "bin\$Arch\WebView2Loader.dll"
    if (-not (Test-Path $Loader)) {
        Write-Warning "Missing optional runtime dependency: bin\$Arch\WebView2Loader.dll. Run tools\Get-WebView2Loader.ps1."
    } else {
        $Signature = Get-AuthenticodeSignature -FilePath $Loader
        if ($Signature.Status -ne "Valid") {
            $Errors.Add("Invalid Authenticode signature: bin\$Arch\WebView2Loader.dll")
        }
    }
}

if ($Errors.Count -gt 0) {
    $Errors | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host "Project structure validation: OK"
Write-Host "Note: this does not replace Au3Check or a Windows WebView2 runtime smoke test."
