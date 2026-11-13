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
		Local $idZoom125 = GUICtrlCreateButton("Zoom 125%", 10, 10, 100, 30)
		Local $idReset = GUICtrlCreateButton("Reset zoom", 120, 10, 100, 30)
		Local $idFocus = GUICtrlCreateButton("Focus", 230, 10, 80, 30)
		Local $idPrint = GUICtrlCreateButton("Print", 320, 10, 80, 30)
		GUISetState(@SW_MAXIMIZE, $hGUI)
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\010_Zoom_Print_Focus"
		If Not _WebView2_Init(Default, $sProfile) Then
			$__WebView2ExitValue = _Error("Init")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $aInitialClient = WinGetClientSize($hGUI)
		Local $iWebView = _WebView2_Create($hGUI, 0, 50, $aInitialClient[0], $aInitialClient[1] - 50)
		If @error Then
			$__WebView2ExitValue = _Error("Create")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		_WebView2_NavigateToString($iWebView, '<html><body style="font-family:Segoe UI;padding:30px"><h1>Zoom / print / focus</h1><input value="Click Focus, then type here" style="width:320px;padding:8px"></body></html>')
		While True
			Switch GUIGetMsg()
				Case $idZoom125
					_WebView2_SetZoomFactor($iWebView, 1.25)
				Case $idReset
					_WebView2_ResetZoom($iWebView)
				Case $idFocus
					_WebView2_SetFocus($iWebView)
				Case $idPrint
					_WebView2_Print($iWebView)
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					Local $aResize = WinGetClientSize($hGUI)
					If IsArray($aResize) Then _WebView2_SetBounds($iWebView, 0, 50, $aResize[0], $aResize[1] - 50)
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
