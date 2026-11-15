#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_EX_hGUI = 0, $g_EX_idLog = 0, $g_EX_idGuide = 0, $g_EX_iWebView = -1
Global $g_EX_bBlockF5 = False

_Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Demonstrates the browser accelerator switch and selective key handling.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: A WebView2 Runtime is required.
; Related .......: _WebView2_SetBrowserAcceleratorKeysEnabled, _WebView2_SetCallback
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	Local $iError = 0, $iExtended = 0
	Do
		$g_EX_hGUI = GUICreate("WebView2 - Accelerator keys", 1100, 720, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		Local $idEnable = GUICtrlCreateButton("Enable browser shortcuts", 10, 8, 170, 30)
		Local $idDisable = GUICtrlCreateButton("Disable browser shortcuts", 190, 8, 170, 30)
		Local $idBlock = GUICtrlCreateButton("Block F5: OFF", 370, 8, 120, 30)
		Local $idReload = GUICtrlCreateButton("Reload page", 500, 8, 120, 30)
		GUICtrlCreateLabel("AutoIt operation log", 8, 48, 285, 18)
		$g_EX_idLog = GUICtrlCreateEdit("", 8, 68, 285, 450, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idLog, 0xE2F0E4)
		$g_EX_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
				"1. Click inside the page, then press F5. Its load counter should increase." & @CRLF & _
				"2. Turn Block F5 ON and press F5 again. AutoIt logs the key; the counter stays unchanged." & @CRLF & _
				"3. Turn Block F5 OFF, click Disable browser shortcuts, then Reload page. F5 no longer reloads." & @CRLF & _
				"4. Enable browser shortcuts, Reload page and press F5. The counter increases again." & @CRLF & _
				"HOW IT WORKS" & @CRLF & _
				"The Settings3 switch controls browser shortcuts such as F5 and Ctrl+P. AcceleratorKeyPressed still fires while they are disabled. Returning True from the AutoIt callback handles only the selected key. Text editing keys remain available.", _
				305, 500, 780, 210, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idGuide, 0xFFF1BF)
		GUISetState(@SW_MAXIMIZE, $g_EX_hGUI)
		GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hGUI)
		Local $aClient = WinGetClientSize($g_EX_hGUI)
		_Layout($aClient)
		_Log("Starting WebView2...")
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\037_AcceleratorKeys"
		If Not _WebView2_Init(Default, $sProfile) Then
			$iError = @error
			$iExtended = @extended
			_Log("Init failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		_Log("WebView2 environment ready.")
		$g_EX_iWebView = _WebView2_Create($g_EX_hGUI, 305, 48, $aClient[0] - 313, $aClient[1] - 280)
		If @error Then
			$iError = @error
			$iExtended = @extended
			_Log("Create failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		_Log("WebView2 controller ready.")
		If Not _WebView2_SetCallback($g_EX_iWebView, $WEBVIEW2_EVENT_ACCELERATOR_KEY_PRESSED, _OnAccelerator) Then
			$iError = @error
			$iExtended = @extended
			_Log("Accelerator callback failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		_Log("Native accelerator event ready.")
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_EX_iWebView, "udf-virtual-host.example", @ScriptDir & "\assets\native") Then
			$iError = @error
			$iExtended = @extended
			_Log("Local page mapping failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		_Log("Local page mapped.")
		If Not _WebView2_Navigate($g_EX_iWebView, "https://udf-virtual-host.example/037.html") Then
			$iError = @error
			$iExtended = @extended
			_Log("Navigate failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		_Log("Page navigation started.")
		While True
			Local $iMsg = GUIGetMsg()
			Switch $iMsg
				Case $idEnable, $idDisable
					Local $bEnable = $iMsg = $idEnable
					_Click($bEnable ? "Enable browser shortcuts" : "Disable browser shortcuts")
					If _WebView2_SetBrowserAcceleratorKeysEnabled($g_EX_iWebView, $bEnable) Then
						_Log("Browser shortcuts " & ($bEnable ? "enabled" : "disabled") & ". Reload page to apply the change.")
					Else
						_Log("Setting failed: " & _WebView2_Error_GetDescription())
					EndIf
				Case $idBlock
					_Click(GUICtrlRead($idBlock))
					$g_EX_bBlockF5 = Not $g_EX_bBlockF5
					GUICtrlSetData($idBlock, "Block F5: " & ($g_EX_bBlockF5 ? "ON" : "OFF"))
					_Log("Selective F5 handling " & ($g_EX_bBlockF5 ? "enabled" : "disabled") & ".")
				Case $idReload
					_Click("Reload page")
					_WebView2_Reload($g_EX_iWebView)
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

; #FUNCTION# ====================================================================================================================
; Name ..........: _OnAccelerator
; Description ...: Logs F5 and optionally suppresses its default browser action.
; Syntax ........: _OnAccelerator($iWebView, $iKind, $iKey, $iLParam)
; Parameters ....: $iWebView - WebView instance ID.
;                  $iKind - Native key event kind.
;                  $iKey - Win32 virtual key code.
;                  $iLParam - Native key event LPARAM.
; Return values .: True to handle F5, otherwise False.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This callback must return promptly.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnAccelerator($iWebView, $iKind, $iKey, $iLParam)
	#forceref $iWebView, $iLParam
	Local $bHandled = False
	If $iKey = 0x74 And $iKind = $WEBVIEW2_KEY_EVENT_KIND_KEY_DOWN Then
		_Log("F5 detected by native AcceleratorKeyPressed; handled=" & $g_EX_bBlockF5 & ".")
		$bHandled = $g_EX_bBlockF5
	EndIf
	Return $bHandled
EndFunc   ;==>_OnAccelerator

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Layout
; Description ...: Fits the three test panels to the current GUI client area.
; Syntax ........: _Layout($aClient)
; Parameters ....: $aClient - Current GUI client dimensions.
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
; Description ...: Appends a time-stamped message and scrolls to its end.
; Syntax ........: _Log($sMessage)
; Parameters ....: $sMessage - Text to append.
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
; Description ...: Starts a new log group for an AutoIt button click.
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
