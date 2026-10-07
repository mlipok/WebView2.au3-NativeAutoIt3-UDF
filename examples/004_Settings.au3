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
; Description ...: Runs the Settings example.
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
		Local $hGUI = GUICreate("WebView2.au3 - Settings", 1100, 760, -1, -1, $WS_OVERLAPPEDWINDOW)
		Local $idContext = GUICtrlCreateCheckbox("Context menu", 10, 10, 110, 25)
		Local $idDevTools = GUICtrlCreateCheckbox("DevTools", 130, 10, 90, 25)
		Local $idStatus = GUICtrlCreateCheckbox("Status bar", 230, 10, 90, 25)
		Local $idDialogs = GUICtrlCreateCheckbox("JS dialogs", 330, 10, 90, 25)
		Local $idZoom = GUICtrlCreateCheckbox("Zoom control", 430, 10, 100, 25)
		GUICtrlSetState($idContext, $GUI_CHECKED)
		GUICtrlSetState($idDevTools, $GUI_CHECKED)
		GUICtrlSetState($idStatus, $GUI_CHECKED)
		GUICtrlSetState($idDialogs, $GUI_CHECKED)
		GUICtrlSetState($idZoom, $GUI_CHECKED)
		GUISetState(@SW_SHOW, $hGUI)

		If Not _WebView2_Init() Then
			$__WebView2ExitValue = _Error("Init")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $iWebView = _WebView2_Create($hGUI, 0, 45, 1100, 715)
		If @error Then
			$__WebView2ExitValue = _Error("Create")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		_WebView2_NavigateToString($iWebView, '<html><body style="font-family:Segoe UI;padding:30px"><h1>Settings demo</h1><p>Right-click, use F12 and hover links to test settings.</p><a href="https://www.autoitscript.com">AutoIt</a><br><br><button onclick="alert(''JavaScript dialog'')">alert()</button></body></html>')

		While True
			Switch GUIGetMsg()
				Case $idContext
					_WebView2_SetDefaultContextMenusEnabled($iWebView, BitAND(GUICtrlRead($idContext), $GUI_CHECKED) <> 0)
				Case $idDevTools
					_WebView2_SetDevToolsEnabled($iWebView, BitAND(GUICtrlRead($idDevTools), $GUI_CHECKED) <> 0)
				Case $idStatus
					_WebView2_SetStatusBarEnabled($iWebView, BitAND(GUICtrlRead($idStatus), $GUI_CHECKED) <> 0)
				Case $idDialogs
					_WebView2_SetDefaultScriptDialogsEnabled($iWebView, BitAND(GUICtrlRead($idDialogs), $GUI_CHECKED) <> 0)
				Case $idZoom
					_WebView2_SetZoomControlEnabled($iWebView, BitAND(GUICtrlRead($idZoom), $GUI_CHECKED) <> 0)
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					Local $aSize = WinGetClientSize($hGUI)
					If IsArray($aSize) Then _WebView2_SetBounds($iWebView, 0, 45, $aSize[0], $aSize[1] - 45)
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
