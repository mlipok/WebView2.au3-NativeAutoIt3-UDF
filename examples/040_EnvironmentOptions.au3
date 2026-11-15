#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
; #WIP - Work in Progress: native WebView2 behavior needs an interactive confirmation.

#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_EX_hGUI = 0, $g_EX_hHost = 0, $g_EX_idLog = 0, $g_EX_idGuide = 0, $g_EX_iWebView = -1
Global $g_EX_iSmokeExit = 0
Global $g_EX_bHostMoved = False
Global Const $g_EX_sHTML = '<!doctype html><html><head><meta charset="utf-8"><title>Environment options</title><style>body{margin:32px;font:18px Segoe UI,sans-serif;color:#183247}main{max-width:850px}code{display:block;overflow-wrap:anywhere;background:#eef4f8;padding:14px;margin:8px 0 24px}</style></head><body><main><h1>WebView2 environment options</h1><p>The page reports browser values established before WebView2 initialization.</p><h2>navigator.language</h2><code id="language"></code><h2>navigator.userAgent</h2><code id="agent"></code><p>Windows-account SSO stays disabled in this local sample; no account or network request is used.</p></main><script>document.getElementById("language").textContent=navigator.language;document.getElementById("agent").textContent=navigator.userAgent;</script></body></html>'

_Example()
If $CmdLine[0] And $CmdLine[1] = "--smoke" Then Exit $g_EX_iSmokeExit

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Demonstrates environment language, browser arguments and the opt-in SSO setting.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The sample does not enable SSO or contact an authentication service.
; Related .......: _WebView2_Environment_SetLanguage, _WebView2_Environment_SetAdditionalBrowserArguments
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2environmentoptions
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	Local $iError = 0, $iExtended = 0
	Local $sValues = ""
	If $CmdLine[0] And $CmdLine[1] = "--smoke" Then $g_EX_iSmokeExit = 1
	Do
		$g_EX_hGUI = GUICreate("WebView2 - Environment options", 1100, 720, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		GUIRegisterMsg($WM_MOVE, "_OnMainMove")
		Local $idRead = GUICtrlCreateButton("Read browser values", 10, 8, 175, 30)
		GUICtrlCreateLabel("AutoIt operation log", 8, 48, 285, 18)
		$g_EX_idLog = GUICtrlCreateEdit("", 8, 68, 285, 450, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idLog, 0xE2F0E4)
		$g_EX_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
				"1. Check that the page reports a Polish browser language (pl or pl-PL) and a user agent containing WV2EnvOptionsDemo/1.0." & @CRLF & _
				"2. Click Read browser values. The AutoIt log should report the same values read by native ExecuteScript." & @CRLF & _
				"HOW IT WORKS" & @CRLF & _
				"Language and Chromium browser arguments are supplied before environment creation. The language affects browser UI and Accept-Language. The sample user-agent switch is visible in navigator.userAgent. Windows-account SSO is explicitly kept off; enabling it in another application can allow eligible Microsoft identity sites to use the Windows account, but it does not sign in to arbitrary sites. These options cannot be changed in an existing environment. No Internet connection is required.", _
				305, 500, 780, 210, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idGuide, 0xFFF1BF)
		GUISetState(@SW_MAXIMIZE, $g_EX_hGUI)
		GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hGUI)
		Local $aClient = WinGetClientSize($g_EX_hGUI)
		_Layout($aClient)
		Local $tPoint = DllStructCreate("long X;long Y")
		DllStructSetData($tPoint, "X", 305)
		DllStructSetData($tPoint, "Y", 48)
		DllCall("user32.dll", "bool", "ClientToScreen", "hwnd", $g_EX_hGUI, "struct*", $tPoint)
		$g_EX_hHost = GUICreate("", $aClient[0] - 313, $aClient[1] - 280, DllStructGetData($tPoint, "X"), DllStructGetData($tPoint, "Y"), $WS_POPUP, $WS_EX_NOREDIRECTIONBITMAP, $g_EX_hGUI)
		GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hHost)
		_Log("Configuring WebView2 environment before initialization...")
		If Not _WebView2_Environment_SetLanguage("pl-PL") Then
			$iError = @error
			$iExtended = @extended
			_Log("Language configuration failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		If Not _WebView2_Environment_SetAdditionalBrowserArguments("--user-agent=WV2EnvOptionsDemo/1.0") Then
			$iError = @error
			$iExtended = @extended
			_Log("Browser argument configuration failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		If Not _WebView2_Environment_SetOSPrimaryAccountSSO(False) Then
			$iError = @error
			$iExtended = @extended
			_Log("SSO configuration failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		_Log("Language=pl-PL; browser argument sets the demo user agent; OS-account SSO=False.")
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\040_EnvironmentOptions"
		If Not _WebView2_Init(Default, $sProfile) Then
			$iError = @error
			$iExtended = @extended
			_Log("Init failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		$g_EX_iWebView = _WebView2_Create($g_EX_hHost, 0, 0, $aClient[0] - 313, $aClient[1] - 280)
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
		_Log("Page ready. Click Read browser values.")
		If $CmdLine[0] And $CmdLine[1] = "--smoke" Then
			$sValues = _WebView2_ExecuteScript($g_EX_iWebView, "JSON.stringify({language:navigator.language,userAgent:navigator.userAgent})")
			If @error Or StringInStr($sValues, "WV2EnvOptionsDemo/1.0") = 0 Then
				_Log("Smoke readback failed: " & $sValues)
				ExitLoop 1
			EndIf
			Local $sLanguage = _WebView2_ExecuteScript($g_EX_iWebView, "navigator.language")
			If @error Or ($sLanguage <> '"pl"' And $sLanguage <> '"pl-PL"') Then
				_Log("Smoke language readback failed: " & $sLanguage)
				ExitLoop 1
			EndIf
			ConsoleWrite("EX_SMOKE_OK" & @CRLF)
			$g_EX_iSmokeExit = 0
			ExitLoop 1
		EndIf
		While True
			Local $iMsg = GUIGetMsg()
			If $g_EX_bHostMoved Then
				$g_EX_bHostMoved = False
				_SyncHost()
			EndIf
			Switch $iMsg
				Case $idRead
					_Click("Read browser values")
					$sValues = _WebView2_ExecuteScript($g_EX_iWebView, "JSON.stringify({language:navigator.language,userAgent:navigator.userAgent})")
					If @error Then
						_Log("Readback failed: " & _WebView2_Error_GetDescription())
					Else
						_Log("Browser values: " & $sValues)
					EndIf
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					_SyncHost()
				Case $GUI_EVENT_CLOSE
					ExitLoop
			EndSwitch
		WEnd
	Until True
	_WebView2_Cleanup()
	If $g_EX_hHost Then GUIDelete($g_EX_hHost)
	If $g_EX_hGUI Then GUIDelete($g_EX_hGUI)
	Return SetError($iError, $iExtended, 0)
EndFunc   ;==>_Example

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Layout
; Description ...: Fits the test panels to the current GUI client size.
; Syntax ........: _Layout($aClient)
; Parameters ....: $aClient - GUI client dimensions.
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
; Name ..........: _OnMainMove
; Description ...: Defers owned WebView host positioning until the GUI message loop resumes.
; Syntax ........: _OnMainMove($hWnd, $iMsg, $wParam, $lParam)
; Parameters ....: $hWnd - Message target window.
;                  $iMsg - Windows message identifier.
;                  $wParam - Message parameter.
;                  $lParam - Message parameter.
; Return values .: $GUI_RUNDEFMSG.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _SyncHost
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnMainMove($hWnd, $iMsg, $wParam, $lParam)
	#forceref $iMsg, $wParam, $lParam
	If $hWnd = $g_EX_hGUI Then $g_EX_bHostMoved = True
	Return $GUI_RUNDEFMSG
EndFunc   ;==>_OnMainMove

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _SyncHost
; Description ...: Aligns the owned WebView host with its area in the main GUI.
; Syntax ........: _SyncHost()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _OnMainMove, _Layout
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _SyncHost()
	Local $aClient = WinGetClientSize($g_EX_hGUI)
	If IsArray($aClient) Then
		_Layout($aClient)
		Local $tPoint = DllStructCreate("long X;long Y")
		DllStructSetData($tPoint, "X", 305)
		DllStructSetData($tPoint, "Y", 48)
		DllCall("user32.dll", "bool", "ClientToScreen", "hwnd", $g_EX_hGUI, "struct*", $tPoint)
		WinMove($g_EX_hHost, "", DllStructGetData($tPoint, "X"), DllStructGetData($tPoint, "Y"), $aClient[0] - 313, $aClient[1] - 280)
		_WebView2_SetBounds($g_EX_iWebView, 0, 0, $aClient[0] - 313, $aClient[1] - 280)
	EndIf
	Return
EndFunc   ;==>_SyncHost

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Log
; Description ...: Appends a timestamped message and scrolls to it.
; Syntax ........: _Log($sMessage)
; Parameters ....: $sMessage - Message text.
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
; Description ...: Starts a log group for an AutoIt button click.
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
