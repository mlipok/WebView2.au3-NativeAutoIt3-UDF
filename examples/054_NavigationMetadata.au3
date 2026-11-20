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
Global Const $g_sOther = $g_sPage & "?document=2"
Global Const $g_sBlocked = $g_sPage & "?blocked=1"
Global Const $g_sFrame = "https://" & $g_sHost & "/frame.html"
Global $g_hMain = 0, $g_hHost = 0, $g_idLog = 0, $g_idGuide = 0, $g_iView = -1
Global $g_bSmoke = False, $g_sGeometry = ""
Global $g_iStartID = 0, $g_iCompletedID = 0, $g_iCompletionCount = 0, $g_bSuccess = False
Global $g_iStartKind = Null, $g_bHeadersRead = False, $g_iHeaderRows = 0, $g_iFrameID = 0

If $CmdLine[0] Then $g_bSmoke = $CmdLine[1] = "--smoke"
Exit _Example()

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Example
; Description ...: Runs the local navigation metadata demonstration.
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
	$g_hMain = GUICreate("WebView2 - Navigation start metadata", 1120, 700, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	Local $idOpen = GUICtrlCreateButton("Open second document", 8, 8, 167, 28)
	Local $idReload = GUICtrlCreateButton("Reload", 182, 8, 85, 28)
	Local $idBack = GUICtrlCreateButton("Back", 274, 8, 85, 28)
	Local $idBlock = GUICtrlCreateButton("Block test navigation", 366, 8, 147, 28)
	$g_idLog = GUICtrlCreateEdit("", 8, 48, 330, 600, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idLog, 0xE2F0E4)
	$g_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
			"1. On startup, compare the top-level NavigationStarting and NavigationCompleted IDs. Look for a separate start entry for the iframe." & @CRLF & _
			"2. Click Open second document, Reload and Back. Compare NewDocument, Reload and BackOrForward where supported by the Runtime." & @CRLF & _
			"3. Click Block test navigation. The callback logs the metadata and cancels the request. The current page stays visible." & @CRLF & _
			"4. Inspect the request header rows. This example shows values for selected standard headers and redacts the rest." & @CRLF & @CRLF & _
			"The existing navigation callbacks read a snapshot of data supplied by WebView2. The sample and its iframe are served locally through virtual host mapping.", _
			350, 535, 760, 155, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idGuide, 0xFFF1BF)
	If Not $g_bSmoke Then
		GUISetState(@SW_MAXIMIZE, $g_hMain)
		GUISetState(@SW_SHOWNOACTIVATE, $g_hMain)
	EndIf
	$g_hHost = GUICreate("", 1, 1, 0, 0, $WS_POPUP, $WS_EX_NOREDIRECTIONBITMAP, $g_hMain)
	_SyncLayout()
	If Not $g_bSmoke Then GUISetState(@SW_SHOWNOACTIVATE, $g_hHost)
	Local $sProfile = @TempDir & "\WebView2-054-" & @AutoItPID & "-" & Random(100000, 999999, 1)
	Local $iResult = 1
	Do
		If Not _WebView2_Init(Default, $sProfile) Then ExitLoop
		Local $aSize = WinGetClientSize($g_hHost)
		$g_iView = _WebView2_Create($g_hHost, 0, 0, $aSize[0], $aSize[1])
		If @error Then ExitLoop
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_NAVIGATION_STARTING, _OnStart) Then ExitLoop
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _OnComplete) Then ExitLoop
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_NAVIGATION_STARTING, _OnFrameStart) Then ExitLoop
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_iView, $g_sHost, @ScriptDir & "\assets\native\054-navigation") Then ExitLoop
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
				Case $idOpen
					_Click("Open second document")
					If Not _WebView2_Navigate($g_iView, $g_sOther) Then _Log(_WebView2_Error_GetDescription())
				Case $idReload
					_Click("Reload")
					If Not _WebView2_Reload($g_iView) Then _Log(_WebView2_Error_GetDescription())
				Case $idBack
					_Click("Back")
					If Not _WebView2_CanGoBack($g_iView) Then
						_Log("There is no earlier history entry.")
					ElseIf Not _WebView2_GoBack($g_iView) Then
						_Log(_WebView2_Error_GetDescription())
					EndIf
				Case $idBlock
					_Click("Block test navigation")
					If Not _WebView2_Navigate($g_iView, $g_sBlocked) Then _Log(_WebView2_Error_GetDescription())
			EndSwitch
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
; Name ..........: _OnStart
; Description ...: Reads metadata and blocks the sample cancellation URL.
; Syntax ........: _OnStart($iView, $sURI, $bUserInitiated, $bRedirected)
; Parameters ....: $iView - WebView ID.
;                  $sURI - Navigation URI.
;                  $bUserInitiated - Native user flag.
;                  $bRedirected - Native redirect flag.
; Return values .: True only for the test URL.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnStart($iView, $sURI, $bUserInitiated, $bRedirected)
	Local $aData = _WebView2_GetNavigationStartingMetadata($iView)
	_Log("Top-level NavigationStarting: " & $sURI & " | user=" & $bUserInitiated & " | redirected=" & $bRedirected)
	If IsArray($aData) Then
		$g_iStartID = $aData[$WEBVIEW2_NAVIGATION_METADATA_ID]
		$g_iStartKind = $aData[$WEBVIEW2_NAVIGATION_METADATA_KIND]
		$g_bHeadersRead = IsArray($aData[$WEBVIEW2_NAVIGATION_METADATA_HEADERS])
		_LogMetadata($aData)
	EndIf
	Return $sURI = $g_sBlocked
EndFunc   ;==>_OnStart

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _OnFrameStart
; Description ...: Reads metadata for the sample iframe.
; Syntax ........: _OnFrameStart($iView, $iFrame, $sURI, $bUserInitiated, $bRedirected)
; Parameters ....: $iView - WebView ID.
;                  $iFrame - Frame ID.
;                  $sURI - Navigation URI.
;                  $bUserInitiated - Native user flag.
;                  $bRedirected - Native redirect flag.
; Return values .: False to allow navigation.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnFrameStart($iView, $iFrame, $sURI, $bUserInitiated, $bRedirected)
	If $sURI <> $g_sFrame Then Return False
	Local $aData = _WebView2_GetNavigationStartingMetadata($iView)
	_Log("Frame " & $iFrame & " NavigationStarting: " & $sURI & " | user=" & $bUserInitiated & " | redirected=" & $bRedirected)
	If IsArray($aData) Then
		$g_iFrameID = $aData[$WEBVIEW2_NAVIGATION_METADATA_ID]
		_LogMetadata($aData)
	EndIf
	Return False
EndFunc   ;==>_OnFrameStart

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _OnComplete
; Description ...: Logs the top-level completion identifier.
; Syntax ........: _OnComplete($iView, $bSuccess, $iStatus, $iNavigationID)
; Parameters ....: $iView - WebView ID.
;                  $bSuccess - Native success flag.
;                  $iStatus - Native status.
;                  $iNavigationID - Completion navigation ID.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnComplete($iView, $bSuccess, $iStatus, $iNavigationID)
	#forceref $iView
	$g_bSuccess = $bSuccess
	$g_iCompletedID = $iNavigationID
	$g_iCompletionCount += 1
	_Log("NavigationCompleted: ID=" & $iNavigationID & " | success=" & $bSuccess & " | web error=" & $iStatus)
EndFunc   ;==>_OnComplete

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _LogMetadata
; Description ...: Writes the copied metadata with selected header values.
; Syntax ........: _LogMetadata($aData)
; Parameters ....: $aData - A metadata array.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _LogMetadata($aData)
	Local $vKind = $aData[$WEBVIEW2_NAVIGATION_METADATA_KIND]
	Local $sKind = "Unavailable"
	If IsNumber($vKind) Then
		Switch $vKind
			Case $WEBVIEW2_NAVIGATION_KIND_NEW_DOCUMENT
				$sKind = "NewDocument"
			Case $WEBVIEW2_NAVIGATION_KIND_RELOAD
				$sKind = "Reload"
			Case $WEBVIEW2_NAVIGATION_KIND_BACK_OR_FORWARD
				$sKind = "BackOrForward"
			Case Else
				$sKind = "Native value " & $vKind
		EndSwitch
	EndIf
	_Log("  ID=" & $aData[$WEBVIEW2_NAVIGATION_METADATA_ID] & " | kind=" & $sKind)
	Local $aHeaders = $aData[$WEBVIEW2_NAVIGATION_METADATA_HEADERS]
	If Not IsArray($aHeaders) Then
		_Log("  Request headers: unavailable")
		Return
	EndIf
	Local $iCount = UBound($aHeaders)
	$g_iHeaderRows += $iCount
	_Log("  Request headers: " & $iCount)
	For $i = 0 To $iCount - 1
		Local $sValue = "(redacted)"
		Switch StringLower($aHeaders[$i][0])
			Case "accept", "accept-language", "sec-fetch-dest", "sec-fetch-mode", "sec-fetch-site", "user-agent"
				$sValue = $aHeaders[$i][1]
		EndSwitch
		_Log("    " & $aHeaders[$i][0] & ": " & $sValue)
	Next
EndFunc   ;==>_LogMetadata

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Smoke
; Description ...: Checks native start fields, legacy cancellation and callback lifetime.
; Syntax ........: _Smoke()
; Parameters ....: None.
; Return values .: True when the checks pass.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Smoke()
	If Not _WaitComplete(0, True, $WEBVIEW2_NAVIGATION_KIND_NEW_DOCUMENT) Then Return False
	If Not IsNumber($g_iFrameID) Or $g_iFrameID <= 0 Or Not $g_bHeadersRead Or $g_iHeaderRows = 0 Then Return False
	Local $iComplete = $g_iCompletionCount
	If Not _WebView2_Navigate($g_iView, $g_sOther) Or Not _WaitComplete($iComplete, True, $WEBVIEW2_NAVIGATION_KIND_NEW_DOCUMENT) Then Return False
	$iComplete = $g_iCompletionCount
	If Not _WebView2_Reload($g_iView) Or Not _WaitComplete($iComplete, True, $WEBVIEW2_NAVIGATION_KIND_RELOAD) Then Return False
	$iComplete = $g_iCompletionCount
	If Not _WebView2_GoBack($g_iView) Or Not _WaitComplete($iComplete, True, $WEBVIEW2_NAVIGATION_KIND_BACK_OR_FORWARD) Then Return False
	$iComplete = $g_iCompletionCount
	If Not _WebView2_Navigate($g_iView, $g_sBlocked) Or Not _WaitComplete($iComplete, False, $WEBVIEW2_NAVIGATION_KIND_NEW_DOCUMENT) Then Return False
	If _WebView2_GetSource($g_iView) <> $g_sPage Then Return False
	_WebView2_GetNavigationStartingMetadata($g_iView)
	If @error <> $WEBVIEW2_ERR_NO_MATCH Then Return False
	_WebView2_GetNavigationStartingMetadata(-1)
	If @error <> $WEBVIEW2_ERR_INVALID_INSTANCE Then Return False
	_Log("Smoke: start/complete IDs, headers, frame event, navigation kinds, cancellation and context lifetime verified.")
	Return True
EndFunc   ;==>_Smoke

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _WaitComplete
; Description ...: Waits for a matching top-level completion event.
; Syntax ........: _WaitComplete($iOldCount, $bExpected, $iKind)
; Parameters ....: $iOldCount - Previously observed completion count.
;                  $bExpected - Expected success flag.
;                  $iKind - Expected native kind if available.
; Return values .: True for the expected new result.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WaitComplete($iOldCount, $bExpected, $iKind)
	Local $hTimer = TimerInit()
	While $g_iCompletionCount = $iOldCount And TimerDiff($hTimer) < 4000
		GUIGetMsg()
		Sleep(10)
	WEnd
	If $g_iCompletionCount = $iOldCount Or $g_bSuccess <> $bExpected Then Return False
	If Not IsNumber($g_iStartID) Or $g_iStartID <= 0 Or $g_iStartID <> $g_iCompletedID Then Return False
	Return Not IsNumber($g_iStartKind) Or $g_iStartKind = $iKind
EndFunc   ;==>_WaitComplete

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
	ConsoleWrite("[054] " & $sMessage & @CRLF)
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
