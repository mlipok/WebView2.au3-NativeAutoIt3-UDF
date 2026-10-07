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
; Description ...: Runs the Content Selection example.
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
		Local $hGUI = GUICreate("WebView2.au3 - HTML source + selected text", 1050, 720, -1, -1, $WS_OVERLAPPEDWINDOW)
		Local $idSource = GUICtrlCreateButton("HTML source", 10, 10, 120, 30)
		Local $idSelected = GUICtrlCreateButton("Selected text", 140, 10, 120, 30)
		GUISetState(@SW_SHOW, $hGUI)
		If Not _WebView2_Init() Then
			$__WebView2ExitValue = _Error("Init")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $iWebView = _WebView2_Create($hGUI, 0, 50, 1050, 670)
		If @error Then
			$__WebView2ExitValue = _Error("Create")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		_WebView2_NavigateToString($iWebView, '<html><body style="font-family:Segoe UI;padding:30px"><h1>Select some text</h1><p>Select any part of this sentence with the mouse and press the AutoIt button above.</p></body></html>')
		While True
			Switch GUIGetMsg()
				Case $idSource
					MsgBox($MB_ICONINFORMATION, "HTML source", _WebView2_GetHtmlSource($iWebView))
				Case $idSelected
					MsgBox($MB_ICONINFORMATION, "Selected text", _WebView2_GetSelectedText($iWebView))
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
