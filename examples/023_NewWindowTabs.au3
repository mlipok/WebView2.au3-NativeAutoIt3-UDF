#Tidy_ILC_Pos=44

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GuiTab.au3>
#include "..\WebView2.au3"

Global $g_hGUI = 0, $g_idTabs = 0
Global $g_aTabs[0], $g_aPending[0]

_Main()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Main
; Description ...: Opens target=_blank and window.open requests as tabs in the host window.
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
	$g_hGUI = GUICreate("WebView2 - New windows in tabs", 1000, 700, -1, -1, $WS_OVERLAPPEDWINDOW)
	$g_idTabs = GUICtrlCreateTab(0, 0, 1000, 32)
	GUICtrlCreateTabItem("")
	Do
		If Not _WebView2_Init() Then
			MsgBox(16, "WebView2", _WebView2_Error_GetDescription())
			ExitLoop
		EndIf
		GUISetState(@SW_SHOW, $g_hGUI)
		Local $iFirst = _AddTab("about:blank")
		If $iFirst < 0 Then
			MsgBox(16, "WebView2", _WebView2_Error_GetDescription())
			ExitLoop
		EndIf
		Local $sHTML = '<!doctype html><html><body style="font:18px Segoe UI;padding:24px">' & _
				'<h1>New-window requests</h1><p>Both links open in a new tab inside this window.</p>' & _
				'<p><a href="https://example.com/" target="_blank">Open example.com (target=_blank)</a></p>' & _
				'<p><button onclick="window.open(''https://www.autoitscript.com/'', ''_blank'')">Open AutoIt website (window.open)</button></p>' & _
				'</body></html>'
		_WebView2_NavigateToString($iFirst, $sHTML)
		While True
			Switch GUIGetMsg()
				Case $GUI_EVENT_CLOSE
					ExitLoop
				Case $g_idTabs
					Local $iSelected = GUICtrlRead($g_idTabs)
					If $iSelected >= 0 And $iSelected < UBound($g_aTabs) Then _WebView2_Tab_Activate($g_aTabs[$iSelected])
			EndSwitch
			While UBound($g_aPending) > 0
				Local $sURI = $g_aPending[0]
				_ArrayDeleteFirstPending()
				If _AddTab($sURI) < 0 Then ConsoleWrite("New tab failed: " & _WebView2_Error_GetDescription() & @CRLF)
			WEnd
		WEnd
	Until True
	For $i = 0 To UBound($g_aTabs) - 1
		_WebView2_Tab_Close($g_aTabs[$i])
	Next
	_WebView2_Cleanup()
	GUIDelete($g_hGUI)
	Return
EndFunc   ;==>_Main

; #FUNCTION# ====================================================================================================================
; Name ..........: _NewWindowRequested
; Description ...: Queues a user-initiated new-window URI and prevents a native popup.
; Syntax ........: _NewWindowRequested($iSource, $sURI, $bUserInitiated)
; Parameters ....: $iSource - Source WebView2 instance ID.
;                  $sURI - Requested URI.
;                  $bUserInitiated - True for a direct user gesture.
; Return values .: True to mark the request handled.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Never call _WebView2_Tab_Create from inside this callback.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: Yes
; ================================================================================================================================
Func _NewWindowRequested($iSource, $sURI, $bUserInitiated)
	#forceref $iSource
	If $bUserInitiated And $sURI <> "" Then
		Local $iCount = UBound($g_aPending)
		ReDim $g_aPending[$iCount + 1]
		$g_aPending[$iCount] = $sURI
	EndIf
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
; Name ..........: _ArrayDeleteFirstPending
; Description ...: Removes the URI just processed by the GUI loop.
; Syntax ........: _ArrayDeleteFirstPending()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _NewWindowRequested
; Link ..........:
; Example .......: Yes
; ================================================================================================================================
Func _ArrayDeleteFirstPending()
	Local $iCount = UBound($g_aPending)
	For $i = 1 To $iCount - 1
		$g_aPending[$i - 1] = $g_aPending[$i]
	Next
	ReDim $g_aPending[$iCount - 1]
EndFunc   ;==>_ArrayDeleteFirstPending
