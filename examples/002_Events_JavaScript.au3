#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <WindowsConstants.au3>

#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

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
		Local $hGUI = GUICreate("WebView2.au3 - Events + JavaScript", 1100, 760, -1, -1, $WS_OVERLAPPEDWINDOW)

		; inicjalizacja $idButtonScript
		Local $idButtonScript = GUICtrlCreateButton("Execute JavaScript", 10, 10, 160, 30)

		; inicjalizacja $idButtonMessage
		Local $idButtonMessage = GUICtrlCreateButton("Post message", 180, 10, 140, 30)

		; inicjalizacja $idButtonDevTools
		Local $idButtonDevTools = GUICtrlCreateButton("DevTools", 330, 10, 120, 30)

		GUISetState(@SW_SHOW, $hGUI)

		If Not _WebView2_Init() Then
			MsgBox($MB_ICONERROR, "WebView2 initialization", _WebView2_Error_GetDescription())
			$__WebView2ExitValue = 0
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $iWebView = _WebView2_Create($hGUI, 0, 50, 1100, 710)
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
				'<button onclick="window.chrome.webview.postMessage(''Message from JavaScript'')">Send message to AutoIt</button>' & _
				'<script>window.chrome.webview.addEventListener(''message'',e=>{document.getElementById(''status'').textContent=''AutoIt says: ''+e.data;});</script>' & _
				'</body></html>'

		_WebView2_NavigateToString($iWebView, $sHTML)

		While True
			Switch GUIGetMsg()
				Case $idButtonScript
					Local $sResult = _WebView2_ExecuteScript($iWebView, "document.title")
					If @error Then
						MsgBox($MB_ICONERROR, "ExecuteScript", _WebView2_Error_GetDescription())
					Else
						MsgBox($MB_ICONINFORMATION, "ExecuteScript result (JSON)", $sResult)
					EndIf

				Case $idButtonMessage
					_WebView2_PostWebMessageAsString($iWebView, "Hello from AutoIt at " & @HOUR & ":" & @MIN & ":" & @SEC)

				Case $idButtonDevTools
					_WebView2_OpenDevToolsWindow($iWebView)

				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					Local $aClient = WinGetClientSize($hGUI)
					If IsArray($aClient) Then _WebView2_SetBounds($iWebView, 0, 50, $aClient[0], $aClient[1] - 50)

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
	MsgBox($MB_ICONINFORMATION, "WebMessageReceived", _
			"WebView=" & $iWebView & @CRLF & _
			"Source=" & $sSource & @CRLF & _
			"JSON=" & $bJSON & @CRLF & @CRLF & _
			$sMessage)
	Return
EndFunc   ;==>_Example_WebMessageReceived
