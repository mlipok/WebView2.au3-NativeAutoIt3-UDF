#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_iWebView = -1
Global $g_idStatus = 0, $g_idLog = 0, $g_idGuide = 0
Global $g_bSmoke = False

Exit _Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Compares a page's preferred color scheme with Chromium's experimental automatic darkening.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: 0 on normal close or successful smoke run; 1 on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This example uses existing CDP and script APIs; it does not add a native color-scheme wrapper.
; Related .......: _WebView2_CallDevToolsProtocolMethod, _WebView2_ExecuteScript
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	If $CmdLine[0] > 0 Then $g_bSmoke = ($CmdLine[1] = "--smoke")
	Local $hGUI = GUICreate("WebView2 - Dark appearance", 900, 630, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	Local $idLight = GUICtrlCreateButton("Prefer light", 10, 9, 105, 28)
	Local $idDark = GUICtrlCreateButton("Prefer dark", 122, 9, 105, 28)
	Local $idForce = GUICtrlCreateButton("Force dark", 234, 9, 105, 28)
	Local $idReset = GUICtrlCreateButton("Stop forcing", 346, 9, 115, 28)
	$g_idStatus = GUICtrlCreateLabel("Starting WebView2...", 470, 14, 415, 24)
	GUICtrlSetResizing($idLight, $GUI_DOCKALL)
	GUICtrlSetResizing($idDark, $GUI_DOCKALL)
	GUICtrlSetResizing($idForce, $GUI_DOCKALL)
	GUICtrlSetResizing($idReset, $GUI_DOCKALL)
	GUICtrlSetResizing($g_idStatus, $GUI_DOCKALL)
	GUICtrlCreateLabel("Operation log", 5, 49, 290, 18)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	$g_idLog = GUICtrlCreateEdit("", 5, 70, 290, 550, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idLog, 0xE2F0E4)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	Local $sGuide = "TEST PROCEDURE" & @CRLF & "1. Click Prefer light, Prefer dark, Force dark and Stop forcing." & @CRLF & "EXPECTED RESULT" & @CRLF & "The page reports its preferred color scheme and its visible colors change." & @CRLF & "HOW IT WORKS" & @CRLF & "WebView2 exposes browser preferences; DevTools can override automatic darkening."
	$g_idGuide = GUICtrlCreateEdit($sGuide, 305, 450, 790, 170, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	GUICtrlSetBkColor(-1, 0xFFF4C2)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	GUISetState(@SW_MAXIMIZE, $hGUI)
	Local $aPanelSize = WinGetClientSize($hGUI)
	If IsArray($aPanelSize) Then
		GUICtrlSetPos($g_idLog, 5, 70, 290, $aPanelSize[1] - 80)
		GUICtrlSetPos($g_idGuide, 305, $aPanelSize[1] - 180, $aPanelSize[0] - 310, 170)
	EndIf

	Local $bReady = False
	Do
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\029_DarkAppearance"
		If Not _WebView2_Init(Default, $sProfile) Then
			_Example_Status("Initialization failed: " & _WebView2_Error_GetDescription())
			ExitLoop
		EndIf
		Local $aSize = WinGetClientSize($hGUI)
		$g_iWebView = _WebView2_Create($hGUI, 305, 46, $aSize[0] - 310, $aSize[1] - 236)
		If @error Then
			_Example_Status("Creation failed: " & _WebView2_Error_GetDescription())
			ExitLoop
		EndIf
		If Not _WebView2_NavigateToString($g_iWebView, _Example_Html()) Then
			_Example_Status("Navigation failed: " & _WebView2_Error_GetDescription())
			ExitLoop
		EndIf
		If Not _WebView2_LoadWait($g_iWebView) Then
			_Example_Status("Page load failed: " & _WebView2_Error_GetDescription())
			ExitLoop
		EndIf
		$bReady = True
		_Example_Status("Ready. The left card follows the preferred scheme; the right card is fixed light.")
	Until True

	Local $iExit = 0
	If Not $bReady Then
		$iExit = 1
	ElseIf $g_bSmoke Then
		If Not _Example_SetScheme("dark") Then $iExit = 1
		If $iExit = 0 And Not _Example_Probe("dark") Then $iExit = 1
		If $iExit = 0 And Not _Example_SetScheme("light") Then $iExit = 1
		If $iExit = 0 And Not _Example_Probe("light") Then $iExit = 1
		If $iExit = 0 And Not _Example_ForceDark(True) Then $iExit = 1
		If $iExit = 0 And Not _Example_ForceDark(False) Then $iExit = 1
		ConsoleWrite(($iExit = 0 ? "EX_SMOKE_OK" : "EX_SMOKE_FAIL") & " example=029 arch=" & (@AutoItX64 ? "x64" : "x86") & @CRLF)
	Else
		While True
			Switch GUIGetMsg()
				Case $GUI_EVENT_CLOSE
					ExitLoop
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					Local $aClient = WinGetClientSize($hGUI)
					If IsArray($aClient) Then
						GUICtrlSetPos($g_idLog, 5, 70, 290, $aClient[1] - 80)
						GUICtrlSetPos($g_idGuide, 305, $aClient[1] - 180, $aClient[0] - 310, 170)
						_WebView2_SetBounds($g_iWebView, 305, 46, $aClient[0] - 310, $aClient[1] - 236)
					EndIf
				Case $idLight
					_Example_LogClick("Prefer light")
					_Example_SetScheme("light")
				Case $idDark
					_Example_LogClick("Prefer dark")
					_Example_SetScheme("dark")
				Case $idForce
					_Example_LogClick("Force dark")
					_Example_ForceDark(True)
				Case $idReset
					_Example_LogClick("Stop forcing")
					_Example_ForceDark(False)
			EndSwitch
			Sleep(10)
		WEnd
	EndIf
	_WebView2_Cleanup()
	GUIDelete($hGUI)
	Return $iExit
EndFunc   ;==>_Example

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_SetScheme
; Description ...: Emulates a light or dark prefers-color-scheme media feature in this view.
; Syntax ........: _Example_SetScheme($sScheme)
; Parameters ....: $sScheme - "light" or "dark".
; Return values .: True on success; False on CDP or protocol failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: A page must contain its own dark CSS to respond to this preference.
; Related .......: _WebView2_CallDevToolsProtocolMethod
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example_SetScheme($sScheme)
	Local $sResult = _WebView2_CallDevToolsProtocolMethod($g_iWebView, "Emulation.setEmulatedMedia", '{"features":[{"name":"prefers-color-scheme","value":"' & $sScheme & '"}]}')
	If @error Or StringInStr($sResult, '"error"') Then
		_Example_Status("Color preference failed: " & _WebView2_Error_GetDescription() & " " & $sResult)
		Return False
	EndIf
	_Example_Status("Preferred scheme: " & $sScheme & ". The fixed light card should remain light.")
	Return True
EndFunc   ;==>_Example_SetScheme

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_ForceDark
; Description ...: Toggles Chromium's experimental automatic darkening override.
; Syntax ........: _Example_ForceDark($bEnable)
; Parameters ....: $bEnable - True to darken light-only content; False to restore it.
; Return values .: True on success; False on CDP or protocol failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Automatic darkening is experimental and may render some pages poorly.
; Related .......: _WebView2_CallDevToolsProtocolMethod
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example_ForceDark($bEnable)
	Local $sResult = _WebView2_CallDevToolsProtocolMethod($g_iWebView, "Emulation.setAutoDarkModeOverride", '{"enabled":' & ($bEnable ? "true" : "false") & '}')
	If @error Or StringInStr($sResult, '"error"') Then
		_Example_Status("Automatic darkening failed: " & _WebView2_Error_GetDescription() & " " & $sResult)
		Return False
	EndIf
	_Example_Status($bEnable ? "Experimental automatic darkening enabled." : "Experimental automatic darkening disabled.")
	Return True
EndFunc   ;==>_Example_ForceDark

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Probe
; Description ...: Reads the media-query state from the page for the smoke test.
; Syntax ........: _Example_Probe($sExpected)
; Parameters ....: $sExpected - Expected scheme name.
; Return values .: True if the page reports the expected scheme; False otherwise.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_ExecuteScript
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example_Probe($sExpected)
	Local $sActual = _WebView2_ExecuteScript($g_iWebView, "matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'")
	If @error Or $sActual <> '"' & $sExpected & '"' Then
		_Example_Status("Scheme probe expected " & $sExpected & " and received " & $sActual)
		Return False
	EndIf
	Return True
EndFunc   ;==>_Example_Probe

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Html
; Description ...: Builds a self-contained page with adaptive and fixed light cards.
; Syntax ........: _Example_Html()
; Parameters ....: None.
; Return values .: HTML document string.
; Author ........: mLipok
; Modified ......:
; Remarks .......: No Internet connection or external assets are needed.
; Related .......: _WebView2_NavigateToString
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example_Html()
	Local $sHtml = '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Dark appearance</title>' & _
			'<style>body{font:17px Segoe UI, sans-serif;margin:0;padding:28px;background:#eceff2;color:#17212b}' & _
			'h1{margin:0 0 12px}.grid{display:flex;gap:22px;flex-wrap:wrap}.card{width:330px;min-height:180px;padding:22px;border-radius:12px;box-shadow:0 2px 12px #0002}' & _
			'.adaptive{background:white;color:#202830}.fixed{background:#fff;color:#202830;border:2px solid #e0bb4b}' & _
			'@media(prefers-color-scheme:dark){body{background:#151b23;color:#f4f7fb}.adaptive{background:#293746;color:#f4f7fb}}' & _
			'</style></head><body><h1>Appearance modes</h1><p>The AutoIt buttons change Chromium state. This page has no JavaScript.</p>' & _
			'<div class="grid"><section class="card adaptive"><h2>Adaptive card</h2><p>Uses CSS prefers-color-scheme.</p></section>' & _
			'<section class="card fixed"><h2>Fixed light card</h2><p>Has no dark CSS. Forced darkening is experimental.</p></section></div>' & _
			'</body></html>'
	Return $sHtml
EndFunc   ;==>_Example_Html

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Status
; Description ...: Displays and logs the latest example result.
; Syntax ........: _Example_Status($sText)
; Parameters ....: $sText - Message to display.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Example_LogClick
; Description ...: Starts a separate operation-log group for a manual button click.
; Syntax ........: _Example_LogClick($sCaption)
; Parameters ....: $sCaption - Exact caption of the clicked button.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Automated smoke actions do not use this helper.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_LogClick($sCaption)
	_GUICtrlEdit_AppendText($g_idLog, @CRLF & "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] '" & $sCaption & "' was clicked." & @CRLF)
	GUICtrlSendMsg($g_idLog, $EM_SCROLLCARET, 0, 0)
	Return
EndFunc   ;==>_Example_LogClick

Func _Example_Status($sText)
	GUICtrlSetData($g_idStatus, $sText)
	_GUICtrlEdit_AppendText($g_idLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sText & @CRLF)
	GUICtrlSendMsg($g_idLog, $EM_SCROLLCARET, 0, 0)
	ConsoleWrite($sText & @CRLF)
	Return
EndFunc   ;==>_Example_Status
