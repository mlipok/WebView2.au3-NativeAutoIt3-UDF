#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
; Functional copy/adaptation of the GitHub Markdown example by ioa747.
; Source: https://github.com/ioa747/NetWebView2Lib/blob/main/examples/019-MarkdownViewer.au3
; Uses the local MIT-licensed marked library; no .NET bridge is required.
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <StaticConstants.au3>
#include <GuiEdit.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <Math.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)
Global $g_hMD = 0, $g_idMDEdit = 0, $g_idMDSplit = 0, $g_idMDStatus = 0, $g_iMDView = -1
Global $g_sMDPath = "", $g_sMDSaved = "", $g_sMDRendered = "", $g_sMDLink = "", $g_sMDShell = ""
Global $g_bMDPending = False, $g_bMDResize = False, $g_bMDDragging = False, $g_bMDReady = False
Global $g_bMDNavigationDone = False, $g_bMDNavigationOK = False
Global $g_hMDTimer = 0, $g_fMDRatio = 0.5, $g_fMDZoom = 1.0, $g_iMDFont = 11
Global $g_aMDButtons[19]
Global $g_bMDSmoke = False
If $CmdLine[0] > 0 Then $g_bMDSmoke = ($CmdLine[1] = "--smoke")

Exit _MD_Main()

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _MD_Main
; Description ...: Runs the native Markdown editor and live preview.
; Syntax ........: _MD_Main()
; Parameters ....: None.
; Return values .: 0 on normal close or successful smoke test; 1 on initialization/test failure.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; does not modify the public UDF API.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _MD_Main()
	Local $iResult = 0
	Do
		$g_hMD = GUICreate("219 - Markdown Viewer", 1200, 820, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		If Not @Compiled Then GUISetIcon(@AutoItExe)
		Local $aLabels[19] = ["New", "Open", "Save", "Save as", "B", "I", "U", "Code", "List", "A-", "A+", "Editor", "Both", "Preview", "HTML", "-", "+", "PDF", "MHTML"]
		Local $iX = 5
		For $i = 0 To UBound($aLabels) - 1
			Local $iWidth = 45
			If $i < 4 Or $i >= 17 Then $iWidth = 80
			If $i >= 11 And $i <= 13 Then $iWidth = 70
			$g_aMDButtons[$i] = GUICtrlCreateButton($aLabels[$i], $iX, 5, $iWidth, 28)
			GUICtrlSetResizing(-1, $GUI_DOCKALL)
			$iX += $iWidth + 2
		Next
		$g_idMDEdit = GUICtrlCreateEdit("", 5, 40, 590, 750, BitOR($ES_MULTILINE, $ES_WANTRETURN, $WS_VSCROLL, $WS_HSCROLL))
		GUICtrlSetFont(-1, $g_iMDFont, 400, 0, "Consolas")
		GUICtrlSetResizing(-1, $GUI_DOCKALL)
		$g_idMDSplit = GUICtrlCreateLabel("", 598, 40, 8, 750, $SS_NOTIFY)
		GUICtrlSetBkColor(-1, 0xA0A0A0)
		GUICtrlSetCursor(-1, 13)
		GUICtrlSetResizing(-1, $GUI_DOCKALL)
		$g_idMDStatus = GUICtrlCreateLabel("", 5, 795, 1190, 20)
		GUICtrlSetResizing(-1, $GUI_DOCKALL)
		GUIRegisterMsg($WM_COMMAND, _MD_Command)
		GUIRegisterMsg($WM_SIZE, _MD_Size)
		_WebView2_SetDebugLevel($WEBVIEW2_DEBUG_ERROR)
		GUISetState(@SW_SHOWNOACTIVATE, $g_hMD)
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\MarkdownViewer"
		If $g_bMDSmoke Then $sProfile = @TempDir & "\WebView2-Markdown-Profile-" & @AutoItPID
		If Not _WebView2_Init(Default, $sProfile) Then
			_MD_Error("Init")
			$iResult = 1
			ExitLoop
		EndIf
		$g_iMDView = _WebView2_Create($g_hMD, 608, 40, 587, 750)
		If @error Then
			_MD_Error("Create")
			$iResult = 1
			ExitLoop
		EndIf
		_WebView2_SetCallback($g_iMDView, $WEBVIEW2_EVENT_NAVIGATION_STARTING, _MD_Navigation)
		_WebView2_SetCallback($g_iMDView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _MD_NavigationDone)
		$g_sMDShell = _MD_FileUri(@TempDir & "\WebView2-Markdown-" & @AutoItPID & "\viewer.html")
		If Not FileExists(@ScriptDir & "\JS_Lib\marked\marked.umd.js") Then
			_MD_Error("Missing JS_Lib\marked\marked.umd.js")
			$iResult = 1
			ExitLoop
		EndIf
		Local $sShell = FileRead(@ScriptDir & "\assets\markdown\viewer.html")
		$sShell = StringReplace($sShell, "{{STYLE}}", FileRead(@ScriptDir & "\assets\markdown\viewer.css"))
		$sShell = StringReplace($sShell, "{{MARKED}}", StringReplace(FileRead(@ScriptDir & "\JS_Lib\marked\marked.umd.js"), "</script", "<\/script"))
		$sShell = StringReplace($sShell, "{{VIEWER}}", FileRead(@ScriptDir & "\assets\markdown\viewer.js"))
		DirCreate(@TempDir & "\WebView2-Markdown-" & @AutoItPID)
		Local $hShell = FileOpen(@TempDir & "\WebView2-Markdown-" & @AutoItPID & "\viewer.html", BitOR($FO_OVERWRITE, $FO_UTF8_NOBOM))
		If $hShell = -1 Then
			_MD_Error("Could not save the preview page")
			$iResult = 1
			ExitLoop
		EndIf
		Local $bShellSaved = FileWrite($hShell, $sShell)
		FileClose($hShell)
		If Not $bShellSaved Then
			_MD_Error("Preview page save")
			$iResult = 1
			ExitLoop
		EndIf
		If Not _WebView2_Navigate($g_iMDView, $g_sMDShell) Then
			_MD_Error("Navigate")
			$iResult = 1
			ExitLoop
		EndIf
		If Not _MD_WaitNavigation() Then
			_MD_Error("LoadWait")
			$iResult = 1
			ExitLoop
		EndIf
		Local $sReady = _WebView2_ExecuteScript($g_iMDView, "typeof window.updateView === 'function' && typeof marked === 'object'")
		If @error Or $sReady <> "true" Then
			_MD_Error("The Markdown library did not load")
			$iResult = 1
			ExitLoop
		EndIf
		$g_bMDReady = True
		Local $hSample = FileOpen(@ScriptDir & "\assets\markdown\sample.md", BitOR($FO_READ, $FO_UTF8))
		If $hSample = -1 Then
			_MD_Error("The Markdown sample could not be opened")
			$iResult = 1
			ExitLoop
		EndIf
		Local $sDemo = FileRead($hSample)
		Local $iReadError = @error
		FileClose($hSample)
		If $iReadError Then
			_MD_Error("The Markdown sample could not be read")
			$iResult = 1
			ExitLoop
		EndIf
		GUICtrlSetData($g_idMDEdit, $sDemo)
		$g_sMDSaved = $sDemo
		If $CmdLine[0] > 0 And Not $g_bMDSmoke Then _MD_OpenPath($CmdLine[1])
		If Not _MD_Render() Then
			$iResult = 1
			ExitLoop
		EndIf
		_MD_Layout()
		If $g_bMDSmoke Then
			$iResult = _MD_Smoke()
			ExitLoop
		EndIf
		GUISetState(@SW_SHOW, $g_hMD)
		Local $bClose = False
		While Not $bClose
			Local $iMsg = GUIGetMsg()
			Switch $iMsg
				Case $GUI_EVENT_CLOSE
					$bClose = _MD_CanDiscard()
				Case $g_aMDButtons[0]
					If _MD_CanDiscard() Then
						$g_sMDPath = ""
						GUICtrlSetData($g_idMDEdit, "")
						$g_sMDSaved = ""
					EndIf
				Case $g_aMDButtons[1]
					If _MD_CanDiscard() Then
						Local $sOpen = FileOpenDialog("Open Markdown", @MyDocumentsDir, "Markdown (*.md;*.markdown;*.txt)|All files (*.*)", $FD_FILEMUSTEXIST, "", $g_hMD)
						If Not @error Then _MD_OpenPath($sOpen)
					EndIf
				Case $g_aMDButtons[2], $g_aMDButtons[3]
					_MD_Save($iMsg = $g_aMDButtons[3])
				Case $g_aMDButtons[4]
					_MD_Wrap("**", "**")
				Case $g_aMDButtons[5]
					_MD_Wrap("*", "*")
				Case $g_aMDButtons[6]
					_MD_Wrap("<u>", "</u>")
				Case $g_aMDButtons[7]
					_MD_Wrap("`", "`")
				Case $g_aMDButtons[8]
					_MD_Wrap("- ", "")
				Case $g_aMDButtons[9], $g_aMDButtons[10]
					$g_iMDFont += ($iMsg = $g_aMDButtons[10]) ? 1 : -1
					$g_iMDFont = _Max(8, _Min(24, $g_iMDFont))
					GUICtrlSetFont($g_idMDEdit, $g_iMDFont, 400, 0, "Consolas")
				Case $g_aMDButtons[11], $g_aMDButtons[12], $g_aMDButtons[13]
					$g_fMDRatio = 0.5
					If $iMsg = $g_aMDButtons[11] Then $g_fMDRatio = 0.98
					If $iMsg = $g_aMDButtons[13] Then $g_fMDRatio = 0.02
					$g_bMDResize = True
				Case $g_aMDButtons[14]
					Local $sHTML = _WebView2_ExecuteScript($g_iMDView, "document.getElementById('view').innerHTML")
					If Not @error Then ClipPut(_WebView2_JSONStringDecode($sHTML))
				Case $g_aMDButtons[15], $g_aMDButtons[16]
					$g_fMDZoom += ($iMsg = $g_aMDButtons[16]) ? 0.1 : -0.1
					$g_fMDZoom = _Max(0.5, _Min(2.0, $g_fMDZoom))
					_WebView2_SetZoomFactor($g_iMDView, $g_fMDZoom)
				Case $g_aMDButtons[17], $g_aMDButtons[18]
					_MD_Export($iMsg = $g_aMDButtons[17])
				Case $GUI_EVENT_PRIMARYDOWN
					Local $aCursor = GUIGetCursorInfo($g_hMD)
					If IsArray($aCursor) Then $g_bMDDragging = ($aCursor[4] = $g_idMDSplit)
				Case $GUI_EVENT_PRIMARYUP
					$g_bMDDragging = False
			EndSwitch
			If $g_bMDDragging Then
				Local $aDrag = GUIGetCursorInfo($g_hMD), $aClient = WinGetClientSize($g_hMD)
				If IsArray($aDrag) And IsArray($aClient) Then
					If $aDrag[2] Then
						$g_fMDRatio = _Max(0.05, _Min(0.95, $aDrag[0] / $aClient[0]))
						$g_bMDResize = True
					Else
						$g_bMDDragging = False
					EndIf
				EndIf
			EndIf
			If $g_bMDResize Then _MD_Layout()
			If $g_bMDPending And TimerDiff($g_hMDTimer) >= 250 Then _MD_Render()
			If $g_sMDLink <> "" Then
				ShellExecute($g_sMDLink)
				$g_sMDLink = ""
			EndIf
			Sleep(10)
		WEnd
	Until True
	GUIRegisterMsg($WM_COMMAND, "")
	GUIRegisterMsg($WM_SIZE, "")
	_WebView2_Cleanup()
	If $g_hMD Then GUIDelete($g_hMD)
	Return $iResult
EndFunc   ;==>_MD_Main

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _MD_Render
; Description ...: Renders editor text without navigating or reloading the preview.
; Syntax ........: _MD_Render()
; Parameters ....: None.
; Return values .: True after rendering; False if the preview is unavailable or script execution fails.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; does not modify the public UDF API.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _MD_Render()
	Local $bResult = False
	If $g_bMDReady Then
		Local $sText = GUICtrlRead($g_idMDEdit), $sBase = @ScriptDir & "\"
		If $g_sMDPath <> "" Then $sBase = StringLeft($g_sMDPath, StringInStr($g_sMDPath, "\", 0, -1))
		Local $sJS = "window.updateView(" & __WebView2_JavaScript_StringLiteral($sText) & "," & __WebView2_JavaScript_StringLiteral(_MD_FileUri($sBase)) & ")"
		Local $sResult = _WebView2_ExecuteScript($g_iMDView, $sJS)
		If Not @error And $sResult = "true" Then
			$g_sMDRendered = $sText
			$g_bMDPending = False
			$bResult = True
			Local $sDirty = ($sText = $g_sMDSaved) ? "" : " *"
			WinSetTitle($g_hMD, "", "219 - Markdown Viewer" & $sDirty & " - " & ($g_sMDPath = "" ? "New document" : $g_sMDPath))
			GUICtrlSetData($g_idMDStatus, ($g_sMDPath = "" ? "New document" : $g_sMDPath) & $sDirty)
		Else
			_MD_Error("Render")
		EndIf
	EndIf
	Return $bResult
EndFunc   ;==>_MD_Render

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _MD_NavigationDone
; Description ...: Stores initial navigation completion without running browser commands in the callback.
; Syntax ........: _MD_NavigationDone($iWebView, $bSuccess, $iWebErrorStatus, $iNavigationId)
; Parameters ....: $iWebView - WebView2 instance ID; unused.
;                  $bSuccess - True when navigation completed successfully.
;                  $iWebErrorStatus - Native navigation error status; unused.
;                  $iNavigationId - Native navigation ID; unused.
; Return values .: 0.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; does not modify the public UDF API.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _MD_NavigationDone($iWebView, $bSuccess, $iWebErrorStatus, $iNavigationId)
	#forceref $iWebView, $iWebErrorStatus, $iNavigationId
	$g_bMDNavigationOK = $bSuccess
	$g_bMDNavigationDone = True
	Return 0
EndFunc   ;==>_MD_NavigationDone

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _MD_WaitNavigation
; Description ...: Waits up to 30 seconds for successful initial navigation while processing GUI messages.
; Syntax ........: _MD_WaitNavigation()
; Parameters ....: None.
; Return values .: True after successful navigation; False on timeout or navigation failure.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; does not modify the public UDF API.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _MD_WaitNavigation()
	Local $hTimer = TimerInit()
	While Not $g_bMDNavigationDone And TimerDiff($hTimer) < 30000
		GUIGetMsg()
		Sleep(10)
	WEnd
	Return $g_bMDNavigationDone And $g_bMDNavigationOK
EndFunc   ;==>_MD_WaitNavigation

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _MD_OpenPath
; Description ...: Loads a Markdown file and sets its relative-resource base folder.
; Syntax ........: _MD_OpenPath($sPath)
; Parameters ....: $sPath - Full path to the Markdown text file.
; Return values .: True on success; False on file-read failure.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; does not modify the public UDF API.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _MD_OpenPath($sPath)
	Local $bResult = False
	Local $sText = FileRead($sPath)
	If @error Then
		_MD_Error("Could not read: " & $sPath)
	Else
		$g_sMDPath = $sPath
		$g_sMDSaved = $sText
		GUICtrlSetData($g_idMDEdit, $sText)
		$g_bMDPending = True
		$g_hMDTimer = TimerInit()
		$bResult = True
	EndIf
	Return $bResult
EndFunc   ;==>_MD_OpenPath

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _MD_Save
; Description ...: Writes Markdown as UTF-8 without BOM; optionally asks for a new path.
; Syntax ........: _MD_Save($bSaveAs = False)
; Parameters ....: $bSaveAs - True asks for a filename; False uses the current path when available. Default is False.
; Return values .: True after saving; False on cancellation or file error.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; does not modify the public UDF API.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _MD_Save($bSaveAs = False)
	Local $bResult = False, $sPath = $g_sMDPath
	If $bSaveAs Or $sPath = "" Then
		$sPath = FileSaveDialog("Save Markdown", @MyDocumentsDir, "Markdown (*.md)", $FD_PROMPTOVERWRITE, "document.md", $g_hMD)
		If @error Then $sPath = ""
		If $sPath <> "" And Not StringRegExp($sPath, '(?i)\.(md|markdown|txt)$') Then $sPath &= ".md"
	EndIf
	If $sPath <> "" Then
		Local $hFile = FileOpen($sPath, BitOR($FO_OVERWRITE, $FO_UTF8_NOBOM))
		If $hFile = -1 Then
			_MD_Error("Could not save: " & $sPath)
		Else
			Local $sText = GUICtrlRead($g_idMDEdit)
			$bResult = FileWrite($hFile, $sText) <> 0
			FileClose($hFile)
			If $bResult Then
				$g_sMDPath = $sPath
				$g_sMDSaved = $sText
				_MD_Render()
			Else
				_MD_Error("File save failed")
			EndIf
		EndIf
	EndIf
	Return $bResult
EndFunc   ;==>_MD_Save

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _MD_CanDiscard
; Description ...: Asks whether changed text may be discarded or saved.
; Syntax ........: _MD_CanDiscard()
; Parameters ....: None.
; Return values .: True to continue; False on cancellation or unsuccessful save.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; does not modify the public UDF API.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _MD_CanDiscard()
	Local $bResult = True
	If GUICtrlRead($g_idMDEdit) <> $g_sMDSaved Then
		Local $iAnswer = MsgBox(BitOR($MB_YESNOCANCEL, $MB_ICONQUESTION), "Unsaved changes", "Save changes before continuing?", 0, $g_hMD)
		Switch $iAnswer
			Case $IDYES
				$bResult = _MD_Save()
			Case $IDCANCEL
				$bResult = False
		EndSwitch
	EndIf
	Return $bResult
EndFunc   ;==>_MD_CanDiscard

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _MD_Wrap
; Description ...: Wraps the selected editor text with Markdown delimiters.
; Syntax ........: _MD_Wrap($sOpen, $sClose)
; Parameters ....: $sOpen - Text inserted before the selected editor text.
;                  $sClose - Text inserted after the selected editor text.
; Return values .: True.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; does not modify the public UDF API.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _MD_Wrap($sOpen, $sClose)
	Local $aSel = _GUICtrlEdit_GetSel($g_idMDEdit)
	Local $sText = GUICtrlRead($g_idMDEdit)
	Local $sSelected = StringMid($sText, $aSel[0] + 1, $aSel[1] - $aSel[0])
	_GUICtrlEdit_ReplaceSel($g_idMDEdit, $sOpen & $sSelected & $sClose, True)
	GUICtrlSetState($g_idMDEdit, $GUI_FOCUS)
	Return True
EndFunc   ;==>_MD_Wrap

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _MD_Export
; Description ...: Renders the editor, asks for a destination and exports PDF or MHTML.
; Syntax ........: _MD_Export($bPDF)
; Parameters ....: $bPDF - True exports PDF; False exports MHTML.
; Return values .: True on successful export; False on cancellation or render/export failure.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; does not modify the public UDF API.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _MD_Export($bPDF)
	Local $bResult = False
	If _MD_Render() Then
		Local $sExtension = $bPDF ? "pdf" : "mhtml"
		Local $sPath = FileSaveDialog("Export " & StringUpper($sExtension), @MyDocumentsDir, "Document (*." & $sExtension & ")", $FD_PROMPTOVERWRITE, "document." & $sExtension, $g_hMD)
		If Not @error Then
			If Not StringRegExp($sPath, '(?i)\.' & $sExtension & '$') Then $sPath &= "." & $sExtension
			If $bPDF Then
				$bResult = _WebView2_ExportToPdfFile($g_iMDView, $sPath, '{"printBackground":true,"preferCSSPageSize":true}')
			Else
				$bResult = _WebView2_ExportToMhtmlFile($g_iMDView, $sPath)
			EndIf
			If Not $bResult Then _MD_Error("Export")
		EndIf
	EndIf
	Return $bResult
EndFunc   ;==>_MD_Export

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _MD_FileUri
; Description ...: Converts a local Windows path to a file URI.
; Syntax ........: _MD_FileUri($sPath)
; Parameters ....: $sPath - Absolute Windows path, including a trailing separator for a directory.
; Return values .: The file URI with percent, spaces, question marks and hash characters escaped.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; does not modify the public UDF API.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _MD_FileUri($sPath)
	Local $sURI = "file:///" & StringReplace($sPath, "\", "/")
	$sURI = StringReplace($sURI, "%", "%25")
	$sURI = StringReplace($sURI, " ", "%20")
	$sURI = StringReplace($sURI, "#", "%23")
	$sURI = StringReplace($sURI, "?", "%3F")
	Return $sURI
EndFunc   ;==>_MD_FileUri

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _MD_Layout
; Description ...: Repositions the editor, splitter, status and WebView2 using the current client size.
; Syntax ........: _MD_Layout()
; Parameters ....: None.
; Return values .: True; layout requests are cleared.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; does not modify the public UDF API.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _MD_Layout()
	Local $aClient = WinGetClientSize($g_hMD)
	If IsArray($aClient) Then
		Local $iX = 5, $iY = 5
		For $i = 0 To UBound($g_aMDButtons) - 1
			Local $iWidth = 45
			If $i < 4 Or $i >= 17 Then $iWidth = 80
			If $i >= 11 And $i <= 13 Then $iWidth = 70
			If $iX + $iWidth > $aClient[0] - 5 Then
				$iX = 5
				$iY += 33
			EndIf
			GUICtrlSetPos($g_aMDButtons[$i], $iX, $iY, $iWidth, 28)
			$iX += $iWidth + 2
		Next
		Local $iTop = $iY + 35
		Local $iLeft = Int($aClient[0] * $g_fMDRatio)
		Local $iHeight = _Max(1, $aClient[1] - $iTop - 30)
		GUICtrlSetPos($g_idMDEdit, 5, $iTop, _Max(1, $iLeft - 10), $iHeight)
		GUICtrlSetPos($g_idMDSplit, $iLeft, $iTop, 8, $iHeight)
		GUICtrlSetPos($g_idMDStatus, 5, $aClient[1] - 25, _Max(1, $aClient[0] - 10), 20)
		If $g_iMDView >= 0 Then _WebView2_SetBounds($g_iMDView, $iLeft + 10, $iTop, _Max(1, $aClient[0] - $iLeft - 15), $iHeight)
	EndIf
	$g_bMDResize = False
	Return True
EndFunc   ;==>_MD_Layout

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _MD_Command
; Description ...: Queues a debounced editor refresh outside the Windows callback.
; Syntax ........: _MD_Command($hWnd, $iMsg, $wParam, $lParam)
; Parameters ....: $hWnd - Window receiving WM_COMMAND.
;                  $iMsg - Windows message ID.
;                  $wParam - Control ID and notification code.
;                  $lParam - Control HWND; unused.
; Return values .: $GUI_RUNDEFMSG.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; does not modify the public UDF API.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _MD_Command($hWnd, $iMsg, $wParam, $lParam)
	#forceref $iMsg, $lParam
	If $hWnd = $g_hMD And BitAND($wParam, 0xFFFF) = $g_idMDEdit And BitShift($wParam, 16) = $EN_CHANGE Then
		$g_bMDPending = True
		$g_hMDTimer = TimerInit()
	EndIf
	Return $GUI_RUNDEFMSG
EndFunc   ;==>_MD_Command

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _MD_Size
; Description ...: Queues layout changes outside the Windows callback.
; Syntax ........: _MD_Size($hWnd, $iMsg, $wParam, $lParam)
; Parameters ....: $hWnd - Window receiving WM_SIZE.
;                  $iMsg - Windows message ID; unused.
;                  $wParam - Resize state; unused.
;                  $lParam - Packed client dimensions; unused.
; Return values .: $GUI_RUNDEFMSG.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; does not modify the public UDF API.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _MD_Size($hWnd, $iMsg, $wParam, $lParam)
	#forceref $iMsg, $wParam, $lParam
	If $hWnd = $g_hMD Then $g_bMDResize = True
	Return $GUI_RUNDEFMSG
EndFunc   ;==>_MD_Size

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _MD_Navigation
; Description ...: Keeps the preview shell loaded and queues external HTTP links.
; Syntax ........: _MD_Navigation($iWebView, $sURI, $bUserInitiated, $bRedirected)
; Parameters ....: $iWebView - WebView2 instance ID; unused.
;                  $sURI - Destination URI.
;                  $bUserInitiated - Whether the user initiated navigation; unused.
;                  $bRedirected - Whether this is a redirect; unused.
; Return values .: True to cancel navigation; False to allow the preview shell.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; does not modify the public UDF API.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _MD_Navigation($iWebView, $sURI, $bUserInitiated, $bRedirected)
	#forceref $iWebView, $bUserInitiated, $bRedirected
	Local $bCancel = False
	If $g_bMDReady And $sURI <> $g_sMDShell And StringLeft($sURI, StringLen($g_sMDShell) + 1) <> $g_sMDShell & "#" Then
		$bCancel = True
		If StringRegExp($sURI, '(?i)^https?://') Then $g_sMDLink = $sURI
	EndIf
	Return $bCancel
EndFunc   ;==>_MD_Navigation

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _MD_Error
; Description ...: Logs an example failure and displays it outside smoke-test mode.
; Syntax ........: _MD_Error($sStage)
; Parameters ....: $sStage - Description of the failed operation.
; Return values .: False.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; does not modify the public UDF API.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _MD_Error($sStage)
	Local $sMessage = $sStage & @CRLF & _WebView2_Error_GetDescription()
	ConsoleWrite("! Markdown: " & $sMessage & @CRLF)
	If $g_bMDSmoke Then
		ConsoleWrite("MD_SMOKE_FAIL" & @CRLF)
	Else
		MsgBox($MB_ICONERROR, "Markdown Viewer", $sMessage, 0, $g_hMD)
	EndIf
	Return False
EndFunc   ;==>_MD_Error

; #INTERNAL_USE_ONLY# ==========================================================================================================
; Name ..........: _MD_Smoke
; Description ...: Checks Markdown, Unicode, sanitizing, selection formatting and PDF/MHTML export.
; Syntax ........: _MD_Smoke()
; Parameters ....: None.
; Return values .: 0 when all checks pass; 1 on failure.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: Example helper; does not modify the public UDF API.
; Related .......:
; Link ..........:
; Example .......: No
; ================================================================================================================================
Func _MD_Smoke()
	Local $iResult = 1
	Do
		Local $sProbe = _WebView2_ExecuteScript($g_iMDView, "document.querySelectorAll('#view h1').length===1 && document.querySelectorAll('#view h2').length>=3 && document.querySelectorAll('#toc-tree > li').length===1 && document.querySelectorAll('#toc-tree [role=treeitem]').length>=8 && document.querySelectorAll('#toc-tree [aria-expanded=true]').length>=1 && document.querySelectorAll('#toc-tree [aria-expanded=false]').length===0 && document.querySelectorAll('#view table').length===1 && document.getElementById('view').textContent.includes('ąćęłńóśźż')")
		If @error Or $sProbe <> "true" Then ExitLoop
		Local $sPathProbe = 'C:\new\folder literal \n \u0105 ąćę 😀'
		$sProbe = _WebView2_ExecuteScript($g_iMDView, "(()=>{const p=document.createElement('p');p.id='decode-probe';p.textContent=" & __WebView2_JavaScript_StringLiteral($sPathProbe) & ";document.getElementById('view').append(p);return true})()")
		If @error Then ExitLoop
		Local $sElement = _WebView2_GetElementById($g_iMDView, "decode-probe")
		If @error Then ExitLoop
		Local $sDecoded = _WebView2_ElementAction($g_iMDView, $sElement, "TEXT")
		If @error Or $sDecoded <> $sPathProbe Then ExitLoop
		Local $sEscapes = '# Escapes' & @CRLF & 'Quotes " '' and slash \ and emoji 😀' & @CRLF & '<img src=x onerror="window.bad=1"><script>window.bad=2</script>'
		GUICtrlSetData($g_idMDEdit, $sEscapes)
		If Not _MD_Render() Then ExitLoop
		$sProbe = _WebView2_ExecuteScript($g_iMDView, "!window.bad && !document.querySelector('#view script') && !document.querySelector('#view [onerror]') && document.querySelectorAll('#toc-tree [role=treeitem]').length===1")
		If @error Or $sProbe <> "true" Then ExitLoop
		_GUICtrlEdit_SetSel($g_idMDEdit, 2, 9)
		ControlClick($g_hMD, "", $g_aMDButtons[4])
		Local $hButtonWait = TimerInit(), $iButtonEvent = 0
		Do
			$iButtonEvent = GUIGetMsg()
			If $iButtonEvent = $g_aMDButtons[4] Then ExitLoop
			Sleep(10)
		Until TimerDiff($hButtonWait) > 2000
		If $iButtonEvent <> $g_aMDButtons[4] Then ExitLoop
		_MD_Wrap("**", "**")
		If StringInStr(GUICtrlRead($g_idMDEdit), "**Escapes**") = 0 Then ExitLoop
		If Not _MD_Render() Then ExitLoop
		Local $dPDF = _WebView2_ExportToPdfBinary($g_iMDView)
		If @error Or BinaryToString(BinaryMid($dPDF, 1, 5)) <> "%PDF-" Then ExitLoop
		Local $dMHTML = _WebView2_ExportToMhtmlBinary($g_iMDView)
		If @error Or Not StringInStr(BinaryToString($dMHTML, $SB_UTF8), "multipart/related") Then ExitLoop
		Local $sTemp = @TempDir & "\WebView2-Markdown-" & @AutoItPID
		DirCreate($sTemp)
		If Not _WebView2_ExportToPdfFile($g_iMDView, $sTemp & "\preview.pdf") Then ExitLoop
		If Not _WebView2_ExportToMhtmlFile($g_iMDView, $sTemp & "\preview.mhtml") Then ExitLoop
		$g_sMDPath = $sTemp & "\document.md"
		If Not _MD_Save() Then ExitLoop
		Local $sRoundTrip = GUICtrlRead($g_idMDEdit)
		GUICtrlSetData($g_idMDEdit, "")
		If Not _MD_OpenPath($g_sMDPath) Then ExitLoop
		If GUICtrlRead($g_idMDEdit) <> $sRoundTrip Then ExitLoop
		Local $hImage = FileOpen($sTemp & "\pixel.png", BitOR($FO_OVERWRITE, $FO_BINARY))
		If $hImage = -1 Then ExitLoop
		FileWrite($hImage, Binary("0x89504e470d0a1a0a0000000d4948445200000001000000010804000000b51c0c020000000b4944415478da6364f80f00010501012718e3660000000049454e44ae426082"))
		FileClose($hImage)
		GUICtrlSetData($g_idMDEdit, $sRoundTrip & @CRLF & "![Local image](pixel.png)")
		If Not _MD_Render() Then ExitLoop
		Local $hImageTimer = TimerInit()
		Do
			$sProbe = _WebView2_ExecuteScript($g_iMDView, "Array.from(document.images).some(i=>i.alt==='Local image'&&i.naturalWidth===1)")
			If $sProbe = "true" Or @error Then ExitLoop
			Sleep(20)
		Until TimerDiff($hImageTimer) > 5000
		If $sProbe <> "true" Then ExitLoop
		WinMove($g_hMD, "", Default, Default, 1100, 700)
		_MD_Layout()
		If Not _WebView2_SetZoomFactor($g_iMDView, 1.2) Then ExitLoop
		GUICtrlSetData($g_idMDEdit, "# Markdown Viewer" & @CRLF & @CRLF & "Unicode sample: ąćęłńóśźż 😀" & @CRLF & @CRLF & "**AutoIt** and live preview." & @CRLF & @CRLF & "| Format | Export |" & @CRLF & "| --- | --- |" & @CRLF & "| PDF | OK |" & @CRLF & "| MHTML | OK |")
		If Not _MD_Render() Then ExitLoop
		Local $hPaint = TimerInit()
		While TimerDiff($hPaint) < 250
			GUIGetMsg()
			Sleep(10)
		WEnd
		ConsoleWrite("MD_SMOKE_OK arch=" & (@AutoItX64 ? "x64" : "x86") & " pdf=" & BinaryLen($dPDF) & " mhtml=" & BinaryLen($dMHTML) & " files=" & $sTemp & @CRLF)
		$iResult = 0
	Until True
	If $iResult Then _MD_Error("Test Markdown/PDF/MHTML")
	Return $iResult
EndFunc   ;==>_MD_Smoke
