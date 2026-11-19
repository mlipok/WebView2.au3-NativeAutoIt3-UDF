#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiEdit.au3>
#include <Math.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)
Opt("GUIResizeMode", $GUI_DOCKALL)
Global $g_hMain = 0, $g_hHost = 0, $g_idLog = 0, $g_idGuide = 0, $g_iView = -1
Global $g_bSmoke = False, $g_bPageReady = False, $g_bReadingPage = False
Global $g_iRendererFailures = 0, $g_bRendererDetails = False
Global $g_sGeometry = ""
Global Const $g_sPage = '<!doctype html><meta charset="utf-8"><title>Process diagnostics demo</title>' & _
		'<main style="margin:2rem;font:20px system-ui"><h1>Demo renderer is running</h1><p>Use the AutoIt controls to test diagnostics and restore this page.</p></main>'
If $CmdLine[0] Then $g_bSmoke = $CmdLine[1] = "--smoke"
Exit _Example()

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Example
; Description ...: Runs the isolated WebView2 diagnostic example.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: 0 on normal close or successful smoke. 1 on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	$g_hMain = GUICreate("WebView2 - Process failure diagnostics", 1120, 700, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	Local $idCrash = GUICtrlCreateButton("Crash demo renderer", 8, 8, 158, 28)
	Local $idRestore = GUICtrlCreateButton("Restore demo page", 176, 8, 154, 28)
	Local $idFolder = GUICtrlCreateButton("Read report folder", 340, 8, 150, 28)
	$g_idLog = GUICtrlCreateEdit("", 8, 48, 330, 600, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idLog, 0xE2F0E4)
	$g_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
			"1. Wait for the demo page. Click [Read report folder] to show the Runtime's diagnostics path." & @CRLF & _
			"2. Click [Crash demo renderer]. Wait for a RenderProcessExited entry in the operation log." & @CRLF & _
			"3. Click [Restore demo page]. The heading should return. You can repeat the test." & @CRLF & @CRLF & _
			"The example uses an isolated WebView2 profile and the Runtime's built-in renderer diagnostic page. ProcessFailed reports the failure kind, reason, exit code and any description. The report folder may contain older files or no dump for this event.", _
			350, 535, 760, 155, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idGuide, 0xFFF1BF)
	If Not $g_bSmoke Then
		GUISetState(@SW_MAXIMIZE, $g_hMain)
		GUISetState(@SW_SHOWNOACTIVATE, $g_hMain)
	EndIf
	$g_hHost = GUICreate("", 1, 1, 0, 0, $WS_POPUP, $WS_EX_NOREDIRECTIONBITMAP, $g_hMain)
	_SyncLayout()
	If Not $g_bSmoke Then GUISetState(@SW_SHOWNOACTIVATE, $g_hHost)
	Local $sProfile = @TempDir & "\WebView2-051-" & @AutoItPID & "-" & Random(100000, 999999, 1)
	Local $iResult = 1
	Do
		If Not _WebView2_Init(Default, $sProfile) Then ExitLoop
		Local $aSize = WinGetClientSize($g_hHost)
		$g_iView = _WebView2_Create($g_hHost, 0, 0, $aSize[0], $aSize[1])
		If @error Then ExitLoop
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_PROCESS_FAILED, _OnProcessFailed) Then ExitLoop
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _OnNavigation) Then ExitLoop
		If Not _OpenPage() Then ExitLoop
		If $g_bSmoke Then
			If _Smoke($sProfile) Then $iResult = 0
			ExitLoop
		EndIf
		While True
			Switch GUIGetMsg()
				Case $GUI_EVENT_CLOSE
					$iResult = 0
					ExitLoop
				Case $idCrash
					_Click("Crash demo renderer")
					If $g_bPageReady Then
						$g_bPageReady = False
						If Not _WebView2_Navigate($g_iView, "edge://crash") Then _Log("Diagnostic navigation failed.")
					Else
						_Log("Wait for the demo page or restore it first.")
					EndIf
				Case $idRestore
					_Click("Restore demo page")
					_OpenPage()
				Case $idFolder
					_Click("Read report folder")
					_ReadFolder()
			EndSwitch
			_SyncLayout()
			Sleep(10)
		WEnd
	Until True
	If $iResult Then _Log("Example stopped with an error. " & _WebView2_Error_GetDescription())
	_WebView2_Cleanup()
	GUIDelete($g_hHost)
	GUIDelete($g_hMain)
	Return $iResult
EndFunc   ;==>_Example

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _OpenPage
; Description ...: Navigates to the original local demonstration content.
; Syntax ........: _OpenPage()
; Parameters ....: None.
; Return values .: True if navigation was accepted.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OpenPage()
	$g_bPageReady = False
	$g_bReadingPage = True
	If _WebView2_NavigateToString($g_iView, $g_sPage) Then Return True
	$g_bReadingPage = False
	_Log("Could not open the demo page.")
	Return False
EndFunc   ;==>_OpenPage

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _OnNavigation
; Description ...: Marks the demo page ready after a successful navigation.
; Syntax ........: _OnNavigation($iView, $bSuccess, $iStatus, $iNavigation)
; Parameters ....: WebView2 navigation callback arguments.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnNavigation($iView, $bSuccess, $iStatus, $iNavigation)
	#forceref $iView, $iNavigation
	If Not $g_bReadingPage Then Return
	$g_bReadingPage = False
	$g_bPageReady = $bSuccess
	If $bSuccess Then
		_Log("Demo page ready.")
	Else
		_Log("Demo page navigation failed. Status " & $iStatus)
	EndIf
EndFunc   ;==>_OnNavigation

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _OnProcessFailed
; Description ...: Logs copied diagnostic fields from the native callback.
; Syntax ........: _OnProcessFailed($iView, $iKind, $vReason, $vExitCode, $vDescription)
; Parameters ....: WebView2 process failure callback arguments.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Recovery is handled from the GUI message loop.
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnProcessFailed($iView, $iKind, $vReason, $vExitCode, $vDescription)
	Local $sKind = String($iKind)
	If $iKind = $WEBVIEW2_PROCESS_FAILED_KIND_RENDER_PROCESS_EXITED Then
		$sKind = "RenderProcessExited (" & $iKind & ")"
		$g_iRendererFailures += 1
		$g_bRendererDetails = IsInt($vReason) And IsInt($vExitCode) And IsString($vDescription)
		$g_bPageReady = False
	EndIf
	_Log("ProcessFailed | view=" & $iView & " | kind=" & $sKind & _
			" | reason=" & _Field($vReason) & " | exit code=" & _Field($vExitCode) & " | description=" & _Field($vDescription))
EndFunc   ;==>_OnProcessFailed

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Field
; Description ...: Formats an optional field for display.
; Syntax ........: _Field($vValue)
; Parameters ....: $vValue - Diagnostic field.
; Return values .: Display text.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Field($vValue)
	If IsKeyword($vValue) Then Return "(unavailable)"
	If IsString($vValue) And $vValue = "" Then Return "(empty)"
	Return String($vValue)
EndFunc   ;==>_Field

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _ReadFolder
; Description ...: Logs the Runtime report folder or its error.
; Syntax ........: _ReadFolder()
; Parameters ....: None.
; Return values .: Report folder, or an empty string.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _ReadFolder()
	Local $sPath = _WebView2_GetFailureReportFolderPath()
	Local $iError = @error, $iExtended = @extended
	If $iError Then
		_Log("Failure report folder unavailable. Error=" & $iError & " HRESULT=0x" & Hex($iExtended, 8))
	Else
		_Log("Failure report folder: " & $sPath)
	EndIf
	Return $sPath
EndFunc   ;==>_ReadFolder

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Smoke
; Description ...: Checks the report folder, native renderer failure, and content recovery.
; Syntax ........: _Smoke($sProfile)
; Parameters ....: $sProfile - Isolated profile path.
; Return values .: True when the native sequence succeeds.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Smoke($sProfile)
	Local $sFolder = _ReadFolder()
	If StringLeft($sFolder, StringLen($sProfile) + 1) <> $sProfile & "\" Then Return False
	If Not _Wait(False) Then Return False
	$g_bPageReady = False
	If Not _WebView2_Navigate($g_iView, "edge://crash") Then Return False
	If Not _Wait(True) Or Not $g_bRendererDetails Then Return False
	If Not _OpenPage() Or Not _Wait(False) Then Return False
	Local $sResult = _WebView2_ExecuteScript($g_iView, "document.title", 3000)
	If @error Or $sResult <> '"Process diagnostics demo"' Then Return False
	_Log("Native renderer failure and recovery verified.")
	Return True
EndFunc   ;==>_Smoke

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Wait
; Description ...: Pumps window messages until the requested Runtime observation.
; Syntax ........: _Wait($bFailure)
; Parameters ....: $bFailure - Wait for failure when True or page readiness when False.
; Return values .: True if observed within 12 seconds.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Wait($bFailure)
	Local $iTimer = TimerInit()
	While TimerDiff($iTimer) < 12000
		GUIGetMsg()
		If $bFailure And $g_iRendererFailures > 0 Then Return True
		If Not $bFailure And $g_bPageReady Then Return True
		Sleep(10)
	WEnd
	_Log("Timed out waiting for Runtime callback. Waiting for failure=" & $bFailure)
	Return False
EndFunc   ;==>_Wait

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _SyncLayout
; Description ...: Fits the native panels and the owned WebView2 host to the window.
; Syntax ........: _SyncLayout()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _SyncLayout()
	Local $aClient = WinGetClientSize($g_hMain)
	If Not IsArray($aClient) Then Return
	If $aClient[0] < 80 Or $aClient[1] < 80 Then Return
	Local $iLeft = _Min(350, Int($aClient[0] * 0.42))
	Local $iGuide = _Min(165, Int($aClient[1] * 0.30))
	Local $iWidth = $aClient[0] - $iLeft - 8, $iHeight = $aClient[1] - $iGuide - 64
	If $iWidth < 1 Or $iHeight < 1 Then Return
	Local $tPoint = DllStructCreate("long X;long Y")
	DllStructSetData($tPoint, "X", $iLeft)
	DllStructSetData($tPoint, "Y", 48)
	Local $aCall = DllCall("user32.dll", "bool", "ClientToScreen", "hwnd", $g_hMain, "struct*", $tPoint)
	If @error Then Return
	If Not $aCall[0] Then Return
	Local $iX = DllStructGetData($tPoint, "X"), $iY = DllStructGetData($tPoint, "Y")
	Local $sGeometry = $iX & ":" & $iY & ":" & $iWidth & ":" & $iHeight
	If $sGeometry = $g_sGeometry Then Return
	$g_sGeometry = $sGeometry
	GUICtrlSetPos($g_idLog, 8, 48, $iLeft - 16, $aClient[1] - 56)
	GUICtrlSetPos($g_idGuide, $iLeft, $aClient[1] - $iGuide - 8, $iWidth, $iGuide)
	WinMove($g_hHost, "", $iX, $iY, $iWidth, $iHeight)
	If $g_iView >= 0 Then _WebView2_SetBounds($g_iView, 0, 0, $iWidth, $iHeight)
EndFunc   ;==>_SyncLayout

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Log
; Description ...: Appends an operation to the log and console.
; Syntax ........: _Log($sMessage)
; Parameters ....: $sMessage - Diagnostic message.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Log($sMessage)
	ConsoleWrite("[051] " & $sMessage & @CRLF)
	_GUICtrlEdit_AppendText($g_idLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sMessage & @CRLF)
	GUICtrlSendMsg($g_idLog, $EM_SCROLLCARET, 0, 0)
EndFunc   ;==>_Log

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Click
; Description ...: Logs a real AutoIt button click.
; Syntax ........: _Click($sCaption)
; Parameters ....: $sCaption - Button caption.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Click($sCaption)
	_GUICtrlEdit_AppendText($g_idLog, @CRLF & "[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [AutoIt]: " & $sCaption & " was clicked." & @CRLF)
	GUICtrlSendMsg($g_idLog, $EM_SCROLLCARET, 0, 0)
EndFunc   ;==>_Click

