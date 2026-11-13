; Standalone functional copy/adaptation of the GitHub example by ioa747.
; Source: https://github.com/ioa747/NetWebView2Lib/blob/main/examples/005-SaveDemo.au3
#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <FileConstants.au3>
#include <File.au3>
#include <MsgBoxConstants.au3>
#include "..\WebView2.au3"

Global $g_EX_hGUI = 0, $g_EX_iView = -1
Global $g_EX_idAddress = 0, $g_EX_idStatus = 0, $g_EX_idGuide = 0, $g_EX_sPage = "", $g_EX_sQueue = "", $g_EX_iSender = -1
Global $g_EX_bDone = False, $g_EX_bOK = False, $g_EX_sPath = ""
Global $g_EX_bSmoke = False

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
	If $CmdLine[0] > 0 Then $g_EX_bSmoke = ($CmdLine[1] = "--smoke")
	Do
		$g_EX_hGUI = GUICreate("205-SaveDemo", 1100, 800, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		Local $idBack = GUICtrlCreateButton("<", 5, 5, 30, 25), $idForward = GUICtrlCreateButton(">", 40, 5, 30, 25)
		Local $idReload = GUICtrlCreateButton("Reload", 75, 5, 70, 25), $idStop = GUICtrlCreateButton("Stop", 150, 5, 45, 25)
		$g_EX_idAddress = GUICtrlCreateInput("", 200, 5, 705, 25)
		Local $idGo = GUICtrlCreateButton("Go", 910, 5, 50, 25), $idOpen = GUICtrlCreateButton("Open file", 965, 5, 125, 25)
		Local $aLabels[3] = ["Save HTML", "PDF", "MHTML"]
		Local $aAction[3]
		For $i = 0 To 2
			$aAction[$i] = GUICtrlCreateButton($aLabels[$i], 5 + $i * 175, 35, 170, 25)
			GUICtrlSetResizing(-1, $GUI_DOCKALL)
		Next
		GUICtrlSetResizing($idBack, $GUI_DOCKALL)
		GUICtrlSetResizing($idForward, $GUI_DOCKALL)
		GUICtrlSetResizing($idReload, $GUI_DOCKALL)
		GUICtrlSetResizing($idStop, $GUI_DOCKALL)
		GUICtrlSetResizing($g_EX_idAddress, $GUI_DOCKALL)
		GUICtrlSetResizing($idGo, $GUI_DOCKALL)
		GUICtrlSetResizing($idOpen, $GUI_DOCKALL)
		$g_EX_idStatus = GUICtrlCreateEdit("", 5, 65, 290, 725, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idStatus, 0xE2F0E4)
		GUICtrlSetResizing(-1, $GUI_DOCKALL)
		Local $sGuide = "TEST PROCEDURE" & @CRLF & "1. Load a page; click Save HTML, PDF and MHTML in turn." & @CRLF & "EXPECTED RESULT" & @CRLF & "Check the log and the resulting files for each format." & @CRLF & "HOW IT WORKS" & @CRLF & "WebView2 exports page content through distinct native save and print APIs."
		$g_EX_idGuide = GUICtrlCreateEdit($sGuide, 305, 620, 790, 170, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
		GUICtrlSetBkColor(-1, 0xFFF4C2)
		GUICtrlSetResizing(-1, $GUI_DOCKALL)
		GUISetState(@SW_MAXIMIZE, $g_EX_hGUI)
		GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hGUI)
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\205-SaveDemo"
		If $g_EX_bSmoke Then $sProfile = @TempDir & "\WebView2-Example-Profile-" & @AutoItPID
		_WebView2_SetDebugLevel($WEBVIEW2_DEBUG_ERROR)
		If Not _WebView2_Init(Default, $sProfile) Then ExitLoop
		$g_EX_iView = _WebView2_Create($g_EX_hGUI, 305, 65, 790, 545)
		If @error Then ExitLoop
		_WebView2_SetCallback($g_EX_iView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _EX_Done)
		_WebView2_SetCallback($g_EX_iView, $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED, _EX_Message)
		$g_EX_sPage = _EX_URI(@ScriptDir & "\assets\native\205.html")
		If Not _EX_Navigate($g_EX_iView, $g_EX_sPage) Then ExitLoop
		If Not _EX_Wait() Then ExitLoop
		GUICtrlSetData($g_EX_idAddress, $g_EX_sPage)
		_EX_Status("Loaded example 205. Page messages are handled in the AutoIt loop.")
		If $g_EX_bSmoke Then
			If _EX_Check() Then
				ConsoleWrite("EX_SMOKE_OK example=205 arch=" & (@AutoItX64 ? "x64" : "x86") & @CRLF)
				$iExit = 0
			EndIf
			ExitLoop
		EndIf
		Local $aMaxSize = WinGetClientSize($g_EX_hGUI)
		If IsArray($aMaxSize) Then
			GUICtrlSetPos($g_EX_idStatus, 5, 65, 290, $aMaxSize[1] - 75)
			GUICtrlSetPos($g_EX_idGuide, 305, $aMaxSize[1] - 180, $aMaxSize[0] - 310, 170)
			_WebView2_SetBounds($g_EX_iView, 305, 65, $aMaxSize[0] - 310, $aMaxSize[1] - 255)
		EndIf
		Local $bClose = False
		While Not $bClose
			Local $iMessage = GUIGetMsg()
			Switch $iMessage
				Case $GUI_EVENT_CLOSE
					$bClose = True
				Case $idBack
					_EX_LogClick("<")
					_WebView2_GoBack($g_EX_iView)
				Case $idForward
					_EX_LogClick(">")
					_WebView2_GoForward($g_EX_iView)
				Case $idReload
					_EX_LogClick("Reload")
					_WebView2_Reload($g_EX_iView)
				Case $idStop
					_EX_LogClick("Stop")
					_WebView2_Stop($g_EX_iView)
				Case $idGo, $g_EX_idAddress
					If $iMessage = $idGo Then _EX_LogClick("Go")
					_EX_Navigate($g_EX_iView, GUICtrlRead($g_EX_idAddress))
				Case $idOpen
					_EX_LogClick("Open file")
					If Not _EX_Open() Then _EX_Status(_WebView2_Error_GetDescription())
				Case $aAction[0], $aAction[1], $aAction[2]
					For $i = 0 To 2
						If $iMessage = $aAction[$i] Then
							_EX_LogClick($aLabels[$i])
							If Not _EX_Action($i) Then _EX_Status(_WebView2_Error_GetDescription())
						EndIf
					Next
				Case $GUI_EVENT_RESIZED, $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE
					Local $aClient = WinGetClientSize($g_EX_hGUI)
					If IsArray($aClient) Then
						GUICtrlSetPos($g_EX_idStatus, 5, 65, 290, $aClient[1] - 75)
						GUICtrlSetPos($g_EX_idGuide, 305, $aClient[1] - 180, $aClient[0] - 310, 170)
						Local $iWidth = $aClient[0] - 310
						_WebView2_SetBounds($g_EX_iView, 305, 65, $iWidth, $aClient[1] - 255)
					EndIf
			EndSwitch
			If $g_EX_sQueue <> "" Then
				Local $sQueued = $g_EX_sQueue
				$g_EX_sQueue = ""
				_EX_Status("WebView " & $g_EX_iSender & ": " & $sQueued)
			EndIf
			Sleep(10)
		WEnd
		$iExit = 0
	Until True
	If $iExit Then ConsoleWrite("EX_SMOKE_FAIL example=205 " & _WebView2_Error_GetDescription() & @CRLF)
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
	If Not $bOK Then ConsoleWrite("Navigation failure=" & $iError & @CRLF)
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
; Name ..........: _EX_URI
; Description ...: Converts a Windows path to a local file URI.
; Syntax ........: _EX_URI($sPath)
; Parameters ....: $sPath - Absolute file or folder path.
; Return values .: URI with special path characters escaped.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; the public WebView2 API is unchanged.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _EX_URI($sPath)
	Local $sURI = "file:///" & StringReplace($sPath, "\", "/")
	$sURI = StringReplace($sURI, "%", "%25")
	$sURI = StringReplace($sURI, " ", "%20")
	$sURI = StringReplace($sURI, "#", "%23")
	$sURI = StringReplace($sURI, "?", "%3F")
	Return $sURI
EndFunc   ;==>_EX_URI


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


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _EX_LogClick
; Description ...: Starts a separate operation-log group for a manual button click.
; Syntax ........: _EX_LogClick($sCaption)
; Parameters ....: $sCaption - Exact caption of the clicked button.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Automated smoke actions do not use this helper.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _EX_LogClick($sCaption)
	_GUICtrlEdit_AppendText($g_EX_idStatus, @CRLF & "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] '" & $sCaption & "' was clicked." & @CRLF)
	GUICtrlSendMsg($g_EX_idStatus, $EM_SCROLLCARET, 0, 0)
	Return
EndFunc   ;==>_EX_LogClick

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
	_GUICtrlEdit_AppendText($g_EX_idStatus, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sText & @CRLF)
	GUICtrlSendMsg($g_EX_idStatus, $EM_SCROLLCARET, 0, 0)
	ConsoleWrite($sText & @CRLF)
	Return 0
EndFunc   ;==>_EX_Status


; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _EX_Action
; Description ...: Executes a feature-specific native toolbar action.
; Syntax ........: _EX_Action($iAction)
; Parameters ....: $iAction - One of the following local toolbar actions:
;                  |
;                  |0 - Save HTML.
;                  |1 - PDF.
;                  |2 - MHTML.
; Return values .: True when the action succeeds or the user cancels; False on an operation failure.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; the public WebView2 API is unchanged.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _EX_Action($iAction)
	Local $bOK = True, $sResult = ""
	Switch $iAction
		Case 0
			$sResult = _WebView2_GetHtmlSource($g_EX_iView)
			$bOK = (@error = 0)
			If $bOK Then $bOK = _EX_SaveText($sResult, "page.html")
		Case 1, 2
			Local $sExtension = $iAction = 1 ? "pdf" : "mhtml"
			Local $sPath = FileSaveDialog("Export " & $sExtension, @MyDocumentsDir, "Document (*." & $sExtension & ")", $FD_PROMPTOVERWRITE, "page." & $sExtension, $g_EX_hGUI)
			If Not @error Then
				If Not StringRegExp($sPath, '(?i)\.' & $sExtension & '$') Then $sPath &= "." & $sExtension
				If $iAction = 1 Then
					$bOK = _WebView2_ExportToPdfFile($g_EX_iView, $sPath)
				Else
					$bOK = _WebView2_ExportToMhtmlFile($g_EX_iView, $sPath)
				EndIf
				If $bOK Then _EX_Status("Saved: " & $sPath)
			EndIf
	EndSwitch
	Return $bOK
EndFunc   ;==>_EX_Action


; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _EX_Open
; Description ...: Opens a selected local file in the feature-specific viewer or editor.
; Syntax ........: _EX_Open()
; Parameters ....: None.
; Return values .: True on success or cancellation; False on failure.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; the public WebView2 API is unchanged.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _EX_Open()
	Local $bOK = True
	Local $sPath = FileOpenDialog("Open local document", @MyDocumentsDir, "Document (*.pdf;*.html;*.htm;*.png;*.jpg;*.svg;*.txt;*.csv;*.json)", $FD_FILEMUSTEXIST, "", $g_EX_hGUI)
	If Not @error Then
		$g_EX_sPath = $sPath
		$bOK = _EX_Navigate($g_EX_iView, _EX_URI($sPath))
		If $bOK Then GUICtrlSetData($g_EX_idAddress, _EX_URI($sPath))
	EndIf
	Return $bOK
EndFunc   ;==>_EX_Open


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
		Local $dPDF = _WebView2_ExportToPdfBinary($g_EX_iView)
		If @error Or BinaryToString(BinaryMid($dPDF, 1, 5)) <> "%PDF-" Then ExitLoop
		Local $dMHTML = _WebView2_ExportToMhtmlBinary($g_EX_iView)
		If @error Or Not StringInStr(BinaryToString($dMHTML, $SB_UTF8), "multipart/related") Then ExitLoop
		Local $dPNG = _WebView2_CapturePreviewBinary($g_EX_iView)
		If @error Or BinaryMid($dPNG, 1, 8) <> Binary("0x89504E470D0A1A0A") Then ExitLoop

		$sResult = _WebView2_ExecuteScript($g_EX_iView, "window.chrome.webview.postMessage('SMOKE_MESSAGE');true")
		If @error Then ExitLoop
		Local $hTimer = TimerInit()
		While $g_EX_sQueue <> "SMOKE_MESSAGE" And TimerDiff($hTimer) < 3000
			GUIGetMsg()
			Sleep(10)
		WEnd
		If $g_EX_sQueue <> "SMOKE_MESSAGE" Then ExitLoop
		$bOK = True
	Until True
	Return $bOK
EndFunc   ;==>_EX_Check


; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _EX_SaveText
; Description ...: Asks for a path and writes UTF-8 text without BOM.
; Syntax ........: _EX_SaveText($sText,$sName)
; Parameters ....: $sText - Text to save.
;                  $sName - Suggested filename.
; Return values .: True after saving or cancellation; False on file-write failure.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; the public WebView2 API is unchanged.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _EX_SaveText($sText, $sName)
	Local $bOK = True
	Local $sPath = FileSaveDialog("Save", @MyDocumentsDir, "All files (*.*)", $FD_PROMPTOVERWRITE, $sName, $g_EX_hGUI)
	If Not @error Then
		Local $hFile = FileOpen($sPath, BitOR($FO_OVERWRITE, $FO_UTF8_NOBOM))
		If $hFile = -1 Then
			$bOK = False
		Else
			$bOK = FileWrite($hFile, $sText) <> 0
			FileClose($hFile)
			If $bOK Then _EX_Status("Saved: " & $sPath)
		EndIf
	EndIf
	Return $bOK
EndFunc   ;==>_EX_SaveText
