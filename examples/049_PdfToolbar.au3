#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"
Opt("MustDeclareVars", 1)
Global $g_EX_hGUI = 0, $g_EX_hHost = 0, $g_EX_idLog = 0, $g_EX_idGuide = 0, $g_EX_iWebView = -1
Global $g_EX_sHostGeometry = "", $g_EX_bSmoke = False, $g_EX_iNavigation = 0, $g_EX_bNavigated = False
If $CmdLine[0] Then $g_EX_bSmoke = $CmdLine[1] = "--smoke"
Exit _Example()

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Example
; Description ...: Demonstrates individual native PDF toolbar flags and readback.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: Zero on success; one on initialization or smoke failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The bundled PDF.js sample document is opened directly by the native viewer, without PDF.js.
; Related .......:
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2settings7
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	Local $iExit = 1
	Opt("GUIResizeMode", $GUI_DOCKALL)
	Local $aNames = ["Save", "Print", "Save as", "Zoom in", "Zoom out", "Rotate", "Fit page", "Page layout", "Bookmarks", "Page selector", "Search", "Full screen", "More settings"]
	Local $aChecks[13]
	Do
		$g_EX_hGUI = GUICreate("WebView2 - Native PDF toolbar", 1200, 800, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		Local $idApply = GUICtrlCreateButton("Apply and reload", 8, 8, 150, 28)
		Local $idRead = GUICtrlCreateButton("Read native value", 168, 8, 150, 28)
		Local $idReset = GUICtrlCreateButton("Restore all items", 328, 8, 150, 28)
		For $i = 0 To 12
			$aChecks[$i] = GUICtrlCreateCheckbox($aNames[$i], 8 + Mod($i, 7) * 130, 40 + Int($i / 7) * 23, 125, 22)
		Next
		GUICtrlCreateLabel("Checked = hidden after Apply and reload", 920, 44, 260, 35)
		GUICtrlCreateLabel("AutoIt operation log", 8, 80, 332, 18)
		$g_EX_idLog = GUICtrlCreateEdit("", 8, 98, 332, 500, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idLog, 0xE2F0E4)
		$g_EX_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
				"1. The native PDF viewer opens a local sample document. Click Read native value: initial mask should be 0." & @CRLF & _
				"2. Check Print, Save or Save as, then click Apply and reload. The log must show matching requested/native masks; those toolbar controls should disappear after navigation." & @CRLF & _
				"3. Try other individual items or combinations. Click Restore all items: the mask returns to 0 and default controls return after navigation." & @CRLF & _
				"4. Resize, maximize and restore. Some toolbar items move into menus on narrow windows or are not offered by every Runtime." & @CRLF & _
				"HOW IT WORKS" & @CRLF & _
				"ICoreWebView2Settings7.HiddenPdfToolbarItems is a bitmask, read back from the native COM interface. It affects views sharing an environment/profile, so this example uses its own profile. Changes take effect on the next navigation. The document is opened directly in the native viewer; PDF.js is not used. Hiding controls is UI customization, not a security restriction on saving or printing. No Internet is required.", _
				350, 570, 840, 220, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idGuide, 0xFFF1BF)
		For $i = 0 To 12
			GUICtrlSetResizing($aChecks[$i], $GUI_DOCKALL)
		Next
		GUICtrlSetResizing($idApply, $GUI_DOCKALL)
		GUICtrlSetResizing($idRead, $GUI_DOCKALL)
		GUICtrlSetResizing($idReset, $GUI_DOCKALL)
		GUICtrlSetResizing($g_EX_idLog, $GUI_DOCKALL)
		GUICtrlSetResizing($g_EX_idGuide, $GUI_DOCKALL)
		If Not $g_EX_bSmoke Then
			GUISetState(@SW_MAXIMIZE, $g_EX_hGUI)
			GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hGUI)
		EndIf
		Local $aClient = WinGetClientSize($g_EX_hGUI)
		_Layout($aClient)
		$g_EX_hHost = GUICreate("", 1, 1, 0, 0, $WS_POPUP, $WS_EX_NOREDIRECTIONBITMAP, $g_EX_hGUI)
		_SyncHost()
		If Not $g_EX_bSmoke Then GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hHost)
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\049_PdfToolbar"
		If $g_EX_bSmoke Then $sProfile = @TempDir & "\WebView2-PdfToolbar-" & @AutoItPID
		_Log("Starting WebView2...")
		If Not _WebView2_Init(Default, $sProfile) Then ExitLoop
		Local $aSize = WinGetClientSize($g_EX_hHost)
		$g_EX_iWebView = _WebView2_Create($g_EX_hHost, 0, 0, $aSize[0], $aSize[1])
		If @error Then ExitLoop
		Local $sPdfFolder = @ScriptDir & "\assets\pdfjs\web"
		If Not FileExists($sPdfFolder & "\compressed.tracemonkey-pldi-09.pdf") Then
			_Log("Bundled sample PDF is missing: " & $sPdfFolder)
			ExitLoop
		EndIf
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_EX_iWebView, "udf-virtual-host.example", $sPdfFolder) Then ExitLoop
		If Not _WebView2_SetCallback($g_EX_iWebView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _OnNavigation) Then ExitLoop
		If Not _Apply(0) Then ExitLoop
		If $g_EX_bSmoke Then
			Local $iWait = TimerInit()
			While Not $g_EX_bNavigated And TimerDiff($iWait) < 15000
				Sleep(10)
			WEnd
			If $g_EX_bNavigated Then $iExit = _Smoke()
			ExitLoop
		EndIf
		While True
			Local $aMsg = GUIGetMsg(1)
			Switch $aMsg[0]
				Case $GUI_EVENT_CLOSE
					If $aMsg[1] = $g_EX_hGUI Then
						$iExit = 0
						ExitLoop
					EndIf
				Case $idApply
					_Click("Apply and reload")
					Local $iMask = 0
					For $i = 0 To 12
						If BitAND(GUICtrlRead($aChecks[$i]), $GUI_CHECKED) Then $iMask = BitOR($iMask, 2 ^ $i)
					Next
					_Apply(Int($iMask))
				Case $idRead
					_Click("Read native value")
					Local $iRead = _WebView2_GetHiddenPdfToolbarItems($g_EX_iWebView)
					If @error Then
						_Log("Read failed: " & _WebView2_Error_GetDescription())
					Else
						_Log("Native hidden mask = 0x" & Hex($iRead, 4) & " (" & $iRead & ").")
					EndIf
				Case $idReset
					_Click("Restore all items")
					If _Apply(0) Then
						For $i = 0 To 12
							GUICtrlSetState($aChecks[$i], $GUI_UNCHECKED)
						Next
					EndIf
			EndSwitch
			_SyncHost()
			Sleep(10)
		WEnd
	Until True
	If $iExit Then _Log("Example failed: " & _WebView2_Error_GetDescription())
	If $g_EX_bSmoke Then FileWrite(@ScriptDir & "\049_PdfToolbar.result.txt", "PDF_TOOLBAR_SMOKE arch=" & (@AutoItX64 ? "x64" : "x86") & " exit=" & $iExit & @CRLF)
	_WebView2_Cleanup()
	If $g_EX_hHost Then GUIDelete($g_EX_hHost)
	If $g_EX_hGUI Then GUIDelete($g_EX_hGUI)
	Return $iExit
EndFunc   ;==>_Example

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Apply
; Description ...: Sets and immediately reads the mask, then navigates the native PDF viewer.
; Syntax ........: _Apply($iMask)
; Parameters ....: $iMask - Items to hide.
; Return values .: True on matching readback and accepted navigation; otherwise False.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Readback confirms the setting, not visible toolbar rendering.
; Related .......:
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2settings7
; Example .......: Yes
; ===============================================================================================================================
Func _Apply($iMask)
	If Not _WebView2_SetHiddenPdfToolbarItems($g_EX_iWebView, $iMask) Then
		_Log("Set failed: " & _WebView2_Error_GetDescription())
		Return False
	EndIf
	Local $iActual = _WebView2_GetHiddenPdfToolbarItems($g_EX_iWebView)
	If @error Then
		_Log("Readback failed: " & _WebView2_Error_GetDescription())
		Return False
	EndIf
	_Log("Requested 0x" & Hex($iMask, 4) & "; native readback 0x" & Hex($iActual, 4) & ".")
	If $iActual <> $iMask Then Return False
	$g_EX_bNavigated = False
	$g_EX_iNavigation += 1
	If Not _WebView2_Navigate($g_EX_iWebView, "https://udf-virtual-host.example/compressed.tracemonkey-pldi-09.pdf?navigation=" & $g_EX_iNavigation) Then
		_Log("PDF navigation failed: " & _WebView2_Error_GetDescription())
		Return False
	EndIf
	_Log("PDF navigation requested; inspect the native toolbar after loading.")
	Return True
EndFunc   ;==>_Apply

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Smoke
; Description ...: Checks native mask round trips, invalid inputs and invalid owners.
; Syntax ........: _Smoke()
; Parameters ....: None.
; Return values .: Zero on success; one on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Programmatic checks do not establish toolbar appearance.
; Related .......:
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2settings7
; Example .......: Yes
; ===============================================================================================================================
Func _Smoke()
	Local $aMasks = [0, 1, 2, 4, 7, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8191, 0]
	For $i = 0 To UBound($aMasks) - 1
		If Not _WebView2_SetHiddenPdfToolbarItems($g_EX_iWebView, $aMasks[$i]) Then Return 1
		Local $iRead = _WebView2_GetHiddenPdfToolbarItems($g_EX_iWebView)
		If @error Then Return 1
		If $iRead <> $aMasks[$i] Then Return 1
	Next
	Local $aInvalid = [-1, 8192, "2", 1.5, True]
	For $i = 0 To UBound($aInvalid) - 1
		_WebView2_SetHiddenPdfToolbarItems($g_EX_iWebView, $aInvalid[$i])
		If @error <> $WEBVIEW2_ERR_INVALID_PARAMETER Then Return 1
	Next
	_WebView2_GetHiddenPdfToolbarItems(-1)
	If @error <> $WEBVIEW2_ERR_INVALID_INSTANCE Then Return 1
	_WebView2_SetHiddenPdfToolbarItems(-1, 0)
	If @error <> $WEBVIEW2_ERR_INVALID_INSTANCE Then Return 1
	_Log("Native mask round trips and rejected-input checks passed; visual PDF controls remain unverified.")
	Return 0
EndFunc   ;==>_Smoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Layout
; Description ...: Fits the log and guide to the GUI client area.
; Syntax ........: _Layout($aClient)
; Parameters ....: $aClient - GUI client dimensions.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetBounds
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Layout($aClient)
	If IsArray($aClient) Then
		GUICtrlSetPos($g_EX_idLog, 8, 98, 332, $aClient[1] - 108)
		GUICtrlSetPos($g_EX_idGuide, 350, $aClient[1] - 222, $aClient[0] - 358, 212)
	EndIf
	Return
EndFunc   ;==>_Layout

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _SyncHost
; Description ...: Aligns the separate WebView-only window with the main GUI's browser panel.
; Syntax ........: _SyncHost()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Geometry is checked in the GUI loop; native controls remain in the main window.
; Related .......: _Layout, _WebView2_SetBounds
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _SyncHost()
	Do
		If Not $g_EX_hHost Then ExitLoop 1
		Local $aClient = WinGetClientSize($g_EX_hGUI)
		If Not IsArray($aClient) Then ExitLoop 1
		Local $tPoint = DllStructCreate("long X;long Y")
		DllStructSetData($tPoint, "X", 350)
		DllStructSetData($tPoint, "Y", 88)
		Local $aCall = DllCall("user32.dll", "bool", "ClientToScreen", "hwnd", $g_EX_hGUI, "struct*", $tPoint)
		If @error Then ExitLoop 1
		If Not $aCall[0] Then ExitLoop 1
		Local $iWidth = $aClient[0] - 358, $iHeight = $aClient[1] - 310
		If $iWidth < 1 Then $iWidth = 1
		If $iHeight < 1 Then $iHeight = 1
		Local $sGeometry = DllStructGetData($tPoint, "X") & ":" & DllStructGetData($tPoint, "Y") & ":" & $iWidth & ":" & $iHeight
		If $sGeometry = $g_EX_sHostGeometry Then ExitLoop 1
		$g_EX_sHostGeometry = $sGeometry
		_Layout($aClient)
		WinMove($g_EX_hHost, "", DllStructGetData($tPoint, "X"), DllStructGetData($tPoint, "Y"), $iWidth, $iHeight)
		If $g_EX_iWebView >= 0 Then _WebView2_SetBounds($g_EX_iWebView, 0, 0, $iWidth, $iHeight)
	Until True
	Return
EndFunc   ;==>_SyncHost

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Log
; Description ...: Appends a time-stamped message and scrolls to the newest line.
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
; Description ...: Starts a separate log group for one AutoIt button click.
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

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _OnNavigation
; Description ...: Logs native PDF navigation completion.
; Syntax ........: _OnNavigation($iWebView, $bSuccess, $iWebErrorStatus, $iNavigationId)
; Parameters ....: $iWebView, $bSuccess, $iWebErrorStatus, $iNavigationId - Native navigation event fields.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Successful navigation does not certify individual toolbar controls.
; Related .......:
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2settings7
; Example .......: Yes
; ===============================================================================================================================
Func _OnNavigation($iWebView, $bSuccess, $iWebErrorStatus, $iNavigationId)
	#forceref $iWebView, $iNavigationId
	$g_EX_bNavigated = $bSuccess
	_Log("PDF navigation completed: success=" & $bSuccess & "; web error=" & $iWebErrorStatus & ".")
EndFunc   ;==>_OnNavigation
