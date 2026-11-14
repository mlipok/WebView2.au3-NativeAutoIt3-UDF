#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <WindowsConstants.au3>

#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_EX_idLog = 0, $g_EX_idGuide = 0

_Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Demonstrates WebView2 events, JavaScript execution, messaging and DevTools.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Events and scripting example.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example()
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Do
		Local $hGUI = GUICreate("WebView2.au3 - Events + JavaScript", 1100, 760, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		GUICtrlCreateLabel("AutoIt operation log", 5, 53, 290, 18)
		GUICtrlSetResizing(-1, $GUI_DOCKALL)
		$g_EX_idLog = GUICtrlCreateEdit("", 5, 74, 290, 450, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idLog, 0xE2F0E4)
		GUICtrlSetResizing($g_EX_idLog, $GUI_DOCKALL)
		Local $sEXGuide = "TEST PROCEDURE" & @CRLF & "Click Execute JavaScript, Post message and DevTools; click Send message to AutoIt inside the page." & @CRLF & "EXPECTED RESULT" & @CRLF & "The log identifies native and page button clicks separately. The page message and script result appear after their clicks." & @CRLF & "HOW IT WORKS" & @CRLF & "A trusted page click sends its caption through WebMessageReceived before the page sends its message."
		$g_EX_idGuide = GUICtrlCreateEdit($sEXGuide, 305, 520, 790, 170, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idGuide, 0xFFF1BF)
		GUICtrlSetResizing($g_EX_idGuide, $GUI_DOCKALL)

		; inicjalizacja $idButtonScript
		Local $idButtonScript = GUICtrlCreateButton("Execute JavaScript", 10, 10, 160, 30)

		; inicjalizacja $idButtonMessage
		Local $idButtonMessage = GUICtrlCreateButton("Post message", 180, 10, 140, 30)

		; inicjalizacja $idButtonDevTools
		Local $idButtonDevTools = GUICtrlCreateButton("DevTools", 330, 10, 120, 30)

		GUISetState(@SW_MAXIMIZE, $hGUI)
		_EX_Log("Starting WebView2...")

		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\002_Events_JavaScript"
		If Not _WebView2_Init(Default, $sProfile) Then
			MsgBox($MB_ICONERROR, "WebView2 initialization", _WebView2_Error_GetDescription())
			$__WebView2ExitValue = 0
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $aInitialClient = WinGetClientSize($hGUI)
		If IsArray($aInitialClient) Then _EX_Layout($aInitialClient, 50)
		Local $iWebView = _WebView2_Create($hGUI, 305, 50, $aInitialClient[0] - 310, $aInitialClient[1] - 240)
		If @error Then
			MsgBox($MB_ICONERROR, "WebView2 create", _WebView2_Error_GetDescription())
			_WebView2_Cleanup()
			$__WebView2ExitValue = 0
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		_WebView2_SetCallback($iWebView, $WEBVIEW2_EVENT_NAVIGATION_STARTING, _Example_NavigationStarting)
		_WebView2_SetCallback($iWebView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _Example_NavigationCompleted)
		_WebView2_SetCallback($iWebView, $WEBVIEW2_EVENT_DOCUMENT_TITLE_CHANGED, _Example_TitleChanged)
		_WebView2_SetCallback($iWebView, $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED, _Example_WebMessageReceived)

		Local $sHTML = _
				'<!doctype html><html><head><meta charset="utf-8"><title>AutoIt + WebView2</title></head>' & _
				'<body style="font-family:Segoe UI;padding:28px">' & _
				'<h1>WebView2.au3</h1>' & _
				'<p id="status">HTML loaded by NavigateToString().</p>' & _
				'<button id="send-message">Send message to AutoIt</button>' & _
				'<script>document.getElementById(''send-message'').addEventListener(''click'',e=>{if(e.isTrusted)window.chrome.webview.postMessage(''EX_CLICK_TRUSTED:Send message to AutoIt'');window.chrome.webview.postMessage(''Message from JavaScript'');});window.chrome.webview.addEventListener(''message'',e=>{document.getElementById(''status'').textContent=''AutoIt says: ''+e.data;});</script>' & _
				'</body></html>'

		_WebView2_NavigateToString($iWebView, $sHTML)

		While True
			Switch GUIGetMsg()
				Case $idButtonScript
					_EX_Click("Execute JavaScript")
					Local $sResult = _WebView2_ExecuteScript($iWebView, "document.title")
					If @error Then
						_EX_Log("ExecuteScript failed: " & _WebView2_Error_GetDescription())
						MsgBox($MB_ICONERROR, "ExecuteScript", _WebView2_Error_GetDescription())
					Else
						_EX_Log("ExecuteScript returned JSON: " & $sResult)
						MsgBox($MB_ICONINFORMATION, "ExecuteScript result (JSON)", $sResult)
					EndIf

				Case $idButtonMessage
					_EX_Click("Post message")
					_WebView2_PostWebMessageAsString($iWebView, "Hello from AutoIt at " & @HOUR & ":" & @MIN & ":" & @SEC)
					_EX_Log("Sent a string message to the page.")

				Case $idButtonDevTools
					_EX_Click("DevTools")
					_WebView2_OpenDevToolsWindow($iWebView)

				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					Local $aClient = WinGetClientSize($hGUI)
					If IsArray($aClient) Then
						_EX_Layout($aClient, 50)
						_WebView2_SetBounds($iWebView, 305, 50, $aClient[0] - 310, $aClient[1] - 240)
					EndIf

				Case $GUI_EVENT_CLOSE
					ExitLoop
			EndSwitch
		WEnd

		_WebView2_Cleanup()
		GUIDelete($hGUI)
	Until True
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_Example

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_NavigationStarting
; Description ...: Receives NavigationStarting from WebView2.
; Syntax ........: _Example_NavigationStarting($iWebView, $sURI, $bUserInitiated, $bRedirected)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sURI - Target URI.
;                  $bUserInitiated - True when the navigation was user initiated.
;                  $bRedirected - True for redirected navigation.
; Return values .: False to allow the navigation.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Example callback.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_NavigationStarting($iWebView, $sURI, $bUserInitiated, $bRedirected)
	ConsoleWrite("NAV START id=" & $iWebView & " uri=" & $sURI & " user=" & $bUserInitiated & " redirect=" & $bRedirected & @CRLF)
	_EX_Log("NAV START id=" & $iWebView & " uri=" & $sURI & " user=" & $bUserInitiated & " redirect=" & $bRedirected)
	Return False
EndFunc   ;==>_Example_NavigationStarting

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_NavigationCompleted
; Description ...: Receives NavigationCompleted from WebView2.
; Syntax ........: _Example_NavigationCompleted($iWebView, $bSuccess, $iWebErrorStatus, $iNavigationId)
; Parameters ....: $iWebView - WebView instance ID.
;                  $bSuccess - Navigation success state.
;                  $iWebErrorStatus - WebView2 web error status.
;                  $iNavigationId - Navigation identifier.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Example callback.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_NavigationCompleted($iWebView, $bSuccess, $iWebErrorStatus, $iNavigationId)
	ConsoleWrite("NAV END id=" & $iWebView & " success=" & $bSuccess & " webError=" & $iWebErrorStatus & " navigationId=" & $iNavigationId & @CRLF)
	_EX_Log("NAV END id=" & $iWebView & " success=" & $bSuccess & " webError=" & $iWebErrorStatus & " navigationId=" & $iNavigationId)
	Return
EndFunc   ;==>_Example_NavigationCompleted

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_TitleChanged
; Description ...: Receives DocumentTitleChanged from WebView2.
; Syntax ........: _Example_TitleChanged($iWebView, $sTitle)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sTitle - New document title.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Example callback.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_TitleChanged($iWebView, $sTitle)
	ConsoleWrite("TITLE id=" & $iWebView & " title=" & $sTitle & @CRLF)
	_EX_Log("TITLE id=" & $iWebView & " title=" & $sTitle)
	Return
EndFunc   ;==>_Example_TitleChanged

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_WebMessageReceived
; Description ...: Receives a web message from JavaScript.
; Syntax ........: _Example_WebMessageReceived($iWebView, $sMessage, $sSource, $bJSON)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sMessage - Message payload.
;                  $sSource - Source URI.
;                  $bJSON - True when the UDF fell back to the JSON representation.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Validate source/payload before privileged native actions.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_WebMessageReceived($iWebView, $sMessage, $sSource, $bJSON)
	If Not $bJSON And $sMessage = "EX_CLICK_TRUSTED:Send message to AutoIt" Then
		_EX_Click("Send message to AutoIt", "WebView2")
		Return
	EndIf
	_EX_Log("Page message from " & $sSource & ": " & $sMessage)
	MsgBox($MB_ICONINFORMATION, "WebMessageReceived", _
			"WebView=" & $iWebView & @CRLF & _
			"Source=" & $sSource & @CRLF & _
			"JSON=" & $bJSON & @CRLF & @CRLF & _
			$sMessage)
	Return
EndFunc   ;==>_Example_WebMessageReceived

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _EX_Layout
; Description ...: Sizes the operation log and test guide.
; Syntax ........: _EX_Layout($aClient, $iTop)
; Parameters ....: $aClient - GUI client size; $iTop - height of the control strip.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _EX_Layout($aClient, $iTop)
	GUICtrlSetPos($g_EX_idLog, 5, $iTop + 24, 290, $aClient[1] - $iTop - 34)
	GUICtrlSetPos($g_EX_idGuide, 305, $aClient[1] - 180, $aClient[0] - 310, 170)
	Return
EndFunc   ;==>_EX_Layout

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _EX_Log
; Description ...: Appends a time-stamped operation-log entry.
; Syntax ........: _EX_Log($sText)
; Parameters ....: $sText - Message to append.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _EX_Log($sText)
	If $g_EX_idLog Then _GUICtrlEdit_AppendText($g_EX_idLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sText & @CRLF)
	Return
EndFunc   ;==>_EX_Log

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _EX_Click
; Description ...: Logs a native or trusted page click in a separate group.
; Syntax ........: _EX_Click($sCaption[, $sSource = "AutoIt"])
; Parameters ....: $sCaption - Visible button caption.
;                  $sSource - AutoIt or trusted WebView2 click source.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _EX_Click($sCaption, $sSource = "AutoIt")
	If $g_EX_idLog Then _GUICtrlEdit_AppendText($g_EX_idLog, @CRLF & "[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & $sSource & "]: " & $sCaption & " was clicked." & @CRLF)
	Return
EndFunc   ;==>_EX_Click
