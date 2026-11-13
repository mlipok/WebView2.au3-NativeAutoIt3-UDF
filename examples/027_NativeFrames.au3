#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_iView = -1, $g_iFrame = -1, $g_idStatus = 0, $g_idLog = 0, $g_idGuide = 0, $g_bReady = False, $g_oHost = ObjCreate("Scripting.Dictionary")
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
	Local $sGuide = "TEST PROCEDURE" & @CRLF & "1. Click Send JSON to frame and Run frame script; try the page button." & @CRLF & "EXPECTED RESULT" & @CRLF & "The iframe receives JSON, sends a response and exposes its title; the log reports native frame events." & @CRLF & "HOW IT WORKS" & @CRLF & "AutoIt addresses the tracked iframe directly and may expose a COM object to an allowed origin."
	$g_idGuide = GUICtrlCreateEdit($sGuide, 305, 370, 790, 170, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	GUICtrlSetBkColor(-1, 0xFFF4C2)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	Local $idSend = GUICtrlCreateButton("Send JSON to frame", 12, 38, 180, 30)
	Local $idScript = GUICtrlCreateButton("Run frame script", 205, 38, 180, 30)
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
		ElseIf Not _WebView2_SetVirtualHostNameToFolderMapping($g_iView, "udf-virtual-host.example", @ScriptDir & "\027_NativeFrames", $WEBVIEW2_HOST_RESOURCE_ACCESS_ALLOW) Then
			_Example_Status("Mapping failed: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_Navigate($g_iView, "https://udf-virtual-host.example/index.html") Then
			_Example_Status("Navigation failed: " & _WebView2_Error_GetDescription())
		EndIf
	EndIf

	Local $bSmoke = $CmdLine[0] > 0 And $CmdLine[1] = "--smoke"
	Local $tSmoke = TimerInit()
	While True
		If $bSmoke And ($g_bReady Or TimerDiff($tSmoke) > 10000) Then ExitLoop
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
		EndSwitch
	WEnd
	ConsoleWrite('smoke ready=' & $g_bReady & ' frame=' & $g_iFrame & ' status=' & GUICtrlRead($g_idStatus) & @CRLF)
	_WebView2_Cleanup()
	GUIDelete($hGUI)
	If $bSmoke And Not $g_bReady Then Exit 1
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
