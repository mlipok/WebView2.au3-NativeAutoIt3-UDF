; #WIP - Work in Progress
; PDF.js is bundled, but runtime navigation still needs confirmation in a working WebView2 session.
; The bundled PDF.js viewer and worker are the intended rendering path for local PDF files.
; Standalone functional copy/adaptation of the GitHub example by ioa747.
; Source: https://github.com/ioa747/NetWebView2Lib/blob/main/examples/014-pdfJS-Static_PDF_Viewer.au3
#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <FileConstants.au3>
#include <File.au3>
#include <MsgBoxConstants.au3>
#include "..\WebView2.au3"

Global $g_EX_hGUI = 0, $g_EX_iView = -1
Global $g_EX_idAddress = 0, $g_EX_idStatus = 0, $g_EX_sPage = "", $g_EX_sQueue = "", $g_EX_iSender = -1
Global $g_EX_bDone = False, $g_EX_bOK = False, $g_EX_sPath = ""
Global $g_EX_bSmoke = False, $g_EX_sViewer = ""

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
		$g_EX_hGUI = GUICreate("214-pdfJS-Static_PDF_Viewer", 1100, 800, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		If Not @Compiled Then GUISetIcon(@AutoItExe)
		Local $idBack = GUICtrlCreateButton("<", 5, 5, 30, 25), $idForward = GUICtrlCreateButton(">", 40, 5, 30, 25)
		Local $idReload = GUICtrlCreateButton("Reload", 75, 5, 70, 25), $idStop = GUICtrlCreateButton("Stop", 150, 5, 45, 25)
		$g_EX_idAddress = GUICtrlCreateInput("", 200, 5, 705, 25)
		Local $idGo = GUICtrlCreateButton("Go", 910, 5, 50, 25), $idOpen = GUICtrlCreateButton("Open PDF", 965, 5, 125, 25)
		Local $aLabels[3] = ["Title", "Zoom 100%", "DevTools"]
		Local $aAction[3]
		For $i = 0 To 2
			$aAction[$i] = GUICtrlCreateButton($aLabels[$i], 5 + $i * 175, 35, 170, 25)
			GUICtrlSetResizing(-1, $GUI_DOCKALL)
		Next
		$g_EX_idStatus = GUICtrlCreateEdit("", 5, 655, 1090, 135, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
		GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hGUI)
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\214-pdfJS-Static_PDF_Viewer"
		If $g_EX_bSmoke Then $sProfile = @TempDir & "\WebView2-Example-Profile-" & @AutoItPID
		_WebView2_SetDebugLevel($WEBVIEW2_DEBUG_ERROR)
		Local $sPreviousArgs = EnvGet("WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS")
		If Not StringInStr($sPreviousArgs, "--allow-file-access-from-files") Then _
				EnvSet("WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS", StringStripWS($sPreviousArgs & " --allow-file-access-from-files", 3))
		Local $bInitialized = _WebView2_Init(Default, $sProfile)
		If $sPreviousArgs = "" Then
			EnvSet("WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS")
		Else
			EnvSet("WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS", $sPreviousArgs)
		EndIf
		If Not $bInitialized Then ExitLoop
		$g_EX_iView = _WebView2_Create($g_EX_hGUI, 5, 65, 1090, 580)
		If @error Then ExitLoop
		_WebView2_SetCallback($g_EX_iView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _EX_Done)
		_WebView2_SetCallback($g_EX_iView, $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED, _EX_Message)
		$g_EX_sViewer = _EX_URI(@ScriptDir & "\assets\pdfjs\web\viewer.html")
		$g_EX_sPage = $g_EX_sViewer
		ConsoleWrite("PDFJS_VIEWER_URI=" & $g_EX_sPage & @CRLF)
		If Not _EX_Navigate($g_EX_iView, $g_EX_sPage) Then ExitLoop
		If Not _EX_Wait() Then ExitLoop
		GUICtrlSetData($g_EX_idAddress, $g_EX_sPage)
		_EX_Status("PDF.js viewer loaded. Open a PDF or use the bundled sample document.")
		If $g_EX_bSmoke Then
			If _EX_Check() Then
				ConsoleWrite("EX_SMOKE_OK example=214 arch=" & (@AutoItX64 ? "x64" : "x86") & @CRLF)
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
					Local $sAddress = GUICtrlRead($g_EX_idAddress)
					If StringRegExp($sAddress, "(?i)\.pdf(?:[?#].*)?$") Then $sAddress = $g_EX_sViewer & "?file=" & _EX_QueryValue($sAddress)
					_EX_Navigate($g_EX_iView, $sAddress)
				Case $idOpen
					If Not _EX_Open() Then _EX_Status(_WebView2_Error_GetDescription())
				Case $aAction[0], $aAction[1], $aAction[2]
					For $i = 0 To 2
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
			Sleep(10)
		WEnd
		$iExit = 0
	Until True
	If $iExit Then ConsoleWrite("EX_SMOKE_FAIL example=214 " & _WebView2_Error_GetDescription() & @CRLF)
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
	If Not $bOK Then ConsoleWrite("Navigation failure=" & $iError & " source=" & _WebView2_GetSource($iView) & @CRLF)
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
; Name ..........: _EX_QueryValue
; Description ...: Escapes a file URI for the PDF.js viewer's file query parameter.
; Syntax ........: _EX_QueryValue($sValue)
; Parameters ....: $sValue - File URI.
; Return values .: Escaped query value.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: The viewer decodes this value before loading the PDF.
; Related .......: _EX_URI
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _EX_QueryValue($sValue)
	Local $sEscaped = StringReplace($sValue, "%", "%25")
	$sEscaped = StringReplace($sEscaped, "&", "%26")
	$sEscaped = StringReplace($sEscaped, "+", "%2B")
	$sEscaped = StringReplace($sEscaped, "=", "%3D")
	Return $sEscaped
EndFunc   ;==>_EX_QueryValue


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
;                  |0 - Title.
;                  |1 - Zoom 100%.
;                  |2 - DevTools.
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
	Local $aScript[3] = ["document.title", "document.title", "document.title"]
	Switch $iAction
		Case 1
			$bOK = _WebView2_SetZoomFactor($g_EX_iView, 1.0)
		Case 2
			$bOK = _WebView2_OpenDevToolsWindow($g_EX_iView)
		Case Else
			$sResult = _WebView2_ExecuteScript($g_EX_iView, $aScript[$iAction])
			$bOK = (@error = 0)
			If $bOK Then _EX_Status($sResult)
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
	Local $sPath = FileOpenDialog("Open PDF", @MyDocumentsDir, "PDF files (*.pdf)", $FD_FILEMUSTEXIST, "", $g_EX_hGUI)
	If Not @error Then
		$g_EX_sPath = $sPath
		Local $sViewerURI = $g_EX_sViewer & "?file=" & _EX_QueryValue(_EX_URI($sPath))
		$bOK = _EX_Navigate($g_EX_iView, $sViewerURI)
		If $bOK Then GUICtrlSetData($g_EX_idAddress, $sViewerURI)
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
		Local $bReady = _WebView2_WaitScript($g_EX_iView, "Boolean(window.PDFViewerApplication && PDFViewerApplication.pdfDocument && PDFViewerApplication.pdfDocument.numPages > 0)", 30000, 100)
		If Not $bReady Then ExitLoop
		Local $sResult = _WebView2_ExecuteScript($g_EX_iView, "PDFViewerApplication.pdfDocument.numPages")
		If @error Or Number($sResult) < 1 Then ExitLoop

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
