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
; Description ...: Runs the Browser Navigation example.
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
		Local $hGUI = GUICreate("WebView2.au3 - Browser navigation", 1200, 800, -1, -1, $WS_OVERLAPPEDWINDOW)
		Local $idBack = GUICtrlCreateButton("Back", 10, 10, 60, 30)
		Local $idForward = GUICtrlCreateButton("Forward", 80, 10, 70, 30)
		Local $idReload = GUICtrlCreateButton("Reload", 160, 10, 70, 30)
		Local $idStop = GUICtrlCreateButton("Stop", 240, 10, 60, 30)
		Local $idGo = GUICtrlCreateButton("Go", 1110, 10, 60, 30)
		Local $idURL = GUICtrlCreateInput("https://www.autoitscript.com", 310, 10, 790, 30)
		GUISetState(@SW_SHOW, $hGUI)
		If Not _WebView2_Init() Then
			$__WebView2ExitValue = _Error("Init")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $iWebView = _WebView2_Create($hGUI, 0, 50, 1200, 750)
		If @error Then
			$__WebView2ExitValue = _Error("Create")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		_WebView2_Navigate($iWebView, GUICtrlRead($idURL))
		ConsoleWrite("Browser PID=" & _WebView2_GetBrowserProcessId($iWebView) & @CRLF)
		While True
			Switch GUIGetMsg()
				Case $idBack
					If _WebView2_CanGoBack($iWebView) Then _WebView2_GoBack($iWebView)
				Case $idForward
					If _WebView2_CanGoForward($iWebView) Then _WebView2_GoForward($iWebView)
				Case $idReload
					_WebView2_Reload($iWebView)
				Case $idStop
					_WebView2_Stop($iWebView)
				Case $idGo
					_WebView2_Navigate($iWebView, GUICtrlRead($idURL))
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					Local $aSize = WinGetClientSize($hGUI)
					If IsArray($aSize) Then _WebView2_SetBounds($iWebView, 0, 50, $aSize[0], $aSize[1] - 50)
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
