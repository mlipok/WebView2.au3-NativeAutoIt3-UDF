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
	Local $idAdd = GUICtrlCreateButton("Install sample", 10, 8, 115, 28)
	Local $idList = GUICtrlCreateButton("List", 130, 8, 75, 28)
	Local $idDisable = GUICtrlCreateButton("Disable", 210, 8, 85, 28)
	Local $idEnable = GUICtrlCreateButton("Enable", 300, 8, 85, 28)
	Local $idRemove = GUICtrlCreateButton("Remove", 390, 8, 85, 28)
	Local $idReload = GUICtrlCreateButton("Reload page", 480, 8, 110, 28)
	$g_idStatus = GUICtrlCreateLabel("Ready. The profile is preserved between runs.", 12, 44, 815, 28)
	GUISetState(@SW_SHOW, $g_hGUI)
	Local $aClient = WinGetClientSize($g_hGUI)
	$g_iWebView = _WebView2_Create($g_hGUI, 0, 76, $aClient[0], $aClient[1] - 76)
	If @error Then Return _Example_Fail("Create view")
	If Not _WebView2_SetVirtualHostNameToFolderMapping($g_iWebView, "extension-demo.local", $sFolder) Then Return _Example_Fail("Map sample folder")
	If Not _WebView2_Navigate($g_iWebView, "https://extension-demo.local/page.html") Then Return _Example_Fail("Navigate")
	_Example_List()
	While True
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
					_Example_Status("Installed " & $g_sExtensionId & ". Reload the page to see the banner.")
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
				_WebView2_Reload($g_iWebView)
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
	For $i = 0 To UBound($aList) - 1
		If $aList[$i][1] <> $g_sSampleName Then ContinueLoop
		$g_sExtensionId = $aList[$i][0]
		_Example_Status($g_sSampleName & " (" & $g_sExtensionId & "), enabled=" & $aList[$i][2] & "; total=" & UBound($aList))
		Return
	Next
	_Example_Status("Sample extension not installed. Other profile extensions: " & UBound($aList))
EndFunc   ;==>_Example_List

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Change
; Description ...: Changes the first listed extension using its ID.
; ===============================================================================================================================
Func _Example_Change($bEnabled, $bRemove)
	If $g_sExtensionId = "" Then Return _Example_Status("Install the sample extension first.")
	Local $bResult = $bRemove ? _WebView2_NativeExtension_Remove($g_iWebView, $g_sExtensionId) : _WebView2_NativeExtension_SetEnabled($g_iWebView, $g_sExtensionId, $bEnabled)
	If Not $bResult Then Return _Example_Fail("Change extension")
	_Example_List()
EndFunc   ;==>_Example_Change

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
