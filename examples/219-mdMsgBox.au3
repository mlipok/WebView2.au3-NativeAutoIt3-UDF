#include-once
#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
; Functional copy/adaptation of the Markdown message-box GitHub example by ioa747.
; Source: https://github.com/ioa747/NetWebView2Lib/blob/main/examples/019-mdMsgBox.au3
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <FileConstants.au3>
#include "..\WebView2.au3"

Global $g_MDBox_bDone = False, $g_MDBox_bOK = False

; #FUNCTION# ====================================================================================================================
; Name ..........: _MDBox_Show
; Description ...: Displays Markdown in a native WebView2 message box with AutoIt buttons.
; Syntax ........: _MDBox_Show($sMarkdown[, $sTitle = "Markdown"[, $sButtons = "OK|Cancel"[, $iTimeoutMs = 0[, $hParent = 0[, $bSmoke = False]]]]])
; Parameters ....: $sMarkdown - Markdown text; rendered with the bundled marked parser and sanitizer.
;                  $sTitle - Window title. Default is "Markdown".
;                  $sButtons - Pipe-separated button labels. Default is "OK|Cancel"; empty means "OK".
;                  $iTimeoutMs - Timeout after content is ready, in milliseconds; 0 disables the timeout.
;                  $hParent - Optional parent HWND; 0 creates an independent window.
;                  $bSmoke - True checks rendering and programmatically clicks the first button. Default False.
; Return values .: On Success - One-based button index; 0 on window close or timeout.
;                  On Failure - 0 and @error = 1 for asset, initialization, navigation or rendering failure.
;                  @extended = 1 on timeout; otherwise 0.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example API; replaces the upstream command-line flag interface. At most one box runs at a time.
;                  Reuses an initialized environment and destroys only its own controller in that case.
; Related .......: _WebView2_Create, _WebView2_Destroy
; Link ..........: https://github.com/ioa747/NetWebView2Lib/blob/main/examples/019-mdMsgBox.au3
; Example .......: Yes
; ===============================================================================================================================
Func _MDBox_Show($sMarkdown, $sTitle = "Markdown", $sButtons = "OK|Cancel", $iTimeoutMs = 0, $hParent = 0, $bSmoke = False)
	Local $iResult = 0, $iError = 1, $iExtended = 0, $iView = -1
	Local $bOwnEnvironment = Not $__g_bWebView2_Initialized
	Local $hGUI = GUICreate($sTitle, 650, 530, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), -1, $hParent)
	Do
		If $sButtons = "" Then $sButtons = "OK"
		Local $aLabels = StringSplit($sButtons, "|", $STR_NOCOUNT)
		Local $aButtons[UBound($aLabels)]
		For $i = 0 To UBound($aLabels) - 1
			$aButtons[$i] = GUICtrlCreateButton($aLabels[$i], 10 + $i * 110, 490, 100, 30)
		Next
		GUISetState(@SW_SHOWNOACTIVATE, $hGUI)
		If $bOwnEnvironment Then
			Local $sProfile = @LocalAppDataDir & "\WebView2.au3\MarkdownMessageBox"
			If $bSmoke Then $sProfile = @TempDir & "\WebView2-MDBox-" & @AutoItPID
			If Not _WebView2_Init(Default, $sProfile) Then ExitLoop
		EndIf
		$iView = _WebView2_Create($hGUI, 5, 5, 640, 475)
		If @error Then ExitLoop
		$g_MDBox_bDone = False
		$g_MDBox_bOK = False
		_WebView2_SetCallback($iView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _MDBox_Done)
		Local $sShell = FileRead(@ScriptDir & "\assets\markdown\viewer.html")
		If @error Then ExitLoop
		Local $sCSS = FileRead(@ScriptDir & "\assets\markdown\viewer.css")
		If @error Then ExitLoop
		Local $sMarked = FileRead(@ScriptDir & "\JS_Lib\marked\marked.umd.js")
		If @error Then ExitLoop
		Local $sJS = FileRead(@ScriptDir & "\assets\markdown\viewer.js")
		If @error Then ExitLoop
		$sShell = StringReplace($sShell, "{{STYLE}}", $sCSS)
		$sShell = StringReplace($sShell, "{{MARKED}}", StringReplace($sMarked, "</script", "<\/script"))
		$sShell = StringReplace($sShell, "{{VIEWER}}", $sJS)
		If Not _WebView2_NavigateToString($iView, $sShell) Then ExitLoop
		Local $hWait = TimerInit()
		While Not $g_MDBox_bDone And TimerDiff($hWait) < 30000
			GUIGetMsg()
			Sleep(10)
		WEnd
		If Not $g_MDBox_bDone Or Not $g_MDBox_bOK Then ExitLoop
		Local $sResult = _WebView2_ExecuteScript($iView, "window.updateView(" & __WebView2_JavaScript_StringLiteral($sMarkdown) & ",'about:blank')")
		If @error Or $sResult <> "true" Then ExitLoop
		If $bSmoke Then
			$sResult = _WebView2_ExecuteScript($iView, "document.getElementById('view').textContent.includes('Markdown') && !!document.querySelector('#view strong')")
			If @error Or $sResult <> "true" Then ExitLoop
			ControlClick($hGUI, "", $aButtons[0])
		Else
			GUISetState(@SW_SHOW, $hGUI)
		EndIf
		$iError = 0
		Local $hTimer = TimerInit(), $bClose = False
		While Not $bClose
			Local $iMessage = GUIGetMsg()
			If $iMessage = $GUI_EVENT_CLOSE Then $bClose = True
			For $i = 0 To UBound($aButtons) - 1
				If $iMessage = $aButtons[$i] Then
					$iResult = $i + 1
					$bClose = True
				EndIf
			Next
			If $iTimeoutMs > 0 And TimerDiff($hTimer) > $iTimeoutMs Then
				$iExtended = 1
				$bClose = True
			EndIf
			Sleep(10)
		WEnd
	Until True
	If $iView >= 0 Then _WebView2_Destroy($iView)
	If $bOwnEnvironment Then _WebView2_Cleanup()
	GUIDelete($hGUI)
	Return SetError($iError, $iExtended, $iResult)
EndFunc   ;==>_MDBox_Show

; #INTERNAL_USE_ONLY# ============================================================================================================
; Name ..........: _MDBox_Done
; Description ...: Stores navigation completion for the Markdown message box.
; Syntax ........: _MDBox_Done($iView, $bSuccess, $iStatus, $iNavigation)
; Parameters ....: $iView - Instance ID; unused.
;                  $bSuccess - Navigation success flag.
;                  $iStatus - Native error status; unused.
;                  $iNavigation - Navigation ID; unused.
; Return values .: 0.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Does not call synchronous browser APIs from the callback.
; Related .......: _MDBox_Show
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _MDBox_Done($iView, $bSuccess, $iStatus, $iNavigation)
	#forceref $iView, $iStatus, $iNavigation
	$g_MDBox_bDone = True
	$g_MDBox_bOK = $bSuccess
	Return 0
EndFunc   ;==>_MDBox_Done
