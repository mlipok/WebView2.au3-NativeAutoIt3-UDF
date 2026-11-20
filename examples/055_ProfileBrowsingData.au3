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

Global Const $g_sHosts[2] = ["udf-virtual-host.example", "udf-virtual-host-alt.example"]
Global $g_aViews[2] = [-1, -1], $g_aReady[2] = [False, False]
Global $g_hMain = 0, $g_hHost = 0, $g_idLog = 0, $g_idGuide = 0, $g_iView = -1
Global $g_bSmoke = False, $g_sGeometry = "", $g_bPending = False, $g_bClearDone = False
Global $g_iClearResult = 0

If $CmdLine[0] Then $g_bSmoke = $CmdLine[1] = "--smoke"
Exit _Example()

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Example
; Description ...: Runs the profile-wide data clearing demonstration.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: 0 on close or successful smoke. 1 on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	$g_hMain = GUICreate("WebView2 - Clear profile browsing data", 1120, 700, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	Local $idSeed = GUICtrlCreateButton("Seed demo data", 8, 8, 125, 28)
	Local $idInspect = GUICtrlCreateButton("Read both origins", 140, 8, 133, 28)
	Local $idCookies = GUICtrlCreateButton("Clear cookies (all time)", 280, 8, 151, 28)
	Local $idRecent = GUICtrlCreateButton("Clear cookies (recent)", 438, 8, 150, 28)
	Local $idStorage = GUICtrlCreateButton("Clear local storage", 595, 8, 145, 28)
	$g_idLog = GUICtrlCreateEdit("", 8, 48, 330, 600, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idLog, 0xE2F0E4)
	$g_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
			"1. Click Seed demo data. Both origins should report a cookie and a local-storage value." & @CRLF & _
			"2. Click Clear cookies (recent). The Runtime clears cookies in the recent UTC interval. The log should show success, cookies absent, and local storage still present on both origins." & @CRLF & _
			"3. Seed again, then use Clear cookies (all time) to run without a time range. Read both origins to check the state at any point." & @CRLF & _
			"4. Click Clear local storage to remove the storage marker on both origins." & @CRLF & @CRLF & _
			"Two views share a fresh, isolated profile; the second view is hidden. Profile2 clears the selected kinds across the profile. WebView2 reports completion asynchronously, then the example checks both origins.", _
			350, 535, 760, 155, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idGuide, 0xFFF1BF)
	If Not $g_bSmoke Then
		GUISetState(@SW_MAXIMIZE, $g_hMain)
		GUISetState(@SW_SHOWNOACTIVATE, $g_hMain)
	EndIf
	$g_hHost = GUICreate("", 1, 1, 0, 0, $WS_POPUP, $WS_EX_NOREDIRECTIONBITMAP, $g_hMain)
	Local $hSecond = GUICreate("055 hidden second origin", 640, 480, -1, -1, $WS_POPUP)
	_SyncLayout()
	If Not $g_bSmoke Then GUISetState(@SW_SHOWNOACTIVATE, $g_hHost)
	Local $sProfile = @TempDir & "\WebView2-055-" & @AutoItPID & "-" & Random(100000, 999999, 1)
	Local $iResult = 1
	Do
		If Not _WebView2_Init(Default, $sProfile) Then ExitLoop
		Local $aSize = WinGetClientSize($g_hHost)
		$g_iView = _WebView2_Create($g_hHost, 0, 0, $aSize[0], $aSize[1])
		If @error Then ExitLoop
		$g_aViews[0] = $g_iView
		$g_aViews[1] = _WebView2_Create($hSecond, 0, 0, 640, 480)
		If @error Then ExitLoop
		For $i = 0 To UBound($g_aViews) - 1
			If Not _WebView2_SetCallback($g_aViews[$i], $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _OnNavigation) Then ExitLoop 2
			If Not _WebView2_SetVirtualHostNameToFolderMapping($g_aViews[$i], $g_sHosts[$i], @ScriptDir & "\assets\native\055-profile-data") Then ExitLoop 2
			If Not _WebView2_Navigate($g_aViews[$i], "https://" & $g_sHosts[$i] & "/index.html") Then ExitLoop 2
		Next
		If Not _WaitForReady() Then ExitLoop
		_Log("Both origins are ready in the isolated profile.")
		If $g_bSmoke Then
			If _Smoke() Then $iResult = 0
			ExitLoop
		EndIf
		While True
			Local $idClicked = GUIGetMsg()
			Switch $idClicked
				Case $GUI_EVENT_CLOSE
					$iResult = 0
					ExitLoop
				Case $idSeed To $idStorage
					Local $aCaptions[5] = ["Seed demo data", "Read both origins", "Clear cookies (all time)", "Clear cookies (recent)", "Clear local storage"]
					_Click($aCaptions[$idClicked - $idSeed])
					If $g_bPending Then
						_Log("Wait for the clear operation to complete.")
					Else
						Switch $idClicked
							Case $idSeed
								_Seed()
								_ReadBoth()
							Case $idInspect
								_ReadBoth()
							Case $idCookies
								_StartClear($WEBVIEW2_BROWSING_DATA_COOKIES)
							Case $idRecent
								Local $iNow = Number(_WebView2_ExecuteScript($g_iView, "Math.floor(Date.now()/1000)", 3000))
								If $iNow > 0 Then _StartClear($WEBVIEW2_BROWSING_DATA_COOKIES, $iNow - 3600, $iNow + 1)
							Case $idStorage
								_StartClear($WEBVIEW2_BROWSING_DATA_LOCAL_STORAGE)
						EndSwitch
					EndIf
			EndSwitch
			If $g_bClearDone Then
				$g_bClearDone = False
				_ReadBoth()
			EndIf
			_SyncLayout()
			Sleep(10)
		WEnd
	Until True
	If $iResult Then _Log("Example stopped with an error. " & _WebView2_Error_GetDescription())
	_WebView2_Cleanup()
	GUIDelete($hSecond)
	GUIDelete($g_hHost)
	GUIDelete($g_hMain)
	Return $iResult
EndFunc   ;==>_Example

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _OnNavigation
; Description ...: Records a completed initial page load.
; Syntax ........: _OnNavigation($iView, $bSuccess, $iStatus, $iNavigation)
; Parameters ....: $iView - View ID.
;                  $bSuccess - Success flag.
;                  $iStatus - Web error value.
;                  $iNavigation - Native navigation ID.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnNavigation($iView, $bSuccess, $iStatus, $iNavigation)
	#forceref $iNavigation
	For $i = 0 To UBound($g_aViews) - 1
		If $iView = $g_aViews[$i] Then $g_aReady[$i] = $bSuccess
	Next
	If Not $bSuccess Then _Log("Navigation failed: " & $iStatus)
EndFunc   ;==>_OnNavigation

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _WaitForReady
; Description ...: Pumps messages until the two origin pages are ready.
; Syntax ........: _WaitForReady()
; Parameters ....: None.
; Return values .: True if both load within six seconds.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WaitForReady()
	Local $hTimer = TimerInit()
	While TimerDiff($hTimer) < 6000
		GUIGetMsg()
		If $g_aReady[0] And $g_aReady[1] Then Return True
		Sleep(10)
	WEnd
	Return False
EndFunc   ;==>_WaitForReady

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Seed
; Description ...: Writes one cookie and local-storage marker per origin.
; Syntax ........: _Seed()
; Parameters ....: None.
; Return values .: True after both scripts succeed.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Seed()
	For $i = 0 To UBound($g_aViews) - 1
		_WebView2_ExecuteScript($g_aViews[$i], 'localStorage.setItem("seed055","1"); document.cookie="seed055=1; path=/; Secure; SameSite=Lax";', 3000)
		If @error Then
			_Log("Could not seed " & $g_sHosts[$i] & ".")
			Return False
		EndIf
	Next
	Return True
EndFunc   ;==>_Seed

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _ReadBoth
; Description ...: Reads and logs the two demo markers from both origins.
; Syntax ........: _ReadBoth()
; Parameters ....: None.
; Return values .: Both origins packed into two two-bit fields, or -1 on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _ReadBoth()
	Local $iCombined = 0
	For $i = 0 To UBound($g_aViews) - 1
		Local $sValue = _WebView2_ExecuteScript($g_aViews[$i], "readDemoState()", 3000)
		If @error Or Not StringRegExp($sValue, "^[0-3]$") Then
			_Log("Could not read " & $g_sHosts[$i] & ".")
			Return -1
		EndIf
		Local $iState = Number($sValue)
		_Log($g_sHosts[$i] & " | local storage=" & (BitAND($iState, 1) <> 0) & " | cookie=" & (BitAND($iState, 2) <> 0))
		$iCombined = BitOR($iCombined, BitShift($iState, -2 * $i))
	Next
	Return $iCombined
EndFunc   ;==>_ReadBoth

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _StartClear
; Description ...: Starts one clear and logs whether the Runtime accepted it.
; Syntax ........: _StartClear($iKinds, $vStart = Default, $vEnd = Default)
; Parameters ....: $iKinds - Data-kind mask.
;                  $vStart = Default - Optional inclusive start seconds.
;                  $vEnd = Default - Optional exclusive end seconds.
; Return values .: True when started.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _StartClear($iKinds, $vStart = Default, $vEnd = Default)
	$g_bClearDone = False
	$g_bPending = True
	$g_iClearResult = 0
	If Not _WebView2_ClearProfileBrowsingData($g_iView, $iKinds, _OnClearComplete, $vStart, $vEnd) Then
		Local $iError = @error, $iNative = @extended
		$g_bPending = False
		_Log("Clear could not start. Error=" & $iError & " | HRESULT=0x" & Hex($iNative, 8))
		Return False
	EndIf
	Local $sRange = "all time"
	If $vStart <> Default Then $sRange = "[" & $vStart & ", " & $vEnd & ") UTC Unix seconds"
	_Log("Clear accepted. Mask=0x" & Hex($iKinds, 4) & " | " & $sRange)
	Return True
EndFunc   ;==>_StartClear

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _OnClearComplete
; Description ...: Records the native completion result.
; Syntax ........: _OnClearComplete($iView, $iHRESULT)
; Parameters ....: $iView - Initiating view ID.
;                  $iHRESULT - Result from WebView2.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnClearComplete($iView, $iHRESULT)
	$g_iClearResult = $iHRESULT
	$g_bPending = False
	$g_bClearDone = True
	_Log("Clear completed for view " & $iView & ". HRESULT=0x" & Hex($iHRESULT, 8) & " | " & ($iHRESULT = 0 ? "success" : "failed"))
EndFunc   ;==>_OnClearComplete

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _WaitClear
; Description ...: Waits for one completed native clear.
; Syntax ........: _WaitClear()
; Parameters ....: None.
; Return values .: True if completed successfully.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WaitClear()
	Local $hTimer = TimerInit()
	While TimerDiff($hTimer) < 6000
		GUIGetMsg()
		If $g_bClearDone Then Return $g_iClearResult = 0
		Sleep(10)
	WEnd
	Return False
EndFunc   ;==>_WaitClear

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Smoke
; Description ...: Verifies range, selection and scope across two origins.
; Syntax ........: _Smoke()
; Parameters ....: None.
; Return values .: True if all checks pass.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Smoke()
	If Not _Seed() Or _ReadBoth() <> 15 Then Return False
	Local $iNow = Number(_WebView2_ExecuteScript($g_iView, "Math.floor(Date.now()/1000)", 3000))
	If $iNow <= 0 Then Return False
	If _WebView2_ClearProfileBrowsingData($g_iView, 0, _OnClearComplete) Or @error <> $WEBVIEW2_ERR_INVALID_PARAMETER Then Return False
	If _WebView2_ClearProfileBrowsingData($g_iView, $WEBVIEW2_BROWSING_DATA_COOKIES, _OnClearComplete, $iNow) Or @error <> $WEBVIEW2_ERR_INVALID_PARAMETER Then Return False
	If _WebView2_ClearProfileBrowsingData($g_iView, $WEBVIEW2_BROWSING_DATA_COOKIES, _OnClearComplete, $iNow, $iNow) Or @error <> $WEBVIEW2_ERR_INVALID_PARAMETER Then Return False
	If Not _StartClear($WEBVIEW2_BROWSING_DATA_COOKIES, $iNow - 7200, $iNow - 3600) Or Not _WaitClear() Or _ReadBoth() <> 15 Then Return False
	If Not _StartClear($WEBVIEW2_BROWSING_DATA_COOKIES, $iNow - 60, $iNow + 60) Or Not _WaitClear() Or _ReadBoth() <> 5 Then Return False
	If Not _Seed() Or _ReadBoth() <> 15 Then Return False
	If Not _StartClear($WEBVIEW2_BROWSING_DATA_LOCAL_STORAGE) Or Not _WaitClear() Or _ReadBoth() <> 10 Then Return False
	If Not _StartClear($WEBVIEW2_BROWSING_DATA_COOKIES) Or Not _WaitClear() Or _ReadBoth() <> 0 Then Return False
	If Not _Seed() Or _ReadBoth() <> 15 Then Return False
	Local $iCombinedMask = BitOR($WEBVIEW2_BROWSING_DATA_LOCAL_STORAGE, $WEBVIEW2_BROWSING_DATA_COOKIES)
	If Not _StartClear($iCombinedMask) Then Return False
	If _WebView2_ClearProfileBrowsingData($g_iView, $iCombinedMask, _OnClearComplete) Or @error <> $WEBVIEW2_ERR_BUSY Then Return False
	If Not _WaitClear() Or _ReadBoth() <> 0 Then Return False
	_Log("Smoke: time range, selected kinds and shared profile verified across both origins.")
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
	ConsoleWrite("[055] " & $sMessage & @CRLF)
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
