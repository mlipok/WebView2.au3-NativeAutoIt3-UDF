#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global Const $g_sHost = "udf-virtual-host.example"
Global Const $g_sOrigin = "https://" & $g_sHost & "/"
Global $g_iView = -1, $g_idLog = 0, $g_idGuide = 0, $g_idStatus = 0
Global $g_hDialog = 0, $g_idDialogOrigin = 0, $g_idDialogMessage = 0
Global $g_idAccept = 0, $g_idDismiss = 0, $g_idPromptText = 0
Global $g_sAcceptCaption = "OK", $g_sDismissCaption = "Cancel"
Global $g_iPending = 0, $g_iPendingKind = -1, $g_iPageKind = -1
Global $g_sPageResult = "", $g_bReady = False, $g_bSmoke = False, $g_bSmokePopup = False
If $CmdLine[0] > 0 Then
	$g_bSmokePopup = ($CmdLine[1] = "--smoke-popup")
	$g_bSmoke = ($CmdLine[1] = "--smoke" Or $g_bSmokePopup)
EndIf

Exit _Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Shows native JavaScript dialog callbacks with deferred AutoIt responses.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: 0 on normal close or successful smoke; 1 on setup or smoke failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Uses a local virtual HTTPS host and a separate temporary profile.
; Related .......: _WebView2_ScriptDialog_Request_Respond
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example()
	Local $iExitCode = 1
	Local $hGUI = GUICreate("WebView2 - Script dialogs", 1000, 650, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	$g_idStatus = GUICtrlCreateLabel("Starting WebView2...", 305, 10, 680, 25)
	GUICtrlSetResizing($g_idStatus, $GUI_DOCKALL)
	GUICtrlCreateLabel("AutoIt operation log", 5, 43, 290, 18)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	$g_idLog = GUICtrlCreateEdit("", 5, 64, 290, 530, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idLog, 0xE2F0E4)
	GUICtrlSetResizing($g_idLog, $GUI_DOCKALL)
	Local $sGuide = "TEST PROCEDURE" & @CRLF & "1. Test Open alert, Open confirm and Open prompt with their AutoIt pop-ups." & @CRLF & "2. Click Mark unsaved changes, then Leave this page. Choose Stay in the AutoIt pop-up; the page remains." & @CRLF & "3. Click Leave this page again and choose Leave; the local destination page appears." & @CRLF & "EXPECTED RESULT" & @CRLF & "The operation log shows a beforeunload request. Stay cancels navigation; Leave completes it. No returns false for confirm; Cancel returns null for prompt." & @CRLF & "HOW IT WORKS" & @CRLF & "The page requests confirmation before leaving. ScriptDialogOpening defers the native decision while the AutoIt event loop opens a host-owned pop-up. Unanswered requests close after 15 seconds."
	$g_idGuide = GUICtrlCreateEdit($sGuide, 305, 400, 680, 190, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idGuide, 0xFFF4C2)
	GUICtrlSetResizing($g_idGuide, $GUI_DOCKALL)
	$g_hDialog = GUICreate("JavaScript dialog", 500, 245, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), $WS_EX_DLGMODALFRAME, $hGUI)
	GUICtrlCreateLabel("Page:", 15, 12, 45, 18)
	$g_idDialogOrigin = GUICtrlCreateLabel("", 60, 12, 420, 35)
	$g_idDialogMessage = GUICtrlCreateEdit("", 15, 53, 470, 80, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	$g_idPromptText = GUICtrlCreateInput("", 15, 144, 470, 24)
	$g_idAccept = GUICtrlCreateButton("OK", 290, 185, 90, 30)
	$g_idDismiss = GUICtrlCreateButton("Cancel", 390, 185, 90, 30)
	GUISetState(@SW_MAXIMIZE, $hGUI)
	Local $aClient = WinGetClientSize($hGUI)
	If IsArray($aClient) Then
		GUICtrlSetPos($g_idLog, 5, 64, 290, $aClient[1] - 74)
		GUICtrlSetPos($g_idGuide, 305, $aClient[1] - 200, $aClient[0] - 310, 190)
	EndIf
	Do
		If Not _WebView2_Init(Default, @TempDir & "\WebView2ScriptDialogExample_" & @AutoItPID) Then ExitLoop
		$aClient = WinGetClientSize($hGUI)
		$g_iView = _WebView2_Create($hGUI, 305, 40, $aClient[0] - 310, $aClient[1] - 250)
		If @error Then ExitLoop
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_SCRIPT_DIALOG_OPENING, _Example_OnDialog) Then ExitLoop
		If Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED, _Example_OnMessage) Then ExitLoop
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_iView, $g_sHost, @ScriptDir & "\036_ScriptDialogs") Then ExitLoop
		If Not _WebView2_Navigate($g_iView, $g_sOrigin & "index.html") Then ExitLoop
		$iExitCode = 0
	Until True
	If $iExitCode Then _Example_Status("Setup failed: " & _WebView2_Error_GetDescription())
	Local $hTimer = TimerInit(), $iSmokeStage = 0
	While $iExitCode = 0
		Local $aPending = _WebView2_ScriptDialog_Request_List($g_iView)
		Local $iCurrent = ($aPending[0] > 0) ? $aPending[1] : 0
		If $iCurrent <> $g_iPending Then
			$g_iPending = $iCurrent
			If $g_iPending Then
				Local $aInfo = _WebView2_ScriptDialog_Request_GetInfo($g_iPending)
				If IsArray($aInfo) And UBound($aInfo) = 5 Then
					$g_iPendingKind = $aInfo[2]
					If $g_iPendingKind = $WEBVIEW2_SCRIPT_DIALOG_KIND_BEFOREUNLOAD Then
						_Example_Status("Beforeunload request " & $g_iPending & " from " & $aInfo[1] & "; choose Leave or Stay.")
					Else
						_Example_Status("Dialog " & $g_iPending & " kind=" & $g_iPendingKind & " from " & $aInfo[1] & ": " & $aInfo[3])
					EndIf
					If Not $g_bSmoke Or $g_bSmokePopup Then _Example_Dialog_Show($aInfo)
				EndIf
			EndIf
		EndIf
		Local $iExpired = _WebView2_ScriptDialog_Request_Expire(15000)
		If $iExpired Then
			GUISetState(@SW_HIDE, $g_hDialog)
			$g_iPending = 0
			_Example_Status($iExpired & " unanswered dialog(s) expired and were dismissed.")
		EndIf
		If $g_bSmoke Then
			If $g_bReady And $iSmokeStage = 0 Then
				If Not _Example_Trigger("alert") Then $iExitCode = 1
				$iSmokeStage = 1
			EndIf
			If $iSmokeStage = 1 And $g_iPending > 0 Then
				If $g_bSmokePopup Then
					If Not _Example_SmokeClick($g_idAccept) Then $iExitCode = 1
				Else
					If Not _WebView2_ScriptDialog_Request_Respond($g_iPending, $WEBVIEW2_SCRIPT_DIALOG_ACCEPT) Then $iExitCode = 1
					$g_iPending = 0
				EndIf
				$iSmokeStage = 2
			EndIf
			If $iSmokeStage = 2 And $g_iPageKind = $WEBVIEW2_SCRIPT_DIALOG_KIND_ALERT Then
				$g_iPageKind = -1
				If Not _Example_Trigger("confirm") Then $iExitCode = 1
				$iSmokeStage = 3
			EndIf
			If $iSmokeStage = 3 And $g_iPending > 0 Then
				If $g_bSmokePopup Then
					If Not _Example_SmokeClick($g_idDismiss) Then $iExitCode = 1
				Else
					If Not _WebView2_ScriptDialog_Request_Cancel($g_iPending) Then $iExitCode = 1
					$g_iPending = 0
				EndIf
				$iSmokeStage = 4
			EndIf
			If $iSmokeStage = 4 And $g_iPageKind = $WEBVIEW2_SCRIPT_DIALOG_KIND_CONFIRM And StringInStr($g_sPageResult, '"value":false') Then
				$g_iPageKind = -1
				If Not _Example_Trigger("prompt") Then $iExitCode = 1
				$iSmokeStage = 5
			EndIf
			If $iSmokeStage = 5 And $g_iPending > 0 Then
				If $g_bSmokePopup Then
					GUICtrlSetData($g_idPromptText, "AutoIt reply")
					If Not _Example_SmokeClick($g_idAccept) Then $iExitCode = 1
				Else
					If Not _WebView2_ScriptDialog_Request_Respond($g_iPending, $WEBVIEW2_SCRIPT_DIALOG_ACCEPT, "AutoIt reply") Then $iExitCode = 1
					$g_iPending = 0
				EndIf
				$iSmokeStage = 6
			EndIf
			If $iSmokeStage = 6 And $g_iPageKind = $WEBVIEW2_SCRIPT_DIALOG_KIND_PROMPT And StringInStr($g_sPageResult, '"value":"AutoIt reply"') Then
				ConsoleWrite("EX_SMOKE_OK example=036 arch=" & (@AutoItX64 ? "x64" : "x86") & " popup=" & $g_bSmokePopup & @CRLF)
				ExitLoop
			EndIf
			If $iExitCode Or TimerDiff($hTimer) > 20000 Then
				_Example_Status("Smoke failed or timed out at stage " & $iSmokeStage & ".")
				$iExitCode = 1
				ExitLoop
			EndIf
		EndIf
		Local $aEvent = GUIGetMsg(1)
		Local $iMessage = $aEvent[0]
		Switch $iMessage
			Case $GUI_EVENT_CLOSE
				If $aEvent[1] = $g_hDialog Then
					_Example_Dialog_Answer(False, "Close")
				Else
					ExitLoop
				EndIf
			Case $g_idAccept, $g_idDismiss
				_Example_Dialog_Answer($iMessage = $g_idAccept, $iMessage = $g_idAccept ? $g_sAcceptCaption : $g_sDismissCaption)
			Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
				$aClient = WinGetClientSize($hGUI)
				If IsArray($aClient) And $g_iView >= 0 Then
					GUICtrlSetPos($g_idLog, 5, 64, 290, $aClient[1] - 74)
					GUICtrlSetPos($g_idGuide, 305, $aClient[1] - 200, $aClient[0] - 310, 190)
					_WebView2_SetBounds($g_iView, 305, 40, $aClient[0] - 310, $aClient[1] - 250)
				EndIf
		EndSwitch
		Sleep(10)
	WEnd
	_WebView2_Cleanup()
	GUIDelete($g_hDialog)
	GUIDelete($hGUI)
	Return $iExitCode
EndFunc   ;==>_Example

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Dialog_Show
; Description ...: Displays a host-owned pop-up for one deferred JavaScript dialog.
; Syntax ........: _Example_Dialog_Show($aInfo)
; Parameters ....: $aInfo - Pending request information returned by the UDF.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Called from the AutoIt event loop, never inside the native WebView2 callback.
; Related .......: _WebView2_ScriptDialog_Request_GetInfo
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_Dialog_Show($aInfo)
	Local $sTitle = "JavaScript dialog"
	$g_sAcceptCaption = "OK"
	$g_sDismissCaption = "Cancel"
	Switch $aInfo[2]
		Case $WEBVIEW2_SCRIPT_DIALOG_KIND_ALERT
			$sTitle = "JavaScript alert"
			GUICtrlSetState($g_idDismiss, $GUI_HIDE)
			GUICtrlSetState($g_idPromptText, $GUI_HIDE)
		Case $WEBVIEW2_SCRIPT_DIALOG_KIND_CONFIRM
			$sTitle = "JavaScript confirmation"
			$g_sAcceptCaption = "Yes"
			$g_sDismissCaption = "No"
			GUICtrlSetState($g_idDismiss, $GUI_SHOW)
			GUICtrlSetState($g_idPromptText, $GUI_HIDE)
		Case $WEBVIEW2_SCRIPT_DIALOG_KIND_PROMPT
			$sTitle = "JavaScript prompt"
			GUICtrlSetData($g_idPromptText, $aInfo[4])
			GUICtrlSetState($g_idPromptText, $GUI_SHOW)
			GUICtrlSetState($g_idDismiss, $GUI_SHOW)
		Case $WEBVIEW2_SCRIPT_DIALOG_KIND_BEFOREUNLOAD
			$sTitle = "Leave this page?"
			$g_sAcceptCaption = "Leave"
			$g_sDismissCaption = "Stay"
			GUICtrlSetState($g_idDismiss, $GUI_SHOW)
			GUICtrlSetState($g_idPromptText, $GUI_HIDE)
	EndSwitch
	WinSetTitle($g_hDialog, "", $sTitle)
	GUICtrlSetData($g_idDialogOrigin, $aInfo[1])
	Local $sDialogMessage = $aInfo[3]
	If $aInfo[2] = $WEBVIEW2_SCRIPT_DIALOG_KIND_BEFOREUNLOAD And $sDialogMessage = "" Then $sDialogMessage = "This page has unsaved changes. Leave this page or stay here?"
	GUICtrlSetData($g_idDialogMessage, $sDialogMessage)
	GUICtrlSetData($g_idAccept, $g_sAcceptCaption)
	GUICtrlSetData($g_idDismiss, $g_sDismissCaption)
	GUISetState(@SW_SHOW, $g_hDialog)
	WinActivate($g_hDialog)
	Return
EndFunc   ;==>_Example_Dialog_Show

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Dialog_Answer
; Description ...: Answers the pending request from the visible AutoIt pop-up.
; Syntax ........: _Example_Dialog_Answer($bAccept, $sCaption)
; Parameters ....: $bAccept - True to accept; False to dismiss.
;                  $sCaption - Action caption for the operation log.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Closing the pop-up with its title-bar button dismisses the dialog.
; Related .......: _WebView2_ScriptDialog_Request_Respond
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_Dialog_Answer($bAccept, $sCaption)
	If $g_iPending > 0 Then
		_GUICtrlEdit_AppendText($g_idLog, @CRLF)
		If $sCaption = "Close" Then
			_Example_Status("The JavaScript dialog pop-up was closed.")
		Else
			Local $sClick = "[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [AutoIt]: " & $sCaption & " was clicked."
			_GUICtrlEdit_AppendText($g_idLog, $sClick & @CRLF)
			GUICtrlSendMsg($g_idLog, $EM_SCROLLCARET, 0, 0)
			ConsoleWrite($sClick & @CRLF)
		EndIf
		Local $sResultText = Default
		If $bAccept And $g_iPendingKind = $WEBVIEW2_SCRIPT_DIALOG_KIND_PROMPT Then $sResultText = GUICtrlRead($g_idPromptText)
		Local $bAnswered = _WebView2_ScriptDialog_Request_Respond($g_iPending, $bAccept ? $WEBVIEW2_SCRIPT_DIALOG_ACCEPT : $WEBVIEW2_SCRIPT_DIALOG_CANCEL, $sResultText)
		Local $iAnswerError = @error, $iAnswerExtended = @extended
		If $bAnswered Then
			_Example_Status("Answered dialog " & $g_iPending & ".")
		Else
			_Example_Status("Could not answer dialog: error=" & $iAnswerError & ", HRESULT=" & $iAnswerExtended)
		EndIf
	EndIf
	$g_iPending = 0
	$g_iPendingKind = -1
	GUISetState(@SW_HIDE, $g_hDialog)
	Return
EndFunc   ;==>_Example_Dialog_Answer

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_SmokeClick
; Description ...: Checks that the native pop-up is visible and clicks one of its buttons.
; Syntax ........: _Example_SmokeClick($idButton)
; Parameters ....: $idButton - Native AutoIt button control ID.
; Return values .: True after a successful click; False when the pop-up or message is missing.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The GUI event loop handles the button response on the next iteration.
; Related .......: _Example_Dialog_Show
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_SmokeClick($idButton)
	Local $bResult = False
	Do
		If Not BitAND(WinGetState($g_hDialog), 2) Then ExitLoop 1
		If GUICtrlRead($g_idDialogMessage) = "" Then ExitLoop 1
		If Not ControlClick($g_hDialog, "", $idButton) Then ExitLoop 1
		$bResult = True
	Until True
	Return $bResult
EndFunc   ;==>_Example_SmokeClick

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Trigger
; Description ...: Starts one local page button action without blocking on its dialog.
; Syntax ........: _Example_Trigger($sID)
; Parameters ....: $sID - Local button ID.
; Return values .: True when script execution completed; otherwise False with propagated @error.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The page schedules its dialog after the click handler returns.
; Related .......: _WebView2_ExecuteScript
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_Trigger($sID)
	_WebView2_ExecuteScript($g_iView, "document.getElementById('" & $sID & "').click(); true")
	Local $iError = @error, $iExtended = @extended
	Return SetError($iError, $iExtended, $iError = 0)
EndFunc   ;==>_Example_Trigger

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_OnDialog
; Description ...: Defers trusted local script dialogs to the AutoIt event loop.
; Syntax ........: _Example_OnDialog($iView, $sURI, $iKind, $sMessage, $sDefaultText)
; Parameters ....: Native dialog metadata.
; Return values .: DEFER for this example's origin; CANCEL for other origins.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This native callback must not show modal UI or call blocking WebView2 helpers.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_OnDialog($iView, $sURI, $iKind, $sMessage, $sDefaultText)
	#forceref $iKind, $sMessage, $sDefaultText
	Local $iDecision = $WEBVIEW2_SCRIPT_DIALOG_CANCEL
	If $iView = $g_iView And $sURI = $g_sOrigin & "index.html" Then $iDecision = $WEBVIEW2_SCRIPT_DIALOG_DEFER
	Return $iDecision
EndFunc   ;==>_Example_OnDialog

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_OnMessage
; Description ...: Receives completion results from the local page.
; Syntax ........: _Example_OnMessage($iView, $sMessage, $sSource, $bJSON)
; Parameters ....: Standard WebView2 message callback values.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Messages outside the mapped origin are ignored.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_OnMessage($iView, $sMessage, $sSource, $bJSON)
	If $iView <> $g_iView Or StringLeft($sSource, StringLen($g_sOrigin)) <> $g_sOrigin Then Return
	If Not $bJSON Then
		If $sSource = $g_sOrigin & "index.html" Then
			Switch $sMessage
				Case "EX_CLICK_TRUSTED:Open alert", "EX_CLICK_TRUSTED:Open confirm", "EX_CLICK_TRUSTED:Open prompt", "EX_CLICK_TRUSTED:Mark unsaved changes", "EX_CLICK_TRUSTED:Leave this page"
					Local $sCaption = StringTrimLeft($sMessage, StringLen("EX_CLICK_TRUSTED:"))
					Local $sClick = "[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [WebView2]: " & $sCaption & " was clicked."
					_GUICtrlEdit_AppendText($g_idLog, @CRLF & $sClick & @CRLF)
					GUICtrlSendMsg($g_idLog, $EM_SCROLLCARET, 0, 0)
					ConsoleWrite($sClick & @CRLF)
			EndSwitch
		EndIf
		Return
	EndIf
	If StringInStr($sMessage, '"type":"ready"') Then
		$g_bReady = True
		_Example_Status("Ready. Open a dialog in the page.")
	ElseIf StringInStr($sMessage, '"type":"result"') Then
		$g_sPageResult = $sMessage
		If StringInStr($sMessage, '"kind":"alert"') Then
			$g_iPageKind = $WEBVIEW2_SCRIPT_DIALOG_KIND_ALERT
		ElseIf StringInStr($sMessage, '"kind":"confirm"') Then
			$g_iPageKind = $WEBVIEW2_SCRIPT_DIALOG_KIND_CONFIRM
		ElseIf StringInStr($sMessage, '"kind":"prompt"') Then
			$g_iPageKind = $WEBVIEW2_SCRIPT_DIALOG_KIND_PROMPT
		EndIf
		_Example_Status("Page result: " & $sMessage)
	EndIf
	Return
EndFunc   ;==>_Example_OnMessage

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Status
; Description ...: Appends a timestamped status entry and keeps it visible.
; Syntax ........: _Example_Status($sText)
; Parameters ....: $sText - Status text.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_Status($sText)
	GUICtrlSetData($g_idStatus, $sText)
	_GUICtrlEdit_AppendText($g_idLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sText & @CRLF)
	GUICtrlSendMsg($g_idLog, $EM_SCROLLCARET, 0, 0)
	ConsoleWrite($sText & @CRLF)
	Return
EndFunc   ;==>_Example_Status
