#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include "..\WebView2.au3"

; #INDEX# =======================================================================================================================
; Title .........: 032_NativeExtensions.au3
; Description ...: Installs, lists, enables, disables and removes a native WebView2 profile extension.
; Author(s) .....: mLipok
; Version .......: 0.6.0
; Remarks .......: The sample extension is unpacked and has no network dependency.
; ===============================================================================================================================

Global $g_iWebView = -1
Global $g_sExtensionId = ""
Global Const $g_sSampleName = "WebView2 Native Extension Sample"
Global $g_hGUI = 0
Global $g_idStatus = 0
Global $g_bRefreshState = False
Global $g_bReloadNeeded = False
Global $g_bReloadInProgress = False

_Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Runs the native profile-extension demonstration.
; ===============================================================================================================================
Func _Example()
	Local $sFolder = @ScriptDir & "\assets\native\032-extension"
	Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\032_NativeExtensions"
	If Not _WebView2_NativeExtensions_EnableForEnvironment() Then Return _Example_Fail("Enable extensions")
	If Not _WebView2_Init(Default, $sProfile) Then Return _Example_Fail("Initialize")
	$g_hGUI = GUICreate("WebView2 - Native extensions", 850, 570, -1, -1, $WS_OVERLAPPEDWINDOW)
	Local $idList = GUICtrlCreateButton("List", 10, 8, 75, 28)
	Local $idAdd = GUICtrlCreateButton("Install sample", 95, 8, 115, 28)
	Local $idRemove = GUICtrlCreateButton("Remove", 234, 8, 85, 28)
	Local $idDisable = GUICtrlCreateButton("Disable", 343, 8, 85, 28)
	Local $idEnable = GUICtrlCreateButton("Enable", 438, 8, 85, 28)
	Local $idReload = GUICtrlCreateButton("Reload page", 547, 8, 110, 28)
	GUICtrlSetBkColor($idList, 0xFFF3BF)
	GUICtrlSetBkColor($idAdd, 0xA9DFBF)
	GUICtrlSetBkColor($idRemove, 0xF4B5B5)
	GUICtrlSetBkColor($idDisable, 0xF8D7DA)
	GUICtrlSetBkColor($idEnable, 0xD8F2DC)
	GUICtrlSetBkColor($idReload, 0xDCEBFA)
	GUICtrlSetResizing($idList, BitOR($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	GUICtrlSetResizing($idAdd, BitOR($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	GUICtrlSetResizing($idRemove, BitOR($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	GUICtrlSetResizing($idDisable, BitOR($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	GUICtrlSetResizing($idEnable, BitOR($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	GUICtrlSetResizing($idReload, BitOR($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	$g_idStatus = GUICtrlCreateLabel("Ready. The profile is preserved between runs.", 12, 44, 815, 28)
	GUISetState(@SW_SHOW, $g_hGUI)
	Local $aClient = WinGetClientSize($g_hGUI)
	$g_iWebView = _WebView2_Create($g_hGUI, 0, 76, $aClient[0], $aClient[1] - 76)
	If @error Then Return _Example_Fail("Create view")
	If Not _WebView2_SetVirtualHostNameToFolderMapping($g_iWebView, "extension-demo.local", $sFolder) Then Return _Example_Fail("Map sample folder")
	If Not _WebView2_SetCallback($g_iWebView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _Example_OnNavigation) Then Return _Example_Fail("Navigation callback")
	If Not _WebView2_Navigate($g_iWebView, "https://extension-demo.local/page.html") Then Return _Example_Fail("Navigate")
	_Example_List()
	While True
		If $g_bRefreshState Then
			$g_bRefreshState = False
			_Example_List()
		EndIf
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $GUI_EVENT_RESIZED
				$aClient = WinGetClientSize($g_hGUI)
				_WebView2_SetBounds($g_iWebView, 0, 76, $aClient[0], $aClient[1] - 76)
			Case $idAdd
				$g_sExtensionId = _WebView2_NativeExtension_Add($g_iWebView, $sFolder)
				If @error Then
					_Example_Fail("Install")
				Else
					$g_bReloadNeeded = True
					_Example_List()
				EndIf
			Case $idList
				_Example_List()
			Case $idDisable
				_Example_Change(False, False)
			Case $idEnable
				_Example_Change(True, False)
			Case $idRemove
				_Example_Change(False, True)
			Case $idReload
				_Example_Reload()
		EndSwitch
	WEnd
	_WebView2_Cleanup()
	GUIDelete($g_hGUI)
EndFunc   ;==>_Example

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_List
; Description ...: Displays the current profile extension snapshot.
; ===============================================================================================================================
Func _Example_List()
	Local $aList = _WebView2_NativeExtension_List($g_iWebView)
	If @error Then Return _Example_Fail("List")
	$g_sExtensionId = ""
	Local $sStatus = ""
	For $i = 0 To UBound($aList) - 1
		If $aList[$i][1] <> $g_sSampleName Then ContinueLoop
		$g_sExtensionId = $aList[$i][0]
		$sStatus = "Sample " & ($aList[$i][2] ? "enabled" : "disabled") & " (ID " & $g_sExtensionId & ")."
		If $g_bReloadNeeded Then $sStatus &= " RELOAD to take effect."
		_Example_Status($sStatus)
		Return
	Next
	$sStatus = "Sample extension not installed. Other profile extensions: " & UBound($aList) & "."
	If $g_bReloadNeeded Then $sStatus &= " RELOAD to take effect."
	_Example_Status($sStatus)
EndFunc   ;==>_Example_List

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Change
; Description ...: Changes the sample extension using its ID.
; ===============================================================================================================================
Func _Example_Change($bEnabled, $bRemove)
	If $g_sExtensionId = "" Then Return _Example_Status("Install the sample extension first.")
	Local $bResult = $bRemove ? _WebView2_NativeExtension_Remove($g_iWebView, $g_sExtensionId) : _WebView2_NativeExtension_SetEnabled($g_iWebView, $g_sExtensionId, $bEnabled)
	If Not $bResult Then Return _Example_Fail("Change extension")
	$g_bReloadNeeded = True
	_Example_List()
EndFunc   ;==>_Example_Change

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Reload
; Description ...: Reloads the page so the content script reflects the changed native state.
; ===============================================================================================================================
Func _Example_Reload()
	$g_bReloadInProgress = True
	If Not _WebView2_Reload($g_iWebView) Then
		$g_bReloadInProgress = False
		_Example_Fail("Reload page")
	EndIf
EndFunc   ;==>_Example_Reload

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_OnNavigation
; Description ...: Schedules a fresh extension-state display after page navigation.
; ===============================================================================================================================
Func _Example_OnNavigation($iWebView, $bSuccess, $iWebErrorStatus, $iNavigationId)
	#forceref $iNavigationId
	If $iWebView <> $g_iWebView Then Return
	If Not $bSuccess Then
		$g_bReloadInProgress = False
		Return _Example_Status("Page load failed; WebView2 status: " & $iWebErrorStatus)
	EndIf
	If $g_bReloadInProgress Then
		$g_bReloadNeeded = False
		$g_bReloadInProgress = False
	EndIf
	$g_bRefreshState = True
EndFunc   ;==>_Example_OnNavigation

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Status
; Description ...: Shows the current operation result.
; ===============================================================================================================================
Func _Example_Status($sText)
	GUICtrlSetData($g_idStatus, $sText)
	ConsoleWrite($sText & @CRLF)
EndFunc   ;==>_Example_Status

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Fail
; Description ...: Shows the UDF diagnostic for a failed step.
; ===============================================================================================================================
Func _Example_Fail($sStage)
	Local $sText = $sStage & ": " & _WebView2_Error_GetDescription()
	If $g_idStatus Then _Example_Status($sText)
	MsgBox($MB_ICONERROR, "Native extensions", $sText)
	Return False
EndFunc   ;==>_Example_Fail
