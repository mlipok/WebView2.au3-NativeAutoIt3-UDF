#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
; #WIP - Work in Progress: confirm the native True/False event sequence in a visible WebView2 session.

#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_EX_hGUI = 0, $g_EX_hHost = 0, $g_EX_idLog = 0, $g_EX_idGuide = 0, $g_EX_iWebView = -1
Global $g_EX_iSmokeExit = 0
Global $g_EX_bHostMoved = False
Global Const $g_EX_sHTML = '<!doctype html><html><head><meta charset="utf-8"><title>Full-screen element</title><style>body{margin:32px;font:18px Segoe UI,sans-serif;color:#183247}main{max-width:850px}button{padding:12px;font-size:18px}#stage{border:2px solid #2874a6;background:#e9f4ff;padding:24px;margin-top:25px}#stage:fullscreen{background:#153653;color:white;display:grid;place-content:center;text-align:center}#stage:fullscreen button{margin:auto}</style></head><body><main><h1>Native full-screen element event</h1><p>Use a real click to enter full-screen mode inside this WebView. The host window stays maximized with its title bar and taskbar when you leave full-screen mode.</p><div id="stage"><h2 id="state">Element is in the page</h2><button id="toggle">Enter full screen</button></div></main><script>const stage=document.getElementById("stage"),toggle=document.getElementById("toggle"),state=document.getElementById("state");toggle.addEventListener("click",async event=>{chrome.webview.postMessage({type:"click",caption:toggle.textContent,trusted:event.isTrusted});try{if(document.fullscreenElement)await document.exitFullscreen();else await stage.requestFullscreen()}catch(e){chrome.webview.postMessage({type:"error",message:e.name+": "+e.message})}});document.addEventListener("fullscreenchange",()=>{let active=!!document.fullscreenElement;toggle.textContent=active?"Exit full screen":"Enter full screen";state.textContent=active?"Element fills the WebView":"Element is in the page"});</script></body></html>'

_Example()
If $CmdLine[0] And $CmdLine[1] = "--smoke" Then Exit $g_EX_iSmokeExit

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Demonstrates native WebView2 full-screen element state and change notifications.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Entering full screen requires a real user gesture in the WebView.
; Related .......: _WebView2_GetContainsFullScreenElement, _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2#add_containsfullscreenelementchanged
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	Local $iError = 0, $iExtended = 0
	If $CmdLine[0] And $CmdLine[1] = "--smoke" Then $g_EX_iSmokeExit = 1
	Do
		$g_EX_hGUI = GUICreate("WebView2 - Full-screen element", 1100, 720, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		GUIRegisterMsg($WM_MOVE, "_OnMainMove")
		Local $idRead = GUICtrlCreateButton("Read native state", 10, 8, 175, 30)
		GUICtrlCreateLabel("AutoIt operation log", 8, 48, 285, 18)
		$g_EX_idLog = GUICtrlCreateEdit("", 8, 68, 285, 450, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idLog, 0xE2F0E4)
		$g_EX_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
				"1. Click Enter full screen in the WebView. The blue element should fill the WebView and the AutoIt log should report a native change to True." & @CRLF & _
				"2. Click Exit full screen or press Escape. The element should return to the page and the AutoIt log should report False." & @CRLF & _
				"3. Click Read native state in AutoIt before, during and after full screen; its Boolean value should agree with the event log." & @CRLF & _
				"HOW IT WORKS" & @CRLF & _
				"The page requests the HTML Fullscreen API after a real click. WebView2 raises ContainsFullScreenElementChanged; AutoIt reads the native property and logs it. This is an element filling WebView2, not a request to make the AutoIt window borderless or cover the taskbar. No Internet connection is required.", _
				305, 500, 780, 210, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idGuide, 0xFFF1BF)
		GUISetState(@SW_MAXIMIZE, $g_EX_hGUI)
		GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hGUI)
		Local $aClient = WinGetClientSize($g_EX_hGUI)
		_Layout($aClient)
		Local $tPoint = DllStructCreate("long X;long Y")
		DllStructSetData($tPoint, "X", 305)
		DllStructSetData($tPoint, "Y", 48)
		DllCall("user32.dll", "bool", "ClientToScreen", "hwnd", $g_EX_hGUI, "struct*", $tPoint)
		$g_EX_hHost = GUICreate("", $aClient[0] - 313, $aClient[1] - 280, DllStructGetData($tPoint, "X"), DllStructGetData($tPoint, "Y"), $WS_POPUP, $WS_EX_NOREDIRECTIONBITMAP, $g_EX_hGUI)
		GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hHost)
		_Log("Starting WebView2...")
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\041_FullScreenElement"
		If Not _WebView2_Init(Default, $sProfile) Then
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
		If Not _WebView2_SetCallback($g_EX_iWebView, $WEBVIEW2_EVENT_CONTAINS_FULLSCREEN_ELEMENT_CHANGED, _OnFullScreenChanged) Then
			$iError = @error
			$iExtended = @extended
			_Log("Native event registration failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		If Not _WebView2_SetCallback($g_EX_iWebView, $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED, _OnWebMessage) Then
			$iError = @error
			$iExtended = @extended
			_Log("Web message registration failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		If Not _WebView2_NavigateToString($g_EX_iWebView, $g_EX_sHTML) Then
			$iError = @error
			$iExtended = @extended
			_Log("Page load failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		_Log("Page ready. Click Enter full screen in the WebView.")
		If $CmdLine[0] And $CmdLine[1] = "--smoke" Then
			Local $bNativeState = _WebView2_GetContainsFullScreenElement($g_EX_iWebView)
			If @error Or $bNativeState Then
				_Log("Smoke native readback failed.")
				ExitLoop 1
			EndIf
			ConsoleWrite("EX_SMOKE_OK" & @CRLF)
			$g_EX_iSmokeExit = 0
			ExitLoop 1
		EndIf
		While True
			Local $iMsg = GUIGetMsg()
			If $g_EX_bHostMoved Then
				$g_EX_bHostMoved = False
				_SyncHost()
			EndIf
			Switch $iMsg
				Case $idRead
					_Click("Read native state")
					Local $bState = _WebView2_GetContainsFullScreenElement($g_EX_iWebView)
					If @error Then
						_Log("Readback failed: " & _WebView2_Error_GetDescription())
					Else
						_Log("Native ContainsFullScreenElement=" & $bState)
					EndIf
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					_SyncHost()
				Case $GUI_EVENT_CLOSE
					ExitLoop
			EndSwitch
		WEnd
	Until True
	_WebView2_Cleanup()
	If $g_EX_hHost Then GUIDelete($g_EX_hHost)
	If $g_EX_hGUI Then GUIDelete($g_EX_hGUI)
	Return SetError($iError, $iExtended, 0)
EndFunc   ;==>_Example

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Layout
; Description ...: Fits the test panels to the current GUI client size.
; Syntax ........: _Layout($aClient)
; Parameters ....: $aClient - GUI client dimensions.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
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
; Name ..........: _OnMainMove
; Description ...: Defers owned WebView host positioning until the GUI message loop resumes.
; Syntax ........: _OnMainMove($hWnd, $iMsg, $wParam, $lParam)
; Parameters ....: $hWnd - Message target window.
;                  $iMsg - Windows message identifier.
;                  $wParam - Message parameter.
;                  $lParam - Message parameter.
; Return values .: $GUI_RUNDEFMSG.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _SyncHost
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnMainMove($hWnd, $iMsg, $wParam, $lParam)
	#forceref $iMsg, $wParam, $lParam
	If $hWnd = $g_EX_hGUI Then $g_EX_bHostMoved = True
	Return $GUI_RUNDEFMSG
EndFunc   ;==>_OnMainMove

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _SyncHost
; Description ...: Aligns the owned WebView host with its area in the main GUI.
; Syntax ........: _SyncHost()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _OnMainMove, _Layout
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _SyncHost()
	Local $aClient = WinGetClientSize($g_EX_hGUI)
	If IsArray($aClient) Then
		_Layout($aClient)
		Local $tPoint = DllStructCreate("long X;long Y")
		DllStructSetData($tPoint, "X", 305)
		DllStructSetData($tPoint, "Y", 48)
		DllCall("user32.dll", "bool", "ClientToScreen", "hwnd", $g_EX_hGUI, "struct*", $tPoint)
		WinMove($g_EX_hHost, "", DllStructGetData($tPoint, "X"), DllStructGetData($tPoint, "Y"), $aClient[0] - 313, $aClient[1] - 280)
		_WebView2_SetBounds($g_EX_iWebView, 0, 0, $aClient[0] - 313, $aClient[1] - 280)
	EndIf
	Return
EndFunc   ;==>_SyncHost

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Log
; Description ...: Appends a timestamped message and scrolls to it.
; Syntax ........: _Log($sMessage)
; Parameters ....: $sMessage - Message text.
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
; Description ...: Starts a log group for an AutoIt button click.
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

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _OnFullScreenChanged
; Description ...: Logs the native WebView2 full-screen element state.
; Syntax ........: _OnFullScreenChanged($iWebView, $bContains)
; Parameters ....: $iWebView - WebView2 instance ID.
;                  $bContains - True if an HTML element fills the WebView.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The event may fire on Escape as well as on the page button.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnFullScreenChanged($iWebView, $bContains)
	If $iWebView = $g_EX_iWebView Then _Log("Native ContainsFullScreenElementChanged: " & $bContains)
	Return
EndFunc   ;==>_OnFullScreenChanged

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _OnWebMessage
; Description ...: Logs trusted button clicks and page Fullscreen API errors.
; Syntax ........: _OnWebMessage($iWebView, $sMessage, $sSource, $bJSON)
; Parameters ....: $iWebView - WebView2 instance ID.
;                  $sMessage - JSON message from the page.
;                  $sSource - URL of the page sending the message.
;                  $bJSON - True for JSON objects.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The example's NavigateToString document has the about:blank origin.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnWebMessage($iWebView, $sMessage, $sSource, $bJSON)
	If $iWebView <> $g_EX_iWebView Or Not $bJSON Or $sSource <> "about:blank" Then Return
	If StringInStr($sMessage, '"type":"click"') And StringInStr($sMessage, '"trusted":true') Then
		If StringInStr($sMessage, '"caption":"Enter full screen"') Then
			_GUICtrlEdit_AppendText($g_EX_idLog, @CRLF & "[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [WebView2]: Enter full screen was clicked." & @CRLF)
		ElseIf StringInStr($sMessage, '"caption":"Exit full screen"') Then
			_GUICtrlEdit_AppendText($g_EX_idLog, @CRLF & "[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [WebView2]: Exit full screen was clicked." & @CRLF)
		EndIf
		GUICtrlSendMsg($g_EX_idLog, $EM_SCROLLCARET, 0, 0)
	ElseIf StringInStr($sMessage, '"type":"error"') Then
		_Log("The page reported a Fullscreen API error: " & $sMessage)
	EndIf
	Return
EndFunc   ;==>_OnWebMessage
