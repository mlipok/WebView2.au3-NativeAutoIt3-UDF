#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#include "..\WebView2.au3"

Global $g_iView = -1, $g_iFrame = 0, $g_idLog = 0
Global $g_iPageWorker = 0, $g_iFrameWorker = 0, $g_iPageChild = 0, $g_iFrameChild = 0
Global $g_bFrameReady = False, $g_bPageWorkerReady = False, $g_bFrameWorkerReady = False
Global $g_iReplies = 0, $g_bInvalidParent = False
Global Const $g_sOrigin = "https://udf-virtual-host.example/"

Exit _Example()

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Example
; Description ...: Demonstrates native worker ownership across the main document, an iframe and child workers.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: Zero on normal close or successful smoke test; one on setup or smoke failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Uses local virtual-host assets and a process-specific profile without Internet access.
; Related .......: _WebView2_Worker_GetParentId
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example()
	Local $iExit = 1, $bSetup = False
	Local $bSmoke = $CmdLine[0] > 0 And $CmdLine[1] = "--smoke"
	Local $hGUI = GUICreate("WebView2 - Worker hierarchy", 1120, 700, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	Local $aCaptions[7] = ["Create page worker", "Create frame worker", "Spawn page child", "Spawn frame child", "Send JSON", "List hierarchy", "Stop roots"]
	Local $aButtons[7]
	For $i = 0 To 6
		$aButtons[$i] = GUICtrlCreateButton($aCaptions[$i], 10 + $i * 157, 10, 150, 30)
		GUICtrlSetResizing(-1, $GUI_DOCKALL)
	Next
	GUICtrlCreateLabel("AutoIt operation log", 10, 49, 280, 18)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	$g_idLog = GUICtrlCreateEdit("", 10, 70, 290, 620, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idLog, 0xE2F0E4)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	GUISetState(@SW_MAXIMIZE, $hGUI)
	GUISetState(@SW_SHOWNOACTIVATE, $hGUI)
	Do
		Local $sProfile = @TempDir & "\WebView2WorkerHierarchy_" & @AutoItPID
		If Not _WebView2_Init(Default, $sProfile) Then ExitLoop 1
		Local $aSize = WinGetClientSize($hGUI)
		GUICtrlSetPos($g_idLog, 10, 70, 290, $aSize[1] - 80)
		$g_iView = _WebView2_Create($hGUI, 310, 50, $aSize[0] - 320, $aSize[1] - 60)
		If @error Then ExitLoop 1
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_CREATED, _OnFrameCreated) Then ExitLoop 1
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_WEB_MESSAGE_RECEIVED, _OnFrameMessage) Then ExitLoop 1
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_WORKER_CREATED, _OnWorkerCreated) Then ExitLoop 1
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_WORKER_WEB_MESSAGE_RECEIVED, _OnWorkerMessage) Then ExitLoop 1
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_WORKER_DESTROYING, _OnWorkerDestroying) Then ExitLoop 1
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_iView, "udf-virtual-host.example", @ScriptDir & "\035_WorkerHierarchy") Then ExitLoop 1
		If Not _WebView2_Navigate($g_iView, $g_sOrigin & "index.html") Then ExitLoop 1
		$bSetup = True
	Until True
	If $bSetup Then
		$iExit = 0
		_Status("Waiting for the iframe and worker creation events.")
	Else
		_Status("Setup failed: " & _WebView2_Error_GetDescription())
	EndIf
	Local $iSmokeStep = 0, $hTimer = TimerInit()
	While $iExit = 0
		If $bSmoke Then
			Switch $iSmokeStep
				Case 0
					If $g_bFrameReady Then
						_WebView2_ExecuteScript($g_iView, "startPageWorker()")
						If @error Then $iExit = 1
						$iSmokeStep = 1
					EndIf
				Case 1
					If $g_iPageWorker And $g_bPageWorkerReady Then
						_WebView2_Frame_ExecuteScript($g_iFrame, "startFrameWorker()")
						If @error Then $iExit = 1
						$iSmokeStep = 2
					EndIf
				Case 2
					If $g_iFrameWorker And $g_bFrameWorkerReady Then
						If Not _WebView2_Worker_PostWebMessageAsJson($g_iPageWorker, '{"kind":"spawn-child"}') Then $iExit = 1
						$iSmokeStep = 3
					EndIf
				Case 3
					If $g_iPageChild Then
						If Not _WebView2_Worker_PostWebMessageAsJson($g_iFrameWorker, '{"kind":"spawn-child"}') Then $iExit = 1
						$iSmokeStep = 4
					EndIf
				Case 4
					If $g_iFrameChild Then
						Local $aWorkers = _WebView2_Worker_List($g_iView)
						If @error Or UBound($aWorkers) <> 4 Or $g_bInvalidParent Or $g_iFrame <= 0 Then
							$iExit = 1
						Else
							If Not _WebView2_Worker_PostWebMessageAsJson($g_iPageChild, '{"kind":"add","values":[3,4]}') Then $iExit = 1
							If Not _WebView2_Worker_PostWebMessageAsJson($g_iFrameChild, '{"kind":"add","values":[3,4]}') Then $iExit = 1
						EndIf
						$iSmokeStep = 5
					EndIf
				Case 5
					If $g_iReplies >= 2 Then
						ConsoleWrite("EX_SMOKE_OK example=035 arch=" & (@AutoItX64 ? "x64" : "x86") & " workers=4 replies=" & $g_iReplies & @CRLF)
						ExitLoop
					EndIf
			EndSwitch
			If $iExit Or TimerDiff($hTimer) > 15000 Then
				_Status("Worker hierarchy smoke failed or timed out at step " & $iSmokeStep & ".")
				$iExit = 1
				ExitLoop
			EndIf
		EndIf
		Local $iMsg = GUIGetMsg()
		Switch $iMsg
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $aButtons[0]
				_LogClick($aCaptions[0])
				_WebView2_ExecuteScript($g_iView, "startPageWorker()")
			Case $aButtons[1]
				_LogClick($aCaptions[1])
				If $g_iFrame Then _WebView2_Frame_ExecuteScript($g_iFrame, "startFrameWorker()")
			Case $aButtons[2]
				_LogClick($aCaptions[2])
				If $g_iPageWorker Then _WebView2_Worker_PostWebMessageAsJson($g_iPageWorker, '{"kind":"spawn-child"}')
			Case $aButtons[3]
				_LogClick($aCaptions[3])
				If $g_iFrameWorker Then _WebView2_Worker_PostWebMessageAsJson($g_iFrameWorker, '{"kind":"spawn-child"}')
			Case $aButtons[4]
				_LogClick($aCaptions[4])
				If $g_iPageChild Then _WebView2_Worker_PostWebMessageAsJson($g_iPageChild, '{"kind":"add","values":[3,4]}')
				If $g_iFrameChild Then _WebView2_Worker_PostWebMessageAsJson($g_iFrameChild, '{"kind":"add","values":[3,4]}')
			Case $aButtons[5]
				_LogClick($aCaptions[5])
				Local $aList = _WebView2_Worker_List($g_iView)
				For $i = 0 To UBound($aList) - 1
					Local $iParent = _WebView2_Worker_GetParentId($aList[$i])
					_Status("Worker " & $aList[$i] & " has parent worker " & $iParent & ".")
				Next
			Case $aButtons[6]
				_LogClick($aCaptions[6])
				_WebView2_ExecuteScript($g_iView, "stopPageWorker()")
				If $g_iFrame Then _WebView2_Frame_ExecuteScript($g_iFrame, "stopFrameWorker()")
			Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
				$aSize = WinGetClientSize($hGUI)
				If IsArray($aSize) Then
					GUICtrlSetPos($g_idLog, 10, 70, 290, $aSize[1] - 80)
					_WebView2_SetBounds($g_iView, 310, 50, $aSize[0] - 320, $aSize[1] - 60)
				EndIf
		EndSwitch
		Sleep(10)
	WEnd
	_WebView2_Cleanup()
	GUIDelete($hGUI)
	Return $iExit
EndFunc   ;==>_Example

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _OnFrameCreated
; Description ...: Remembers the iframe's tracked ID.
; Syntax ........: _OnFrameCreated($iView, $iFrame)
; Parameters ....: $iView - WebView2 instance ID.
;                  $iFrame - Tracked frame ID.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This example has one iframe.
; Related .......: _OnFrameMessage
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _OnFrameCreated($iView, $iFrame)
	If $iView = $g_iView Then $g_iFrame = $iFrame
	Return
EndFunc   ;==>_OnFrameCreated

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _OnFrameMessage
; Description ...: Accepts the iframe's ready signal.
; Syntax ........: _OnFrameMessage($iView, $iFrame, $sMessage, $sSource, $bJSON)
; Parameters ....: Native frame message values.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Only the mapped local iframe is accepted.
; Related .......: _OnFrameCreated
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _OnFrameMessage($iView, $iFrame, $sMessage, $sSource, $bJSON)
	#forceref $bJSON
	If $iView = $g_iView And $iFrame = $g_iFrame And $sSource = $g_sOrigin & "frame.html" And $sMessage = "ready" Then
		$g_bFrameReady = True
		_Status("Iframe ready; page and frame workers can be created.")
	EndIf
	Return
EndFunc   ;==>_OnFrameMessage

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _OnWorkerCreated
; Description ...: Classifies each native worker by owning frame and immediate parent worker.
; Syntax ........: _OnWorkerCreated($iView, $iFrame, $iWorker, $sScriptURI)
; Parameters ....: Native worker creation callback values.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Frame zero is the main document; a positive parent ID identifies a child worker.
; Related .......: _WebView2_Worker_GetParentId
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _OnWorkerCreated($iView, $iFrame, $iWorker, $sScriptURI)
	If $iView = $g_iView Then
		Local $iParent = _WebView2_Worker_GetParentId($iWorker)
		If @error Then
			$g_bInvalidParent = True
		Else
			If $iParent = 0 And $iFrame = 0 Then
				$g_iPageWorker = $iWorker
			ElseIf $iParent = 0 And $iFrame = $g_iFrame Then
				$g_iFrameWorker = $iWorker
			ElseIf $iParent = $g_iPageWorker And $iFrame = 0 Then
				$g_iPageChild = $iWorker
			ElseIf $iParent = $g_iFrameWorker And $iFrame = $g_iFrame Then
				$g_iFrameChild = $iWorker
			Else
				$g_bInvalidParent = True
			EndIf
			_Status("Created worker " & $iWorker & ": frame=" & $iFrame & ", parent worker=" & $iParent & ", script=" & $sScriptURI)
		EndIf
	EndIf
	Return
EndFunc   ;==>_OnWorkerCreated

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _OnWorkerMessage
; Description ...: Reports native worker JSON replies.
; Syntax ........: _OnWorkerMessage($iView, $iFrame, $iWorker, $sJSON, $sSource)
; Parameters ....: Native worker message callback values.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Messages are accepted only from the two mapped local worker scripts.
; Related .......: _OnWorkerCreated
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _OnWorkerMessage($iView, $iFrame, $iWorker, $sJSON, $sSource)
	#forceref $iFrame
	If $iView = $g_iView And ($sSource = $g_sOrigin & "root.js" Or $sSource = $g_sOrigin & "child.js") Then
		If StringInStr($sJSON, '"kind":"ready"') Then
			If $iWorker = $g_iPageWorker Then $g_bPageWorkerReady = True
			If $iWorker = $g_iFrameWorker Then $g_bFrameWorkerReady = True
		EndIf
		If StringInStr($sJSON, '"sum":7') And ($iWorker = $g_iPageChild Or $iWorker = $g_iFrameChild) Then $g_iReplies += 1
		_Status("Worker " & $iWorker & " sent JSON: " & $sJSON)
	EndIf
	Return
EndFunc   ;==>_OnWorkerMessage

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _OnWorkerDestroying
; Description ...: Logs a worker ID invalidated by native destruction.
; Syntax ........: _OnWorkerDestroying($iView, $iFrame, $iWorker, $sScriptURI)
; Parameters ....: Native worker destruction callback values.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The ID cannot be used after this callback starts.
; Related .......: _OnWorkerCreated
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _OnWorkerDestroying($iView, $iFrame, $iWorker, $sScriptURI)
	#forceref $iFrame, $sScriptURI
	If $iView = $g_iView Then _Status("Worker " & $iWorker & " was destroyed; its ID is stale.")
	Return
EndFunc   ;==>_OnWorkerDestroying

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _LogClick
; Description ...: Separates manual button actions in the operation log.
; Syntax ........: _LogClick($sCaption)
; Parameters ....: $sCaption - Clicked button caption.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Smoke actions are not logged as button clicks.
; Related .......: _Status
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _LogClick($sCaption)
	_GUICtrlEdit_AppendText($g_idLog, @CRLF & "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] '" & $sCaption & "' was clicked." & @CRLF)
	GUICtrlSendMsg($g_idLog, $EM_SCROLLCARET, 0, 0)
	Return
EndFunc   ;==>_LogClick

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Status
; Description ...: Appends one timestamped AutoIt operation-log entry.
; Syntax ........: _Status($sText)
; Parameters ....: $sText - Message to append.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Keeps the latest entry visible in the native EDIT control.
; Related .......: _LogClick
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Status($sText)
	_GUICtrlEdit_AppendText($g_idLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sText & @CRLF)
	GUICtrlSendMsg($g_idLog, $EM_SCROLLCARET, 0, 0)
	Return
EndFunc   ;==>_Status
