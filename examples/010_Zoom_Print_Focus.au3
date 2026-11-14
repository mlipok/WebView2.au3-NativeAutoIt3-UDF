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
; Description ...: Runs the Zoom Print Focus example.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: No value; shows the result in the example GUI or console.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Do
		Local $hGUI = GUICreate("WebView2.au3 - Zoom + Print + Focus", 1000, 700, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		GUICtrlCreateLabel("AutoIt operation log", 5, 53, 290, 18)
		GUICtrlSetResizing(-1, $GUI_DOCKALL)
		$g_EX_idLog = GUICtrlCreateEdit("", 5, 74, 290, 450, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idLog, 0xE2F0E4)
		GUICtrlSetResizing($g_EX_idLog, $GUI_DOCKALL)
		Local $sEXGuide = "TEST PROCEDURE" & @CRLF & "Click Zoom 125%, Reset zoom, Focus and Print; then click the page's input field and move focus into and out of it." & @CRLF & "EXPECTED RESULT" & @CRLF & "Zoom changes and resets; Print opens its native UI. The log distinguishes a native Focus request from the input's click and focus events." & @CRLF & "HOW IT WORKS" & @CRLF & "AutoIt controls WebView2 zoom, focus and printing. The page reports input events through WebMessageReceived."
		$g_EX_idGuide = GUICtrlCreateEdit($sEXGuide, 305, 520, 790, 170, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idGuide, 0xFFF1BF)
		GUICtrlSetResizing($g_EX_idGuide, $GUI_DOCKALL)
		Local $idZoom125 = GUICtrlCreateButton("Zoom 125%", 10, 10, 100, 30)
		Local $idReset = GUICtrlCreateButton("Reset zoom", 120, 10, 100, 30)
		Local $idFocus = GUICtrlCreateButton("Focus", 230, 10, 80, 30)
		Local $idPrint = GUICtrlCreateButton("Print", 320, 10, 80, 30)
		GUISetState(@SW_MAXIMIZE, $hGUI)
		_EX_Log("Starting WebView2...")
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\010_Zoom_Print_Focus"
		If Not _WebView2_Init(Default, $sProfile) Then
			$__WebView2ExitValue = _Error("Init")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $aInitialClient = WinGetClientSize($hGUI)
		If IsArray($aInitialClient) Then _EX_Layout($aInitialClient, 50)
		Local $iWebView = _WebView2_Create($hGUI, 305, 50, $aInitialClient[0] - 310, $aInitialClient[1] - 240)
		If @error Then
			$__WebView2ExitValue = _Error("Create")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		_WebView2_SetCallback($iWebView, $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED, _Example_WebMessageReceived)
		_WebView2_NavigateToString($iWebView, '<!doctype html><html><body style="font-family:Segoe UI;padding:30px"><h1>Zoom / print / focus</h1><label for="demo-input">Input field</label><br><input id="demo-input" value="Click Focus, then type here" style="width:320px;padding:8px"><script>const input=document.getElementById(''demo-input'');input.addEventListener(''focus'',()=>chrome.webview.postMessage(''EX_INPUT_FOCUS''));input.addEventListener(''blur'',()=>chrome.webview.postMessage(''EX_INPUT_BLUR''));input.addEventListener(''click'',e=>{if(e.isTrusted)chrome.webview.postMessage(''EX_INPUT_CLICK_TRUSTED'');});</script></body></html>')
		While True
			Switch GUIGetMsg()
				Case $idZoom125
					_EX_Click("Zoom 125%")
					_WebView2_SetZoomFactor($iWebView, 1.25)
					_EX_Log("Requested 125% zoom.")
				Case $idReset
					_EX_Click("Reset zoom")
					_WebView2_ResetZoom($iWebView)
					_EX_Log("Requested default zoom.")
				Case $idFocus
					_EX_Click("Focus")
					_WebView2_SetFocus($iWebView)
					_EX_Log("Requested WebView2 keyboard focus.")
				Case $idPrint
					_EX_Click("Print")
					_WebView2_Print($iWebView)
					_EX_Log("Requested the print dialog.")
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					Local $aResize = WinGetClientSize($hGUI)
					If IsArray($aResize) Then
						_EX_Layout($aResize, 50)
						_WebView2_SetBounds($iWebView, 305, 50, $aResize[0] - 310, $aResize[1] - 240)
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
; Name ..........: _Error
; Description ...: Reports a failed WebView2 operation and its diagnostic.
; Syntax ........: _Error($sStage)
; Parameters ....: $sStage - Name of the failed example stage.
; Return values .: No value; shows the result in the example GUI or console.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Error($sStage)
	MsgBox($MB_ICONERROR, "WebView2 " & $sStage, _WebView2_Error_GetDescription())
	_WebView2_Cleanup()
	Return
EndFunc   ;==>_Error

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_WebMessageReceived
; Description ...: Logs the editable field's focus and trusted click events.
; Syntax ........: _Example_WebMessageReceived($iWebView, $sMessage, $sSource, $bJSON)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sMessage - Page event marker.
;                  $sSource - Source URI.
;                  $bJSON - True when only a JSON representation was available.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Input content is deliberately not sent to AutoIt.
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example_WebMessageReceived($iWebView, $sMessage, $sSource, $bJSON)
	#forceref $iWebView, $sSource
	If $bJSON Then Return
	Switch $sMessage
		Case "EX_INPUT_FOCUS"
			_EX_Log("[WebView2]: Input field received focus.")
		Case "EX_INPUT_BLUR"
			_EX_Log("[WebView2]: Input field lost focus.")
		Case "EX_INPUT_CLICK_TRUSTED"
			_EX_Click("Input field", "WebView2")
	EndSwitch
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
; Parameters ....: $sCaption - Visible control caption.
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
