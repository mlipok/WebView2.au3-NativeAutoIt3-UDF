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

_Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Demonstrates bounded, explicit dispatch of copied WebView2 page messages.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Three of five messages are intentionally dropped with a two-slot queue.
; Related .......: _WebView2_EventQueue_Enable, _WebView2_EventQueue_Dispatch
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	Local $iError = 0, $iExtended = 0
	Do
		$g_EX_hGUI = GUICreate("WebView2 - Notification queue", 1100, 720, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		Local $idBurst = GUICtrlCreateButton("Queue five messages", 8, 8, 145, 30)
		Local $idOne = GUICtrlCreateButton("Dispatch one", 163, 8, 120, 30)
		Local $idAll = GUICtrlCreateButton("Dispatch all", 293, 8, 120, 30)
		Local $idStats = GUICtrlCreateButton("Read queue stats", 423, 8, 125, 30)
		GUICtrlCreateLabel("AutoIt operation log", 8, 48, 285, 18)
		$g_EX_idLog = GUICtrlCreateEdit("", 8, 68, 285, 450, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idLog, 0xE2F0E4)
		$g_EX_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
				"1. Click Queue five messages. The page emits five JSON messages; the two-slot queue retains the first two." & @CRLF & _
				"2. Click Read queue stats. Expect queued=2 and dropped=3." & @CRLF & _
				"3. Click Dispatch one twice. AutoIt receives messages 1 and 2 in order. Stats now show queued=0, dropped=3." & @CRLF & _
				"4. Click Queue five messages and Dispatch all. Expect two more callbacks and three more drops." & @CRLF & _
				"HOW IT WORKS" & @CRLF & _
				"The native callback copies each page message into a bounded per-view ring buffer. AutoIt calls Dispatch from its GUI loop. Only notification events use this mode; permission, dialog and other decision callbacks stay direct.", _
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
		If Not _WebView2_Init(Default, @LocalAppDataDir & "\WebView2.au3\Examples\045_EventQueue") Then
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
		If Not _WebView2_SetCallback($g_EX_iWebView, $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED, _OnWebMessage) Then
			$iError = @error
			$iExtended = @extended
			_Log("Message callback failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		If Not _WebView2_EventQueue_Enable($g_EX_iWebView, 2) Then
			$iError = @error
			$iExtended = @extended
			_Log("Queue setup failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_EX_iWebView, "udf-virtual-host.example", @ScriptDir & "\assets\native") Then
			$iError = @error
			$iExtended = @extended
			_Log("Mapping failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		If Not _WebView2_Navigate($g_EX_iWebView, "https://udf-virtual-host.example/045.html") Then
			$iError = @error
			$iExtended = @extended
			_Log("Navigation failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		_Log("Page loading. Wait until the heading is visible before queueing a burst.")
		While True
			Local $aMsg = GUIGetMsg(1)
			Local $iMsg = $aMsg[0]
			Switch $iMsg
				Case $idBurst
					_Click("Queue five messages")
					_WebView2_ExecuteScript($g_EX_iWebView, "for(let i=1;i<=5;i++)window.chrome.webview.postMessage({kind:'item',index:i});true")
					If @error Then _Log("Burst script failed: " & _WebView2_Error_GetDescription())
				Case $idOne
					_Click("Dispatch one")
					_Log("Dispatched " & _WebView2_EventQueue_Dispatch($g_EX_iWebView, 1) & " notification(s).")
				Case $idAll
					_Click("Dispatch all")
					_Log("Dispatched " & _WebView2_EventQueue_Dispatch($g_EX_iWebView, 64) & " notification(s).")
				Case $idStats
					_Click("Read queue stats")
					Local $aStats = _WebView2_EventQueue_GetStats($g_EX_iWebView)
					If IsArray($aStats) Then _Log("Queue: queued=" & $aStats[0] & ", dropped=" & $aStats[1] & ", capacity=" & $aStats[2] & ".")
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					_SyncHost()
				Case $GUI_EVENT_CLOSE
					If $aMsg[1] = $g_EX_hGUI Then ExitLoop
			EndSwitch
			_SyncHost()
		WEnd
	Until True
	_WebView2_Cleanup()
	If $g_EX_hHost Then GUIDelete($g_EX_hHost)
	If $g_EX_hGUI Then GUIDelete($g_EX_hGUI)
	Return SetError($iError, $iExtended, 0)
EndFunc   ;==>_Example

; #FUNCTION# ====================================================================================================================
; Name ..........: _OnWebMessage
; Description ...: Logs copied message data when AutoIt explicitly dispatches the queue.
; Syntax ........: _OnWebMessage($iWebView, $sMessage, $sSource, $bJSON)
; Parameters ....: The ordinary UDF message callback fields.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Source is checked even in this local example; a host must validate all privileged messages.
; Related .......: _WebView2_EventQueue_Dispatch
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnWebMessage($iWebView, $sMessage, $sSource, $bJSON)
	#forceref $iWebView, $bJSON
	If $sSource = "https://udf-virtual-host.example/045.html" Then _Log("Dispatched page message: " & $sMessage)
	Return
EndFunc   ;==>_OnWebMessage

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Layout
; Description ...: Fits the log and guide to the GUI client area.
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
; Description ...: Appends a time-stamped message and scrolls to the newest line.
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
