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
; Description ...: Demonstrates two simultaneous native WebView2 instances in one AutoIt GUI.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Multi-instance WebView2.au3 example.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example()
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Do
		Local $hGUI = GUICreate("WebView2.au3 - Multi-instance", 1200, 760, -1, -1, $WS_OVERLAPPEDWINDOW)
		GUISetState(@SW_SHOW, $hGUI)

		If Not _WebView2_Init() Then
			MsgBox($MB_ICONERROR, "WebView2 initialization", _WebView2_Error_GetDescription())
			$__WebView2ExitValue = 0
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $iLeftView = _WebView2_Create($hGUI, 0, 0, 600, 760)
		If @error Then
			MsgBox($MB_ICONERROR, "Left WebView", _WebView2_Error_GetDescription())
			_WebView2_Cleanup()
			$__WebView2ExitValue = 0
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $iRightView = _WebView2_Create($hGUI, 600, 0, 600, 760)
		If @error Then
			MsgBox($MB_ICONERROR, "Right WebView", _WebView2_Error_GetDescription())
			_WebView2_Cleanup()
			$__WebView2ExitValue = 0
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		_WebView2_NavigateToString($iLeftView, '<!doctype html><html><body style="font-family:Segoe UI;background:#f4f7fb;padding:28px"><h1>WebView A</h1><p>Instance ID: ' & $iLeftView & '</p></body></html>')
		_WebView2_NavigateToString($iRightView, '<!doctype html><html><body style="font-family:Segoe UI;background:#fff8eb;padding:28px"><h1>WebView B</h1><p>Instance ID: ' & $iRightView & '</p></body></html>')

		While True
			Switch GUIGetMsg()
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					Local $aClient = WinGetClientSize($hGUI)
					If IsArray($aClient) Then
						Local $iHalfWidth = Int($aClient[0] / 2)
						_WebView2_SetBounds($iLeftView, 0, 0, $iHalfWidth, $aClient[1])
						_WebView2_SetBounds($iRightView, $iHalfWidth, 0, $aClient[0] - $iHalfWidth, $aClient[1])
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
