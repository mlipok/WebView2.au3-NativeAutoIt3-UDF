#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_iView = -1, $g_iFrame = 0, $g_iWorker = 0, $g_idStatus = 0
Global $g_bFrameReady = False, $g_bWorkerReady = False, $g_bReply = False, $g_bDestroyed = False
Global $g_iWorkerCount = 0, $g_sWorkerURI = "", $g_bInvalidMessage = False

Exit _Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Demonstrates native worker creation, JSON messaging and destruction in an iframe.
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
	Local $hGUI = GUICreate("WebView2 - Frame dedicated worker", 1020, 550, -1, -1, $WS_OVERLAPPEDWINDOW)
	Local $idStart = GUICtrlCreateButton("Create worker in iframe", 12, 10, 190, 30)
	Local $idSend = GUICtrlCreateButton("Send JSON to worker", 210, 10, 170, 30)
	Local $idTerminate = GUICtrlCreateButton("Terminate worker", 388, 10, 160, 30)
	$g_idStatus = GUICtrlCreateLabel("Starting WebView2...", 560, 16, 445, 24)
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
		If Not $bSmokeLate And Not _RegisterWorkerCallbacks() Then ExitLoop 1
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_iView, "udf-virtual-host.example", @ScriptDir & "\034_FrameDedicatedWorker") Then ExitLoop 1
		If Not _WebView2_Navigate($g_iView, "https://udf-virtual-host.example/index.html") Then ExitLoop 1
		$bSetup = True
	Until True
	If Not $bSetup Then
		_Status("Setup failed: " & _WebView2_Error_GetDescription())
		$iExitCode = 1
	EndIf
	Local $bSmoke = $CmdLine[0] > 0 And ($CmdLine[1] = "--smoke" Or $bSmokeLate)
	Local $bTriggered = False, $bLateRegistered = False, $bSent = False, $bTerminated = False, $hTimer = TimerInit()
	While $iExitCode = 0
		If $bSmoke And $g_bFrameReady And Not $bTriggered Then
			If $bSmokeLate And Not $bLateRegistered Then
				If Not _RegisterWorkerCallbacks() Then
					$iExitCode = 1
					ExitLoop
				EndIf
				$bLateRegistered = True
			EndIf
			$bTriggered = True
			If Not _StartWorker() Then $iExitCode = 1
		EndIf
		If $bSmoke And $g_bWorkerReady And Not $bSent Then
			$bSent = True
			Local $aActiveWorkers = _WebView2_Worker_List($g_iView)
			Local $iActiveListError = @error
			If $iActiveListError Or UBound($aActiveWorkers) <> 1 Then
				$iExitCode = 1
			ElseIf $aActiveWorkers[0] <> $g_iWorker Then
				$iExitCode = 1
			ElseIf Not _SendJSON() Then
				$iExitCode = 1
			EndIf
		EndIf
		If $bSmoke And $g_bReply And Not $bTerminated Then
			$bTerminated = True
			If Not _TerminateWorker() Then $iExitCode = 1
		EndIf
		If $bSmoke And $g_bDestroyed Then
			Local $aWorkers = _WebView2_Worker_List($g_iView)
			Local $iListError = @error
			Local $bStaleSend = _WebView2_Worker_PostWebMessageAsJson($g_iWorker, '{"kind":"stale"}')
			Local $iStaleError = @error
			If $iListError Or UBound($aWorkers) <> 0 Or $g_iWorkerCount <> 1 Or $g_sWorkerURI <> "https://udf-virtual-host.example/worker.js" Or _
					$g_bInvalidMessage Or $bStaleSend Or $iStaleError <> $WEBVIEW2_ERR_INVALID_PARAMETER Then
				$iExitCode = 1
			Else
				ConsoleWrite("EX_SMOKE_OK example=034 arch=" & (@AutoItX64 ? "x64" : "x86") & " frame=" & $g_iFrame & " worker=" & $g_iWorker & @CRLF)
			EndIf
			ExitLoop
		EndIf
		If $bSmoke And TimerDiff($hTimer) > 15000 Then
			_Status("Smoke timed out waiting for worker creation, JSON reply or destruction.")
			$iExitCode = 1
			ExitLoop
		EndIf
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $idStart
				_StartWorker()
			Case $idSend
				_SendJSON()
			Case $idTerminate
				_TerminateWorker()
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
; Remarks .......: The iframe owns the worker; the UDF tracks its native interface until destruction.
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
		$g_bWorkerReady = False
		$g_bReply = False
		$g_bDestroyed = False
		Local $sResult = _WebView2_Frame_ExecuteScript($g_iFrame, "startWorker()")
		If @error Or $sResult <> "true" Then
			_Status("Could not start the worker in the iframe.")
			ExitLoop 1
		EndIf
		$bResult = True
	Until True
	Return $bResult
EndFunc   ;==>_StartWorker

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _RegisterWorkerCallbacks
; Description ...: Registers the original notification and tracked-worker lifecycle events.
; Syntax ........: _RegisterWorkerCallbacks()
; Parameters ....: None.
; Return values .: True when all callbacks were registered, otherwise False.
; Author ........: mLipok
; Modified ......:
; Remarks .......: --smoke-late calls this after the iframe has been tracked.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _RegisterWorkerCallbacks()
	Local $bResult = False
	Do
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_DEDICATED_WORKER_CREATED, _OnWorkerCreated) Then ExitLoop 1
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_WORKER_CREATED, _OnWorkerTracked) Then ExitLoop 1
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_WORKER_WEB_MESSAGE_RECEIVED, _OnWorkerMessage) Then ExitLoop 1
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_WORKER_DESTROYING, _OnWorkerDestroying) Then ExitLoop 1
		$bResult = True
	Until True
	Return $bResult
EndFunc   ;==>_RegisterWorkerCallbacks

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _SendJSON
; Description ...: Sends one JSON request directly to the tracked worker.
; Syntax ........: _SendJSON()
; Parameters ....: None.
; Return values .: True when WebView2 accepts the message, otherwise False.
; Author ........: mLipok
; Modified ......:
; Remarks .......: A native WebMessageReceived callback confirms the worker's reply separately.
; Related .......: _OnWorkerMessage
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _SendJSON()
	Local $bResult = False
	Do
		If Not $g_iWorker Or Not $g_bWorkerReady Then
			_Status("Wait for the worker's native ready message.")
			ExitLoop 1
		EndIf
		If Not _WebView2_Worker_PostWebMessageAsJson($g_iWorker, '{"kind":"add","requestId":1,"values":[2,3]}') Then
			_Status("Could not send JSON to worker: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		_Status("JSON sent to worker " & $g_iWorker & "; waiting for its reply.")
		$bResult = True
	Until True
	Return $bResult
EndFunc   ;==>_SendJSON

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _TerminateWorker
; Description ...: Asks the owning iframe to terminate its worker.
; Syntax ........: _TerminateWorker()
; Parameters ....: None.
; Return values .: True when the iframe script runs, otherwise False.
; Author ........: mLipok
; Modified ......:
; Remarks .......: WebView2 then raises the worker's native Destroying event.
; Related .......: _OnWorkerDestroying
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _TerminateWorker()
	Local $bResult = False
	Do
		If Not $g_iWorker Or $g_bDestroyed Then
			_Status("No active worker to terminate.")
			ExitLoop 1
		EndIf
		Local $sResult = _WebView2_Frame_ExecuteScript($g_iFrame, "terminateWorker()")
		If @error Or $sResult <> "true" Then
			_Status("Could not terminate the iframe's worker.")
			ExitLoop 1
		EndIf
		$bResult = True
	Until True
	Return $bResult
EndFunc   ;==>_TerminateWorker

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
; Name ..........: _OnWorkerTracked
; Description ...: Receives the worker ID added by the UDF's native registry.
; Syntax ........: _OnWorkerTracked($iView, $iFrame, $iWorker, $sScriptURI)
; Parameters ....: $iView - Owner WebView2 instance.
;                  $iFrame - Owner tracked iframe ID.
;                  $iWorker - New worker ID.
;                  $sScriptURI - Worker script URI.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Do not run blocking WebView2 operations inside this callback.
; Related .......: _OnWorkerCreated
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _OnWorkerTracked($iView, $iFrame, $iWorker, $sScriptURI)
	If $iView = $g_iView And $iFrame = $g_iFrame Then
		$g_iWorker = $iWorker
		$g_sWorkerURI = $sScriptURI
		_Status("Worker " & $iWorker & " is tracked; waiting for its ready message.")
	EndIf
	Return
EndFunc   ;==>_OnWorkerTracked

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _OnWorkerMessage
; Description ...: Processes a JSON message sent directly from the worker to AutoIt.
; Syntax ........: _OnWorkerMessage($iView, $iFrame, $iWorker, $sJSON, $sSource)
; Parameters ....: $iView - Owner WebView2 instance.
;                  $iFrame - Owner tracked iframe ID.
;                  $iWorker - Tracked worker ID.
;                  $sJSON - Raw JSON text.
;                  $sSource - Worker script URI.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This local example accepts only its expected worker script address.
; Related .......: _SendJSON
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _OnWorkerMessage($iView, $iFrame, $iWorker, $sJSON, $sSource)
	If $iView = $g_iView And $iFrame = $g_iFrame And $iWorker = $g_iWorker Then
		If $sSource <> "https://udf-virtual-host.example/worker.js" Then
			$g_bInvalidMessage = True
			_Status("Rejected worker message from unexpected source: " & $sSource)
		ElseIf StringInStr($sJSON, '"kind":"ready"') Then
			$g_bWorkerReady = True
			_Status("Worker " & $iWorker & " ready. Click Send JSON to worker.")
		ElseIf StringInStr($sJSON, '"kind":"result"') And StringInStr($sJSON, '"requestId":1') And StringInStr($sJSON, '"sum":5') Then
			$g_bReply = True
			_Status("Worker " & $iWorker & " replied with JSON: " & $sJSON)
		EndIf
	EndIf
	Return
EndFunc   ;==>_OnWorkerMessage

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _OnWorkerDestroying
; Description ...: Reports native worker destruction after the UDF invalidates its ID.
; Syntax ........: _OnWorkerDestroying($iView, $iFrame, $iWorker, $sScriptURI)
; Parameters ....: $iView - Owner WebView2 instance.
;                  $iFrame - Owner tracked iframe ID.
;                  $iWorker - Worker ID that has become invalid.
;                  $sScriptURI - Worker script URI.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: A stale worker ID cannot be used for further messages.
; Related .......: _TerminateWorker
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _OnWorkerDestroying($iView, $iFrame, $iWorker, $sScriptURI)
	#forceref $sScriptURI
	If $iView = $g_iView And $iFrame = $g_iFrame And $iWorker = $g_iWorker Then
		$g_bDestroyed = True
		_Status("Worker " & $iWorker & " was destroyed; its ID is no longer valid.")
	EndIf
	Return
EndFunc   ;==>_OnWorkerDestroying

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
