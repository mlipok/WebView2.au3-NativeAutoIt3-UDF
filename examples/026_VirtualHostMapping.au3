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
Global $g_iWebView = -1
Global $g_idStatus = 0, $g_idLog = 0, $g_idGuide = 0
Global $g_bReady = False
Global $g_bSmoke = False

Exit _Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Loads local HTML, CSS and JavaScript through a virtual HTTPS host.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: 0 on normal close or successful smoke run; 1 if a smoke run times out.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The static files are served by WebView2 without a local HTTP server or Internet connection.
; Related .......: _WebView2_SetVirtualHostNameToFolderMapping
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example()
	If $CmdLine[0] > 0 Then $g_bSmoke = ($CmdLine[1] = "--smoke")
	Local $hGUI = GUICreate("WebView2 - Virtual host mapping", 860, 570, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	Local $idReload = GUICtrlCreateButton("Reload local page", 10, 8, 150, 28)
	$g_idStatus = GUICtrlCreateLabel("Starting WebView2...", 170, 13, 675, 22)
	GUICtrlSetResizing($idReload, $GUI_DOCKALL)
	GUICtrlSetResizing($g_idStatus, $GUI_DOCKALL)
	GUICtrlCreateLabel("Operation log", 5, 47, 290, 18)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	$g_idLog = GUICtrlCreateEdit("", 5, 68, 290, 492, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idLog, 0xE2F0E4)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	Local $sGuide = "TEST PROCEDURE" & @CRLF & "1. Click Reload local page." & @CRLF & "EXPECTED RESULT" & @CRLF & "The HTML and relative assets reload under the virtual HTTPS address." & @CRLF & "HOW IT WORKS" & @CRLF & "WebView2 maps a real folder to an HTTPS host without a local server."
	$g_idGuide = GUICtrlCreateEdit($sGuide, 305, 390, 790, 170, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	GUICtrlSetBkColor(-1, 0xFFF4C2)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	GUISetState(@SW_MAXIMIZE, $hGUI)
	Local $aPanelSize = WinGetClientSize($hGUI)
	If IsArray($aPanelSize) Then
		GUICtrlSetPos($g_idLog, 5, 68, 290, $aPanelSize[1] - 78)
		GUICtrlSetPos($g_idGuide, 305, $aPanelSize[1] - 180, $aPanelSize[0] - 310, 170)
	EndIf

	Do
		Local $sProfile = @TempDir & "\WebView2VirtualHostMapping_" & @AutoItPID
		If Not _WebView2_Init(Default, $sProfile) Then
			_Example_Status("Initialization failed: " & _WebView2_Error_GetDescription())
			ExitLoop
		EndIf
		Local $aClient = WinGetClientSize($hGUI)
		$g_iWebView = _WebView2_Create($hGUI, 305, 44, $aClient[0] - 310, $aClient[1] - 234)
		If @error Then
			_Example_Status("Creation failed: " & _WebView2_Error_GetDescription())
			ExitLoop
		EndIf
		If Not _WebView2_SetCallback($g_iWebView, $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED, _Example_OnMessage) Then
			_Example_Status("Message callback failed: " & _WebView2_Error_GetDescription())
			ExitLoop
		EndIf
		If Not _WebView2_SetCallback($g_iWebView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _Example_OnNavigation) Then
			_Example_Status("Navigation callback failed: " & _WebView2_Error_GetDescription())
			ExitLoop
		EndIf
		Local $sFolder = @ScriptDir & "\026_VirtualHostMapping"
		If Not FileExists($sFolder & "\index.html") Or Not FileExists($sFolder & "\site.css") Or Not FileExists($sFolder & "\site.js") Then
			_Example_Status("Example assets are missing: " & $sFolder)
			ExitLoop
		EndIf
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_iWebView, $g_sHost, $sFolder) Then
			_Example_Status("Mapping failed: " & _WebView2_Error_GetDescription())
			ExitLoop
		EndIf
		_Example_LoadPage()
	Until True

	Local $hTimer = TimerInit()
	While True
		If $g_bSmoke Then
			If $g_bReady Then
				ConsoleWrite("EX_SMOKE_OK example=026 arch=" & (@AutoItX64 ? "x64" : "x86") & @CRLF)
				ExitLoop
			EndIf
			If TimerDiff($hTimer) > 15000 Then
				_Example_Status("Smoke test timed out waiting for the local page.")
				ExitLoop
			EndIf
		EndIf
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
				If $g_iWebView >= 0 Then
					Local $aSize = WinGetClientSize($hGUI)
					If IsArray($aSize) Then
						GUICtrlSetPos($g_idLog, 5, 68, 290, $aSize[1] - 78)
						GUICtrlSetPos($g_idGuide, 305, $aSize[1] - 180, $aSize[0] - 310, 170)
						_WebView2_SetBounds($g_iWebView, 305, 44, $aSize[0] - 310, $aSize[1] - 234)
					EndIf
				EndIf
			Case $idReload
				_Example_LoadPage()
		EndSwitch
		Sleep(10)
	WEnd
	_WebView2_Cleanup()
	GUIDelete($hGUI)
	Return ($g_bSmoke And Not $g_bReady) ? 1 : 0
EndFunc   ;==>_Example

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_LoadPage
; Description ...: Navigates to the local page through the mapped HTTPS origin.
; Syntax ........: _Example_LoadPage()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_Navigate
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_LoadPage()
	If $g_iWebView >= 0 Then
		_Example_Status("Loading local HTML, CSS and JavaScript...")
		If Not _WebView2_Navigate($g_iWebView, $g_sOrigin & "index.html") Then _Example_Status("Navigation failed: " & _WebView2_Error_GetDescription())
	EndIf
	Return
EndFunc   ;==>_Example_LoadPage

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_OnMessage
; Description ...: Reports a page message from the mapped origin.
; Syntax ........: _Example_OnMessage($iWebView, $sMessage, $sSource, $bJSON)
; Parameters ....: $iWebView - Source WebView2 instance ID.
;                  $sMessage - JSON text sent by the page.
;                  $sSource - Source document URI.
;                  $bJSON - True for an object message.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Messages from other origins are ignored.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_OnMessage($iWebView, $sMessage, $sSource, $bJSON)
	If $iWebView = $g_iWebView And $bJSON And StringLeft($sSource, StringLen($g_sOrigin)) = $g_sOrigin And StringLen($sMessage) <= 1024 Then
		If StringInStr($sMessage, '"type":"ready"') Then
			$g_bReady = True
			_Example_Status("Local HTML, CSS and JavaScript loaded from " & $g_sOrigin)
		ElseIf StringInStr($sMessage, '"type":"button"') Then
			_Example_Status("The local JavaScript button sent a message to AutoIt.")
		ElseIf StringInStr($sMessage, '"type":"error"') Then
			_Example_Status("The local stylesheet did not load.")
		EndIf
	EndIf
	Return
EndFunc   ;==>_Example_OnMessage

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_OnNavigation
; Description ...: Reports a failed page load.
; Syntax ........: _Example_OnNavigation($iWebView, $bSuccess, $iWebErrorStatus, $iNavigationId)
; Parameters ....: $iWebView - Source WebView2 instance ID.
;                  $bSuccess - Navigation result.
;                  $iWebErrorStatus - WebView2 error status.
;                  $iNavigationId - Navigation identifier.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_OnNavigation($iWebView, $bSuccess, $iWebErrorStatus, $iNavigationId)
	#forceref $iNavigationId
	If $iWebView = $g_iWebView And Not $bSuccess Then _Example_Status("Page load failed; WebView2 status: " & $iWebErrorStatus)
	Return
EndFunc   ;==>_Example_OnNavigation

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Status
; Description ...: Updates the native status label.
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
