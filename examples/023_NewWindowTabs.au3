#Tidy_ILC_Pos=44

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GuiTab.au3>
#include "..\WebView2.au3"

Global $g_hGUI = 0, $g_idTabs = 0
Global $g_aTabs[0]
Global $g_bSmoke = $CmdLine[0] > 0 And $CmdLine[1] = "--smoke"

_Main()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Main
; Description ...: Hands target=_blank and window.open requests to tabs in the host window.
; Syntax ........: _Main()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: New controllers are created by the GUI loop, outside the native event callback.
; Related .......: _WebView2_SetCallback, _WebView2_Tab_Create
; Link ..........:
; Example .......: Yes
; ================================================================================================================================
Func _Main()
	Local $bSmokePassed = False
	$g_hGUI = GUICreate("WebView2 - New windows in tabs", 1000, 700, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	$g_idTabs = GUICtrlCreateTab(0, 0, 1000, 32)
	GUICtrlCreateTabItem("")
	Do
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\023_NewWindowTabs"
		If Not _WebView2_Init(Default, $sProfile) Then
			MsgBox(16, "WebView2", _WebView2_Error_GetDescription())
			ExitLoop
		EndIf
		GUISetState(@SW_MAXIMIZE, $g_hGUI)
		Local $iFirst = _AddTab("about:blank")
		If $iFirst < 0 Then
			MsgBox(16, "WebView2", _WebView2_Error_GetDescription())
			ExitLoop
		EndIf
		Local $sHTML = '<!doctype html><html><head><title>New window source</title></head><body style="font:18px Segoe UI;padding:24px">' & _
				'<h1>New-window requests</h1><p>The new tab is handed to WebView2 before it navigates, preserving window.opener.</p>' & _
				'<p><a href="https://example.com/" target="_blank">Open example.com (target=_blank)</a></p>' & _
				'<p><button onclick="window.open(''https://www.autoitscript.com/'', ''_blank'')">Open AutoIt website (window.open)</button></p>' & _
				'<p><button onclick="window.open(''about:blank'', ''_blank'')">Open same-origin blank tab (window.open)</button></p>' & _
				'</body></html>'
		If $g_bSmoke Then $sHTML = StringReplace($sHTML, '</body>', '<script>setTimeout(()=>{window.__popup=window.open("about:blank","_blank")},750)</script></body>')
		_WebView2_NavigateToString($iFirst, $sHTML)
		Local $tSmoke = TimerInit(), $iSmokeTarget = -1
		While True
			Switch GUIGetMsg()
				Case $GUI_EVENT_CLOSE
					ExitLoop
				Case $g_idTabs
					Local $iSelected = GUICtrlRead($g_idTabs)
					If $iSelected >= 0 And $iSelected < UBound($g_aTabs) Then _WebView2_Tab_Activate($g_aTabs[$iSelected])
			EndSwitch
			Local $aPending = _WebView2_NewWindow_Request_List()
			If $g_bSmoke And $aPending[0] Then ConsoleWrite("Smoke pending requests=" & $aPending[0] & @CRLF)
			For $i = 1 To $aPending[0]
				Local $iTab = _AddTab("about:blank")
				If $iTab < 0 Then
					_WebView2_NewWindow_Cancel($aPending[$i])
					ConsoleWrite("New tab creation failed: " & _WebView2_Error_GetDescription() & @CRLF)
					ContinueLoop
				EndIf
				If Not _WebView2_NewWindow_Complete($aPending[$i], $iTab) Then
					ConsoleWrite("New-window handoff failed: " & _WebView2_Error_GetDescription() & @CRLF)
					_WebView2_NewWindow_Cancel($aPending[$i])
					_DiscardFailedTab($iTab)
				ElseIf $g_bSmoke Then
					$iSmokeTarget = $iTab
				EndIf
			Next
			If $g_bSmoke Then
				If $iSmokeTarget >= 0 And TimerDiff($tSmoke) > 1500 Then
					Local $sHasOpener = _WebView2_ExecuteScript($iSmokeTarget, "window.opener!==null&&window.opener.document.title==='New window source'")
					If Not @error And $sHasOpener = "true" Then
						Local $sHasProxy = _WebView2_ExecuteScript($iFirst, "!!window.__popup&&!window.__popup.closed")
						If Not @error And $sHasProxy = "true" Then
							$bSmokePassed = True
							ExitLoop
						EndIf
					EndIf
				EndIf
				If TimerDiff($tSmoke) > 15000 Then ExitLoop
			EndIf
		WEnd
		If $g_bSmoke Then ConsoleWrite("New-window handoff smoke: " & ($bSmokePassed ? "PASS (window.opener and WindowProxy)" : "FAIL") & @CRLF)
	Until True
	For $i = 0 To UBound($g_aTabs) - 1
		_WebView2_Tab_Close($g_aTabs[$i])
	Next
	_WebView2_Cleanup()
	GUIDelete($g_hGUI)
	If $g_bSmoke And Not $bSmokePassed Then Exit 1
	Return
EndFunc   ;==>_Main

; #FUNCTION# ====================================================================================================================
; Name ..........: _NewWindowRequested
; Description ...: Defers a user-initiated new window for native controller handoff.
; Syntax ........: _NewWindowRequested($iSource, $sURI, $bUserInitiated)
; Parameters ....: $iSource - Source WebView2 instance ID.
;                  $sURI - Requested URI.
;                  $bUserInitiated - True for a direct user gesture.
; Return values .: $WEBVIEW2_NEW_WINDOW_DEFER for handoff; True to block other requests.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Never call _WebView2_Tab_Create from inside this callback.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: Yes
; ================================================================================================================================
Func _NewWindowRequested($iSource, $sURI, $bUserInitiated)
	#forceref $iSource, $sURI
	If $g_bSmoke Then ConsoleWrite("Smoke NewWindowRequested uri=" & $sURI & " user=" & $bUserInitiated & @CRLF)
	If $bUserInitiated Or $g_bSmoke Then Return $WEBVIEW2_NEW_WINDOW_DEFER
	Return True
EndFunc   ;==>_NewWindowRequested

; #FUNCTION# ====================================================================================================================
; Name ..........: _AddTab
; Description ...: Creates a WebView2 controller and a matching AutoIt tab item.
; Syntax ........: _AddTab($sURI)
; Parameters ....: $sURI - URI to load, or about:blank for an empty tab.
; Return values .: New tab ID, or -1 on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_Tab_Create
; Link ..........:
; Example .......: Yes
; ================================================================================================================================
Func _AddTab($sURI)
	Local $iTab = _WebView2_Tab_Create($g_hGUI, "about:blank", 0, 34)
	Do
		If $iTab < 0 Then ExitLoop
		If Not _WebView2_SetCallback($iTab, $WEBVIEW2_EVENT_NEW_WINDOW_REQUESTED, _NewWindowRequested) Then
			_WebView2_Tab_Close($iTab)
			$iTab = -1
			ExitLoop
		EndIf
		If $sURI <> "about:blank" And Not _WebView2_Navigate($iTab, $sURI) Then
			_WebView2_Tab_Close($iTab)
			$iTab = -1
			ExitLoop
		EndIf
		Local $iIndex = UBound($g_aTabs)
		ReDim $g_aTabs[$iIndex + 1]
		$g_aTabs[$iIndex] = $iTab
		GUICtrlCreateTabItem("Tab " & ($iIndex + 1))
		GUICtrlCreateTabItem("")
		_GUICtrlTab_SetCurSel(GUICtrlGetHandle($g_idTabs), $iIndex)
		_WebView2_Tab_Activate($iTab)
	Until True
	Return $iTab
EndFunc   ;==>_AddTab

; #FUNCTION# ====================================================================================================================
; Name ..........: _DiscardFailedTab
; Description ...: Removes a newly added tab after native popup handoff fails.
; ===============================================================================================================================
Func _DiscardFailedTab($iTab)
	Local $iLast = UBound($g_aTabs) - 1
	If $iLast < 0 Or $g_aTabs[$iLast] <> $iTab Then Return
	_WebView2_Tab_Close($iTab)
	_GUICtrlTab_DeleteItem(GUICtrlGetHandle($g_idTabs), $iLast)
	ReDim $g_aTabs[$iLast]
	If $iLast > 0 Then _WebView2_Tab_Activate($g_aTabs[$iLast - 1])
	Return
EndFunc   ;==>_DiscardFailedTab
