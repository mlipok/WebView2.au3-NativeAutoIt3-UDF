#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiEdit.au3>
#include <Math.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)
Opt("GUIResizeMode", $GUI_DOCKALL)

Global Const $g_sHost = "udf-virtual-host.example"
Global Const $g_sPage = "https://" & $g_sHost & "/index.html"
Global Const $g_sCaption = "Copy link address"
Global $g_hMain = 0, $g_hHost = 0, $g_idLog = 0, $g_idGuide = 0, $g_iView = -1
Global $g_bSmoke = False, $g_bPageReady = False
Global $g_sGeometry = "", $g_sPendingCopy = ""

If $CmdLine[0] Then $g_bSmoke = $CmdLine[1] = "--smoke"
Exit _Example()

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Example
; Description ...: Runs the local native context-menu demonstration.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: 0 on normal close or successful smoke. 1 on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	$g_hMain = GUICreate("WebView2 - Native context menu", 1120, 700, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	Local $idReload = GUICtrlCreateButton("Reload test page", 8, 8, 158, 28)
	$g_idLog = GUICtrlCreateEdit("", 8, 48, 330, 600, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idLog, 0xE2F0E4)
	$g_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
			"1. Right-click the first sample link. Choose the custom Copy link address item at the bottom of the WebView2 menu." & @CRLF & _
			"2. Paste into a text editor. Expect https://udf-virtual-host.example/index.html#first. Repeat for the second link and expect #second." & @CRLF & _
			"3. Right-click ordinary text or blank space. The native menu should appear without our custom item. Selecting text first logs the selection." & @CRLF & _
			"4. Dismiss the menu with Escape. The clipboard should keep its previous value. Use Reload test page to repeat." & @CRLF & @CRLF & _
			"WebView2 supplies the menu location and target. AutoIt appends one native command on the sample links and copies the captured address only on selection. The page and both links work offline.", _
			350, 535, 760, 155, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idGuide, 0xFFF1BF)
	If Not $g_bSmoke Then
		GUISetState(@SW_MAXIMIZE, $g_hMain)
		GUISetState(@SW_SHOWNOACTIVATE, $g_hMain)
	EndIf
	$g_hHost = GUICreate("", 1, 1, 0, 0, $WS_POPUP, $WS_EX_NOREDIRECTIONBITMAP, $g_hMain)
	_SyncLayout()
	If Not $g_bSmoke Then GUISetState(@SW_SHOWNOACTIVATE, $g_hHost)
	Local $sProfile = @TempDir & "\WebView2-052-" & @AutoItPID & "-" & Random(100000, 999999, 1)
	Local $iResult = 1
	Do
		If Not _WebView2_Init(Default, $sProfile) Then ExitLoop
		Local $aSize = WinGetClientSize($g_hHost)
		$g_iView = _WebView2_Create($g_hHost, 0, 0, $aSize[0], $aSize[1])
		If @error Then ExitLoop
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_CONTEXT_MENU_REQUESTED, _OnContextMenu) Then ExitLoop
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _OnNavigation) Then ExitLoop
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_iView, $g_sHost, @ScriptDir & "\assets\native\052-context-menu") Then ExitLoop
		If Not _WebView2_Navigate($g_iView, $g_sPage) Then ExitLoop
		If $g_bSmoke Then
			If _Smoke() Then $iResult = 0
			ExitLoop
		EndIf
		While True
			Switch GUIGetMsg()
				Case $GUI_EVENT_CLOSE
					$iResult = 0
					ExitLoop
				Case $idReload
					_Click("Reload test page")
					If Not _WebView2_Navigate($g_iView, $g_sPage) Then _Log("Reload failed: " & _WebView2_Error_GetDescription())
			EndSwitch
			If $g_sPendingCopy <> "" Then
				Local $sLink = $g_sPendingCopy
				$g_sPendingCopy = ""
				If ClipPut($sLink) Then
					_Log("Copied: " & $sLink)
				Else
					_Log("Could not write to the clipboard.")
				EndIf
			EndIf
			_SyncLayout()
			Sleep(10)
		WEnd
	Until True
	If $iResult Then _Log("Example stopped with an error. " & _WebView2_Error_GetDescription())
	_WebView2_Cleanup()
	GUIDelete($g_hHost)
	GUIDelete($g_hMain)
	Return $iResult
EndFunc   ;==>_Example

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _OnNavigation
; Description ...: Reports completion of the demo page navigation.
; Syntax ........: _OnNavigation($iView, $bSuccess, $iStatus, $iNavigation)
; Parameters ....: $iView - WebView instance.
;                  $bSuccess - Native success flag.
;                  $iStatus - Native error status.
;                  $iNavigation - Navigation ID.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnNavigation($iView, $bSuccess, $iStatus, $iNavigation)
	#forceref $iView, $iNavigation
	$g_bPageReady = $bSuccess
	If $bSuccess Then
		_Log("Ready. Right-click a sample link.")
	Else
		_Log("Navigation failed. Status: " & $iStatus)
	EndIf
EndFunc   ;==>_OnNavigation

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _OnContextMenu
; Description ...: Adds a native command only for the two demo links.
; Syntax ........: _OnContextMenu($iView, $aContext)
; Parameters ....: $iView - WebView instance.
;                  $aContext - Copied native menu context.
; Return values .: A two-element command descriptor for a sample link; otherwise Default.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnContextMenu($iView, $aContext)
	#forceref $iView
	Local $sPage = $aContext[$WEBVIEW2_CONTEXT_MENU_PAGE_URI]
	Local $sFrame = $aContext[$WEBVIEW2_CONTEXT_MENU_FRAME_URI]
	If $sFrame <> "" And $sFrame <> $sPage Then Return Default
	If $sPage <> $g_sPage And $sPage <> $g_sPage & "#first" And $sPage <> $g_sPage & "#second" Then Return Default
	Local $sLink = $aContext[$WEBVIEW2_CONTEXT_MENU_LINK_URI]
	Local $sSelection = $aContext[$WEBVIEW2_CONTEXT_MENU_SELECTION_TEXT]
	_Log("Native menu request: kind=" & $aContext[$WEBVIEW2_CONTEXT_MENU_KIND] & _
			", position=" & $aContext[$WEBVIEW2_CONTEXT_MENU_X] & ", " & $aContext[$WEBVIEW2_CONTEXT_MENU_Y])
	If $sSelection <> "" Then _Log("Selected text: " & $sSelection)
	If $sLink <> $g_sPage & "#first" And $sLink <> $g_sPage & "#second" Then Return Default
	_Log("Link address: " & $sLink)
	Local $aCommand[2] = [$g_sCaption, _OnCopySelected]
	Return $aCommand
EndFunc   ;==>_OnContextMenu

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _OnCopySelected
; Description ...: Queues the browser-selected link for the main AutoIt loop.
; Syntax ........: _OnCopySelected($iView, $aContext)
; Parameters ....: $iView - WebView instance.
;                  $aContext - Original request context.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnCopySelected($iView, $aContext)
	#forceref $iView
	_Log("Native context menu command selected: " & $g_sCaption)
	$g_sPendingCopy = $aContext[$WEBVIEW2_CONTEXT_MENU_LINK_URI]
EndFunc   ;==>_OnCopySelected

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Smoke
; Description ...: Verifies the mapped page and callback registration without opening a visible window.
; Syntax ........: _Smoke()
; Parameters ....: None.
; Return values .: True when the page and callback are ready.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Smoke()
	Local $hTimer = TimerInit()
	While Not $g_bPageReady And TimerDiff($hTimer) < 5000
		GUIGetMsg()
		Sleep(10)
	WEnd
	If Not $g_bPageReady Then Return False
	Local $sLink = _WebView2_ExecuteScript($g_iView, "document.getElementById('first-link').href", 3000)
	If @error Or $sLink <> '"' & $g_sPage & '#first"' Then Return False
	If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_CONTEXT_MENU_REQUESTED, _OnContextMenu) Then Return False
	_Log("Smoke: mapped links and native callback registration verified.")
	Return True
EndFunc   ;==>_Smoke

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _SyncLayout
; Description ...: Fits the native panels and the owned WebView2 host to the window.
; Syntax ........: _SyncLayout()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _SyncLayout()
	Local $aClient = WinGetClientSize($g_hMain)
	If Not IsArray($aClient) Then Return
	If $aClient[0] < 80 Or $aClient[1] < 80 Then Return
	Local $iLeft = _Min(350, Int($aClient[0] * 0.42))
	Local $iGuide = _Min(165, Int($aClient[1] * 0.30))
	Local $iWidth = $aClient[0] - $iLeft - 8, $iHeight = $aClient[1] - $iGuide - 64
	If $iWidth < 1 Or $iHeight < 1 Then Return
	Local $tPoint = DllStructCreate("long X;long Y")
	DllStructSetData($tPoint, "X", $iLeft)
	DllStructSetData($tPoint, "Y", 48)
	Local $aCall = DllCall("user32.dll", "bool", "ClientToScreen", "hwnd", $g_hMain, "struct*", $tPoint)
	If @error Then Return
	If Not $aCall[0] Then Return
	Local $iX = DllStructGetData($tPoint, "X"), $iY = DllStructGetData($tPoint, "Y")
	Local $sGeometry = $iX & ":" & $iY & ":" & $iWidth & ":" & $iHeight
	If $sGeometry = $g_sGeometry Then Return
	$g_sGeometry = $sGeometry
	GUICtrlSetPos($g_idLog, 8, 48, $iLeft - 16, $aClient[1] - 56)
	GUICtrlSetPos($g_idGuide, $iLeft, $aClient[1] - $iGuide - 8, $iWidth, $iGuide)
	WinMove($g_hHost, "", $iX, $iY, $iWidth, $iHeight)
	If $g_iView >= 0 Then _WebView2_SetBounds($g_iView, 0, 0, $iWidth, $iHeight)
EndFunc   ;==>_SyncLayout

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Log
; Description ...: Appends an operation to the log and console.
; Syntax ........: _Log($sMessage)
; Parameters ....: $sMessage - Diagnostic message.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Log($sMessage)
	ConsoleWrite("[052] " & $sMessage & @CRLF)
	_GUICtrlEdit_AppendText($g_idLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sMessage & @CRLF)
	GUICtrlSendMsg($g_idLog, $EM_SCROLLCARET, 0, 0)
EndFunc   ;==>_Log

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Click
; Description ...: Logs a real AutoIt button click.
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
	_GUICtrlEdit_AppendText($g_idLog, @CRLF & "[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [AutoIt]: " & $sCaption & " was clicked." & @CRLF)
	GUICtrlSendMsg($g_idLog, $EM_SCROLLCARET, 0, 0)
EndFunc   ;==>_Click
