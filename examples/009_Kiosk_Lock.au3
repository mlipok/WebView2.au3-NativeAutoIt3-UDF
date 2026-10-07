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
; Description ...: Runs the Kiosk Lock example.
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
		Local $hGUI = GUICreate("WebView2.au3 - Lock / Unlock", 1000, 700, -1, -1, $WS_OVERLAPPEDWINDOW)
		Local $idLock = GUICtrlCreateButton("Lock WebView", 10, 10, 120, 30)
		Local $idUnlock = GUICtrlCreateButton("Unlock WebView", 140, 10, 120, 30)
		Local $idDevTools = GUICtrlCreateButton("Open DevTools", 270, 10, 120, 30)
		GUISetState(@SW_SHOW, $hGUI)
		If Not _WebView2_Init() Then
			$__WebView2ExitValue = _Error("Init")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $iWebView = _WebView2_Create($hGUI, 0, 50, 1000, 650)
		If @error Then
			$__WebView2ExitValue = _Error("Create")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		_WebView2_NavigateToString($iWebView, '<html><body style="font-family:Segoe UI;padding:30px"><h1>Kiosk settings</h1><p>Use right-click, Ctrl+mouse-wheel and the DevTools button to compare locked/unlocked states.</p><button onclick="alert(''dialog'')">alert()</button></body></html>')
		While True
			Switch GUIGetMsg()
				Case $idLock
					_WebView2_LockWebView($iWebView)
				Case $idUnlock
					_WebView2_UnlockWebView($iWebView)
				Case $idDevTools
					_WebView2_OpenDevToolsWindow($iWebView)
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
