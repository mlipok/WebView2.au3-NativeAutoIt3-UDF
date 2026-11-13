#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_iView = -1, $g_iFrame = 0, $g_idStatus = 0
Global $g_bFrameReady = False, $g_iWorkerCount = 0, $g_sWorkerURI = ""

Exit _Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Demonstrates native detection of a dedicated worker created by an iframe.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: Exit code.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Uses an isolated profile and a mapped local folder; no Internet is required.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example()
	Local $iExitCode = 0
	Local $bSmokeLate = $CmdLine[0] > 0 And $CmdLine[1] = "--smoke-late"
	Local $hGUI = GUICreate("WebView2 - Frame dedicated worker", 900, 550, -1, -1, $WS_OVERLAPPEDWINDOW)
	Local $idStart = GUICtrlCreateButton("Create worker in iframe", 12, 10, 190, 30)
	$g_idStatus = GUICtrlCreateLabel("Starting WebView2...", 215, 16, 665, 24)
	GUISetState(@SW_SHOW, $hGUI)
	Local $bSetup = False
	Do
		Local $sProfile = @TempDir & "\WebView2FrameWorker_" & @AutoItPID
		If Not _WebView2_Init(Default, $sProfile) Then ExitLoop 1
		Local $aSize = WinGetClientSize($hGUI)
		$g_iView = _WebView2_Create($hGUI, 0, 48, $aSize[0], $aSize[1] - 48)
		If @error Then ExitLoop 1
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_CREATED, _OnFrameCreated) Then ExitLoop 1
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_WEB_MESSAGE_RECEIVED, _OnFrameMessage) Then ExitLoop 1
		If Not $bSmokeLate Then
			If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_DEDICATED_WORKER_CREATED, _OnWorkerCreated) Then ExitLoop 1
		EndIf
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_iView, "udf-virtual-host.example", @ScriptDir & "\034_FrameDedicatedWorker") Then ExitLoop 1
		If Not _WebView2_Navigate($g_iView, "https://udf-virtual-host.example/index.html") Then ExitLoop 1
		$bSetup = True
	Until True
	If Not $bSetup Then
		_Status("Setup failed: " & _WebView2_Error_GetDescription())
		$iExitCode = 1
	EndIf
	Local $bSmoke = $CmdLine[0] > 0 And ($CmdLine[1] = "--smoke" Or $bSmokeLate)
	Local $bTriggered = False, $bLateRegistered = False, $hTimer = TimerInit()
	While $iExitCode = 0
		If $bSmoke And $g_bFrameReady And Not $bTriggered Then
			If $bSmokeLate And Not $bLateRegistered Then
				If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_DEDICATED_WORKER_CREATED, _OnWorkerCreated) Then
					$iExitCode = 1
					ExitLoop
				EndIf
				$bLateRegistered = True
			EndIf
			$bTriggered = True
			If Not _StartWorker() Then $iExitCode = 1
		EndIf
		If $bSmoke And $g_iWorkerCount = 1 Then
			If $g_sWorkerURI <> "https://udf-virtual-host.example/worker.js" Then
				_Status("Unexpected worker script URI: " & $g_sWorkerURI)
				$iExitCode = 1
			Else
				ConsoleWrite("EX_SMOKE_OK example=034 arch=" & (@AutoItX64 ? "x64" : "x86") & " frame=" & $g_iFrame & @CRLF)
			EndIf
			ExitLoop
		EndIf
		If $bSmoke And TimerDiff($hTimer) > 15000 Then
			_Status("Smoke timed out waiting for the native worker callback.")
			$iExitCode = 1
			ExitLoop
		EndIf
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $idStart
				_StartWorker()
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

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _StartWorker
; Description ...: Starts one worker from the tracked iframe's script context.
; Syntax ........: _StartWorker()
; Parameters ....: None.
; Return values .: True on success, False when the frame is unavailable or script execution fails.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The iframe page owns the worker; the UDF only observes its creation.
; Related .......: _OnWorkerCreated
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _StartWorker()
	Local $bResult = False
	Do
		If Not $g_bFrameReady Or Not $g_iFrame Then
			_Status("Wait until the iframe is ready.")
			ExitLoop 1
		EndIf
		_WebView2_Frame_ExecuteScript($g_iFrame, "startWorker(); true")
		If @error Then
			_Status("Could not start the worker in the iframe.")
			ExitLoop 1
		EndIf
		$bResult = True
	Until True
	Return $bResult
EndFunc   ;==>_StartWorker

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _OnFrameCreated
; Description ...: Remembers the tracked iframe ID.
; Syntax ........: _OnFrameCreated($iView, $iFrame)
; Parameters ....: $iView - Owner WebView2 instance.
;                  $iFrame - Tracked frame ID.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This example contains one iframe.
; Related .......: _OnWorkerCreated
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _OnFrameCreated($iView, $iFrame)
	If $iView = $g_iView Then $g_iFrame = $iFrame
	Return
EndFunc   ;==>_OnFrameCreated

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _OnFrameMessage
; Description ...: Marks the local iframe ready after its own script loads.
; Syntax ........: _OnFrameMessage($iView, $iFrame, $sMessage, $sSource, $bJSON)
; Parameters ....: Native frame message callback values.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Only the exact mapped page is accepted.
; Related .......: _StartWorker
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _OnFrameMessage($iView, $iFrame, $sMessage, $sSource, $bJSON)
	#forceref $bJSON
	If $iView = $g_iView And $iFrame = $g_iFrame And $sSource = "https://udf-virtual-host.example/frame.html" And $sMessage = "ready" Then
		$g_bFrameReady = True
		_Status("Iframe ready. Click Create worker in iframe.")
	EndIf
	Return
EndFunc   ;==>_OnFrameMessage

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _OnWorkerCreated
; Description ...: Reports the native Frame8 worker-created notification.
; Syntax ........: _OnWorkerCreated($iView, $iFrame, $sScriptURI)
; Parameters ....: $iView - Owner WebView2 instance.
;                  $iFrame - Tracked iframe ID.
;                  $sScriptURI - Fully qualified worker script URI.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Do not call blocking WebView2 helpers from this callback.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _OnWorkerCreated($iView, $iFrame, $sScriptURI)
	If $iView = $g_iView And $iFrame = $g_iFrame Then
		$g_iWorkerCount += 1
		$g_sWorkerURI = $sScriptURI
		_Status("Frame ID " & $iFrame & " created worker " & $g_iWorkerCount & ": " & $sScriptURI)
	EndIf
	Return
EndFunc   ;==>_OnWorkerCreated

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Status
; Description ...: Updates the native status label.
; Syntax ........: _Status($sText)
; Parameters ....: $sText - Status text.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Status($sText)
	GUICtrlSetData($g_idStatus, $sText)
	Return
EndFunc   ;==>_Status
