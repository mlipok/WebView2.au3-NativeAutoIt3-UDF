#Tidy_ILC_Pos=44

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

_Main()

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Main
; Description ...: Demonstrates two WebView2 tabs in one parent window.
; Syntax ........: _Main()
; Parameters ....: None.
; Return values .: No value.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The WebView2 controls begin below the AutoIt tab header.
; Related .......: _WebView2_Tab_Create, _WebView2_Tab_Activate, _WebView2_Tab_List, _WebView2_Instance_List
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Main()
	Local $hGUI = GUICreate("WebView2.au3 - Tabs", 1000, 700, -1, -1, $WS_OVERLAPPEDWINDOW)
	Local $idTabs = GUICtrlCreateTab(0, 0, 1000, 32)
	GUICtrlCreateTabItem("AutoIt")
	GUICtrlCreateTabItem("Example")
	GUICtrlCreateTabItem("")
	Local $aTabs[2] = [-1, -1]
	Local $bReady = _WebView2_Init()
	If $bReady Then
		$aTabs[0] = _WebView2_Tab_Create($hGUI, "https://www.autoitscript.com/", 0, 34)
		If $aTabs[0] < 0 Then $bReady = False
	EndIf
	If $bReady Then
		$aTabs[1] = _WebView2_Tab_Create($hGUI, "https://example.com/", 0, 34)
		If $aTabs[1] < 0 Then $bReady = False
	EndIf
	If $bReady Then
		_WebView2_Tab_Activate($aTabs[0])
		Local $aCurrentTabs = _WebView2_Tab_List($hGUI)
		Local $aInstances = _WebView2_Instance_List()
		ConsoleWrite("Tabs=" & $aCurrentTabs[0] & "; instances=" & $aInstances[0] & @CRLF)
		GUISetState(@SW_SHOW, $hGUI)
		While True
			Switch GUIGetMsg()
				Case $GUI_EVENT_CLOSE
					ExitLoop
				Case $idTabs
					Local $iSelected = GUICtrlRead($idTabs)
					If $iSelected >= 0 And $iSelected < UBound($aTabs) Then _WebView2_Tab_Activate($aTabs[$iSelected])
			EndSwitch
		WEnd
	Else
		MsgBox(16, "WebView2 tabs", _WebView2_Error_GetDescription())
	EndIf
	For $i = 0 To UBound($aTabs) - 1
		If $aTabs[$i] >= 0 Then _WebView2_Tab_Close($aTabs[$i])
	Next
	_WebView2_Cleanup()
	GUIDelete($hGUI)
	Return
EndFunc   ;==>_Main
