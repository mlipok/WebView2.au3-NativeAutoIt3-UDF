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
; Description ...: Runs the Wait Storage example.
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
		Local $hGUI = GUICreate("WebView2.au3 - Wait and Storage", 1000, 700, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		GUISetState(@SW_MAXIMIZE, $hGUI)

		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\012_Wait_Storage"
		If Not _WebView2_Init(Default, $sProfile) Then
			$__WebView2ExitValue = _Error("Init")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $aInitialClient = WinGetClientSize($hGUI)
		Local $iWebView = _WebView2_Create($hGUI, 0, 0, $aInitialClient[0], $aInitialClient[1])
		If @error Then
			$__WebView2ExitValue = _Error("Create")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		_WebView2_Navigate($iWebView, "https://example.com/")
		If Not _WebView2_LoadWait($iWebView) Then
			$__WebView2ExitValue = _Error("LoadWait")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		_WebView2_ExecuteScript($iWebView, "document.body.insertAdjacentHTML('beforeend','<p id=\""status\"">Creating delayed element...</p>');setTimeout(()=>{const b=document.createElement('button');b.id='delayed';b.textContent='Ready';document.body.appendChild(b);document.getElementById('status').textContent='Element created';},1200);")
		If @error Then
			$__WebView2ExitValue = _Error("ExecuteScript")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		_WebView2_Storage($iWebView, "LOCAL", "SET", "example", "stored by AutoIt")
		ConsoleWrite("localStorage example=" & _WebView2_Storage($iWebView, "LOCAL", "GET", "example") & @CRLF)

		Local $sElement = _WebView2_WaitElement($iWebView, $WEBVIEW2_LOCATOR_BY_ID, "delayed", 5000, 100, True, True)
		If @error Then
			$__WebView2ExitValue = _Error("WaitElement")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		_WebView2_HighlightElements($iWebView, $sElement, "3px solid lime")

		If _WebView2_WaitScript($iWebView, "document.getElementById('delayed') !== null", 2000) Then
			ConsoleWrite("WaitScript: condition satisfied" & @CRLF)
		EndIf

		While True
			Switch GUIGetMsg()
				Case $GUI_EVENT_CLOSE
					ExitLoop
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					Local $aResize = WinGetClientSize($hGUI)
					If IsArray($aResize) Then _WebView2_SetBounds($iWebView, 0, 0, $aResize[0], $aResize[1])
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
