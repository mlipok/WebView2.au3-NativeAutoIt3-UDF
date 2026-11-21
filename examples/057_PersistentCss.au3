#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
; #WIP - Work in Progress: verify the visible layout and manual button sequence.
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiEdit.au3>
#include <Math.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)
Opt("GUIResizeMode", $GUI_DOCKALL)

Global Const $g_sHost = "udf-virtual-host.example", $g_sFolder = @ScriptDir & "\assets\native\057-persistent-css"
Global Const $g_sCss = '/* net08-demo */ .sample { background-color: rgb(196, 240, 217); border-color: #19765a; }' & @CRLF & _
		'.sample strong::after { content: " · Persistent CSS active"; }'
Global Const $g_sStyleCount = "Array.from(document.querySelectorAll('style')).filter(s=>s.textContent.includes('net08-demo')).length"
Global $g_idLog = 0, $g_idGuide = 0, $g_hMain = 0, $g_hHost = 0, $g_iView = -1, $g_sGeometry = ""
Global $g_bSmoke = False, $g_iVisit = 0, $g_iNavigationState = 0

If $CmdLine[0] Then $g_bSmoke = $CmdLine[1] = "--smoke"
Exit _Example()

; #INTERNAL_USE_ONLY# ==============================================================================================================
; Name...........: _Example
; Description....: Runs the persistent CSS demonstration.
; Syntax.........: _Example()
; Parameters.....: None.
; Return values..: 0 on close or smoke success; 1 on failure.
; Author.........: mLipok
; Modified.......:
; Remarks........:
; Related........:
; Link...........:
; Example........: Yes
; ===============================================================================================================================
Func _Example()
	$g_hMain = GUICreate("WebView2 - Persistent CSS", 1080, 680, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	Local $aCaptions[5] = ["Register CSS", "Navigate to A", "Navigate to B", "Remove CSS", "Reload"]
	Local $aButtons[UBound($aCaptions)]
	For $i = 0 To UBound($aButtons) - 1
		$aButtons[$i] = GUICtrlCreateButton($aCaptions[$i], 8 + $i * 130, 8, 120, 28)
	Next
	$g_idLog = GUICtrlCreateEdit("", 8, 48, 280, 560, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idLog, 0xE2F0E4)
	$g_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
			"1. Start on document A. Its card is blue. Click Register CSS. The log shows an ID and the card stays blue." & @CRLF & _
			"2. Click Reload. Document A turns green. Navigate to B and check that its new card is also green." & @CRLF & _
			"3. Click Remove CSS. The current card stays green. Click Reload to restore the blue card on the same page." & @CRLF & @CRLF & _
			"HOW IT WORKS" & @CRLF & "The registration adds a style element to future HTML documents. Removing its ID stops future injection. This example works offline.", _
			300, 500, 760, 150, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idGuide, 0xFFF1BF)
	If Not $g_bSmoke Then
		GUISetState(@SW_MAXIMIZE, $g_hMain)
		GUISetState(@SW_SHOWNOACTIVATE, $g_hMain)
	EndIf
	$g_hHost = GUICreate("", 1, 1, 0, 0, $WS_POPUP, $WS_EX_NOREDIRECTIONBITMAP, $g_hMain)
	_SyncLayout()
	If Not $g_bSmoke Then GUISetState(@SW_SHOWNOACTIVATE, $g_hHost)

	Local $sProfile = @TempDir & "\WebView2-057-" & @AutoItPID & "-" & Random(100000, 999999, 1)
	Local $iResult = 1, $sId = ""
	Do
		If Not _WebView2_Init(Default, $sProfile) Then ExitLoop
		If Not _CreateView() Or Not _Navigate("A") Then ExitLoop
		If $g_bSmoke Then
			If _Smoke() Then $iResult = 0
			ExitLoop
		EndIf
		While True
			Local $iMessage = GUIGetMsg()
			If $iMessage = $GUI_EVENT_CLOSE Then
				$iResult = 0
				ExitLoop
			EndIf
			For $i = 0 To UBound($aButtons) - 1
				If $iMessage <> $aButtons[$i] Then ContinueLoop
				_Log($aCaptions[$i] & " was clicked.", True)
				Switch $i
					Case 0
						If $sId = "" Then
							$sId = _WebView2_AddPersistentCss($g_iView, $g_sCss)
							If @error Then
								_Log(_WebView2_Error_GetDescription())
							Else
								_Log("Registered CSS ID " & $sId & ".")
							EndIf
						Else
							_Log("CSS is already registered as " & $sId & ".")
						EndIf
						_ReadStyle()
					Case 1, 2
						_Navigate(Chr(64 + $i))
					Case 3
						If $sId = "" Then
							_Log("There is no CSS registration to remove.")
						ElseIf _WebView2_RemovePersistentCss($g_iView, $sId) Then
							_Log("Removed CSS registration " & $sId & ".")
							$sId = ""
						Else
							_Log(_WebView2_Error_GetDescription())
						EndIf
						_ReadStyle()
					Case 4
						_Navigate()
				EndSwitch
				ExitLoop
			Next
			_SyncLayout()
			Sleep(10)
		WEnd
	Until True
	If $iResult Then _Log("Example stopped with an error. " & _WebView2_Error_GetDescription())
	_WebView2_Cleanup()
	GUIDelete($g_hHost)
	GUIDelete($g_hMain)
	If FileExists($sProfile) Then DirRemove($sProfile, 1)
	Return $iResult
EndFunc   ;==>_Example

; #INTERNAL_USE_ONLY# ==============================================================================================================
; Name...........: _CreateView
; Description....: Creates and configures a WebView for the local page.
; Syntax.........: _CreateView()
; Parameters.....: None.
; Return values..: True on success; False on failure.
; Author.........: mLipok
; Modified.......:
; Remarks........:
; Related........:
; Link...........:
; Example........: Yes
; ===============================================================================================================================
Func _CreateView()
	Local $aSize = WinGetClientSize($g_hHost)
	$g_iView = _WebView2_Create($g_hHost, 0, 0, $aSize[0], $aSize[1])
	If @error Then
		$g_iView = -1
		Return False
	EndIf
	If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _OnNavigation) Then Return False
	Return _WebView2_SetVirtualHostNameToFolderMapping($g_iView, $g_sHost, $g_sFolder)
EndFunc   ;==>_CreateView

; #INTERNAL_USE_ONLY# ==============================================================================================================
; Name...........: _Navigate
; Description....: Loads or reloads a document and reports its computed style.
; Syntax.........: _Navigate([$sPage = ""])
; Parameters.....: $sPage - Label A or B; omit to reload the current page.
; Return values..: True on success; False on failure.
; Author.........: mLipok
; Modified.......:
; Remarks........:
; Related........:
; Link...........:
; Example........: Yes
; ===============================================================================================================================
Func _Navigate($sPage = "")
	$g_iNavigationState = 0
	Local $bStarted
	If $sPage = "" Then
		$bStarted = _WebView2_Reload($g_iView)
	Else
		$g_iVisit += 1
		$bStarted = _WebView2_Navigate($g_iView, "https://" & $g_sHost & "/index.html?page=" & $sPage & "&visit=" & $g_iVisit)
	EndIf
	If Not $bStarted Then
		_Log(_WebView2_Error_GetDescription())
		Return False
	EndIf
	Local $hTimer = TimerInit()
	While Not $g_iNavigationState And TimerDiff($hTimer) < 5000
		GUIGetMsg()
		Sleep(10)
	WEnd
	If $g_iNavigationState <> 1 Then
		_Log("Navigation did not complete successfully.")
		Return False
	EndIf
	If $sPage = "" Then
		_Log("Reloaded the current document.")
	Else
		_Log("Loaded document " & $sPage & ".")
	EndIf
	Return _ReadStyle() >= 0
EndFunc   ;==>_Navigate

; #INTERNAL_USE_ONLY# ==============================================================================================================
; Name...........: _OnNavigation
; Description....: Records completion of the current navigation.
; Syntax.........: _OnNavigation($iView, $bSuccess, $iStatus, $iNavigation)
; Parameters.....: Native navigation callback arguments.
; Return values..: None.
; Author.........: mLipok
; Modified.......:
; Remarks........:
; Related........:
; Link...........:
; Example........: Yes
; ===============================================================================================================================
Func _OnNavigation($iView, $bSuccess, $iStatus, $iNavigation)
	#forceref $iStatus, $iNavigation
	If $iView <> $g_iView Then Return
	$g_iNavigationState = -1
	If $bSuccess Then $g_iNavigationState = 1
EndFunc   ;==>_OnNavigation

; #INTERNAL_USE_ONLY# ==============================================================================================================
; Name...........: _ReadStyle
; Description....: Reports the style block count and computed color.
; Syntax.........: _ReadStyle()
; Parameters.....: None.
; Return values..: Style block count, or -1 on failure.
; Author.........: mLipok
; Modified.......:
; Remarks........:
; Related........:
; Link...........:
; Example........: Yes
; ===============================================================================================================================
Func _ReadStyle()
	Local $sCount = _WebView2_ExecuteScript($g_iView, $g_sStyleCount, 3000)
	If @error Or Not StringIsDigit($sCount) Then Return -1
	Local $iCount = Number($sCount)
	Local $sResult = _WebView2_ExecuteScript($g_iView, "getComputedStyle(document.querySelector('.sample')).backgroundColor", 3000)
	If @error Then Return -1
	Local $sColor = _WebView2_JSONStringDecode($sResult)
	If @error Then Return -1
	_Log("Persistent style blocks in the current document: " & $iCount & ". Computed background: " & $sColor & ".")
	Return $iCount
EndFunc   ;==>_ReadStyle

; #INTERNAL_USE_ONLY# ==============================================================================================================
; Name...........: _Smoke
; Description....: Checks style registration across multiple documents.
; Syntax.........: _Smoke()
; Parameters.....: None.
; Return values..: True on success; False on failure.
; Author.........: mLipok
; Modified.......:
; Remarks........:
; Related........:
; Link...........:
; Example........: Yes
; ===============================================================================================================================
Func _Smoke()
	If _ReadStyle() <> 0 Then Return False
	Local $sId = _WebView2_AddPersistentCss($g_iView, " " & @CRLF)
	If @error <> $WEBVIEW2_ERR_INVALID_PARAMETER Then Return False
	$sId = _WebView2_AddPersistentCss(-1, $g_sCss)
	If @error <> $WEBVIEW2_ERR_INVALID_INSTANCE Then Return False
	_WebView2_RemovePersistentCss($g_iView, "")
	If @error <> $WEBVIEW2_ERR_INVALID_PARAMETER Then Return False

	If Not _WebView2_SetSleepCallback(_AbortRegistrationWait) Then Return False
	$sId = _WebView2_AddPersistentCss($g_iView, $g_sCss)
	Local $iAbortError = @error, $iAbortExtended = @extended
	_WebView2_SetSleepCallback()
	If $sId <> "" Or $iAbortError <> $WEBVIEW2_ERR_USER_ABORT Or $iAbortExtended <> 57 Then Return False
	If Not _Navigate("B") Or _ReadStyle() <> 0 Then Return False

	$sId = _WebView2_AddPersistentCss($g_iView, $g_sCss)
	If @error Or $sId = "" Or _ReadStyle() <> 0 Then Return False
	Local $sCurrentUrl = _WebView2_ExecuteScript($g_iView, "location.href", 3000)
	If @error Or $sCurrentUrl = "" Then Return False
	If Not _Navigate() Or _ReadStyle() <> 1 Then Return False
	If _WebView2_ExecuteScript($g_iView, "location.href", 3000) <> $sCurrentUrl Then Return False
	If Not _Navigate("B") Or _ReadStyle() <> 1 Then Return False
	Local $sCheck = "getComputedStyle(document.querySelector('.sample')).backgroundColor === 'rgb(196, 240, 217)'"
	If _WebView2_ExecuteScript($g_iView, $sCheck, 3000) <> "true" Then Return False
	If Not _Navigate("A") Or _ReadStyle() <> 1 Then Return False

	Local $sSecond = _WebView2_AddPersistentCss($g_iView, $g_sCss)
	If @error Or $sSecond = "" Or $sSecond = $sId Then Return False
	If Not _Navigate("B") Or _ReadStyle() <> 2 Then Return False
	If Not _WebView2_RemovePersistentCss($g_iView, $sId) Or _ReadStyle() <> 2 Then Return False
	If Not _Navigate("A") Or _ReadStyle() <> 1 Then Return False
	$sCurrentUrl = _WebView2_ExecuteScript($g_iView, "location.href", 3000)
	If @error Or $sCurrentUrl = "" Then Return False
	If Not _WebView2_RemovePersistentCss($g_iView, $sSecond) Or _ReadStyle() <> 1 Then Return False
	If Not _Navigate() Or _ReadStyle() <> 0 Then Return False
	If _WebView2_ExecuteScript($g_iView, "location.href", 3000) <> $sCurrentUrl Then Return False

	Local $bCurrent = _WebView2_InjectCss($g_iView, $g_sCss)
	If @error Or Not $bCurrent Or _ReadStyle() <> 1 Then Return False
	If Not _Navigate("A") Or _ReadStyle() <> 0 Then Return False
	$sId = _WebView2_AddPersistentCss($g_iView, $g_sCss)
	If @error Or $sId = "" Then Return False
	If Not _WebView2_Destroy($g_iView) Then Return False
	$g_iView = -1
	If Not _CreateView() Or Not _Navigate("B") Or _ReadStyle() <> 0 Then Return False
	_Log("SMOKE PASS: navigation, same-URL reload, duplicate IDs, removal, cancelled registration, immediate CSS, and view recreation.")
	Return True
EndFunc   ;==>_Smoke

; #INTERNAL_USE_ONLY# ==============================================================================================================
; Name...........: _SyncLayout
; Description....: Fits the owned WebView host and native panels to the client area.
; Syntax.........: _SyncLayout()
; Parameters.....: None.
; Return values..: None.
; Author.........: mLipok
; Modified.......:
; Remarks........:
; Related........:
; Link...........:
; Example........: Yes
; ===============================================================================================================================
Func _SyncLayout()
	Local $aClient = WinGetClientSize($g_hMain)
	If Not IsArray($aClient) Or $aClient[0] < 240 Or $aClient[1] < 180 Then Return
	Local $iLeft = _Min(300, Int($aClient[0] * 0.40)), $iGuide = _Min(155, Int($aClient[1] * 0.32))
	Local $iWidth = $aClient[0] - $iLeft - 8, $iHeight = $aClient[1] - $iGuide - 64
	Local $tPoint = DllStructCreate("long X;long Y")
	DllStructSetData($tPoint, "X", $iLeft)
	DllStructSetData($tPoint, "Y", 48)
	Local $aCall = DllCall("user32.dll", "bool", "ClientToScreen", "hwnd", $g_hMain, "struct*", $tPoint)
	If @error Or Not $aCall[0] Then Return
	Local $iX = DllStructGetData($tPoint, "X"), $iY = DllStructGetData($tPoint, "Y")
	Local $sGeometry = $iX & ":" & $iY & ":" & $iWidth & ":" & $iHeight
	If $sGeometry = $g_sGeometry Then Return
	$g_sGeometry = $sGeometry
	GUICtrlSetPos($g_idLog, 8, 48, $iLeft - 16, $aClient[1] - 56)
	GUICtrlSetPos($g_idGuide, $iLeft, $aClient[1] - $iGuide - 8, $iWidth, $iGuide)
	WinMove($g_hHost, "", $iX, $iY, $iWidth, $iHeight)
	If $g_iView >= 0 Then _WebView2_SetBounds($g_iView, 0, 0, $iWidth, $iHeight)
EndFunc   ;==>_SyncLayout

; #INTERNAL_USE_ONLY# ==============================================================================================================
; Name...........: _Log
; Description....: Appends a time-stamped event and scrolls the log.
; Syntax.........: _Log($sMessage[, $bClick = False])
; Parameters.....: $sMessage - Message to show.
;                  $bClick - Whether this entry records an AutoIt button click.
; Return values..: None.
; Author.........: mLipok
; Modified.......:
; Remarks........:
; Related........:
; Link...........:
; Example........: Yes
; ===============================================================================================================================
Func _Log($sMessage, $bClick = False)
	ConsoleWrite("[057] " & $sMessage & @CRLF)
	Local $sTime = @HOUR & ":" & @MIN & ":" & @SEC
	Local $sLine = "[" & $sTime & "] " & $sMessage
	If $bClick Then $sLine = @CRLF & "[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & $sTime & "] [AutoIt]: " & $sMessage
	_GUICtrlEdit_AppendText($g_idLog, $sLine & @CRLF)
	GUICtrlSendMsg($g_idLog, $EM_SCROLLCARET, 0, 0)
EndFunc   ;==>_Log

; #INTERNAL_USE_ONLY# ==============================================================================================================
; Name ..........: _AbortRegistrationWait
; Description ...: Cancels the wait for the staged smoke test.
; Syntax ........: _AbortRegistrationWait($iPause)
; Parameters ....: $iPause - Requested delay in milliseconds.
; Return values .: False, with a test error of 57.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetSleepCallback
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _AbortRegistrationWait($iPause)
	#forceref $iPause
	Return SetError(57, 0, False)
EndFunc   ;==>_AbortRegistrationWait
