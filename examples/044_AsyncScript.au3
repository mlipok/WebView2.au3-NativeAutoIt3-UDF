#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_EX_hGUI = 0, $g_EX_hHost = 0, $g_EX_idLog = 0, $g_EX_idGuide = 0, $g_EX_iWebView = -1
Global $g_EX_sHostGeometry = ""
Global $g_EX_iRequestA = 0, $g_EX_iRequestB = 0

_Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Starts two independent native script requests and polls them from the GUI loop.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: A successful start means the request was accepted, not that the script has completed.
; Related .......: _WebView2_ExecuteScriptAsyncStart, _WebView2_ExecuteScriptAsyncPoll
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	Local $iError = 0, $iExtended = 0
	Do
		$g_EX_hGUI = GUICreate("WebView2 - Asynchronous scripts", 1100, 720, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		Local $idStart = GUICtrlCreateButton("Start two scripts", 8, 8, 150, 30)
		Local $idCounter = GUICtrlCreateButton("Count AutoIt clicks", 168, 8, 150, 30)
		Local $iClickCount = 0
		GUICtrlCreateLabel("AutoIt operation log", 8, 48, 285, 18)
		$g_EX_idLog = GUICtrlCreateEdit("", 8, 68, 285, 450, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idLog, 0xE2F0E4)
		$g_EX_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
				"1. Click Start two scripts. The AutoIt loop begins two native requests without waiting." & @CRLF & _
				"2. Check the green log for two different request IDs and separate JSON results A and B." & @CRLF & _
				"3. Click Count AutoIt clicks while requests are pending. This button is processed by the same GUI loop." & @CRLF & _
				"HOW IT WORKS" & @CRLF & _
				"Each request has its own native completion callback. The callbacks only store results; AutoIt reads them with Poll during its normal GUI loop. The existing synchronous ExecuteScript API is unchanged.", _
				305, 500, 780, 210, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idGuide, 0xFFF1BF)
		GUISetState(@SW_MAXIMIZE, $g_EX_hGUI)
		GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hGUI)
		Local $aClient = WinGetClientSize($g_EX_hGUI)
		_Layout($aClient)
		$g_EX_hHost = GUICreate("", 1, 1, 0, 0, $WS_POPUP, $WS_EX_NOREDIRECTIONBITMAP, $g_EX_hGUI)
		_SyncHost()
		GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hHost)
		_Log("Starting WebView2...")
		If Not _WebView2_Init(Default, @LocalAppDataDir & "\WebView2.au3\Examples\044_AsyncScript") Then
			$iError = @error
			$iExtended = @extended
			_Log("Init failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		$g_EX_iWebView = _WebView2_Create($g_EX_hHost, 0, 0, $aClient[0] - 313, $aClient[1] - 280)
		If @error Then
			$iError = @error
			$iExtended = @extended
			_Log("Create failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		If Not _WebView2_NavigateToString($g_EX_iWebView, '<!doctype html><html><meta name="viewport" content="width=device-width,initial-scale=1"><style>body{font:20px Segoe UI,sans-serif;margin:24px}article{background:#eaf4ff;border:2px solid #2772a8;padding:24px}</style><article><h1>Two independent script requests</h1><p>The AutoIt log reports each native request ID and JSON result.</p></article></html>') Then
			$iError = @error
			$iExtended = @extended
			_Log("Navigation failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		While True
			Local $aMsg = GUIGetMsg(1)
			Local $iMsg = $aMsg[0]
			Switch $iMsg
				Case $idStart
					_Click("Start two scripts")
					If $g_EX_iRequestA Or $g_EX_iRequestB Then
						_Log("Wait until both previous requests have been consumed.")
					Else
						$g_EX_iRequestA = _WebView2_ExecuteScriptAsyncStart($g_EX_iWebView, '"A:" + document.title')
						If @error Then
							_Log("Request A failed to start: " & _WebView2_Error_GetDescription())
							$g_EX_iRequestA = 0
						Else
							_Log("Request A started with ID " & $g_EX_iRequestA & ".")
						EndIf
						$g_EX_iRequestB = _WebView2_ExecuteScriptAsyncStart($g_EX_iWebView, '"B:" + document.location.protocol')
						If @error Then
							_Log("Request B failed to start: " & _WebView2_Error_GetDescription())
							$g_EX_iRequestB = 0
						Else
							_Log("Request B started with ID " & $g_EX_iRequestB & ".")
						EndIf
					EndIf
				Case $idCounter
					_Click("Count AutoIt clicks")
					$iClickCount += 1
					_Log("AutoIt click count=" & $iClickCount & ".")
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					_SyncHost()
				Case $GUI_EVENT_CLOSE
					If $aMsg[1] = $g_EX_hGUI Then ExitLoop
			EndSwitch
			_SyncHost()
			_PollOne("A", $g_EX_iRequestA)
			_PollOne("B", $g_EX_iRequestB)
		WEnd
	Until True
	If $g_EX_iRequestA Then _WebView2_ExecuteScriptAsyncForget($g_EX_iRequestA)
	If $g_EX_iRequestB Then _WebView2_ExecuteScriptAsyncForget($g_EX_iRequestB)
	_WebView2_Cleanup()
	If $g_EX_hHost Then GUIDelete($g_EX_hHost)
	If $g_EX_hGUI Then GUIDelete($g_EX_hGUI)
	Return SetError($iError, $iExtended, 0)
EndFunc   ;==>_Example

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _PollOne
; Description ...: Consumes one completed native result without blocking the GUI loop.
; Syntax ........: _PollOne($sName, ByRef $iRequest)
; Parameters ....: $sName - Human-readable request name.
;                  $iRequest - Active request ID, cleared when consumed.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_ExecuteScriptAsyncPoll
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _PollOne($sName, ByRef $iRequest)
	If $iRequest Then
		Local $sJSON = ""
		Local $iState = _WebView2_ExecuteScriptAsyncPoll($iRequest, $sJSON)
		If $iState = 1 Then
			_Log("Request " & $sName & " returned JSON: " & $sJSON)
			$iRequest = 0
		ElseIf $iState = -1 Then
			_Log("Request " & $sName & " failed: " & _WebView2_Error_GetDescription())
			$iRequest = 0
		EndIf
	EndIf
	Return
EndFunc   ;==>_PollOne

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Layout
; Description ...: Fits the log and guide to the current GUI client area.
; Syntax ........: _Layout($aClient)
; Parameters ....: $aClient - GUI client dimensions.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetBounds
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Layout($aClient)
	If IsArray($aClient) Then
		GUICtrlSetPos($g_EX_idLog, 8, 68, 285, $aClient[1] - 78)
		GUICtrlSetPos($g_EX_idGuide, 305, $aClient[1] - 222, $aClient[0] - 313, 212)
	EndIf
	Return
EndFunc   ;==>_Layout

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _SyncHost
; Description ...: Aligns the separate WebView-only window with the main GUI's browser panel.
; Syntax ........: _SyncHost()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Geometry is checked in the GUI loop; native controls remain in the main window.
; Related .......: _Layout, _WebView2_SetBounds
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _SyncHost()
	Do
		If Not $g_EX_hHost Then ExitLoop 1
		Local $aClient = WinGetClientSize($g_EX_hGUI)
		If Not IsArray($aClient) Then ExitLoop 1
		Local $tPoint = DllStructCreate("long X;long Y")
		DllStructSetData($tPoint, "X", 305)
		DllStructSetData($tPoint, "Y", 48)
		Local $aCall = DllCall("user32.dll", "bool", "ClientToScreen", "hwnd", $g_EX_hGUI, "struct*", $tPoint)
		If @error Then ExitLoop 1
		If Not $aCall[0] Then ExitLoop 1
		Local $iWidth = $aClient[0] - 313, $iHeight = $aClient[1] - 280
		If $iWidth < 1 Then $iWidth = 1
		If $iHeight < 1 Then $iHeight = 1
		Local $sGeometry = DllStructGetData($tPoint, "X") & ":" & DllStructGetData($tPoint, "Y") & ":" & $iWidth & ":" & $iHeight
		If $sGeometry = $g_EX_sHostGeometry Then ExitLoop 1
		$g_EX_sHostGeometry = $sGeometry
		_Layout($aClient)
		WinMove($g_EX_hHost, "", DllStructGetData($tPoint, "X"), DllStructGetData($tPoint, "Y"), $iWidth, $iHeight)
		If $g_EX_iWebView >= 0 Then _WebView2_SetBounds($g_EX_iWebView, 0, 0, $iWidth, $iHeight)
	Until True
	Return
EndFunc   ;==>_SyncHost

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Log
; Description ...: Appends a time-stamped operation line.
; Syntax ........: _Log($sMessage)
; Parameters ....: $sMessage - Message to append.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Log($sMessage)
	_GUICtrlEdit_AppendText($g_EX_idLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sMessage & @CRLF)
	GUICtrlSendMsg($g_EX_idLog, $EM_SCROLLCARET, 0, 0)
	Return
EndFunc   ;==>_Log

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Click
; Description ...: Starts a separate log group for one AutoIt button click.
; Syntax ........: _Click($sCaption)
; Parameters ....: $sCaption - Visible button caption.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Click($sCaption)
	_GUICtrlEdit_AppendText($g_EX_idLog, @CRLF & "[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [AutoIt]: " & $sCaption & " was clicked." & @CRLF)
	GUICtrlSendMsg($g_EX_idLog, $EM_SCROLLCARET, 0, 0)
	Return
EndFunc   ;==>_Click
