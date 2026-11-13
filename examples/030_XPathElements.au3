#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_iWebView = -1
Global $g_idStatus = 0, $g_idLog = 0, $g_idGuide = 0
Global $g_bSmoke = False

Exit _Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Finds and updates elements in a local document using XPath locators.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: 0 on normal close or successful smoke run; 1 on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Uses only test data; no network or real sign-in is performed.
; Related .......: _WebView2_FindElement, _WebView2_SetElementValue, _WebView2_ElementAction
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	If $CmdLine[0] > 0 Then $g_bSmoke = ($CmdLine[1] = "--smoke")
	Local $hGUI = GUICreate("WebView2 - XPath elements", 850, 540, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	Local $idRun = GUICtrlCreateButton("Find and fill by XPath", 10, 9, 190, 28)
	$g_idStatus = GUICtrlCreateLabel("Starting WebView2...", 210, 14, 625, 24)
	GUICtrlSetResizing($idRun, $GUI_DOCKALL)
	GUICtrlSetResizing($g_idStatus, $GUI_DOCKALL)
	GUICtrlCreateLabel("Operation log", 5, 49, 290, 18)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	$g_idLog = GUICtrlCreateEdit("", 5, 70, 290, 460, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	Local $sGuide = "TEST PROCEDURE" & @CRLF & "1. Click Find and fill by XPath, then Show values in the page." & @CRLF & "EXPECTED RESULT" & @CRLF & "The two fields are filled, then the page reports their values." & @CRLF & "HOW IT WORKS" & @CRLF & "AutoIt locates DOM elements by XPath and changes their values through WebView2."
	$g_idGuide = GUICtrlCreateEdit($sGuide, 305, 360, 790, 170, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	GUICtrlSetBkColor(-1, 0xFFF4C2)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	GUISetState(@SW_MAXIMIZE, $hGUI)
	Local $aPanelSize = WinGetClientSize($hGUI)
	If IsArray($aPanelSize) Then
		GUICtrlSetPos($g_idLog, 5, 70, 290, $aPanelSize[1] - 80)
		GUICtrlSetPos($g_idGuide, 305, $aPanelSize[1] - 180, $aPanelSize[0] - 310, 170)
	EndIf

	Local $bReady = False
	Do
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\030_XPathElements"
		If Not _WebView2_Init(Default, $sProfile) Then
			_Example_Status("Initialization failed: " & _WebView2_Error_GetDescription())
			ExitLoop
		EndIf
		Local $aSize = WinGetClientSize($hGUI)
		$g_iWebView = _WebView2_Create($hGUI, 305, 46, $aSize[0] - 310, $aSize[1] - 236)
		If @error Then
			_Example_Status("Creation failed: " & _WebView2_Error_GetDescription())
			ExitLoop
		EndIf
		If Not _WebView2_NavigateToString($g_iWebView, _Example_Html()) Then
			_Example_Status("Navigation failed: " & _WebView2_Error_GetDescription())
			ExitLoop
		EndIf
		If Not _WebView2_LoadWait($g_iWebView) Then
			_Example_Status("Page load failed: " & _WebView2_Error_GetDescription())
			ExitLoop
		EndIf
		$bReady = True
		_Example_Status("Ready. Click the AutoIt button to locate and update the form.")
	Until True

	Local $iExit = 0
	If Not $bReady Then
		$iExit = 1
	ElseIf $g_bSmoke Then
		If Not _Example_FillByXPath() Then $iExit = 1
		If $iExit = 0 And Not _Example_VerifyShowValues() Then $iExit = 1
		ConsoleWrite(($iExit = 0 ? "EX_SMOKE_OK" : "EX_SMOKE_FAIL") & " example=030 arch=" & (@AutoItX64 ? "x64" : "x86") & @CRLF)
	Else
		While True
			Switch GUIGetMsg()
				Case $GUI_EVENT_CLOSE
					ExitLoop
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					Local $aClient = WinGetClientSize($hGUI)
					If IsArray($aClient) Then
						GUICtrlSetPos($g_idLog, 5, 70, 290, $aClient[1] - 80)
						GUICtrlSetPos($g_idGuide, 305, $aClient[1] - 180, $aClient[0] - 310, 170)
						_WebView2_SetBounds($g_iWebView, 305, 46, $aClient[0] - 310, $aClient[1] - 236)
					EndIf
				Case $idRun
					_Example_FillByXPath()
			EndSwitch
			Sleep(10)
		WEnd
	EndIf
	_WebView2_Cleanup()
	GUIDelete($hGUI)
	Return $iExit
EndFunc   ;==>_Example

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_FillByXPath
; Description ...: Finds and fills two inputs by XPath without clicking the page button.
; Syntax ........: _Example_FillByXPath()
; Parameters ....: None.
; Return values .: True if both fields were filled; False otherwise.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Element tokens are document-scoped; find them again after navigation.
; Related .......: _WebView2_FindElement, _WebView2_SetElementValue, _WebView2_ElementAction
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example_FillByXPath()
	Local $sUser = _WebView2_FindElement($g_iWebView, $WEBVIEW2_LOCATOR_BY_XPATH, "//form[@id='demo-form']//input[@name='user']")
	If @error Then Return _Example_Fail("User field")
	Local $sCode = _WebView2_FindElement($g_iWebView, $WEBVIEW2_LOCATOR_BY_XPATH, "//form[@id='demo-form']//input[@name='code']")
	If @error Then Return _Example_Fail("Code field")

	If Not _WebView2_SetElementValue($g_iWebView, $sUser, "Sample user") Then Return _Example_Fail("Set user")
	If Not _WebView2_SetElementValue($g_iWebView, $sCode, "1234") Then Return _Example_Fail("Set code")
	_WebView2_ExecuteScript($g_iWebView, "document.getElementById('result').textContent = 'Waiting...'")
	If @error Then Return _Example_Fail("Reset result")
	_Example_Status("Fields filled by XPath. Click Show values in the page to display them.")
	Return True
EndFunc   ;==>_Example_FillByXPath

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_VerifyShowValues
; Description ...: Verifies that only the page button displays the filled values.
; Syntax ........: _Example_VerifyShowValues()
; Parameters ....: None.
; Return values .: True if the result changes from Waiting to the expected values; False otherwise.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Used only by the automated smoke test; the visible AutoIt button does not call it.
; Related .......: _WebView2_FindElement, _WebView2_ElementAction
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example_VerifyShowValues()
	Local $sOutput = _WebView2_FindElement($g_iWebView, $WEBVIEW2_LOCATOR_BY_XPATH, "//p[@id='result']")
	If @error Then Return _Example_Fail("Result label")
	Local $sText = _WebView2_ElementAction($g_iWebView, $sOutput, "TEXT")
	If @error Then Return _Example_Fail("Read initial result")
	If $sText <> "Waiting..." Then
		_Example_Status("Result changed before Show values was clicked: " & $sText)
		Return False
	EndIf
	Local $sButton = _WebView2_FindElement($g_iWebView, $WEBVIEW2_LOCATOR_BY_XPATH, "//form[@id='demo-form']//button[@type='button']")
	If @error Then Return _Example_Fail("Show values button")
	_WebView2_ElementAction($g_iWebView, $sButton, "CLICK")
	If @error Then Return _Example_Fail("Click Show values")
	$sText = _WebView2_ElementAction($g_iWebView, $sOutput, "TEXT")
	If @error Then Return _Example_Fail("Read result")
	If $sText <> "Sample user / 1234" Then
		_Example_Status("Unexpected result: " & $sText)
		Return False
	EndIf
	_Example_Status("Show values displayed: " & $sText)
	Return True
EndFunc   ;==>_Example_VerifyShowValues

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Fail
; Description ...: Reports the failed DOM operation.
; Syntax ........: _Example_Fail($sStage)
; Parameters ....: $sStage - Name of the failed operation.
; Return values .: False.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_Error_GetDescription
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example_Fail($sStage)
	_Example_Status($sStage & " failed: " & _WebView2_Error_GetDescription())
	Return False
EndFunc   ;==>_Example_Fail

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Html
; Description ...: Builds the local form used to demonstrate XPath locators.
; Syntax ........: _Example_Html()
; Parameters ....: None.
; Return values .: HTML document string.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_NavigateToString
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example_Html()
	Local $sHtml = '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>XPath elements</title>' & _
			'<style>body{font:17px Segoe UI,sans-serif;max-width:650px;margin:35px auto;color:#233042}' & _
			'form{display:grid;gap:14px;padding:22px;border:1px solid #a9b7c5;border-radius:12px}' & _
			'input,button{font:inherit;padding:8px}label{display:grid;gap:4px}</style></head><body>' & _
			'<h1>XPath element discovery</h1><p>This local form uses sample values only.</p>' & _
			'<form id="demo-form"><label>User<input name="user" autocomplete="off"></label>' & _
			'<label>Code<input name="code" autocomplete="off"></label>' & _
			'<button type="button" onclick="document.getElementById(''result'').textContent=this.form.elements.user.value+'' / ''+this.form.elements.code.value">Show values</button>' & _
			'</form><p id="result">Waiting...</p></body></html>'
	Return $sHtml
EndFunc   ;==>_Example_Html

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Status
; Description ...: Displays and logs the latest example result.
; Syntax ........: _Example_Status($sText)
; Parameters ....: $sText - Message to display.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example_Status($sText)
	GUICtrlSetData($g_idStatus, $sText)
	_GUICtrlEdit_AppendText($g_idLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sText & @CRLF)
	GUICtrlSendMsg($g_idLog, $EM_SCROLLCARET, 0, 0)
	ConsoleWrite($sText & @CRLF)
	Return
EndFunc   ;==>_Example_Status
