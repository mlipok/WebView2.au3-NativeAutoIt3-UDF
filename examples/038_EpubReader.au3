#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_EX_hGUI = 0, $g_EX_idStatus = 0, $g_EX_iWebView = -1, $g_EX_bReady = False
Global $g_EX_bBookLoaded = False, $g_EX_bDisplayed = False

_Example()
Exit @error

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Opens a downloaded public EPUB in the locally hosted epubreader-js reader.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Internet access is required for the sample download; a local EPUB can be selected if it fails.
; Related .......: _WebView2_SetVirtualHostNameToFolderMapping
; Link ..........: https://github.com/intity/epubreader-js
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	Local $iError = 0, $iExtended = 0
	Local $bSmoke = $CmdLine[0] > 0 And $CmdLine[1] = "--smoke"
	Local Const $sSource = @ScriptDir & "\038_EpubReader"
	Local Const $sWork = @TempDir & "\WebView2_038_EpubReader_" & @AutoItPID
	Local Const $sBook = $sWork & "\book.epub"
	Local Const $sBookURL = "https://wolnelektury.pl/media/book/epub/laments-motto-and-dedication.epub"
	Do
		$g_EX_hGUI = GUICreate("WebView2 - EPUB reader", 1100, 720, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		$g_EX_idStatus = GUICtrlCreateLabel("Preparing the local EPUB reader...", 10, 10, 1060, 22)
		GUISetState(@SW_MAXIMIZE, $g_EX_hGUI)
		GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hGUI)
		If Not DirCreate($sWork) Or Not DirCopy($sSource & "\assets", $sWork & "\assets", 1) Or _
				Not DirCopy($sSource & "\dist", $sWork & "\dist", 1) Or Not FileCopy($sSource & "\index.html", $sWork & "\index.html", 1) Then
			$iError = 1
			GUICtrlSetData($g_EX_idStatus, "Could not prepare the local reader files.")
			ExitLoop 1
		EndIf
		GUICtrlSetData($g_EX_idStatus, "Downloading the sample EPUB from Wolne Lektury...")
		Local $iDownloaded = InetGet($sBookURL, $sBook, 1, 0)
		Local $iDownloadError = @error
		If $iDownloadError Or $iDownloaded < 100 Or FileGetSize($sBook) < 100 Then
			Local $sLocal = FileOpenDialog("Choose a local EPUB instead", @MyDocumentsDir, "EPUB books (*.epub)", 1, "", $g_EX_hGUI)
			If @error Or Not FileCopy($sLocal, $sBook, 1) Then
				$iError = 2
				GUICtrlSetData($g_EX_idStatus, "No sample EPUB is available.")
				ExitLoop 1
			EndIf
		EndIf
		GUICtrlSetData($g_EX_idStatus, "Starting WebView2...")
		If Not _WebView2_Init(Default, @LocalAppDataDir & "\WebView2.au3\Examples\038_EpubReader") Then
			$iError = @error
			$iExtended = @extended
			GUICtrlSetData($g_EX_idStatus, "WebView2 initialization failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		Local $aClient = WinGetClientSize($g_EX_hGUI)
		$g_EX_iWebView = _WebView2_Create($g_EX_hGUI, 0, 38, $aClient[0], $aClient[1] - 38)
		If @error Then
			$iError = @error
			$iExtended = @extended
			GUICtrlSetData($g_EX_idStatus, "WebView2 creation failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		If Not _WebView2_SetCallback($g_EX_iWebView, $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED, _OnReaderMessage) Then
			$iError = @error
			$iExtended = @extended
			GUICtrlSetData($g_EX_idStatus, "Reader message callback failed.")
			ExitLoop 1
		EndIf
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_EX_iWebView, "udf-virtual-host.example", $sWork) Then
			$iError = @error
			$iExtended = @extended
			GUICtrlSetData($g_EX_idStatus, "Local host mapping failed.")
			ExitLoop 1
		EndIf
		If Not _WebView2_Navigate($g_EX_iWebView, "https://udf-virtual-host.example/index.html?bookPath=book.epub") Then
			$iError = @error
			$iExtended = @extended
			GUICtrlSetData($g_EX_idStatus, "Reader navigation failed.")
			ExitLoop 1
		EndIf
		GUICtrlSetData($g_EX_idStatus, "Opening the EPUB. Use the reader toolbar to open another local book.")
		Local $hTimeout = TimerInit()
		While True
			If $bSmoke Then
				If $g_EX_bReady Then ExitLoop
				If TimerDiff($hTimeout) > 30000 Then
					$iError = 3
					ConsoleWrite("EPUB smoke timeout: bookloaded or displayed message missing." & @CRLF)
					ExitLoop
				EndIf
			EndIf
			Switch GUIGetMsg()
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					$aClient = WinGetClientSize($g_EX_hGUI)
					If IsArray($aClient) Then
						GUICtrlSetPos($g_EX_idStatus, 10, 10, $aClient[0] - 20, 22)
						_WebView2_SetBounds($g_EX_iWebView, 0, 38, $aClient[0], $aClient[1] - 38)
					EndIf
				Case $GUI_EVENT_CLOSE
					ExitLoop
			EndSwitch
			Sleep(20)
		WEnd
	Until True
	_WebView2_Cleanup()
	If $g_EX_hGUI Then GUIDelete($g_EX_hGUI)
	If StringLeft($sWork, StringLen(@TempDir & "\WebView2_038_EpubReader_")) = @TempDir & "\WebView2_038_EpubReader_" Then DirRemove($sWork, 1)
	Return SetError($iError, $iExtended, 0)
EndFunc   ;==>_Example

; #FUNCTION# ====================================================================================================================
; Name ..........: _OnReaderMessage
; Description ...: Reports reader metadata and loading status from the trusted local page.
; Syntax ........: _OnReaderMessage($iWebView, $sMessage, $sSource, $bJSON)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sMessage - Message sent by the reader page.
;                  $sSource - Address of the sending page.
;                  $bJSON - True for a JSON message.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Messages from any other origin are ignored.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnReaderMessage($iWebView, $sMessage, $sSource, $bJSON)
	#forceref $iWebView
	If Not $bJSON And StringLeft($sSource, StringLen("https://udf-virtual-host.example/")) = "https://udf-virtual-host.example/" Then
		If StringLeft($sMessage, 6) = "TITLE:" Then
			ConsoleWrite("EPUB title: " & StringTrimLeft($sMessage, 6) & @CRLF)
			GUICtrlSetData($g_EX_idStatus, "EPUB: " & StringTrimLeft($sMessage, 6))
		ElseIf $sMessage = "READY" Then
			$g_EX_bBookLoaded = True
		ElseIf $sMessage = "DISPLAYED" Then
			$g_EX_bDisplayed = True
		ElseIf StringLeft($sMessage, 6) = "ERROR:" Then
			GUICtrlSetData($g_EX_idStatus, "Reader error: " & StringTrimLeft($sMessage, 6))
		EndIf
		If $g_EX_bBookLoaded And $g_EX_bDisplayed And Not $g_EX_bReady Then
			$g_EX_bReady = True
			ConsoleWrite("EPUB loaded and displayed in WebView2." & @CRLF)
			GUICtrlSetData($g_EX_idStatus, "EPUB ready. Use the reader toolbar to open another local book.")
		EndIf
	EndIf
	Return
EndFunc   ;==>_OnReaderMessage
