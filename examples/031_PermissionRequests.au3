#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global Const $g_sHost = "udf-virtual-host.example"
Global Const $g_sOrigin = "https://" & $g_sHost & "/"
Global $g_iWebView = -1, $g_idStatus = 0, $g_idLog = 0, $g_idGuide = 0
Global $g_bReady = False, $g_bRequestPending = False, $g_bPageDone = False
Global $g_iDecision = $WEBVIEW2_PERMISSION_STATE_DENY, $g_iDecisionCount = 0
Global $g_sMode = "deny", $g_sPageResult = ""
Global $g_bSmoke = False
If $CmdLine[0] > 0 Then $g_bSmoke = ($CmdLine[1] = "--smoke")

Exit _Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Shows a native WebView2 permission request and an immediate host decision.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: 0 on normal close or successful smoke run; 1 on setup or smoke failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Two page buttons select DENY or ALLOW; the page displays coordinates when available.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example()
	Local $iExitCode = 1
	Local $hGUI = GUICreate("WebView2 - Permission requests", 800, 520, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	$g_idStatus = GUICtrlCreateLabel("Starting WebView2...", 10, 10, 780, 25)

	GUICtrlSetResizing($g_idStatus, $GUI_DOCKALL)
	GUICtrlCreateLabel("Operation log", 5, 43, 290, 18)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	$g_idLog = GUICtrlCreateEdit("", 5, 64, 290, 446, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	Local $sGuide = "TEST PROCEDURE" & @CRLF & "1. Click Deny geolocation, then Allow geolocation." & @CRLF & "EXPECTED RESULT" & @CRLF & "The page reports denial first; Allow may return coordinates or a location-provider error." & @CRLF & "HOW IT WORKS" & @CRLF & "A native WebView2 permission callback decides each request without saving the decision."
	$g_idGuide = GUICtrlCreateEdit($sGuide, 305, 340, 790, 170, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	GUICtrlSetBkColor(-1, 0xFFF4C2)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	GUISetState(@SW_MAXIMIZE, $hGUI)
	Local $aPanelSize = WinGetClientSize($hGUI)
	If IsArray($aPanelSize) Then
		GUICtrlSetPos($g_idLog, 5, 64, 290, $aPanelSize[1] - 74)
		GUICtrlSetPos($g_idGuide, 305, $aPanelSize[1] - 180, $aPanelSize[0] - 310, 170)
	EndIf
	Do
		Local $sProfile = @TempDir & "\WebView2PermissionExample_" & @AutoItPID
		If Not _WebView2_Init(Default, $sProfile) Then ExitLoop
		Local $aSize = WinGetClientSize($hGUI)
		$g_iWebView = _WebView2_Create($hGUI, 305, 40, $aSize[0] - 310, $aSize[1] - 230)
		If @error Then ExitLoop
		If Not _WebView2_SetCallback($g_iWebView, $WEBVIEW2_EVENT_PERMISSION_REQUESTED, _Example_OnPermission) Then ExitLoop
		If Not _WebView2_SetCallback($g_iWebView, $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED, _Example_OnMessage) Then ExitLoop
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_iWebView, $g_sHost, @ScriptDir & "\031_PermissionRequests") Then ExitLoop
		If Not _WebView2_Navigate($g_iWebView, $g_sOrigin & "index.html") Then ExitLoop
		$iExitCode = 0
	Until True
	If $iExitCode Then _Example_Status("Setup failed: " & _WebView2_Error_GetDescription())
	Local $hTimer = TimerInit(), $iSmokeStage = 0
	While $iExitCode = 0
		If $g_bRequestPending Then
			$g_bRequestPending = False
			_WebView2_ExecuteScript($g_iWebView, "requestLocation(" & _WebView2_JavaScriptStringLiteral($g_sMode) & "); true")
			If @error Then
				_Example_Status("Could not start the permission request.")
				$iExitCode = 1
				ExitLoop
			EndIf
		EndIf
		If $g_bSmoke Then
			If $g_bReady And $iSmokeStage = 0 Then
				$iSmokeStage = 1
				_WebView2_ExecuteScript($g_iWebView, "document.getElementById('deny').click(); true")
				If @error Then
					_Example_Status("Could not click DENY.")
					$iExitCode = 1
					ExitLoop
				EndIf
			EndIf
			If $iSmokeStage = 1 And $g_iDecisionCount = 1 And $g_bPageDone And $g_sPageResult = "denied" Then
				$g_bPageDone = False
				$iSmokeStage = 2
				_WebView2_ExecuteScript($g_iWebView, "document.getElementById('allow').click(); true")
				If @error Then
					_Example_Status("Could not click ALLOW.")
					$iExitCode = 1
					ExitLoop
				EndIf
			EndIf
			If $iSmokeStage = 2 And $g_iDecisionCount = 2 And $g_bPageDone Then
				ConsoleWrite("EX_SMOKE_OK example=031 arch=" & (@AutoItX64 ? "x64" : "x86") & @CRLF)
				ExitLoop
			EndIf
			If TimerDiff($hTimer) > 20000 Then
				_Example_Status("Smoke timed out waiting for DENY and ALLOW decisions.")
				$iExitCode = 1
				ExitLoop
			EndIf
		EndIf
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
				Local $aClient = WinGetClientSize($hGUI)
				If IsArray($aClient) And $g_iWebView >= 0 Then
					GUICtrlSetPos($g_idLog, 5, 64, 290, $aClient[1] - 74)
					GUICtrlSetPos($g_idGuide, 305, $aClient[1] - 180, $aClient[0] - 310, 170)
					_WebView2_SetBounds($g_iWebView, 305, 40, $aClient[0] - 310, $aClient[1] - 230)
				EndIf
		EndSwitch
		Sleep(10)
	WEnd
	_WebView2_Cleanup()
	GUIDelete($hGUI)
	Return $iExitCode
EndFunc   ;==>_Example

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_OnPermission
; Description ...: Applies the selected geolocation decision to this example's local origin.
; Syntax ........: _Example_OnPermission($iWebView, $sURI, $iKind, $bUserInitiated)
; Parameters ....: $iWebView - Requesting WebView2 instance.
;                  $sURI - Origin requesting permission.
;                  $iKind - Native WebView2 permission kind.
;                  $bUserInitiated - True when WebView2 reports a user gesture.
; Return values .: [selected state, False] for this origin; DEFAULT otherwise.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Do not show a modal dialog or call blocking WebView2 helpers here.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_OnPermission($iWebView, $sURI, $iKind, $bUserInitiated)
	#forceref $bUserInitiated
	If $iWebView = $g_iWebView And $sURI = $g_sOrigin And $iKind = $WEBVIEW2_PERMISSION_KIND_GEOLOCATION Then
		$g_iDecisionCount += 1
		_Example_Status("AutoIt " & ($g_iDecision = $WEBVIEW2_PERMISSION_STATE_ALLOW ? "allowed" : "denied") & " geolocation for " & $sURI)
		Local $aDecision[2] = [$g_iDecision, False]
		Return $aDecision
	EndIf
	Return $WEBVIEW2_PERMISSION_STATE_DEFAULT
EndFunc   ;==>_Example_OnPermission

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_OnMessage
; Description ...: Receives button requests and geolocation results from the local page.
; Syntax ........: _Example_OnMessage($iWebView, $sMessage, $sSource, $bJSON)
; Parameters ....: $iWebView - Sending WebView2 instance.
;                  $sMessage - JSON message.
;                  $sSource - Sending page URL.
;                  $bJSON - True for JSON objects.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Only messages from the mapped origin are accepted.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_OnMessage($iWebView, $sMessage, $sSource, $bJSON)
	If $iWebView <> $g_iWebView Or Not $bJSON Or StringLeft($sSource, StringLen($g_sOrigin)) <> $g_sOrigin Then Return
	If StringInStr($sMessage, '"type":"ready"') Then
		$g_bReady = True
		_Example_Status("Ready. Choose DENY or ALLOW in the page.")
	ElseIf StringInStr($sMessage, '"type":"request"') Then
		$g_sMode = StringInStr($sMessage, '"mode":"allow"') ? "allow" : "deny"
		$g_iDecision = ($g_sMode = "allow") ? $WEBVIEW2_PERMISSION_STATE_ALLOW : $WEBVIEW2_PERMISSION_STATE_DENY
		$g_bPageDone = False
		$g_bRequestPending = True
	ElseIf StringInStr($sMessage, '"type":"denied"') Then
		$g_sPageResult = "denied"
		$g_bPageDone = True
		_Example_Status("The page received the geolocation denial.")
	ElseIf StringInStr($sMessage, '"type":"allowed"') Then
		$g_sPageResult = "allowed"
		$g_bPageDone = True
		_Example_Status("The page received a location after AutoIt allowed access.")
	ElseIf StringInStr($sMessage, '"type":"error"') Then
		$g_sPageResult = "error"
		$g_bPageDone = True
		_Example_Status("AutoIt allowed access, but the location provider returned an error.")
	EndIf
	Return
EndFunc   ;==>_Example_OnMessage

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Status
; Description ...: Shows the current example state.
; Syntax ........: _Example_Status($sText)
; Parameters ....: $sText - Status text.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_Status($sText)
	GUICtrlSetData($g_idStatus, $sText)
	_GUICtrlEdit_AppendText($g_idLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sText & @CRLF)
	GUICtrlSendMsg($g_idLog, $EM_SCROLLCARET, 0, 0)
	ConsoleWrite($sText & @CRLF)
	Return
EndFunc   ;==>_Example_Status
