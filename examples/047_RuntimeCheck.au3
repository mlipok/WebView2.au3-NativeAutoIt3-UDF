#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
; Scenario inspiration: Ralle1976/Autoit-WebView2-UDF, Examples/Example_RuntimeCheck.au3.
; Implemented with this project's native API; no upstream runtime installer code is included.
#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include <InetConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)
Global $g_EX_hGUI = 0, $g_EX_hHost = 0, $g_EX_idLog = 0, $g_EX_idGuide = 0, $g_EX_iWebView = -1
Global $g_EX_sHostGeometry = "", $g_EX_bInitialized = False
Global Const $g_EX_sFixedVersion = "157.0.4341.60"
Global $g_EX_sFixedRoot = @LocalAppDataDir & "\WebView2.au3\Examples\047_FixedRuntime\" & $g_EX_sFixedVersion & "\" & (@AutoItX64 ? "x64" : "x86")
Global $g_EX_hDownload = 0, $g_EX_hExtract = 0, $g_EX_sExtractFolder = "", $g_EX_iProgress = -1
Global $g_EX_idFixedDownload = 0, $g_EX_idFixedPreview = 0, $g_EX_idCancel = 0
Global $g_EX_bSimulateMissing = False
If $CmdLine[0] Then $g_EX_bSimulateMissing = $CmdLine[1] = "--simulate-missing"
_Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Checks Runtime availability and offers an explicit download-page prompt.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: No installer is downloaded or executed by this example.
; Related .......: _WebView2_Runtime_GetVersion
; Link ..........: https://developer.microsoft.com/en-us/microsoft-edge/webview2/
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	$g_EX_hGUI = GUICreate("WebView2 - Runtime availability", 1100, 720, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	Local $idCheck = GUICtrlCreateButton("Check Runtime", 8, 8, 145, 30)
	Local $idDownload = GUICtrlCreateButton("Download options", 163, 8, 145, 30)
	Local $idPreview = GUICtrlCreateButton("Start preview", 318, 8, 145, 30)
	$g_EX_idFixedDownload = GUICtrlCreateButton("Download Fixed Runtime", 473, 8, 175, 30)
	$g_EX_idFixedPreview = GUICtrlCreateButton("Preview Fixed Runtime", 658, 8, 165, 30)
	$g_EX_idCancel = GUICtrlCreateButton("Cancel download", 833, 8, 130, 30)
	GUICtrlSetState($g_EX_idCancel, $GUI_DISABLE)
	GUICtrlCreateLabel("AutoIt operation log", 8, 48, 285, 18)
	$g_EX_idLog = GUICtrlCreateEdit("", 8, 68, 285, 450, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetBkColor($g_EX_idLog, 0xE2F0E4)
	$g_EX_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
			"1. Check Runtime: the log reports the installed browser version or a precise availability error." & @CRLF & _
			"2. Start preview uses Evergreen. Download Fixed Runtime downloads a pinned CAB for the AutoIt architecture." & @CRLF & _
			"3. Download options opens an AutoIt Yes/No popup. No keeps the browser closed; Yes opens Microsoft's download page in your default browser." & @CRLF & _
			"4. Wait for Fixed Runtime is ready, then click Preview Fixed Runtime. The log must show its local folder and version. Cancel download aborts a pending transfer." & @CRLF & _
			"HOW IT WORKS" & @CRLF & _
			"WebView2Loader.dll queries the installed WebView2 Runtime before environment creation. These are separate dependencies. A missing or broken loader is reported separately. The CAB is extracted to LocalAppData on a local disk and validated before use. No system installation occurs. Fixed Runtime does not update automatically. Downloading requires Internet access; prepared previews work offline.", _
			305, 500, 780, 210, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	GUICtrlSetBkColor($g_EX_idGuide, 0xFFF1BF)
	GUISetState(@SW_MAXIMIZE, $g_EX_hGUI)
	GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hGUI)
	Local $aClient = WinGetClientSize($g_EX_hGUI)
	_Layout($aClient)
	$g_EX_hHost = GUICreate("", 1, 1, 0, 0, $WS_POPUP, $WS_EX_NOREDIRECTIONBITMAP, $g_EX_hGUI)
	_SyncHost()
	GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hHost)
	_CheckRuntime()
	While True
		Local $aMsg = GUIGetMsg(1)
		Switch $aMsg[0]
			Case $idCheck
				_Click("Check Runtime")
				_CheckRuntime()
			Case $idDownload
				_Click("Download options")
				_OfferDownload()
			Case $idPreview
				_Click("Start preview")
				_StartPreview()
			Case $g_EX_idFixedDownload
				_Click("Download Fixed Runtime")
				_DownloadFixed()
			Case $g_EX_idFixedPreview
				_Click("Preview Fixed Runtime")
				_StartPreview(True)
			Case $g_EX_idCancel
				_Click("Cancel download")
				If $g_EX_hDownload Then InetClose($g_EX_hDownload)
				$g_EX_hDownload = 0
				_FixedBusy(False)
				_Log("Download cancelled. An incomplete CAB will not be used.")
			Case $GUI_EVENT_CLOSE
				If $aMsg[1] = $g_EX_hGUI Then ExitLoop
		EndSwitch
		_SyncHost()
		_PollFixed()
	WEnd
	If $g_EX_hDownload Then InetClose($g_EX_hDownload)
	If $g_EX_hExtract Then DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $g_EX_hExtract)
	If $g_EX_bInitialized Then _WebView2_Cleanup()
	If $g_EX_hHost Then GUIDelete($g_EX_hHost)
	GUIDelete($g_EX_hGUI)
	Return
EndFunc   ;==>_Example

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _CheckRuntime
; Description ...: Reports a Runtime version while distinguishing loader failures and simulation.
; Syntax ........: _CheckRuntime()
; Parameters ....: None.
; Return values .: True when a Runtime version was obtained, otherwise False.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Simulation does not change the installed Runtime.
; Related .......: _StartPreview
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _CheckRuntime()
	Local $bAvailable = False, $iError = 0, $iExtended = 0
	Do
		If $g_EX_bSimulateMissing Then
			_Log("SIMULATION: Runtime unavailable. No installed software has been changed.")
			ExitLoop 1
		EndIf
		Local $sVersion = _WebView2_Runtime_GetVersion()
		$iError = @error
		$iExtended = @extended
		If $iError Then
			If $iError = $WEBVIEW2_ERR_RUNTIME_NOT_FOUND Then
				_Log("No available Runtime was reported; native status=" & $iExtended & ".")
			Else
				_Log("Runtime check failed (not proof of missing Runtime): error=" & $iError & "; " & _WebView2_Error_GetDescription())
			EndIf
			ExitLoop 1
		EndIf
		$bAvailable = $sVersion <> ""
		_Log("Available Runtime version: " & $sVersion & ".")
	Until True
	Return SetError($iError, $iExtended, $bAvailable)
EndFunc   ;==>_CheckRuntime

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _OfferDownload
; Description ...: Asks before opening Microsoft's Runtime download page in the default browser.
; Syntax ........: _OfferDownload()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Never installs or downloads an executable.
; Related .......: _CheckRuntime
; Link ..........: https://developer.microsoft.com/en-us/microsoft-edge/webview2/
; Example .......: Yes
; ===============================================================================================================================
Func _OfferDownload()
	Local $iAnswer = MsgBox(BitOR($MB_YESNO, $MB_ICONQUESTION, $MB_DEFBUTTON2), "WebView2 Runtime download", _
			"Open Microsoft's official WebView2 Runtime download page in your default browser?" & @CRLF & _
			"This example will not download or run an installer.", 0, $g_EX_hGUI)
	_Click($iAnswer = $IDYES ? "Yes" : "No")
	If $iAnswer = $IDYES Then
		ShellExecute("https://developer.microsoft.com/en-us/microsoft-edge/webview2/#download-section")
		If @error Then
			_Log("Could not open the default browser.")
		Else
			_Log("The download page was requested in the default browser.")
		EndIf
	Else
		_Log("Download page was not opened.")
	EndIf
	Return
EndFunc   ;==>_OfferDownload

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _StartPreview
; Description ...: Creates an offline preview only after a successful Runtime check.
; Syntax ........: _StartPreview([$bFixed = False])
; Parameters ....: $bFixed - True to use the prepared local Fixed Runtime; False uses the default Runtime.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Switching previews recreates the environment with a separate profile for each mode and architecture.
; Related .......: _CheckRuntime, _OfferDownload
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _StartPreview($bFixed = False)
	Do
		Local $sBrowserFolder = ""
		If $bFixed Then
			If Not FileExists($g_EX_sFixedRoot & "\ready.txt") Then
				_Log("Download and extract Fixed Runtime first.")
				ExitLoop 1
			EndIf
			$sBrowserFolder = StringStripWS(FileRead($g_EX_sFixedRoot & "\ready.txt"), 3)
			If Not FileExists($sBrowserFolder & "\msedgewebview2.exe") Then
				_Log("Prepared Fixed Runtime is missing its executable. Download it again.")
				ExitLoop 1
			EndIf
		ElseIf Not _CheckRuntime() Then
			If $g_EX_bSimulateMissing Or @error = $WEBVIEW2_ERR_RUNTIME_NOT_FOUND Then _OfferDownload()
			ExitLoop 1
		EndIf
		If $g_EX_bInitialized Then _WebView2_Cleanup()
		$g_EX_bInitialized = False
		$g_EX_iWebView = -1
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\047_RuntimeCheck\" & ($bFixed ? "fixed-" : "evergreen-") & (@AutoItX64 ? "x64" : "x86")
		_Log("Creating environment; browser folder=" & ($bFixed ? $sBrowserFolder : "Evergreen default") & ".")
		If Not _WebView2_Init(Default, $sProfile, $sBrowserFolder) Then
			_Log("Initialization failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		$g_EX_bInitialized = True
		_Log("Environment started using " & ($bFixed ? "Fixed Runtime " & FileGetVersion($sBrowserFolder & "\msedgewebview2.exe") : "the default Runtime") & ".")
		Local $aSize = WinGetClientSize($g_EX_hHost)
		$g_EX_iWebView = _WebView2_Create($g_EX_hHost, 0, 0, $aSize[0], $aSize[1])
		If @error Then
			_Log("Create failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		If Not _WebView2_NavigateToString($g_EX_iWebView, '<!doctype html><title>Runtime preview</title><style>body{font:20px Segoe UI;margin:24px}article{padding:24px;background:#eaf4ff;border:2px solid #2772a8}</style><article><h1>WebView2 Runtime preview</h1><p>This offline page is rendered by the available Runtime.</p><p>Runtime detection uses WebView2Loader.dll; the Runtime supplies the browser engine.</p></article>') Then
			_Log("Navigation failed: " & _WebView2_Error_GetDescription())
		Else
			_Log("Local preview navigation started.")
		EndIf
	Until True
	Return
EndFunc   ;==>_StartPreview

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _FixedBusy
; Description ...: Updates controls while downloading or extracting a Fixed Runtime.
; Syntax ........: _FixedBusy($bBusy)
; Parameters ....: $bBusy - True while preparation is active.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Extraction continues to completion if the example is closed.
; Related .......: _DownloadFixed, _PollFixed
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _FixedBusy($bBusy)
	GUICtrlSetState($g_EX_idFixedDownload, $bBusy ? $GUI_DISABLE : $GUI_ENABLE)
	GUICtrlSetState($g_EX_idFixedPreview, $bBusy ? $GUI_DISABLE : $GUI_ENABLE)
	GUICtrlSetState($g_EX_idCancel, $g_EX_hDownload ? $GUI_ENABLE : $GUI_DISABLE)
	Return
EndFunc   ;==>_FixedBusy

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _DownloadFixed
; Description ...: Starts a background CAB download for the current AutoIt architecture.
; Syntax ........: _DownloadFixed()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Pinned Microsoft download URLs must be updated when the version changes.
; Related .......: _PollFixed
; Link ..........: https://developer.microsoft.com/en-us/microsoft-edge/webview2/
; Example .......: Yes
; ===============================================================================================================================
Func _DownloadFixed()
	Do
		If $g_EX_hDownload Or $g_EX_hExtract Then ExitLoop 1
		If DriveGetType(StringLeft($g_EX_sFixedRoot, 3)) <> "Fixed" Or StringLeft($g_EX_sFixedRoot, 2) = "\\" Then
			_Log("Fixed Runtime requires a local fixed disk; this profile path is not supported.")
			ExitLoop 1
		EndIf
		If Not DirCreate($g_EX_sFixedRoot) Then
			_Log("Could not create local Fixed Runtime directory.")
			ExitLoop 1
		EndIf
		Local $sURL = "https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/"
		$sURL &= @AutoItX64 ? "9d6605ff-c172-41a1-8116-e1bb02b93a01/Microsoft.WebView2.FixedVersionRuntime.157.0.4341.60.x64.cab" : "d538223f-4f3c-4cae-a04a-92a4444761bd/Microsoft.WebView2.FixedVersionRuntime.157.0.4341.60.x86.cab"
		_Log("Downloading Fixed Runtime " & $g_EX_sFixedVersion & " for AutoIt " & (@AutoItX64 ? "x64" : "x86") & ".")
		_Log("Local directory: " & $g_EX_sFixedRoot)
		$g_EX_hDownload = InetGet($sURL, $g_EX_sFixedRoot & "\runtime.cab", $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
		If @error Or Not $g_EX_hDownload Then
			$g_EX_hDownload = 0
			_Log("Could not start CAB download.")
			ExitLoop 1
		EndIf
		$g_EX_iProgress = -1
		_FixedBusy(True)
	Until True
	Return
EndFunc   ;==>_DownloadFixed

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _PollFixed
; Description ...: Reports download progress and observes bounded extraction and validation work.
; Syntax ........: _PollFixed()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The helper validates the executable signature, architecture and version before publishing ready.txt.
; Related .......: _DownloadFixed, _StartPreview
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _PollFixed()
	Do
		If $g_EX_hDownload Then
			Local $iBytes = InetGetInfo($g_EX_hDownload, $INET_DOWNLOADREAD)
			Local $iMB = Int($iBytes / 1048576)
			If Int($iMB / 10) <> $g_EX_iProgress Then
				$g_EX_iProgress = Int($iMB / 10)
				_Log("Downloaded " & $iMB & " MiB.")
			EndIf
			If Not InetGetInfo($g_EX_hDownload, $INET_DOWNLOADCOMPLETE) Then ExitLoop 1
			Local $bSuccess = InetGetInfo($g_EX_hDownload, $INET_DOWNLOADSUCCESS)
			InetClose($g_EX_hDownload)
			$g_EX_hDownload = 0
			If Not $bSuccess Or $iBytes = 0 Then
				_Log("CAB download failed. No new Runtime was activated.")
				_FixedBusy(False)
				ExitLoop 1
			EndIf
			$g_EX_sExtractFolder = $g_EX_sFixedRoot & "\extract-" & @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC & "-" & @AutoItPID
			Local $sHelper = @ScriptDir & "\assets\native\047-PrepareFixedRuntime.ps1"
			Local $sCommand = '"' & @SystemDir & '\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' & $sHelper & '" -Package "' & $g_EX_sFixedRoot & '\runtime.cab" -Destination "' & $g_EX_sExtractFolder & '" -Architecture ' & (@AutoItX64 ? "x64" : "x86") & ' -Version ' & $g_EX_sFixedVersion
			Local $iPID = Run($sCommand, @ScriptDir, @SW_HIDE)
			If @error Or Not $iPID Then
				_Log("Could not start CAB extraction helper.")
				_FixedBusy(False)
				ExitLoop 1
			EndIf
			Local $aOpen = DllCall("kernel32.dll", "handle", "OpenProcess", "dword", 0x1000, "bool", False, "dword", $iPID)
			If @error Then
				_Log("Could not observe extraction helper. Check the local output directory.")
				_FixedBusy(False)
				ExitLoop 1
			EndIf
			$g_EX_hExtract = $aOpen[0]
			If Not $g_EX_hExtract Then
				_Log("Could not observe extraction helper. Check the local output directory.")
				_FixedBusy(False)
				ExitLoop 1
			EndIf
			_FixedBusy(True)
			_Log("Extracting CAB and validating Microsoft signature, architecture and version...")
		EndIf
		If $g_EX_hExtract Then
			Local $aExit = DllCall("kernel32.dll", "bool", "GetExitCodeProcess", "handle", $g_EX_hExtract, "dword*", 0)
			If @error Then ExitLoop 1
			If Not $aExit[0] Or $aExit[2] = 259 Then ExitLoop 1
			DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $g_EX_hExtract)
			$g_EX_hExtract = 0
			If $aExit[2] = 0 Then
				_Log("Fixed Runtime is ready. Click Preview Fixed Runtime.")
			Else
				_Log("Runtime preparation failed: " & FileRead($g_EX_sFixedRoot & "\prepare-error.txt"))
			EndIf
			_FixedBusy(False)
		EndIf
	Until True
	Return
EndFunc   ;==>_PollFixed


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Layout
; Description ...: Fits the log and guide to the GUI client area.
; Syntax ........: _Layout($aClient)
; Parameters ....: $aClient - GUI client dimensions.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetBounds
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Layout($aClient)
	If IsArray($aClient) Then
		GUICtrlSetPos($g_EX_idLog, 8, 68, 285, $aClient[1] - 78)
		GUICtrlSetPos($g_EX_idGuide, 305, $aClient[1] - 222, $aClient[0] - 313, 212)
	EndIf
	Return
EndFunc   ;==>_Layout

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _SyncHost
; Description ...: Aligns the separate WebView-only window with the main GUI's browser panel.
; Syntax ........: _SyncHost()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Geometry is checked in the GUI loop; native controls remain in the main window.
; Related .......: _Layout, _WebView2_SetBounds
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _SyncHost()
	Do
		If Not $g_EX_hHost Then ExitLoop 1
		Local $aClient = WinGetClientSize($g_EX_hGUI)
		If Not IsArray($aClient) Then ExitLoop 1
		Local $tPoint = DllStructCreate("long X;long Y")
		DllStructSetData($tPoint, "X", 305)
		DllStructSetData($tPoint, "Y", 48)
		Local $aCall = DllCall("user32.dll", "bool", "ClientToScreen", "hwnd", $g_EX_hGUI, "struct*", $tPoint)
		If @error Then ExitLoop 1
		If Not $aCall[0] Then ExitLoop 1
		Local $iWidth = $aClient[0] - 313, $iHeight = $aClient[1] - 280
		If $iWidth < 1 Then $iWidth = 1
		If $iHeight < 1 Then $iHeight = 1
		Local $sGeometry = DllStructGetData($tPoint, "X") & ":" & DllStructGetData($tPoint, "Y") & ":" & $iWidth & ":" & $iHeight
		If $sGeometry = $g_EX_sHostGeometry Then ExitLoop 1
		$g_EX_sHostGeometry = $sGeometry
		_Layout($aClient)
		WinMove($g_EX_hHost, "", DllStructGetData($tPoint, "X"), DllStructGetData($tPoint, "Y"), $iWidth, $iHeight)
		If $g_EX_iWebView >= 0 Then _WebView2_SetBounds($g_EX_iWebView, 0, 0, $iWidth, $iHeight)
	Until True
	Return
EndFunc   ;==>_SyncHost

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Log
; Description ...: Appends a time-stamped message and scrolls to the newest line.
; Syntax ........: _Log($sMessage)
; Parameters ....: $sMessage - Message to append.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Log($sMessage)
	_GUICtrlEdit_AppendText($g_EX_idLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sMessage & @CRLF)
	GUICtrlSendMsg($g_EX_idLog, $EM_SCROLLCARET, 0, 0)
	Return
EndFunc   ;==>_Log

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Click
; Description ...: Starts a separate log group for one AutoIt button click.
; Syntax ........: _Click($sCaption)
; Parameters ....: $sCaption - Visible button caption.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Click($sCaption)
	_GUICtrlEdit_AppendText($g_EX_idLog, @CRLF & "[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [AutoIt]: " & $sCaption & " was clicked." & @CRLF)
	GUICtrlSendMsg($g_EX_idLog, $EM_SCROLLCARET, 0, 0)
	Return
EndFunc   ;==>_Click
