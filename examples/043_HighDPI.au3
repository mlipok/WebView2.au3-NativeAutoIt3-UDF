; #WIP - Work in Progress: moving between monitors with different scaling awaits interactive confirmation.
#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global Const $g_EX_iWM_DPICHANGED = 0x02E0
Global $g_EX_hGUI = 0, $g_EX_idLog = 0, $g_EX_idGuide = 0, $g_EX_iWebView = -1
Global $g_EX_bDpiChanged = False

_Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Demonstrates process DPI awareness and resizing WebView2 after a monitor DPI change.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Call the process helper before any window is created. Test on monitors with different scale factors.
; Related .......: _WebView2_DPI_SetProcessPerMonitorV2, _WebView2_DPI_GetWindowDpi
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	Local $iError = 0, $iExtended = 0
	Do
		Local $bAware = _WebView2_DPI_SetProcessPerMonitorV2()
		Local $iAwareError = @error, $iAwareExtended = @extended
		$g_EX_hGUI = GUICreate("WebView2 - High DPI", 1100, 720, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		Local $idRead = GUICtrlCreateButton("Read window DPI", 8, 8, 150, 30)
		GUICtrlCreateLabel("AutoIt operation log", 8, 48, 285, 18)
		$g_EX_idLog = GUICtrlCreateEdit("", 8, 68, 285, 450, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idLog, 0xE2F0E4)
		$g_EX_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
				"1. Read the DPI and note the value in the log." & @CRLF & _
				"2. Restore this window and move it to another monitor with a different Windows scale factor." & @CRLF & _
				"3. Check that the DPI event and physical client bounds change, while WebView2 fits its panel." & @CRLF & _
				"4. Maximize and restore the window on both monitors; check that no panel is clipped." & @CRLF & _
				"HOW IT WORKS" & @CRLF & _
				"The host opts into Per Monitor v2 before creating a window. WM_DPICHANGED supplies a recommended window rectangle; AutoIt applies it, then updates WebView2 bounds in its main loop. Production applications should declare DPI awareness in a manifest.", _
				305, 500, 780, 210, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idGuide, 0xFFF1BF)
		GUIRegisterMsg($g_EX_iWM_DPICHANGED, "_OnDpiChanged")
		GUISetState(@SW_MAXIMIZE, $g_EX_hGUI)
		GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hGUI)
		Local $aClient = WinGetClientSize($g_EX_hGUI)
		_Layout($aClient)
		_Log("Per Monitor v2 request: success=" & $bAware & ", error=" & $iAwareError & ", extended=" & $iAwareExtended & ".")
		_LogDpiAndBounds()
		If Not _WebView2_Init(Default, @LocalAppDataDir & "\WebView2.au3\Examples\043_HighDPI") Then
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
		If Not _WebView2_NavigateToString($g_EX_iWebView, '<!doctype html><html><meta name="viewport" content="width=device-width,initial-scale=1"><style>body{font:20px Segoe UI,sans-serif;margin:24px}section{padding:24px;background:#eaf4ff;border:2px solid #2772a8}</style><section><h1>DPI-aware WebView2</h1><p>Move the AutoIt window between monitors. This blue panel should stay inside WebView2.</p><p>CSS pixels and physical pixels may differ when Windows display scaling changes.</p></section></html>') Then
			$iError = @error
			$iExtended = @extended
			_Log("Navigation failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		While True
			Local $iMsg = GUIGetMsg()
			Switch $iMsg
				Case $idRead
					_Click("Read window DPI")
					_LogDpiAndBounds()
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					_UpdateBounds()
				Case $GUI_EVENT_CLOSE
					ExitLoop
			EndSwitch
			If $g_EX_bDpiChanged Then
				$g_EX_bDpiChanged = False
				_UpdateBounds()
				_LogDpiAndBounds()
			EndIf
		WEnd
	Until True
	GUIRegisterMsg($g_EX_iWM_DPICHANGED, "")
	_WebView2_Cleanup()
	If $g_EX_hGUI Then GUIDelete($g_EX_hGUI)
	Return SetError($iError, $iExtended, 0)
EndFunc   ;==>_Example

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _OnDpiChanged
; Description ...: Applies Windows' suggested physical window rectangle without calling WebView2 inside the window procedure.
; Syntax ........: _OnDpiChanged($hWnd, $iMsg, $wParam, $lParam)
; Parameters ....: Standard Win32 window message fields.
; Return values .: Zero when handled, otherwise $GUI_RUNDEFMSG.
; Author ........: mLipok
; Modified ......:
; Remarks .......: WebView2 bounds are updated later by the main GUI loop.
; Related .......: _UpdateBounds
; Link ..........: https://learn.microsoft.com/windows/win32/hidpi/wm-dpichanged
; Example .......: Yes
; ===============================================================================================================================
Func _OnDpiChanged($hWnd, $iMsg, $wParam, $lParam)
	#forceref $iMsg, $wParam
	Local $iResult = $GUI_RUNDEFMSG
	Do
		If $hWnd <> $g_EX_hGUI Or Not $lParam Then ExitLoop 1
		Local $tRect = DllStructCreate("long Left;long Top;long Right;long Bottom", $lParam)
		Local $iLeft = DllStructGetData($tRect, "Left"), $iTop = DllStructGetData($tRect, "Top")
		Local $iWidth = DllStructGetData($tRect, "Right") - $iLeft
		Local $iHeight = DllStructGetData($tRect, "Bottom") - $iTop
		DllCall("user32.dll", "bool", "SetWindowPos", "hwnd", $hWnd, "hwnd", 0, "int", $iLeft, "int", $iTop, "int", $iWidth, "int", $iHeight, "uint", 0x0014)
		$g_EX_bDpiChanged = True
		$iResult = 0
	Until True
	Return $iResult
EndFunc   ;==>_OnDpiChanged

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _UpdateBounds
; Description ...: Fits the log, guide and WebView2 to the GUI client area.
; Syntax ........: _UpdateBounds()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetBounds
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _UpdateBounds()
	Local $aClient = WinGetClientSize($g_EX_hGUI)
	If IsArray($aClient) Then
		_Layout($aClient)
		If $g_EX_iWebView >= 0 Then _WebView2_SetBounds($g_EX_iWebView, 305, 48, $aClient[0] - 313, $aClient[1] - 280)
	EndIf
	Return
EndFunc   ;==>_UpdateBounds

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Layout
; Description ...: Fits the AutoIt panels to the current GUI client area.
; Syntax ........: _Layout($aClient)
; Parameters ....: $aClient - Client dimensions in physical pixels.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _UpdateBounds
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
; Name ..........: _LogDpiAndBounds
; Description ...: Reports native window DPI and client bounds.
; Syntax ........: _LogDpiAndBounds()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_DPI_GetWindowDpi
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _LogDpiAndBounds()
	Local $iDpi = _WebView2_DPI_GetWindowDpi($g_EX_hGUI)
	Local $iDpiError = @error
	Local $aClient = WinGetClientSize($g_EX_hGUI)
	If IsArray($aClient) Then _Log("Window DPI=" & $iDpi & " (error=" & $iDpiError & "); client=" & $aClient[0] & " x " & $aClient[1] & " physical px.")
	Return
EndFunc   ;==>_LogDpiAndBounds

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Log
; Description ...: Appends a message and scrolls to the newest line.
; Syntax ........: _Log($sMessage)
; Parameters ....: $sMessage - Message to append.
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
; Description ...: Starts a separate log group for a native button click.
; Syntax ........: _Click($sCaption)
; Parameters ....: $sCaption - Button caption.
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
