#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_iView = -1, $g_iFrame = 0, $g_idStatus = 0
Global $g_bFrameReady = False, $g_bBufferReceived = False, $g_bGeoDenied = False
Global $g_iPermissionCount = 0, $g_iCaptureCount = 0

Exit _Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Demonstrates native frame permission, shared buffer and screen capture callbacks.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: Exit code.
; Author ........: mLipok
; Modified ......:
; Remarks .......: A separate profile is used; no Internet access is required.
; ===============================================================================================================================
Func _Example()
	Local $iExitCode = 0
	Local $hGUI = GUICreate("WebView2 - Advanced frame APIs", 920, 600, -1, -1, $WS_OVERLAPPEDWINDOW)
	Local $idBuffer = GUICtrlCreateButton("Send read-only buffer to frame", 12, 10, 225, 30)
	$g_idStatus = GUICtrlCreateLabel("Starting WebView2...", 250, 16, 650, 24)
	GUISetState(@SW_SHOW, $hGUI)
	Local $bSetup = False
	Do
		Local $sProfile = @TempDir & "\WebView2AdvancedFrames_" & @AutoItPID
		If Not _WebView2_Init(Default, $sProfile) Then ExitLoop 1
		Local $aSize = WinGetClientSize($hGUI)
		$g_iView = _WebView2_Create($hGUI, 0, 48, $aSize[0], $aSize[1] - 48)
		If @error Then ExitLoop 1
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_CREATED, _OnFrameCreated) Then ExitLoop 1
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_WEB_MESSAGE_RECEIVED, _OnFrameMessage) Then ExitLoop 1
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_PERMISSION_REQUESTED, _OnFramePermission) Then ExitLoop 1
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_SCREEN_CAPTURE_STARTING, _OnFrameCapture) Then ExitLoop 1
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_iView, "advanced-frame.example", @ScriptDir & "\033_AdvancedFrameAPIs") Then ExitLoop 1
		If Not _WebView2_Navigate($g_iView, "https://advanced-frame.example/index.html") Then ExitLoop 1
		$bSetup = True
	Until True
	If Not $bSetup Then
		_Status("Setup failed: " & _WebView2_Error_GetDescription())
		$iExitCode = 1
	EndIf
	Local $bSmoke = $CmdLine[0] > 0 And $CmdLine[1] = "--smoke"
	Local $hTimer = TimerInit(), $bSent = False, $bGeoRequested = False
	While $iExitCode = 0
		If $bSmoke And $g_bFrameReady And Not $bSent Then
			$bSent = _SendBuffer()
			If Not $bSent Then $iExitCode = 1
		EndIf
		If $bSmoke And $g_bBufferReceived And Not $bGeoRequested Then
			$bGeoRequested = True
			_WebView2_Frame_ExecuteScript($g_iFrame, "document.getElementById('location').click(); true")
			If @error Then
				_Status("Could not request frame geolocation.")
				$iExitCode = 1
				ExitLoop
			EndIf
		EndIf
		If $bSmoke And $g_bGeoDenied And $g_iPermissionCount > 0 Then
			ConsoleWrite("EX_SMOKE_OK example=033 arch=" & (@AutoItX64 ? "x64" : "x86") & @CRLF)
			ExitLoop
		EndIf
		If $bSmoke And TimerDiff($hTimer) > 15000 Then
			_Status("Smoke timed out waiting for the frame buffer receipt.")
			$iExitCode = 1
			ExitLoop
		EndIf
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $idBuffer
				_SendBuffer()
			Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
				$aSize = WinGetClientSize($hGUI)
				If IsArray($aSize) Then _WebView2_SetBounds($g_iView, 0, 48, $aSize[0], $aSize[1] - 48)
		EndSwitch
		Sleep(10)
	WEnd
	_WebView2_Cleanup()
	GUIDelete($hGUI)
	Return $iExitCode
EndFunc   ;==>_Example

Func _OnFrameCreated($iView, $iFrame)
	If $iView = $g_iView Then $g_iFrame = $iFrame
	Return
EndFunc   ;==>_OnFrameCreated

Func _OnFrameMessage($iView, $iFrame, $sMessage, $sSource, $bJSON)
	#forceref $bJSON
	If $iView <> $g_iView Or $iFrame <> $g_iFrame Or $sSource <> "https://advanced-frame.example/frame.html" Then Return
	Switch $sMessage
		Case "ready"
			$g_bFrameReady = True
			_Status("Frame ready. Send binary data or try the frame buttons.")
		Case "buffer:Hello from AutoIt"
			$g_bBufferReceived = True
			_Status("Frame read the shared buffer: Hello from AutoIt")
		Case "geolocation-denied"
			$g_bGeoDenied = True
			_Status("Frame geolocation denied by AutoIt; requests=" & $g_iPermissionCount)
		Case "capture-denied"
			_Status("Frame screen capture cancelled by AutoIt; requests=" & $g_iCaptureCount)
	EndSwitch
	Return
EndFunc   ;==>_OnFrameMessage

Func _OnFramePermission($iView, $iFrame, $sURI, $iKind, $bUserInitiated)
	#forceref $bUserInitiated
	If $iView = $g_iView And $iFrame = $g_iFrame And $sURI = "https://advanced-frame.example/" And $iKind = $WEBVIEW2_PERMISSION_KIND_GEOLOCATION Then
		$g_iPermissionCount += 1
		Local $aDecision[2] = [$WEBVIEW2_PERMISSION_STATE_DENY, False]
		Return $aDecision
	EndIf
	Return $WEBVIEW2_PERMISSION_STATE_DEFAULT
EndFunc   ;==>_OnFramePermission

Func _OnFrameCapture($iView, $iFrame)
	If $iView = $g_iView And $iFrame = $g_iFrame Then
		$g_iCaptureCount += 1
		Return True
	EndIf
	Return False
EndFunc   ;==>_OnFrameCapture

Func _SendBuffer()
	If Not $g_bFrameReady Or $g_iFrame < 1 Then
		_Status("Wait for the frame to finish loading.")
		Return False
	EndIf
	Local $bSent = _WebView2_Frame_PostSharedBuffer($g_iFrame, StringToBinary("Hello from AutoIt", 4), '{"source":"AutoIt"}')
	If Not $bSent Then _Status("Shared buffer failed: " & _WebView2_Error_GetDescription())
	Return $bSent
EndFunc   ;==>_SendBuffer

Func _Status($sText)
	GUICtrlSetData($g_idStatus, $sText)
	ConsoleWrite($sText & @CRLF)
	Return
EndFunc   ;==>_Status
