; Standalone functional copy/adaptation of the GitHub example by ioa747.
; Source: https://github.com/ioa747/NetWebView2Lib/blob/main/examples/006-DownloadDemo.au3
#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <FileConstants.au3>
#include "..\WebView2.au3"

Global $g_EX_hGUI = 0, $g_EX_iView = -1
Global $g_EX_idAddress = 0, $g_EX_idStatus = 0, $g_EX_sPage = "", $g_EX_sQueue = "", $g_EX_iSender = -1
Global $g_EX_bDone = False, $g_EX_bOK = False
Global $g_EX_bSmoke = False
Global $g_EX_bSmokeDeny = False
Global $g_EX_bSmokeCancel = False, $g_EX_bCancelRequested = False
Global $g_EX_bSmokeRemote = False
Global Const $g_EX_sOrigin = "https://udf-virtual-host.example/"
Global Const $g_EX_sArchiveURL = "https://codeload.github.com/mlipok/WebView2.au3-NativeAutoIt3-UDF/zip/refs/heads/main"
Global $g_EX_iDownload = 0, $g_EX_iState = -1, $g_EX_iBytes = 0, $g_EX_iTotal = -1
Global $g_EX_iStartCount = 0, $g_EX_iDenied = 0, $g_EX_bDenyNext = False, $g_EX_sDownloadPath = ""
Global $g_EX_sDownloadEvent = ""

Exit _EX_Run()

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _EX_Run
; Description ...: Runs this standalone native example and its own GUI/message loop.
; Syntax ........: _EX_Run()
; Parameters ....: None.
; Return values .: 0 on normal close or successful smoke test; 1 on initialization or smoke failure.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; the public WebView2 API is unchanged.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _EX_Run()
	Local $iExit = 1
	If $CmdLine[0] > 0 Then
		$g_EX_bSmoke = ($CmdLine[1] = "--smoke" Or $CmdLine[1] = "--smoke-deny" Or $CmdLine[1] = "--smoke-cancel" Or $CmdLine[1] = "--smoke-remote")
		$g_EX_bSmokeDeny = ($CmdLine[1] = "--smoke-deny")
		$g_EX_bSmokeCancel = ($CmdLine[1] = "--smoke-cancel")
		$g_EX_bSmokeRemote = ($CmdLine[1] = "--smoke-remote")
	EndIf
	Do
		$g_EX_hGUI = GUICreate("206-DownloadDemo", 1100, 800, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		Local $idBack = GUICtrlCreateButton("<", 5, 5, 30, 25), $idForward = GUICtrlCreateButton(">", 40, 5, 30, 25)
		Local $idReload = GUICtrlCreateButton("Reload", 75, 5, 70, 25), $idStop = GUICtrlCreateButton("Stop", 150, 5, 45, 25)
		$g_EX_idAddress = GUICtrlCreateInput("", 200, 5, 830, 25)
		Local $idGo = GUICtrlCreateButton("Go", 1035, 5, 55, 25)
		Local $aLabels[4] = ["Download main ZIP", "Deny main ZIP", "Cancel current", "Reload"]
		Local $aAction[4]
		For $i = 0 To 3
			$aAction[$i] = GUICtrlCreateButton($aLabels[$i], 5 + $i * 175, 35, 170, 25)
			GUICtrlSetResizing(-1, $GUI_DOCKALL)
		Next
		$g_EX_idStatus = GUICtrlCreateEdit("", 5, 655, 1090, 135, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
		GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hGUI)
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\206-DownloadDemo"
		If $g_EX_bSmoke Then $sProfile = @TempDir & "\WebView2-Example-Profile-" & @AutoItPID
		_WebView2_SetDebugLevel($WEBVIEW2_DEBUG_ERROR)
		If Not _WebView2_Init(Default, $sProfile) Then ExitLoop
		$g_EX_iView = _WebView2_Create($g_EX_hGUI, 5, 65, 1090, 580)
		If @error Then ExitLoop
		_WebView2_SetCallback($g_EX_iView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _EX_Done)
		_WebView2_SetCallback($g_EX_iView, $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED, _EX_Message)
		If Not _WebView2_SetCallback($g_EX_iView, $WEBVIEW2_EVENT_PERMISSION_REQUESTED, _EX_Permission) Then ExitLoop
		If Not _WebView2_SetCallback($g_EX_iView, $WEBVIEW2_EVENT_DOWNLOAD_STARTING, _EX_DownloadStarting) Then ExitLoop
		If Not _WebView2_SetCallback($g_EX_iView, $WEBVIEW2_EVENT_DOWNLOAD_PROGRESS, _EX_DownloadProgress) Then ExitLoop
		If Not _WebView2_SetCallback($g_EX_iView, $WEBVIEW2_EVENT_DOWNLOAD_STATE_CHANGED, _EX_DownloadState) Then ExitLoop
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_EX_iView, "udf-virtual-host.example", @ScriptDir & "\assets\native") Then ExitLoop
		$g_EX_sPage = $g_EX_sOrigin & "206.html"
		If Not _EX_Navigate($g_EX_iView, $g_EX_sPage) Then ExitLoop
		If Not _EX_Wait() Then ExitLoop
		GUICtrlSetData($g_EX_idAddress, $g_EX_sPage)
		If $g_EX_bSmoke Then
			_EX_Status("Loaded example 206. Smoke downloads use a unique temporary file.")
		Else
			_EX_Status("Loaded example 206. The GitHub main ZIP will be saved under " & @MyDocumentsDir & "\WebView2 Downloads.")
		EndIf
		If $g_EX_bSmoke Then
			If _EX_Check() Then
				ConsoleWrite("EX_SMOKE_OK example=206 arch=" & (@AutoItX64 ? "x64" : "x86") & @CRLF)
				$iExit = 0
			EndIf
			ExitLoop
		EndIf
		GUISetState(@SW_SHOW, $g_EX_hGUI)
		Local $bClose = False
		While Not $bClose
			Local $iMessage = GUIGetMsg()
			Switch $iMessage
				Case $GUI_EVENT_CLOSE
					$bClose = True
				Case $idBack
					_WebView2_GoBack($g_EX_iView)
				Case $idForward
					_WebView2_GoForward($g_EX_iView)
				Case $idReload
					_WebView2_Reload($g_EX_iView)
				Case $idStop
					_WebView2_Stop($g_EX_iView)
				Case $idGo, $g_EX_idAddress
					_EX_Navigate($g_EX_iView, GUICtrlRead($g_EX_idAddress))
				Case $aAction[0], $aAction[1], $aAction[2], $aAction[3]
					For $i = 0 To 3
						If $iMessage = $aAction[$i] Then
							If Not _EX_Action($i) Then _EX_Status(_WebView2_Error_GetDescription())
						EndIf
					Next
				Case $GUI_EVENT_RESIZED, $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE
					Local $aClient = WinGetClientSize($g_EX_hGUI)
					If IsArray($aClient) Then
						GUICtrlSetPos($g_EX_idStatus, 5, $aClient[1] - 145, $aClient[0] - 10, 135)
						Local $iWidth = $aClient[0] - 10
						_WebView2_SetBounds($g_EX_iView, 5, 65, $iWidth, $aClient[1] - 220)
					EndIf
			EndSwitch
			If $g_EX_sQueue <> "" Then
				Local $sQueued = $g_EX_sQueue
				$g_EX_sQueue = ""
				_EX_Status("WebView " & $g_EX_iSender & ": " & $sQueued)
			EndIf
			If $g_EX_sDownloadEvent <> "" Then
				_EX_Status($g_EX_sDownloadEvent)
				$g_EX_sDownloadEvent = ""
			EndIf
			Sleep(10)
		WEnd
		$iExit = 0
	Until True
	If $iExit Then ConsoleWrite("EX_SMOKE_FAIL example=206 " & _WebView2_Error_GetDescription() & @CRLF)
	_WebView2_Cleanup()
	If $g_EX_hGUI Then GUIDelete($g_EX_hGUI)
	Return $iExit
EndFunc   ;==>_EX_Run


; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _EX_Wait
; Description ...: Waits for initial navigation while processing GUI messages.
; Syntax ........: _EX_Wait()
; Parameters ....: None.
; Return values .: True after successful navigation; False on failure or 30-second timeout.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; the public WebView2 API is unchanged.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _EX_Wait()
	Local $hTimer = TimerInit()
	While Not $g_EX_bDone And TimerDiff($hTimer) < 30000
		GUIGetMsg()
		Sleep(10)
	WEnd
	Return $g_EX_bDone And $g_EX_bOK
EndFunc   ;==>_EX_Wait


; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _EX_Done
; Description ...: Records navigation completion without synchronous browser calls.
; Syntax ........: _EX_Done($iView,$bOK,$iError,$iID)
; Parameters ....: $iView - WebView2 instance ID; unused.
;                  $bOK - True on successful navigation.
;                  $iError - Native navigation error status.
;                  $iID - Navigation ID; unused.
; Return values .: 0.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; the public WebView2 API is unchanged.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _EX_Done($iView, $bOK, $iError, $iID)
	#forceref $iView, $iID
	$g_EX_bDone = True
	$g_EX_bOK = $bOK
	If Not $bOK Then
		If $iError = 9 And $g_EX_iStartCount > 0 Then
			ConsoleWrite("Navigation ended when the response became a download." & @CRLF)
		Else
			ConsoleWrite("Navigation failure=" & $iError & @CRLF)
		EndIf
	EndIf
	Return 0
EndFunc   ;==>_EX_Done


; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _EX_Message
; Description ...: Queues a message only from the trusted local demo document.
; Syntax ........: _EX_Message($iView,$sMessage,$sSource,$bJSON)
; Parameters ....: $iView - Sender instance ID.
;                  $sMessage - Web message text.
;                  $sSource - Sender document URI.
;                  $bJSON - True for JSON messages; unused.
; Return values .: 0.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; the public WebView2 API is unchanged.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _EX_Message($iView, $sMessage, $sSource, $bJSON)
	#forceref $bJSON
	If $sSource = $g_EX_sPage Then
		$g_EX_sQueue = $sMessage
		$g_EX_iSender = $iView
	EndIf
	Return 0
EndFunc   ;==>_EX_Message


; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _EX_Navigate
; Description ...: Starts navigation and resets the completion flags.
; Syntax ........: _EX_Navigate($iView,$sURI)
; Parameters ....: $iView - Target instance ID.
;                  $sURI - Destination URI.
; Return values .: True when WebView2 accepted navigation; otherwise False.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; the public WebView2 API is unchanged.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _EX_Navigate($iView, $sURI)
	$g_EX_bDone = False
	$g_EX_bOK = False
	Return _WebView2_Navigate($iView, $sURI)
EndFunc   ;==>_EX_Navigate


; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _EX_Status
; Description ...: Updates the native status control and diagnostic console.
; Syntax ........: _EX_Status($sText)
; Parameters ....: $sText - Status text.
; Return values .: 0.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; the public WebView2 API is unchanged.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _EX_Status($sText)
	GUICtrlSetData($g_EX_idStatus, $sText & @CRLF & GUICtrlRead($g_EX_idStatus))
	ConsoleWrite($sText & @CRLF)
	Return 0
EndFunc   ;==>_EX_Status


; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _EX_Action
; Description ...: Executes a feature-specific native toolbar action.
; Syntax ........: _EX_Action($iAction)
; Parameters ....: $iAction - One of the following local toolbar actions:
;                  |
;                  |0 - Start an allowed download of the main-branch ZIP.
;                  |1 - Deny the next ZIP download and start it.
;                  |2 - Cancel the active download.
;                  |3 - Reload.
; Return values .: True when the action succeeds or the user cancels; False on an operation failure.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; the public WebView2 API is unchanged.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _EX_Action($iAction)
	Local $bOK = True
	Switch $iAction
		Case 0, 1
			$g_EX_bDenyNext = ($iAction = 1)
			$g_EX_iState = -1
			If $g_EX_bSmoke And Not $g_EX_bSmokeRemote Then
				_WebView2_ExecuteScript($g_EX_iView, "download();true")
			Else
				_WebView2_ExecuteScript($g_EX_iView, "downloadArchive();true")
			EndIf
			$bOK = (@error = 0)
		Case 2
			If $g_EX_iDownload Then
				$bOK = _WebView2_Download_Cancel($g_EX_iDownload)
			Else
				_EX_Status("No download has started yet.")
			EndIf
		Case 3
			$bOK = _WebView2_Reload($g_EX_iView)
	EndSwitch
	Return $bOK
EndFunc   ;==>_EX_Action

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _EX_DownloadStarting
; Description ...: Chooses a unique local path or denies the download before file creation.
; Syntax ........: _EX_DownloadStarting($iView, $iDownload, $sURI, $sSuggested, $sMime)
; Parameters ....: Native download callback fields.
; Return values .: Cancel policy or [path, hide default UI].
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Do not call blocking WebView2 methods from this callback.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _EX_DownloadStarting($iView, $iDownload, $sURI, $sSuggested, $sMime)
	#forceref $iView, $sSuggested
	$g_EX_iDownload = $iDownload
	$g_EX_iStartCount += 1
	If (Not $g_EX_bSmoke Or $g_EX_bSmokeRemote) And $sURI <> $g_EX_sArchiveURL Then
		$g_EX_sDownloadEvent = "Rejected unexpected download source: " & $sURI
		Return $WEBVIEW2_DOWNLOAD_CANCEL
	EndIf
	If $g_EX_bDenyNext Then
		$g_EX_bDenyNext = False
		$g_EX_iDenied += 1
		$g_EX_sDownloadEvent = "Denied download " & $iDownload & " from " & $sURI
		Return $WEBVIEW2_DOWNLOAD_CANCEL
	EndIf
	If $g_EX_bSmoke And Not $g_EX_bSmokeRemote Then
		$g_EX_sDownloadPath = @TempDir & "\WebView2-206-" & @AutoItPID & "-" & $iDownload & ".txt"
	ElseIf $g_EX_bSmokeRemote Then
		$g_EX_sDownloadPath = @TempDir & "\WebView2-main-" & @AutoItPID & "-" & $iDownload & ".zip"
	Else
		$g_EX_sDownloadPath = @MyDocumentsDir & "\WebView2 Downloads\WebView2-main-" & @AutoItPID & "-" & $iDownload & ".zip"
	EndIf
	$g_EX_sDownloadEvent = "Started download " & $iDownload & " (" & $sMime & ") to " & $g_EX_sDownloadPath
	If $g_EX_bSmokeCancel Then
		$g_EX_bCancelRequested = _WebView2_Download_Cancel($iDownload)
		Return Default
	EndIf
	Local $aPolicy[2] = [$g_EX_sDownloadPath, True]
	Return $aPolicy
EndFunc   ;==>_EX_DownloadStarting

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _EX_DownloadProgress
; Description ...: Collects native byte progress for the GUI loop.
; Syntax ........: _EX_DownloadProgress($iView, $iDownload, $iBytes, $iTotal)
; Parameters ....: Native download progress fields.
; Return values .: 0.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Total may be -1 when not known.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _EX_DownloadProgress($iView, $iDownload, $iBytes, $iTotal)
	#forceref $iView
	$g_EX_iBytes = $iBytes
	$g_EX_iTotal = $iTotal
	$g_EX_sDownloadEvent = "Download " & $iDownload & ": " & $iBytes & " / " & $iTotal & " bytes"
	Return 0
EndFunc   ;==>_EX_DownloadProgress

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _EX_DownloadState
; Description ...: Collects completion and interruption state for the GUI loop.
; Syntax ........: _EX_DownloadState($iView, $iDownload, $iState, $iReason)
; Parameters ....: Native download state fields.
; Return values .: 0.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: State 0=in progress, 1=interrupted, 2=completed.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _EX_DownloadState($iView, $iDownload, $iState, $iReason)
	#forceref $iView
	$g_EX_iState = $iState
	$g_EX_sDownloadEvent = "Download " & $iDownload & " state=" & $iState & " interrupt reason=" & $iReason
	Return 0
EndFunc   ;==>_EX_DownloadState

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _EX_Permission
; Description ...: Permits repeated automatic downloads only from the local demo page.
; Syntax ........: _EX_Permission($iView, $sURI, $iKind, $bUserInitiated)
; Parameters ....: Native permission callback fields.
; Return values .: Permission state.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Other permissions retain default Runtime handling.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _EX_Permission($iView, $sURI, $iKind, $bUserInitiated)
	#forceref $iView, $bUserInitiated
	If StringLeft(StringLower($sURI), StringLen($g_EX_sOrigin)) = $g_EX_sOrigin And $iKind = $WEBVIEW2_PERMISSION_KIND_MULTIPLE_AUTOMATIC_DOWNLOADS Then Return $WEBVIEW2_PERMISSION_STATE_ALLOW
	Return $WEBVIEW2_PERMISSION_STATE_DEFAULT
EndFunc   ;==>_EX_Permission


; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _EX_Check
; Description ...: Checks the feature-specific page API and native operations.
; Syntax ........: _EX_Check()
; Parameters ....: None.
; Return values .: True if all checks pass; False on failure.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; the public WebView2 API is unchanged.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _EX_Check()
	Local $bOK = False
	Do
		Local $sResult = _WebView2_ExecuteScript($g_EX_iView, "window.demoCheck()")
		If @error Or $sResult <> "true" Then ExitLoop

		$sResult = _WebView2_ExecuteScript($g_EX_iView, "window.chrome.webview.postMessage('SMOKE_MESSAGE');true")
		If @error Then ExitLoop
		Local $hTimer = TimerInit()
		While $g_EX_sQueue <> "SMOKE_MESSAGE" And TimerDiff($hTimer) < 3000
			GUIGetMsg()
			Sleep(10)
		WEnd
		If $g_EX_sQueue <> "SMOKE_MESSAGE" Then ExitLoop
		$g_EX_sQueue = ""
		ConsoleWrite("EX_SMOKE_STAGE message_ok" & @CRLF)
		If $g_EX_bSmokeDeny Then
			If Not _EX_Action(1) Then ExitLoop
			$hTimer = TimerInit()
			While $g_EX_iDenied < 1 And TimerDiff($hTimer) < 5000
				GUIGetMsg()
				Sleep(10)
			WEnd
			ConsoleWrite("EX_SMOKE_STAGE denied=" & $g_EX_iDenied & " starts=" & $g_EX_iStartCount & @CRLF)
			If $g_EX_iDenied <> 1 Or $g_EX_sDownloadPath <> "" Then ExitLoop
			$bOK = True
			ExitLoop
		EndIf
		If $g_EX_bSmokeCancel Then
			If Not _EX_Action(0) Then ExitLoop
			$hTimer = TimerInit()
			While $g_EX_iState <> $WEBVIEW2_DOWNLOAD_STATE_INTERRUPTED And TimerDiff($hTimer) < 5000
				GUIGetMsg()
				Sleep(10)
			WEnd
			ConsoleWrite("EX_SMOKE_STAGE cancel=" & $g_EX_bCancelRequested & " state=" & $g_EX_iState & @CRLF)
			If Not $g_EX_bCancelRequested Or $g_EX_iState <> $WEBVIEW2_DOWNLOAD_STATE_INTERRUPTED Then ExitLoop
			$bOK = True
			ExitLoop
		EndIf
		If Not _EX_Action(0) Then ExitLoop
		ConsoleWrite("EX_SMOKE_STAGE download_requested" & @CRLF)
		$hTimer = TimerInit()
		While $g_EX_iState <> $WEBVIEW2_DOWNLOAD_STATE_COMPLETED And TimerDiff($hTimer) < 15000
			GUIGetMsg()
			Sleep(10)
		WEnd
		ConsoleWrite("EX_SMOKE_STAGE state=" & $g_EX_iState & " starts=" & $g_EX_iStartCount & " bytes=" & $g_EX_iBytes & " path=" & $g_EX_sDownloadPath & @CRLF)
		If $g_EX_iState <> $WEBVIEW2_DOWNLOAD_STATE_COMPLETED Or Not FileExists($g_EX_sDownloadPath) Then ExitLoop
		Local $aInfo = _WebView2_Download_GetInfo($g_EX_iDownload)
		ConsoleWrite("EX_SMOKE_STAGE info_error=" & @error & " info_state=" & $aInfo[5] & " info_bytes=" & $aInfo[3] & @CRLF)
		If @error Or $aInfo[5] <> $WEBVIEW2_DOWNLOAD_STATE_COMPLETED Or $aInfo[3] <= 0 Then ExitLoop
		Local $aDownloads = _WebView2_Download_List($g_EX_iView)
		ConsoleWrite("EX_SMOKE_STAGE list_error=" & @error & " count=" & UBound($aDownloads) & @CRLF)
		If @error Or UBound($aDownloads) < 1 Then ExitLoop
		If $g_EX_bSmokeRemote Then
			Local $hArchive = FileOpen($g_EX_sDownloadPath, $FO_BINARY)
			If $hArchive = -1 Then ExitLoop
			Local $bSignature = FileRead($hArchive, 4)
			FileClose($hArchive)
			If $bSignature <> Binary("0x504B0304") Then ExitLoop
			$bOK = True
			ExitLoop
		EndIf
		If Not _EX_Action(1) Then ExitLoop
		$hTimer = TimerInit()
		While $g_EX_iDenied < 1 And TimerDiff($hTimer) < 5000
			GUIGetMsg()
			Sleep(10)
		WEnd
		ConsoleWrite("EX_SMOKE_STAGE repeated_denied=" & $g_EX_iDenied & @CRLF)
		If $g_EX_iDenied <> 1 Then ExitLoop
		$bOK = True
	Until True
	Return $bOK
EndFunc   ;==>_EX_Check
