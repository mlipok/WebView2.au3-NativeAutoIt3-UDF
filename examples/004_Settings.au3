#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <WindowsConstants.au3>

#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_EX_idLog = 0, $g_EX_idGuide = 0

_Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Runs the Settings example.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: No value; shows the result in the example GUI or console.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Do
		Local $hGUI = GUICreate("WebView2.au3 - Settings", 1100, 760, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		GUICtrlCreateLabel("AutoIt operation log", 5, 48, 290, 18)
		GUICtrlSetResizing(-1, $GUI_DOCKALL)
		$g_EX_idLog = GUICtrlCreateEdit("", 5, 69, 290, 450, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idLog, 0xE2F0E4)
		GUICtrlSetResizing($g_EX_idLog, $GUI_DOCKALL)
		Local $sEXGuide = "TEST PROCEDURE" & @CRLF & "Click Show alert pop-up in the page; clear JavaScript alert pop-ups and click again; check it and repeat." & @CRLF & "EXPECTED RESULT" & @CRLF & "The browser alert appears only while the native checkbox is checked." & @CRLF & "HOW IT WORKS" & @CRLF & "The native setting controls WebView2 default JavaScript dialogs."
		$g_EX_idGuide = GUICtrlCreateEdit($sEXGuide, 305, 520, 790, 170, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idGuide, 0xFFF1BF)
		GUICtrlSetResizing($g_EX_idGuide, $GUI_DOCKALL)
		Local $idContext = GUICtrlCreateCheckbox("Context menu", 10, 10, 110, 25)
		Local $idDevTools = GUICtrlCreateCheckbox("DevTools", 130, 10, 90, 25)
		Local $idStatus = GUICtrlCreateCheckbox("Status bar", 230, 10, 90, 25)
		Local $idDialogs = GUICtrlCreateCheckbox("JavaScript alert pop-ups", 330, 10, 170, 25)
		Local $idZoom = GUICtrlCreateCheckbox("Zoom control", 510, 10, 100, 25)
		GUICtrlSetState($idContext, $GUI_CHECKED)
		GUICtrlSetState($idDevTools, $GUI_CHECKED)
		GUICtrlSetState($idStatus, $GUI_CHECKED)
		GUICtrlSetState($idDialogs, $GUI_CHECKED)
		GUICtrlSetState($idZoom, $GUI_CHECKED)
		GUISetState(@SW_MAXIMIZE, $hGUI)
		_EX_Log("Starting WebView2...")

		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\004_Settings"
		If Not _WebView2_Init(Default, $sProfile) Then
			$__WebView2ExitValue = _Error("Init")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $aInitialClient = WinGetClientSize($hGUI)
		If IsArray($aInitialClient) Then _EX_Layout($aInitialClient, 45)
		Local $iWebView = _WebView2_Create($hGUI, 305, 45, $aInitialClient[0] - 310, $aInitialClient[1] - 235)
		If @error Then
			$__WebView2ExitValue = _Error("Create")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not _WebView2_SetDefaultScriptDialogsEnabled($iWebView, True) Then
			$__WebView2ExitValue = _Error("Enable JavaScript alert pop-ups")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		_WebView2_NavigateToString($iWebView, '<html><body style="font-family:Segoe UI;padding:30px"><h1>Settings demo</h1><p>Right-click, use F12 and hover links to test settings.</p><p>Click the button below: a browser alert pop-up appears while JavaScript alert pop-ups is checked. Clear that checkbox to suppress the pop-up, then check it again to restore it.</p><a href="https://www.autoitscript.com">AutoIt</a><br><br><button onclick="alert(''JavaScript alert from the page'')">Show alert pop-up</button></body></html>')

		While True
			Switch GUIGetMsg()
				Case $idContext
					_WebView2_SetDefaultContextMenusEnabled($iWebView, BitAND(GUICtrlRead($idContext), $GUI_CHECKED) <> 0)
					_EX_Log("Context menu setting changed to " & (BitAND(GUICtrlRead($idContext), $GUI_CHECKED) <> 0 ? "checked" : "unchecked") & ".")
				Case $idDevTools
					_WebView2_SetDevToolsEnabled($iWebView, BitAND(GUICtrlRead($idDevTools), $GUI_CHECKED) <> 0)
					_EX_Log("DevTools setting changed to " & (BitAND(GUICtrlRead($idDevTools), $GUI_CHECKED) <> 0 ? "checked" : "unchecked") & ".")
				Case $idStatus
					_WebView2_SetStatusBarEnabled($iWebView, BitAND(GUICtrlRead($idStatus), $GUI_CHECKED) <> 0)
					_EX_Log("Status bar setting changed to " & (BitAND(GUICtrlRead($idStatus), $GUI_CHECKED) <> 0 ? "checked" : "unchecked") & ".")
				Case $idDialogs
					_WebView2_SetDefaultScriptDialogsEnabled($iWebView, BitAND(GUICtrlRead($idDialogs), $GUI_CHECKED) <> 0)
					_EX_Log("JavaScript alert pop-ups setting changed to " & (BitAND(GUICtrlRead($idDialogs), $GUI_CHECKED) <> 0 ? "checked" : "unchecked") & ".")
				Case $idZoom
					_WebView2_SetZoomControlEnabled($iWebView, BitAND(GUICtrlRead($idZoom), $GUI_CHECKED) <> 0)
					_EX_Log("Zoom control setting changed to " & (BitAND(GUICtrlRead($idZoom), $GUI_CHECKED) <> 0 ? "checked" : "unchecked") & ".")
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					Local $aSize = WinGetClientSize($hGUI)
					If IsArray($aSize) Then
						_EX_Layout($aSize, 45)
						_WebView2_SetBounds($iWebView, 305, 45, $aSize[0] - 310, $aSize[1] - 235)
					EndIf
				Case $GUI_EVENT_CLOSE
					ExitLoop
			EndSwitch
		WEnd
		_WebView2_Cleanup()
		GUIDelete($hGUI)
	Until True
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_Example

; #FUNCTION# ====================================================================================================================
; Name ..........: _Error
; Description ...: Reports a failed WebView2 operation and its diagnostic.
; Syntax ........: _Error($sStage)
; Parameters ....: $sStage - Name of the failed example stage.
; Return values .: No value; shows the result in the example GUI or console.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Error($sStage)
	MsgBox($MB_ICONERROR, "WebView2 " & $sStage, _WebView2_Error_GetDescription())
	_WebView2_Cleanup()
	Return
EndFunc   ;==>_Error

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _EX_Layout
; Description ...: Sizes the operation log and test guide.
; Syntax ........: _EX_Layout($aClient, $iTop)
; Parameters ....: $aClient - GUI client size; $iTop - height of the control strip.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _EX_Layout($aClient, $iTop)
	GUICtrlSetPos($g_EX_idLog, 5, $iTop + 24, 290, $aClient[1] - $iTop - 34)
	GUICtrlSetPos($g_EX_idGuide, 305, $aClient[1] - 180, $aClient[0] - 310, 170)
	Return
EndFunc   ;==>_EX_Layout

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _EX_Log
; Description ...: Appends a time-stamped operation-log entry.
; Syntax ........: _EX_Log($sText)
; Parameters ....: $sText - Message to append.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _EX_Log($sText)
	If $g_EX_idLog Then _GUICtrlEdit_AppendText($g_EX_idLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sText & @CRLF)
	Return
EndFunc   ;==>_EX_Log

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _EX_Click
; Description ...: Logs a native button click in a separate group.
; Syntax ........: _EX_Click($sCaption)
; Parameters ....: $sCaption - Visible button caption.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _EX_Click($sCaption)
	If $g_EX_idLog Then _GUICtrlEdit_AppendText($g_EX_idLog, @CRLF & "[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [AutoIt]: " & $sCaption & " was clicked." & @CRLF)
	Return
EndFunc   ;==>_EX_Click
