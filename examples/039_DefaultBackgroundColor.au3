#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_EX_hGUI = 0, $g_EX_idLog = 0, $g_EX_idGuide = 0, $g_EX_iWebView = -1
Global $g_EX_iSmokeExit = 0
Global Const $g_EX_sHTML = '<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;min-height:100%;background:transparent;font:18px Segoe UI,sans-serif}main{margin:24px;padding:24px;border:2px solid #405b70;border-radius:10px;background:rgba(255,255,255,.72);max-width:620px}h1{margin-top:0}</style></head><body><main><h1>Controller background color</h1><p>The colored area around this translucent card comes from the native WebView2 controller, not the page CSS.</p><p>Use the AutoIt buttons above the view to change it without navigating.</p></main></body></html>'

_Example()
If $CmdLine[0] And $CmdLine[1] = "--smoke" Then Exit $g_EX_iSmokeExit

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Demonstrates native controller background colors beneath transparent web content.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Use --smoke for a bounded, noninteractive setter/getter check.
; Related .......: _WebView2_SetDefaultBackgroundColor, _WebView2_GetDefaultBackgroundColor
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2controller2
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	Local $iError = 0, $iExtended = 0
	If $CmdLine[0] And $CmdLine[1] = "--smoke" Then $g_EX_iSmokeExit = 1
	Do
		$g_EX_hGUI = GUICreate("WebView2 - Default background color", 1100, 720, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		Local $idBlue = GUICtrlCreateButton("Pastel blue", 10, 8, 125, 30)
		Local $idGreen = GUICtrlCreateButton("Pastel green", 145, 8, 125, 30)
		Local $idWhite = GUICtrlCreateButton("Default white", 280, 8, 125, 30)
		Local $idTransparent = GUICtrlCreateButton("Transparent", 415, 8, 125, 30)
		GUICtrlCreateLabel("AutoIt operation log", 8, 48, 285, 18)
		$g_EX_idLog = GUICtrlCreateEdit("", 8, 68, 285, 450, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idLog, 0xE2F0E4)
		$g_EX_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
				"1. Click Pastel blue and Pastel green. The area around the white card changes immediately; the page is not reloaded." & @CRLF & _
				"2. Click Default white to restore the initial WebView2 color." & @CRLF & _
				"3. Click Transparent. The parent window shows through the page's transparent background. This mode requires a compatible WebView2 Runtime." & @CRLF & _
				"4. Check the AutoIt log after every click: it reads the color back from the native controller and reports RGB and alpha." & @CRLF & _
				"HOW IT WORKS" & @CRLF & _
				"ICoreWebView2Controller2 stores the color beneath web content. The sample page has a transparent background and a translucent card. An opaque page background would hide the controller color. Only alpha 0 or 255 is supported.", _
				305, 500, 780, 210, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idGuide, 0xFFF1BF)
		GUISetState(@SW_MAXIMIZE, $g_EX_hGUI)
		GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hGUI)
		Local $aClient = WinGetClientSize($g_EX_hGUI)
		_Layout($aClient)
		_Log("Starting WebView2...")
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\039_DefaultBackgroundColor"
		If Not _WebView2_Init(Default, $sProfile) Then
			$iError = @error
			$iExtended = @extended
			_Log("Init failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		$g_EX_iWebView = _WebView2_Create($g_EX_hGUI, 305, 48, $aClient[0] - 313, $aClient[1] - 280)
		If @error Then
			$iError = @error
			$iExtended = @extended
			_Log("Create failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		If Not _WebView2_NavigateToString($g_EX_iWebView, $g_EX_sHTML) Then
			$iError = @error
			$iExtended = @extended
			_Log("Page load failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		_Log("Page ready. Use the AutoIt color buttons.")
		If $CmdLine[0] And $CmdLine[1] = "--smoke" Then
			$g_EX_iSmokeExit = 1
			If Not _SetColor("Pastel blue", 0xDCEEFF, 255) Then ExitLoop 1
			If Not _SetColor("Pastel green", 0xDCF2DF, 255) Then ExitLoop 1
			If Not _SetColor("Default white", 0xFFFFFF, 255) Then ExitLoop 1
			If Not _SetColor("Transparent", 0x000000, 0) Then ExitLoop 1
			ConsoleWrite("EX_SMOKE_OK" & @CRLF)
			$g_EX_iSmokeExit = 0
			ExitLoop 1
		EndIf
		While True
			Local $iMsg = GUIGetMsg()
			Switch $iMsg
				Case $idBlue, $idGreen, $idWhite, $idTransparent
					Local $sCaption = ""
					Switch $iMsg
						Case $idBlue
							$sCaption = "Pastel blue"
						Case $idGreen
							$sCaption = "Pastel green"
						Case $idWhite
							$sCaption = "Default white"
						Case $idTransparent
							$sCaption = "Transparent"
					EndSwitch
					_Click($sCaption)
					Switch $iMsg
						Case $idBlue
							_SetColor($sCaption, 0xDCEEFF, 255)
						Case $idGreen
							_SetColor($sCaption, 0xDCF2DF, 255)
						Case $idWhite
							_SetColor($sCaption, 0xFFFFFF, 255)
						Case $idTransparent
							_SetColor($sCaption, 0x000000, 0)
					EndSwitch
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					$aClient = WinGetClientSize($g_EX_hGUI)
					If IsArray($aClient) Then
						_Layout($aClient)
						_WebView2_SetBounds($g_EX_iWebView, 305, 48, $aClient[0] - 313, $aClient[1] - 280)
					EndIf
				Case $GUI_EVENT_CLOSE
					ExitLoop
			EndSwitch
		WEnd
	Until True
	_WebView2_Cleanup()
	If $g_EX_hGUI Then GUIDelete($g_EX_hGUI)
	Return SetError($iError, $iExtended, 0)
EndFunc   ;==>_Example

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _SetColor
; Description ...: Sets and reads back the controller color.
; Syntax ........: _SetColor($sName, $iRGB, $iAlpha)
; Parameters ....: $sName - Color button caption.
;                  $iRGB - Requested RGB value.
;                  $iAlpha - Requested alpha value.
; Return values .: True if the native readback matches; otherwise False.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This check confirms the native API state, not a visible pixel color.
; Related .......: _WebView2_SetDefaultBackgroundColor, _WebView2_GetDefaultBackgroundColor
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _SetColor($sName, $iRGB, $iAlpha)
	Local $bResult = False
	Do
		If Not _WebView2_SetDefaultBackgroundColor($g_EX_iWebView, $iRGB, $iAlpha) Then
			_Log($sName & " failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		Local $iActual = _WebView2_GetDefaultBackgroundColor($g_EX_iWebView)
		Local $iReadError = @error, $iActualAlpha = @extended
		If $iReadError Or $iActual <> $iRGB Or $iActualAlpha <> $iAlpha Then
			_Log($sName & " readback mismatch: RGB=0x" & Hex($iActual, 6) & ", alpha=" & $iActualAlpha & ".")
			ExitLoop 1
		EndIf
		_Log($sName & " applied and read back: RGB=0x" & Hex($iActual, 6) & ", alpha=" & $iActualAlpha & ".")
		$bResult = True
	Until True
	Return $bResult
EndFunc   ;==>_SetColor

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Layout
; Description ...: Fits the test panels to the current GUI client area.
; Syntax ........: _Layout($aClient)
; Parameters ....: $aClient - Current client dimensions.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Layout($aClient)
	If IsArray($aClient) Then
		GUICtrlSetPos($g_EX_idLog, 8, 68, 285, $aClient[1] - 78)
		GUICtrlSetPos($g_EX_idGuide, 305, $aClient[1] - 222, $aClient[0] - 313, 212)
	EndIf
	Return
EndFunc   ;==>_Layout

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Log
; Description ...: Adds a timestamped line and scrolls to it.
; Syntax ........: _Log($sMessage)
; Parameters ....: $sMessage - Log message.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Log($sMessage)
	_GUICtrlEdit_AppendText($g_EX_idLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sMessage & @CRLF)
	GUICtrlSendMsg($g_EX_idLog, $EM_SCROLLCARET, 0, 0)
	Return
EndFunc   ;==>_Log

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Click
; Description ...: Starts a grouped log entry for a native button.
; Syntax ........: _Click($sCaption)
; Parameters ....: $sCaption - Visible button caption.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Click($sCaption)
	_GUICtrlEdit_AppendText($g_EX_idLog, @CRLF & "[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [AutoIt]: " & $sCaption & " was clicked." & @CRLF)
	GUICtrlSendMsg($g_EX_idLog, $EM_SCROLLCARET, 0, 0)
	Return
EndFunc   ;==>_Click
