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
; Description ...: Demonstrates basic native WebView2 hosting in an AutoIt GUI.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Basic WebView2.au3 example.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example()
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Do
		Local $hGUI = GUICreate("WebView2.au3 - Basic", 1100, 760, -1, -1, $WS_OVERLAPPEDWINDOW)
		GUISetState(@SW_SHOW, $hGUI)

		If Not _WebView2_Init() Then
			MsgBox($MB_ICONERROR, "WebView2 initialization", _WebView2_Error_GetDescription() & @CRLF & "@extended=" & _WebView2_Error_GetExtended())
			$__WebView2ExitValue = 0
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		ConsoleWrite("WebView2 Runtime: " & _WebView2_Runtime_GetVersion() & @CRLF)

		Local $iWebView = _WebView2_Create($hGUI)
		If @error Then
			MsgBox($MB_ICONERROR, "WebView2 create", _WebView2_Error_GetDescription() & @CRLF & "@extended=" & _WebView2_Error_GetExtended())
			_WebView2_Cleanup()
			$__WebView2ExitValue = 0
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		_WebView2_Navigate($iWebView, "https://www.autoitscript.com/")

		While True
			Switch GUIGetMsg()
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					_WebView2_ResizeToParent($iWebView)
				Case $GUI_EVENT_CLOSE
					ExitLoop
			EndSwitch
		WEnd

		_WebView2_Cleanup()
		GUIDelete($hGUI)
	Until True
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_Example
