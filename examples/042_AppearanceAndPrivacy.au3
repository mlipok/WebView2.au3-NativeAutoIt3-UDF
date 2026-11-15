#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_EX_hGUI = 0, $g_EX_hHost = 0, $g_EX_idLog = 0, $g_EX_idGuide = 0, $g_EX_iWebView = -1
Global $g_EX_iSmokeExit = 0
Global $g_EX_bHostMoved = False
Global Const $g_EX_sHTML = '<!doctype html><html><head><meta charset="utf-8"><title>Appearance and privacy</title><style>html{color-scheme:light dark}body{margin:32px;font:18px Segoe UI,sans-serif;background:#f7fbff;color:#173148}main{max-width:920px}.sample{height:1800px;border:2px solid #5189bb;padding:24px;background:#eaf3ff}#scheme{font-weight:bold}@media(prefers-color-scheme:dark){body{background:#18283a;color:#f4f6fa}.sample{background:#203d5b}}</style></head><body><main><h1>Native appearance and privacy</h1><p>CSS prefers-color-scheme: <span id="scheme"></span>. Change the profile scheme with the AutoIt buttons. Scroll this tall panel to compare native scroll bars.</p><p>Tracking prevention is a profile setting. This local page has no trackers; the AutoIt log reports native readback, not a network-blocking test.</p><div class="sample">Scroll down to inspect the WebView2 scroll bar. The page uses CSS color-scheme: light dark.</div></main><script>const value=document.getElementById("scheme");function show(){value.textContent=matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light"}matchMedia("(prefers-color-scheme: dark)").addEventListener("change",show);show()</script></body></html>'

_Example()
If $CmdLine[0] And $CmdLine[1] = "--smoke" Then Exit $g_EX_iSmokeExit

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Demonstrates profile color scheme, tracking prevention and native scroll bar styling.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Local-only page; tracking-prevention strength is read back, not tested against a remote tracker.
; Related .......: _WebView2_Profile_SetPreferredColorScheme, _WebView2_Profile_SetTrackingPreventionLevel
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2profile3
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	Local $iError = 0, $iExtended = 0
	Local $iColor = -1, $iTracking = -1
	If $CmdLine[0] And $CmdLine[1] = "--smoke" Then $g_EX_iSmokeExit = 1
	Do
		$g_EX_hGUI = GUICreate("WebView2 - Appearance and privacy", 1100, 720, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		GUIRegisterMsg($WM_MOVE, "_OnMainMove")
		Local $idAuto = GUICtrlCreateButton("Color: Auto", 10, 8, 120, 30)
		Local $idLight = GUICtrlCreateButton("Color: Light", 136, 8, 120, 30)
		Local $idDark = GUICtrlCreateButton("Color: Dark", 262, 8, 120, 30)
		Local $idBasic = GUICtrlCreateButton("Tracking: Basic", 388, 8, 140, 30)
		Local $idBalanced = GUICtrlCreateButton("Tracking: Balanced", 534, 8, 155, 30)
		Local $idStrict = GUICtrlCreateButton("Tracking: Strict", 695, 8, 140, 30)
		GUICtrlCreateLabel("AutoIt operation log", 8, 48, 285, 18)
		$g_EX_idLog = GUICtrlCreateEdit("", 8, 68, 285, 450, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idLog, 0xE2F0E4)
		$g_EX_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
				"1. Click Color: Dark, Light and Auto. The page background and prefers-color-scheme value should follow each selection; the log reports native profile readback." & @CRLF & _
				"2. Click Tracking: Basic, Balanced and Strict. The log should read back 1, 2 and 3. This offline page has no tracker, so it cannot prove network blocking." & @CRLF & _
				"3. Scroll the tall page. This launch requests Fluent overlay scroll bars. Launch with --default-scrollbar to compare the Runtime default. The native style requires Runtime 125 or newer." & @CRLF & _
				"HOW IT WORKS" & @CRLF & _
				"Color scheme and tracking level are profile settings and affect all views sharing that profile. Tracking prevention remains enabled at the environment level. Scroll bar style is fixed when the environment is created; CSS color-scheme lets the bar follow the theme. No Internet connection is required.", _
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
		Local $iScrollStyle = $WEBVIEW2_SCROLLBAR_STYLE_FLUENT_OVERLAY
		If $CmdLine[0] And $CmdLine[1] = "--default-scrollbar" Then $iScrollStyle = $WEBVIEW2_SCROLLBAR_STYLE_DEFAULT
		_Log("Configuring native scroll bar style " & $iScrollStyle & " before initialization...")
		If Not _WebView2_Environment_SetScrollBarStyle($iScrollStyle) Then
			$iError = @error
			$iExtended = @extended
			_Log("Scroll bar configuration failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\042_AppearanceAndPrivacy"
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
		$iColor = _WebView2_Profile_GetPreferredColorScheme($g_EX_iWebView)
		If @error Then
			_Log("Color scheme readback failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		$iTracking = _WebView2_Profile_GetTrackingPreventionLevel($g_EX_iWebView)
		If @error Then
			_Log("Tracking level readback failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		_Log("Page ready. Native color=" & $iColor & "; tracking=" & $iTracking & "; requested scroll bar style=" & $iScrollStyle & ".")
		If $CmdLine[0] And $CmdLine[1] = "--smoke" Then
			If Not _WebView2_Profile_SetPreferredColorScheme($g_EX_iWebView, $WEBVIEW2_PREFERRED_COLOR_DARK) Then
				_Log("Smoke color write failed.")
				ExitLoop 1
			EndIf
			If _WebView2_Profile_GetPreferredColorScheme($g_EX_iWebView) <> $WEBVIEW2_PREFERRED_COLOR_DARK Or @error Then
				_Log("Smoke color readback failed.")
				ExitLoop 1
			EndIf
			If Not _WebView2_Profile_SetTrackingPreventionLevel($g_EX_iWebView, $WEBVIEW2_TRACKING_PREVENTION_STRICT) Then
				_Log("Smoke tracking write failed.")
				ExitLoop 1
			EndIf
			If _WebView2_Profile_GetTrackingPreventionLevel($g_EX_iWebView) <> $WEBVIEW2_TRACKING_PREVENTION_STRICT Or @error Then
				_Log("Smoke tracking readback failed.")
				ExitLoop 1
			EndIf
			_WebView2_Profile_SetPreferredColorScheme($g_EX_iWebView, $iColor)
			_WebView2_Profile_SetTrackingPreventionLevel($g_EX_iWebView, $iTracking)
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
				Case $idAuto, $idLight, $idDark
					Local $iScheme = $WEBVIEW2_PREFERRED_COLOR_AUTO, $sCaption = "Color: Auto"
					If $iMsg = $idLight Then
						$iScheme = $WEBVIEW2_PREFERRED_COLOR_LIGHT
						$sCaption = "Color: Light"
					ElseIf $iMsg = $idDark Then
						$iScheme = $WEBVIEW2_PREFERRED_COLOR_DARK
						$sCaption = "Color: Dark"
					EndIf
					_Click($sCaption)
					If _WebView2_Profile_SetPreferredColorScheme($g_EX_iWebView, $iScheme) Then
						_Log("Native color scheme=" & _WebView2_Profile_GetPreferredColorScheme($g_EX_iWebView))
					Else
						_Log("Color scheme update failed: " & _WebView2_Error_GetDescription())
					EndIf
				Case $idBasic, $idBalanced, $idStrict
					Local $iLevel = $WEBVIEW2_TRACKING_PREVENTION_BASIC, $sTrackingCaption = "Tracking: Basic"
					If $iMsg = $idBalanced Then
						$iLevel = $WEBVIEW2_TRACKING_PREVENTION_BALANCED
						$sTrackingCaption = "Tracking: Balanced"
					ElseIf $iMsg = $idStrict Then
						$iLevel = $WEBVIEW2_TRACKING_PREVENTION_STRICT
						$sTrackingCaption = "Tracking: Strict"
					EndIf
					_Click($sTrackingCaption)
					If _WebView2_Profile_SetTrackingPreventionLevel($g_EX_iWebView, $iLevel) Then
						_Log("Native tracking prevention level=" & _WebView2_Profile_GetTrackingPreventionLevel($g_EX_iWebView))
					Else
						_Log("Tracking level update failed: " & _WebView2_Error_GetDescription())
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
