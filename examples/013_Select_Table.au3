#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <Array.au3>
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <WindowsConstants.au3>

#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

_Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Runs the Select Table example.
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
		Local $hGUI = GUICreate("WebView2.au3 - SELECT and TABLE", 1000, 700, -1, -1, $WS_OVERLAPPEDWINDOW)
		GUISetState(@SW_SHOW, $hGUI)

		If Not _WebView2_Init() Then
			$__WebView2ExitValue = _Error("Init")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $iWebView = _WebView2_Create($hGUI, 0, 0, 1000, 700)
		If @error Then
			$__WebView2ExitValue = _Error("Create")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $sHTML = '<!doctype html><html><body style="font-family:Segoe UI;padding:30px">' & _
				'<h1>SELECT / TABLE</h1>' & _
				'<select id="city"><option value="bytom">Bytom</option><option value="zabrze">Zabrze</option><option value="gliwice">Gliwice</option></select>' & _
				'<table id="data" border="1" cellpadding="8" style="margin-top:20px"><tr><th>Name</th><th>Value</th></tr><tr><td>A</td><td>10</td></tr><tr><td>B</td><td>20</td></tr></table>' & _
				'</body></html>'
		_WebView2_NavigateToString($iWebView, $sHTML)
		If Not _WebView2_LoadWait($iWebView) Then
			$__WebView2ExitValue = _Error("LoadWait")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $sSelect = _WebView2_GetElementById($iWebView, "city")
		_WebView2_ElementOptionSelect($iWebView, $sSelect, "Zabrze", "TEXT")
		ConsoleWrite("Selected index=" & _WebView2_ElementSelectAction($iWebView, $sSelect, "SELECTEDINDEX") & @CRLF)

		Local $sTable = _WebView2_GetElementById($iWebView, "data")
		Local $aTable = _WebView2_GetTable($iWebView, $sTable)
		If IsArray($aTable) Then _ArrayDisplay($aTable, "WebView2 TABLE")

		While GUIGetMsg() <> $GUI_EVENT_CLOSE
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
