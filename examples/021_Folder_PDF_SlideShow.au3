#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <File.au3>
#include <FileConstants.au3>
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <WindowsConstants.au3>

#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

; "Fit" fits the whole page; change to "FitH" to fit the page width.
;~ Global Const $PDF_VIEW_MODE = "Fit"
Global Const $PDF_VIEW_MODE = "FitH"
Global Const $PDF_NAVIGATION_TIMEOUT_MS = 15000
Global Const $PDF_FIRST_PAINT_WAIT_MS = 200
Global Const $PDF_SLIDE_DURATION_MS = 2000
Global Const $PDF_GUI_POLL_MS = 10
Global $g_bNavigationDone = False
Global $g_bNavigationSuccess = False

_Example()

; Displays each PDF in a selected folder for two seconds.
; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Runs the Folder PDF SlideShow example.
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
		Local $sFolder = FileSelectFolder("Choose folder with PDF files", @ScriptDir, 0, @MyDocumentsDir)
		If @error Or $sFolder = "" Then
			$__WebView2ExitValue = 0
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $aFiles = _FileListToArray($sFolder, "*.pdf", $FLTA_FILES, True)
		If @error Or Not IsArray($aFiles) Then
			MsgBox($MB_ICONINFORMATION, "PDF slideshow", "No PDF files found or the folder cannot be read.")
			$__WebView2ExitValue = 0
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $hGUI = GUICreate("WebView2 PDF slideshow", @DesktopWidth - 100, @DesktopHeight - 100, 50, 0, $WS_OVERLAPPEDWINDOW)
		GUISetBkColor(0xFFFFFF, $hGUI)
		GUISetState(@SW_SHOW, $hGUI)

		If Not _WebView2_Init() Then
			MsgBox($MB_ICONERROR, "PDF slideshow", _WebView2_Error_GetDescription())
			GUIDelete($hGUI)
			$__WebView2ExitValue = 0
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $iWebView = _WebView2_Create($hGUI)
		If @error Then
			MsgBox($MB_ICONERROR, "PDF slideshow", _WebView2_Error_GetDescription())
			_WebView2_Cleanup()
			GUIDelete($hGUI)
			$__WebView2ExitValue = 0
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		_WebView2_SetCallback($iWebView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _SlideShow_NavigationCompleted)

		For $i = 1 To $aFiles[0]
			WinSetTitle($hGUI, "", "WebView2 PDF slideshow - " & $i & "/" & $aFiles[0] & " - " & $aFiles[$i])
			$g_bNavigationDone = False
			$g_bNavigationSuccess = False
			_WebView2_SetVisible($iWebView, False)
			If Not _WebView2_Navigate($iWebView, _FileUri($aFiles[$i]) & "#toolbar=0&view=" & $PDF_VIEW_MODE) Then
				MsgBox($MB_ICONERROR, "PDF slideshow", $aFiles[$i] & @CRLF & _WebView2_Error_GetDescription())
				ExitLoop
			EndIf

			Local $hLoadTimer = TimerInit()
			While Not $g_bNavigationDone And TimerDiff($hLoadTimer) < $PDF_NAVIGATION_TIMEOUT_MS
				If Not _SlideShow_PumpMessages($iWebView) Then ExitLoop 2
			WEnd
			If Not $g_bNavigationDone Or Not $g_bNavigationSuccess Then
				MsgBox($MB_ICONERROR, "PDF slideshow", "Could not load: " & $aFiles[$i])
				ExitLoop
			EndIf

			; NavigationCompleted may precede the PDF viewer's first paint.
			Local $hPaintTimer = TimerInit()
			While TimerDiff($hPaintTimer) < $PDF_FIRST_PAINT_WAIT_MS
				If Not _SlideShow_PumpMessages($iWebView) Then ExitLoop 2
			WEnd
			_WebView2_SetVisible($iWebView, True)

			Local $hTimer = TimerInit()
			While TimerDiff($hTimer) < $PDF_SLIDE_DURATION_MS
				If Not _SlideShow_PumpMessages($iWebView) Then ExitLoop 2
			WEnd
		Next

		_WebView2_Cleanup()
		GUIDelete($hGUI)
	Until True
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_Example

; #FUNCTION# ====================================================================================================================
; Name ..........: _SlideShow_NavigationCompleted
; Description ...: Records the outcome of a PDF navigation event.
; Syntax ........: _SlideShow_NavigationCompleted($iWebView, $bSuccess, $iWebErrorStatus, $iNavigationId)
; Parameters ....: $iWebView - WebView instance ID.
;                  $bSuccess - Whether WebView2 completed navigation successfully.
;                  $iWebErrorStatus - WebView2 navigation error status.
;                  $iNavigationId - Navigation identifier supplied by WebView2.
; Return values .: No value; updates the navigation state.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _SlideShow_NavigationCompleted($iWebView, $bSuccess, $iWebErrorStatus, $iNavigationId)
	#forceref $iWebView, $iWebErrorStatus, $iNavigationId
	$g_bNavigationSuccess = $bSuccess
	$g_bNavigationDone = True
	Return
EndFunc   ;==>_SlideShow_NavigationCompleted

; #FUNCTION# ====================================================================================================================
; Name ..........: _SlideShow_PumpMessages
; Description ...: Processes GUI messages while the slide show waits.
; Syntax ........: _SlideShow_PumpMessages($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: Boolean indicating whether to continue.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _SlideShow_PumpMessages($iWebView)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Do
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				$__WebView2ExitValue = False
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
				_WebView2_ResizeToParent($iWebView)
		EndSwitch
		Sleep($PDF_GUI_POLL_MS)
		$__WebView2ExitValue = True
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_SlideShow_PumpMessages

; Percent-encode a Windows path as a UTF-8 file URI.
; #FUNCTION# ====================================================================================================================
; Name ..........: _FileUri
; Description ...: Percent-encodes a Windows path as a UTF-8 file URI.
; Syntax ........: _FileUri($sPath)
; Parameters ....: $sPath - Absolute Windows file path.
; Return values .: UTF-8 percent-encoded file URI.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _FileUri($sPath)
	Local $sNormalized = StringReplace($sPath, "\", "/")
	Local $bUTF8 = StringToBinary($sNormalized, 4)
	Local $sURI = "file:///"
	For $i = 1 To BinaryLen($bUTF8)
		Local $sByte = Hex(BinaryMid($bUTF8, $i, 1), 2)
		Local $iByte = Dec($sByte)
		If ($iByte >= 48 And $iByte <= 57) Or ($iByte >= 65 And $iByte <= 90) Or ($iByte >= 97 And $iByte <= 122) _
				Or $iByte = 45 Or $iByte = 46 Or $iByte = 47 Or $iByte = 58 Or $iByte = 95 Or $iByte = 126 Then
			$sURI &= Chr($iByte)
		Else
			$sURI &= "%" & $sByte
		EndIf
	Next
	Return $sURI
EndFunc   ;==>_FileUri
