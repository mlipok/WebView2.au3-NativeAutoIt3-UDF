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

Global Const $g_sHost = "udf-virtual-host.example"
Global Const $g_sPage = "https://" & $g_sHost & "/index.html"
Global Const $g_sOther = $g_sPage & "?document=2"
Global Const $g_sFragment = "#sample"
Global $g_hMain = 0, $g_hHost = 0, $g_idLog = 0, $g_idGuide = 0, $g_iView = -1
Global $g_bSmoke = False, $g_bPageReady = False, $g_bNewDocument = False
Global $g_sGeometry = "", $g_sSource = ""
Global $g_iSourceEvents = 0

If $CmdLine[0] Then $g_bSmoke = $CmdLine[1] = "--smoke"
Exit _Example()

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Example
; Description ...: Shows native WebView2 source, zoom and focus notifications.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: 0 on normal exit or successful smoke. 1 on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	$g_hMain = GUICreate("WebView2 - Native view events", 1120, 700, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	Local $idOpen = GUICtrlCreateButton("Open second document", 8, 8, 175, 28)
	Local $idBack = GUICtrlCreateButton("Back", 192, 8, 75, 28)
	Local $idNativeInput = GUICtrlCreateInput("AutoIt focus field", 275, 8, 155, 28)
	$g_idLog = GUICtrlCreateEdit("", 8, 48, 330, 600, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idLog, 0xE2F0E4)
	$g_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
			"1. Startup logs SourceChanged with new document=True. Click Jump to sample on the page; expect the #sample address and new document=False." & @CRLF & _
			"2. Click Open second document, then Back. Compare the addresses and document flags in the log." & @CRLF & _
			"3. Click the WebView2 focus field, then the AutoIt focus field. Look for GotFocus when entering WebView2 and LostFocus when leaving it." & @CRLF & _
			"4. Hold Ctrl and scroll the mouse wheel over the page. Expect a changed zoom factor in the log and visibly larger or smaller page content." & @CRLF & @CRLF & _
			"WebView2 reports changes to the top-level URI and to the controller. Moving between elements inside the web page does not leave the WebView2 controller. This example works offline.", _
			350, 535, 760, 155, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idGuide, 0xFFF1BF)
	GUICtrlSetState($idNativeInput, $GUI_FOCUS)
	If Not $g_bSmoke Then
		GUISetState(@SW_MAXIMIZE, $g_hMain)
		GUISetState(@SW_SHOWNOACTIVATE, $g_hMain)
	EndIf
	$g_hHost = GUICreate("", 1, 1, 0, 0, $WS_POPUP, $WS_EX_NOREDIRECTIONBITMAP, $g_hMain)
	_SyncLayout()
	If Not $g_bSmoke Then GUISetState(@SW_SHOWNOACTIVATE, $g_hHost)
	Local $sProfile = @TempDir & "\WebView2-053-" & @AutoItPID & "-" & Random(100000, 999999, 1)
	Local $iResult = 1
	Do
		If Not _WebView2_Init(Default, $sProfile) Then ExitLoop
		Local $aSize = WinGetClientSize($g_hHost)
		$g_iView = _WebView2_Create($g_hHost, 0, 0, $aSize[0], $aSize[1])
		If @error Then ExitLoop
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_SOURCE_CHANGED, _OnSource) Then ExitLoop
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_ZOOM_FACTOR_CHANGED, _OnZoom) Then ExitLoop
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_GOT_FOCUS, _OnGotFocus) Then ExitLoop
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_LOST_FOCUS, _OnLostFocus) Then ExitLoop
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _OnNavigation) Then ExitLoop
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_iView, $g_sHost, @ScriptDir & "\assets\native\053-view-events") Then ExitLoop
		If Not _WebView2_Navigate($g_iView, $g_sPage) Then ExitLoop
		If $g_bSmoke Then
			If _Smoke() Then $iResult = 0
			ExitLoop
		EndIf
		While True
			Switch GUIGetMsg()
				Case $GUI_EVENT_CLOSE
					$iResult = 0
					ExitLoop
				Case $idOpen
					_Click("Open second document")
					If Not _WebView2_Navigate($g_iView, $g_sOther) Then _Log(_WebView2_Error_GetDescription())
				Case $idBack
					_Click("Back")
					If Not _WebView2_CanGoBack($g_iView) Then
						_Log("There is no earlier history entry.")
					ElseIf Not _WebView2_GoBack($g_iView) Then
						_Log(_WebView2_Error_GetDescription())
					EndIf
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
; Name ..........: _OnSource
; Description ...: Logs the top-level URI and new-document flag.
; Syntax ........: _OnSource($iView, $sURI, $bNewDocument)
; Parameters ....: $iView - WebView instance.
;                  $sURI - Current top-level URI.
;                  $bNewDocument - Native new-document flag.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnSource($iView, $sURI, $bNewDocument)
	$g_sSource = $sURI
	$g_bNewDocument = $bNewDocument
	$g_iSourceEvents += 1
	_Log("SourceChanged [view " & $iView & "]: " & $sURI & " | new document=" & $bNewDocument)
EndFunc   ;==>_OnSource

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _OnZoom
; Description ...: Logs the effective native zoom factor.
; Syntax ........: _OnZoom($iView, $fZoomFactor)
; Parameters ....: $iView - WebView instance.
;                  $fZoomFactor - Controller zoom factor.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnZoom($iView, $fZoomFactor)
	_Log("ZoomFactorChanged [view " & $iView & "]: " & $fZoomFactor & " (" & Round($fZoomFactor * 100) & "%)")
EndFunc   ;==>_OnZoom

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _OnGotFocus
; Description ...: Logs the controller focus notification.
; Syntax ........: _OnGotFocus($iView)
; Parameters ....: $iView - WebView instance.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnGotFocus($iView)
	_Log("GotFocus [view " & $iView & "]")
EndFunc   ;==>_OnGotFocus

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _OnLostFocus
; Description ...: Logs the controller focus notification.
; Syntax ........: _OnLostFocus($iView)
; Parameters ....: $iView - WebView instance.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnLostFocus($iView)
	_Log("LostFocus [view " & $iView & "]")
EndFunc   ;==>_OnLostFocus

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _OnNavigation
; Description ...: Records completion of navigation.
; Syntax ........: _OnNavigation($iView, $bSuccess, $iStatus, $iNavigation)
; Parameters ....: $iView - WebView instance.
;                  $bSuccess - Native success flag.
;                  $iStatus - Native error status.
;                  $iNavigation - Navigation ID.
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
	$g_bPageReady = $bSuccess
	If Not $bSuccess Then _Log("Navigation failed. Status: " & $iStatus)
EndFunc   ;==>_OnNavigation

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Smoke
; Description ...: Exercises real new-document, fragment and history events.
; Syntax ........: _Smoke()
; Parameters ....: None.
; Return values .: True on success.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Smoke()
	Local $hTimer = TimerInit()
	While Not $g_bPageReady And TimerDiff($hTimer) < 5000
		GUIGetMsg()
		Sleep(10)
	WEnd
	If Not $g_bPageReady Or $g_sSource <> $g_sPage Or Not $g_bNewDocument Then Return False
	If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_SOURCE_CHANGED, _OnSource) Then Return False
	Local $iEvents = $g_iSourceEvents
	_WebView2_ExecuteScript($g_iView, "location.hash = 'sample';", 3000)
	If @error Or Not _WaitForSource($g_sPage & $g_sFragment) Then Return False
	If $g_bNewDocument Or $g_iSourceEvents <> $iEvents + 1 Then Return False
	If Not _WebView2_GoBack($g_iView) Or Not _WaitForSource($g_sPage) Then Return False
	If $g_bNewDocument Or $g_iSourceEvents <> $iEvents + 2 Then Return False
	If Not _WebView2_Navigate($g_iView, $g_sOther) Or Not _WaitForSource($g_sOther) Then Return False
	If Not $g_bNewDocument Or $g_iSourceEvents <> $iEvents + 3 Then Return False
	_Log("Smoke: native address, document flag, history, and callback replacement verified.")
	Return True
EndFunc   ;==>_Smoke

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _WaitForSource
; Description ...: Waits for one specific native source event.
; Syntax ........: _WaitForSource($sURI)
; Parameters ....: $sURI - Expected top-level URI.
; Return values .: True if the event arrives within five seconds.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WaitForSource($sURI)
	Local $hTimer = TimerInit()
	While $g_sSource <> $sURI And TimerDiff($hTimer) < 5000
		GUIGetMsg()
		Sleep(10)
	WEnd
	Return $g_sSource = $sURI
EndFunc   ;==>_WaitForSource

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
	ConsoleWrite("[053] " & $sMessage & @CRLF)
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
