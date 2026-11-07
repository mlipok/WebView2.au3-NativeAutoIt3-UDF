#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global Const $g_sHost = "autoit-permission.example"
Global Const $g_sOrigin = "https://" & $g_sHost & "/"
Global $g_iWebView = -1, $g_idStatus = 0
Global $g_bReady = False, $g_bPermissionSeen = False, $g_bDenied = False
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
; Remarks .......: The example denies geolocation; it never obtains location data.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example()
	Local $iExitCode = 1
	Local $hGUI = GUICreate("WebView2 - Permission requests", 800, 520, -1, -1, $WS_OVERLAPPEDWINDOW)
	$g_idStatus = GUICtrlCreateLabel("Starting WebView2...", 10, 10, 780, 25)
	GUISetState(@SW_SHOW, $hGUI)
	Do
		Local $sProfile = @TempDir & "\WebView2PermissionExample_" & @AutoItPID
		If Not _WebView2_Init(Default, $sProfile) Then ExitLoop
		Local $aSize = WinGetClientSize($hGUI)
		$g_iWebView = _WebView2_Create($hGUI, 0, 40, $aSize[0], $aSize[1] - 40)
		If @error Then ExitLoop
		If Not _WebView2_SetCallback($g_iWebView, $WEBVIEW2_EVENT_PERMISSION_REQUESTED, _Example_OnPermission) Then ExitLoop
		If Not _WebView2_SetCallback($g_iWebView, $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED, _Example_OnMessage) Then ExitLoop
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_iWebView, $g_sHost, @ScriptDir & "\031_PermissionRequests") Then ExitLoop
		If Not _WebView2_Navigate($g_iWebView, $g_sOrigin & "index.html") Then ExitLoop
		$iExitCode = 0
	Until True
	If $iExitCode Then _Example_Status("Setup failed: " & _WebView2_Error_GetDescription())
	Local $hTimer = TimerInit(), $bRequested = False
	While $iExitCode = 0
		If $g_bSmoke Then
			If $g_bReady And Not $bRequested Then
				$bRequested = True
				_WebView2_ExecuteScript($g_iWebView, "document.getElementById('request').click(); true")
				If @error Then
					_Example_Status("Could not start the permission request.")
					$iExitCode = 1
					ExitLoop
				EndIf
			EndIf
			If $g_bPermissionSeen And $g_bDenied Then
				ConsoleWrite("EX_SMOKE_OK example=031 arch=" & (@AutoItX64 ? "x64" : "x86") & @CRLF)
				ExitLoop
			EndIf
			If TimerDiff($hTimer) > 15000 Then
				_Example_Status("Smoke timed out waiting for permission denial.")
				$iExitCode = 1
				ExitLoop
			EndIf
		EndIf
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
				Local $aClient = WinGetClientSize($hGUI)
				If IsArray($aClient) And $g_iWebView >= 0 Then _WebView2_SetBounds($g_iWebView, 0, 40, $aClient[0], $aClient[1] - 40)
		EndSwitch
		Sleep(10)
	WEnd
	_WebView2_Cleanup()
	GUIDelete($hGUI)
	Return $iExitCode
EndFunc   ;==>_Example

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_OnPermission
; Description ...: Denies geolocation requests from this example's local origin.
; Syntax ........: _Example_OnPermission($iWebView, $sURI, $iKind, $bUserInitiated)
; Parameters ....: $iWebView - Requesting WebView2 instance.
;                  $sURI - Origin requesting permission.
;                  $iKind - Native WebView2 permission kind.
;                  $bUserInitiated - True when WebView2 reports a user gesture.
; Return values .: DENY for this example's geolocation request; DEFAULT otherwise.
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
		$g_bPermissionSeen = True
		_Example_Status("AutoIt denied geolocation for " & $sURI)
		Return $WEBVIEW2_PERMISSION_STATE_DENY
	EndIf
	Return $WEBVIEW2_PERMISSION_STATE_DEFAULT
EndFunc   ;==>_Example_OnPermission

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_OnMessage
; Description ...: Receives readiness and geolocation error messages from the local page.
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
		_Example_Status("Ready. Click Request geolocation in the page.")
	ElseIf StringInStr($sMessage, '"type":"denied"') Then
		$g_bDenied = True
		_Example_Status("The page received the geolocation denial.")
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
	ConsoleWrite($sText & @CRLF)
	Return
EndFunc   ;==>_Example_Status
