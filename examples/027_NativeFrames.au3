#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_iView = -1, $g_iFrame = -1, $g_idStatus = 0, $g_idLog = 0, $g_idGuide = 0, $g_bReady = False, $g_oHost = ObjCreate("Scripting.Dictionary")
Global $g_iContentEvents = 0, $g_iDOMEvents = 0, $g_iNameEvents = 0, $g_sFrameName = "", $g_iContentNavigation = 0, $g_iDOMNavigation = 0
$g_oHost.Add("example", "value")
_Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Demonstrates native frame script, messages and origin-scoped host object.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This example uses a dedicated WebView2 profile outside the AutoIt installation directory.
; Related .......: _WebView2_Frame_ExecuteScript, _WebView2_Frame_AddHostObjectToScriptWithOrigins
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example()
	Local $hGUI = GUICreate("WebView2 - Native frames", 800, 550, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	$g_idStatus = GUICtrlCreateLabel("Initializing...", 12, 12, 760, 22)
	GUICtrlSetResizing($g_idStatus, $GUI_DOCKALL)
	GUICtrlCreateLabel("Operation log", 5, 81, 290, 18)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	$g_idLog = GUICtrlCreateEdit("", 5, 102, 290, 438, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idLog, 0xE2F0E4)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	Local $sGuide = "TEST PROCEDURE" & @CRLF & "1. Send JSON or run a frame script. Change frame name, then reload the iframe." & @CRLF & "EXPECTED RESULT" & @CRLF & "The log reports the new name and ContentLoading before DOMContentLoaded for each frame navigation." & @CRLF & "HOW IT WORKS" & @CRLF & "AutoIt subscribes to native frame lifecycle events and addresses this iframe directly."
	$g_idGuide = GUICtrlCreateEdit($sGuide, 305, 370, 790, 170, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	GUICtrlSetBkColor(-1, 0xFFF4C2)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	Local $idSend = GUICtrlCreateButton("Send JSON to frame", 12, 38, 180, 30)
	Local $idScript = GUICtrlCreateButton("Run frame script", 205, 38, 180, 30)
	Local $idRename = GUICtrlCreateButton("Change frame name", 398, 38, 180, 30)
	Local $idReload = GUICtrlCreateButton("Reload frame", 591, 38, 180, 30)
	GUISetState(@SW_MAXIMIZE, $hGUI)
	Local $aPanelSize = WinGetClientSize($hGUI)
	If IsArray($aPanelSize) Then
		GUICtrlSetPos($g_idLog, 5, 102, 290, $aPanelSize[1] - 112)
		GUICtrlSetPos($g_idGuide, 305, $aPanelSize[1] - 180, $aPanelSize[0] - 310, 170)
	EndIf
	Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\027_NativeFrames_" & (@AutoItX64 ? "x64" : "x86")
	If Not _WebView2_Init(Default, $sProfile) Then
		_Example_Status("Initialization failed: " & _WebView2_Error_GetDescription())
	Else
		Local $aSize = WinGetClientSize($hGUI)
		$g_iView = _WebView2_Create($hGUI, 305, 78, $aSize[0] - 310, $aSize[1] - 268)
		If @error Then
			_Example_Status("Creation failed: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_CREATED, _OnFrameCreated) Then
			_Example_Status("Frame event unavailable: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_DESTROYED, _OnFrameDestroyed) Then
			_Example_Status("Destroyed event unavailable: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_WEB_MESSAGE_RECEIVED, _OnFrameMessage) Then
			_Example_Status("Message event unavailable: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_NAME_CHANGED, _OnFrameNameChanged) Then
			_Example_Status("Name event unavailable: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_CONTENT_LOADING, _OnFrameContentLoading) Then
			_Example_Status("Content event unavailable: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_DOM_CONTENT_LOADED, _OnFrameDOMLoaded) Then
			_Example_Status("DOM event unavailable: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_SetVirtualHostNameToFolderMapping($g_iView, "udf-virtual-host.example", @ScriptDir & "\027_NativeFrames", $WEBVIEW2_HOST_RESOURCE_ACCESS_ALLOW) Then
			_Example_Status("Mapping failed: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_Navigate($g_iView, "https://udf-virtual-host.example/index.html") Then
			_Example_Status("Navigation failed: " & _WebView2_Error_GetDescription())
		EndIf
	EndIf

	Local $bSmoke = $CmdLine[0] > 0 And $CmdLine[1] = "--smoke"
	Local $bLifecycleSmoke = $CmdLine[0] > 0 And $CmdLine[1] = "--smoke-lifecycle"
	Local $iSmokeStage = 0, $iContentBeforeReload = 0, $iDOMBeforeReload = 0, $bSmokeFailed = False
	Local $tSmoke = TimerInit()
	While True
		If $bSmoke And ($g_bReady Or TimerDiff($tSmoke) > 10000) Then ExitLoop
		If $bLifecycleSmoke Then
			Switch $iSmokeStage
				Case 0
					If $g_bReady And $g_iContentEvents > 0 And $g_iDOMEvents > 0 Then
						_WebView2_Frame_ExecuteScript($g_iFrame, "window.name='renamed-frame'")
						If @error Then $bSmokeFailed = True
						$iSmokeStage = 1
					EndIf
				Case 1
					If $g_iNameEvents > 0 And $g_sFrameName = "renamed-frame" Then
						$iContentBeforeReload = $g_iContentEvents
						$iDOMBeforeReload = $g_iDOMEvents
						$g_bReady = False
						_WebView2_Frame_ExecuteScript($g_iFrame, "location.reload()")
						If @error Then $bSmokeFailed = True
						$iSmokeStage = 2
					EndIf
				Case 2
					If $g_bReady And $g_iContentEvents > $iContentBeforeReload And $g_iDOMEvents > $iDOMBeforeReload And $g_iContentNavigation = $g_iDOMNavigation Then ExitLoop
			EndSwitch
			If $bSmokeFailed Or TimerDiff($tSmoke) > 15000 Then ExitLoop
		EndIf
		Local $iMessage = GUIGetMsg()
		Switch $iMessage
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
				If $g_iView >= 0 Then
					$aSize = WinGetClientSize($hGUI)
					If IsArray($aSize) Then
						GUICtrlSetPos($g_idLog, 5, 102, 290, $aSize[1] - 112)
						GUICtrlSetPos($g_idGuide, 305, $aSize[1] - 180, $aSize[0] - 310, 170)
						_WebView2_SetBounds($g_iView, 305, 78, $aSize[0] - 310, $aSize[1] - 268)
					EndIf
				EndIf
			Case $idSend
				If $g_iFrame >= 0 Then
					If Not _WebView2_Frame_PostWebMessageAsJson($g_iFrame, '{"type":"greeting","text":"Hello from AutoIt"}') Then _Example_Status("Send failed: " & _WebView2_Error_GetDescription())
				EndIf
			Case $idScript
				If $g_iFrame >= 0 Then
					Local $sResult = _WebView2_Frame_ExecuteScript($g_iFrame, "document.title")
					_Example_Status(@error ? "Script failed" : "Frame title: " & $sResult)
				EndIf
			Case $idRename
				If $g_iFrame >= 0 Then _WebView2_Frame_ExecuteScript($g_iFrame, "window.name='renamed-frame'")
			Case $idReload
				If $g_iFrame >= 0 Then _WebView2_Frame_ExecuteScript($g_iFrame, "location.reload()")
		EndSwitch
	WEnd
	ConsoleWrite('smoke ready=' & $g_bReady & ' frame=' & $g_iFrame & ' status=' & GUICtrlRead($g_idStatus) & @CRLF)
	If $bLifecycleSmoke Then ConsoleWrite('EX_SMOKE_' & (($bSmokeFailed Or Not $g_bReady Or $g_iContentEvents <= $iContentBeforeReload Or $g_iDOMEvents <= $iDOMBeforeReload Or $g_iContentNavigation <> $g_iDOMNavigation) ? 'FAIL' : 'OK') & ' example=027 lifecycle name=' & $g_sFrameName & ' content=' & $g_iContentEvents & ' dom=' & $g_iDOMEvents & @CRLF)
	_WebView2_Cleanup()
	GUIDelete($hGUI)
	If $bSmoke And Not $g_bReady Then Exit 1
	If $bLifecycleSmoke And ($bSmokeFailed Or Not $g_bReady Or $g_iContentEvents <= $iContentBeforeReload Or $g_iDOMEvents <= $iDOMBeforeReload Or $g_iContentNavigation <> $g_iDOMNavigation) Then Exit 1
	Return
EndFunc   ;==>_Example

; #FUNCTION# ====================================================================================================================
; Name ..........: _OnFrameCreated
; Description ...: Adds an origin-scoped COM host object before the iframe navigates.
; Syntax ........: _OnFrameCreated($iView, $iFrame)
; Parameters ....: $iView - WebView2 instance ID.
;                  $iFrame - Native frame ID.
; Return values .: None.
; Author ........: mLipok
; ===============================================================================================================================
Func _OnFrameCreated($iView, $iFrame)
	If $iView = $g_iView Then
		$g_iFrame = $iFrame
		Local $aOrigins[1] = ["https://udf-virtual-host.example/"]
		Local $bAdded = _WebView2_Frame_AddHostObjectToScriptWithOrigins($iFrame, "sample", $g_oHost, $aOrigins)
		_Example_Status($bAdded ? "Frame created; host object ready" : "Host object failed: " & _WebView2_Error_GetDescription())
	EndIf
	Return
EndFunc   ;==>_OnFrameCreated

; #FUNCTION# ====================================================================================================================
; Name ..........: _OnFrameDestroyed
; Description ...: Clears the current frame ID when the iframe is removed.
; Syntax ........: _OnFrameDestroyed($iView, $iFrame)
; Parameters ....: $iView - WebView2 instance ID.
;                  $iFrame - Native frame ID.
; Return values .: None.
; Author ........: mLipok
; ===============================================================================================================================
Func _OnFrameDestroyed($iView, $iFrame)
	If $iView = $g_iView And $iFrame = $g_iFrame Then $g_iFrame = -1
	_Example_Status("Frame destroyed")
	Return
EndFunc   ;==>_OnFrameDestroyed

; #FUNCTION# ====================================================================================================================
; Name ..........: _OnFrameNameChanged
; Description ...: Reports the current name after the iframe changes window.name.
; Syntax ........: _OnFrameNameChanged($iView, $iFrame, $sName)
; Parameters ....: $iView - WebView2 instance ID.
;                  $iFrame - Tracked frame ID.
;                  $sName - Current frame name.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Keep native callbacks short.
; Related .......: _WebView2_Frame_GetName
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _OnFrameNameChanged($iView, $iFrame, $sName)
	If $iView = $g_iView And $iFrame = $g_iFrame Then
		$g_iNameEvents += 1
		$g_sFrameName = $sName
		_Example_Status("Frame name changed to " & $sName)
	EndIf
	Return
EndFunc   ;==>_OnFrameNameChanged

; #FUNCTION# ====================================================================================================================
; Name ..........: _OnFrameContentLoading
; Description ...: Reports the native stage before iframe content is loaded.
; Syntax ........: _OnFrameContentLoading($iView, $iFrame, $bErrorPage, $iNavigationId)
; Parameters ....: $iView - WebView2 instance ID.
;                  $iFrame - Tracked frame ID.
;                  $bErrorPage - True when the content is a browser error page.
;                  $iNavigationId - Navigation ID assigned by WebView2.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The navigation ID can be compared with the DOMContentLoaded event.
; Related .......: _OnFrameDOMLoaded
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _OnFrameContentLoading($iView, $iFrame, $bErrorPage, $iNavigationId)
	If $iView = $g_iView And $iFrame = $g_iFrame Then
		$g_iContentEvents += 1
		$g_iContentNavigation = $iNavigationId
		_Example_Status("Frame ContentLoading: navigation=" & $iNavigationId & ", error page=" & $bErrorPage)
	EndIf
	Return
EndFunc   ;==>_OnFrameContentLoading

; #FUNCTION# ====================================================================================================================
; Name ..........: _OnFrameDOMLoaded
; Description ...: Reports when the iframe HTML document has been parsed.
; Syntax ........: _OnFrameDOMLoaded($iView, $iFrame, $iNavigationId)
; Parameters ....: $iView - WebView2 instance ID.
;                  $iFrame - Tracked frame ID.
;                  $iNavigationId - Navigation ID assigned by WebView2.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This stage precedes normal navigation completion.
; Related .......: _OnFrameContentLoading
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _OnFrameDOMLoaded($iView, $iFrame, $iNavigationId)
	If $iView = $g_iView And $iFrame = $g_iFrame Then
		$g_iDOMEvents += 1
		$g_iDOMNavigation = $iNavigationId
		_Example_Status("Frame DOMContentLoaded: navigation=" & $iNavigationId)
	EndIf
	Return
EndFunc   ;==>_OnFrameDOMLoaded

; #FUNCTION# ====================================================================================================================
; Name ..........: _OnFrameMessage
; Description ...: Shows a message sent by the iframe.
; Syntax ........: _OnFrameMessage($iView, $iFrame, $sMessage, $sSource, $bJSON)
; Parameters ....: $iView - WebView2 instance ID.
;                  $iFrame - Native frame ID.
;                  $sMessage - Message content.
;                  $sSource - Frame source URL.
;                  $bJSON - True for JSON content.
; Return values .: None.
; Author ........: mLipok
; ===============================================================================================================================
Func _OnFrameMessage($iView, $iFrame, $sMessage, $sSource, $bJSON)
	#forceref $sSource, $bJSON
	If $iView = $g_iView And $iFrame = $g_iFrame Then
		If StringInStr($sMessage, '"type":"ready"') Then $g_bReady = True
		_Example_Status("Frame message: " & $sMessage)
	EndIf
	Return
EndFunc   ;==>_OnFrameMessage

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Example_Status
; Description ...: Updates the native status label and operation log.
; Syntax ........: _Example_Status($sText)
; Parameters ....: $sText - Status message.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Keeps the newest entry visible.
; Related .......: _Example
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_Status($sText)
	GUICtrlSetData($g_idStatus, $sText)
	_GUICtrlEdit_AppendText($g_idLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sText & @CRLF)
	GUICtrlSendMsg($g_idLog, $EM_SCROLLCARET, 0, 0)
	Return
EndFunc   ;==>_Example_Status
