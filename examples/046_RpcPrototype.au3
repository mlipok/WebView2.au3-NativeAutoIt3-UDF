#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global Const $g_EX_sTrustedPage = "https://udf-virtual-host.example/046.html"
Global $g_EX_hGUI = 0, $g_EX_hHost = 0, $g_EX_idLog = 0, $g_EX_idGuide = 0, $g_EX_iWebView = -1
Global $g_EX_sHostGeometry = ""
Global $g_EX_sSession = "", $g_EX_bReady = False, $g_EX_iLastId = 0
Global $g_EX_aPending[4][4]                ; used, request ID, sum, timer
Global $g_EX_bSmoke = False
If $CmdLine[0] Then $g_EX_bSmoke = $CmdLine[1] = "--smoke"

If $g_EX_bSmoke Then Exit _Example()
_Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Demonstrates one strictly bounded, origin-checked page-to-AutoIt JSON method.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This is a protocol prototype, not a general JSON parser or public RPC UDF.
; Related .......: _WebView2_SetCallback, _WebView2_PostWebMessageAsJson
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	Local $iError = 0, $iExtended = 0
	Local $iSmokeExit = 1, $iSmokeStage = 0, $iSmokeTimer = TimerInit()
	Do
		$g_EX_hGUI = GUICreate("WebView2 - JSON RPC prototype", 1100, 720, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		Local $idReload = GUICtrlCreateButton("Reload trusted page", 8, 8, 160, 30)
		GUICtrlCreateLabel("AutoIt operation log", 8, 48, 285, 18)
		$g_EX_idLog = GUICtrlCreateEdit("", 8, 68, 285, 450, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idLog, 0xE2F0E4)
		$g_EX_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
				"1. Wait for Authorized session ready in the blue page panel." & @CRLF & _
				"2. Click Add sample values inside WebView2. The green log identifies the trusted click and one validated request." & @CRLF & _
				"3. After a short delay, AutoIt returns 5; the page resolves the matching Promise and displays that value." & @CRLF & _
				"4. Reload the trusted page. A new random session is issued; old request IDs and responses are invalidated." & @CRLF & _
				"HOW IT WORKS" & @CRLF & _
				"The host accepts only one exact local HTTPS origin and a strict, fixed-shape JSON add request. It checks an ephemeral session token, bounded request ID and integer arguments. This sample is intentionally limited to one harmless method; it is not a generic RPC parser.", _
				305, 500, 780, 210, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idGuide, 0xFFF1BF)
		If Not $g_EX_bSmoke Then
			GUISetState(@SW_MAXIMIZE, $g_EX_hGUI)
			GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hGUI)
		EndIf
		Local $aClient = WinGetClientSize($g_EX_hGUI)
		_Layout($aClient)
		$g_EX_hHost = GUICreate("", 1, 1, 0, 0, $WS_POPUP, $WS_EX_NOREDIRECTIONBITMAP, $g_EX_hGUI)
		_SyncHost()
		If Not $g_EX_bSmoke Then GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hHost)
		_Log("Starting WebView2...")
		Local $sLoader = Default, $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\046_RpcPrototype"
		If $g_EX_bSmoke Then
			Local $sArch = @AutoItX64 ? "x64" : "x86"
			$sLoader = EnvGet("WEBVIEW2_TEST_LOADER")
			If $sLoader = "" Then $sLoader = Default
			$sProfile = @ScriptDir & "\..\..\profiles\04-rpc-" & $sArch
			DirCreate($sProfile)
		EndIf
		If Not _WebView2_Init($sLoader, $sProfile) Then
			$iError = @error
			$iExtended = @extended
			_Log("Init failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		$g_EX_iWebView = _WebView2_Create($g_EX_hHost, 0, 0, $aClient[0] - 313, $aClient[1] - 280)
		If @error Then
			$iError = @error
			$iExtended = @extended
			_Log("Create failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		If Not _WebView2_SetCallback($g_EX_iWebView, $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED, _OnWebMessage) Then
			$iError = @error
			$iExtended = @extended
			_Log("Message callback failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		If Not _WebView2_SetCallback($g_EX_iWebView, $WEBVIEW2_EVENT_NAVIGATION_STARTING, _OnNavigation) Then
			$iError = @error
			$iExtended = @extended
			_Log("Navigation callback failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_EX_iWebView, "udf-virtual-host.example", @ScriptDir & "\assets\native") Then
			$iError = @error
			$iExtended = @extended
			_Log("Mapping failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		If Not _WebView2_Navigate($g_EX_iWebView, $g_EX_sTrustedPage) Then
			$iError = @error
			$iExtended = @extended
			_Log("Navigation failed: " & _WebView2_Error_GetDescription())
			ExitLoop 1
		EndIf
		While True
			Local $aMsg = GUIGetMsg(1)
			Local $iMsg = $aMsg[0]
			Switch $iMsg
				Case $idReload
					_Click("Reload trusted page")
					_WebView2_Reload($g_EX_iWebView)
				Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
					_SyncHost()
				Case $GUI_EVENT_CLOSE
					If $aMsg[1] = $g_EX_hGUI Then ExitLoop
			EndSwitch
			_SyncHost()
			_ProcessReady()
			_ProcessPending()
			If $g_EX_bSmoke Then
				Local $sPageResult = _WebView2_ExecuteScript($g_EX_iWebView, "document.querySelector('#result')?.textContent", 1000)
				If $iSmokeStage = 0 And StringInStr($sPageResult, "Authorized session ready") Then
					_WebView2_ExecuteScript($g_EX_iWebView, "window.__rpcSmoke()", 1000)
					$iSmokeStage = 1
				EndIf
				If $iSmokeStage = 1 And StringInStr($sPageResult, "AutoIt returned 5") Then
					$iSmokeExit = 0
					ExitLoop
				EndIf
				If TimerDiff($iSmokeTimer) > 15000 Then ExitLoop
			EndIf
		WEnd
	Until True
	If $g_EX_bSmoke Then FileWrite(@ScriptDir & "\046_RpcPrototype.result.txt", "RPC_SMOKE arch=" & (@AutoItX64 ? "x64" : "x86") & " exit=" & $iSmokeExit & " session=" & ($g_EX_sSession <> "") & " lastId=" & $g_EX_iLastId & @CRLF)
	_WebView2_Cleanup()
	If $g_EX_hHost Then GUIDelete($g_EX_hHost)
	If $g_EX_hGUI Then GUIDelete($g_EX_hGUI)
	If $g_EX_bSmoke Then Return $iSmokeExit
	Return SetError($iError, $iExtended, 0)
EndFunc   ;==>_Example

; #FUNCTION# ====================================================================================================================
; Name ..........: _OnNavigation
; Description ...: Invalidates the current session and pending requests before another top-level document loads.
; Syntax ........: _OnNavigation($iWebView, $sURI, $bUserInitiated, $bRedirected)
; Parameters ....: Standard native navigation-start fields.
; Return values .: False to allow navigation.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This direct decision callback does not invoke synchronous WebView2 helpers.
; Related .......: _OnWebMessage
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnNavigation($iWebView, $sURI, $bUserInitiated, $bRedirected)
	#forceref $iWebView, $bUserInitiated, $bRedirected
	$g_EX_sSession = ""
	$g_EX_bReady = False
	$g_EX_iLastId = 0
	For $i = 0 To 3
		$g_EX_aPending[$i][0] = False
	Next
	_Log("Navigation started: " & $sURI & "; prior RPC session invalidated.")
	Return False
EndFunc   ;==>_OnNavigation

; #FUNCTION# ====================================================================================================================
; Name ..........: _OnWebMessage
; Description ...: Validates the exact trusted origin and the prototype's fixed JSON shape.
; Syntax ........: _OnWebMessage($iWebView, $sMessage, $sSource, $bJSON)
; Parameters ....: Standard native web-message fields.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The regex accepts only JSON.stringify output for the one sample method, not general JSON.
; Related .......: _ProcessReady, _ProcessPending
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnWebMessage($iWebView, $sMessage, $sSource, $bJSON)
	#forceref $iWebView
	Do
		If $sSource <> $g_EX_sTrustedPage Or Not $bJSON Then ExitLoop 1
		If $sMessage = '{"protocol":"wv2-rpc/1","kind":"ready"}' Then
			$g_EX_bReady = True
			ExitLoop 1
		EndIf
		If $sMessage = '{"protocol":"wv2-rpc/1","kind":"click","caption":"Add sample values"}' Then
			_GUICtrlEdit_AppendText($g_EX_idLog, @CRLF & "[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [WebView2]: Add sample values was clicked." & @CRLF)
			GUICtrlSendMsg($g_EX_idLog, $EM_SCROLLCARET, 0, 0)
			ExitLoop 1
		EndIf
		Local $aMatch = StringRegExp($sMessage, '^\{"protocol":"wv2-rpc/1","kind":"request","session":"([0-9A-F]{32})","id":([1-9][0-9]{0,8}),"method":"add","params":\[([0-9]{1,4}),([0-9]{1,4})\]\}$', 1)
		If Not IsArray($aMatch) Then
			_Log("Rejected message: invalid RPC shape or method.")
			ExitLoop 1
		EndIf
		If $g_EX_sSession = "" Or $aMatch[0] <> $g_EX_sSession Then
			_Log("Rejected request: missing or stale session.")
			ExitLoop 1
		EndIf
		Local $iId = Number($aMatch[1]), $iA = Number($aMatch[2]), $iB = Number($aMatch[3])
		If $iId <= $g_EX_iLastId Or $iA > 1000 Or $iB > 1000 Then
			_Log("Rejected request: duplicate ID or out-of-range arguments.")
			ExitLoop 1
		EndIf
		Local $iSlot = -1
		For $i = 0 To 3
			If Not $g_EX_aPending[$i][0] Then
				$iSlot = $i
				ExitLoop
			EndIf
		Next
		If $iSlot < 0 Then
			_Log("Rejected request: four requests are already pending.")
			ExitLoop 1
		EndIf
		$g_EX_iLastId = $iId
		$g_EX_aPending[$iSlot][0] = True
		$g_EX_aPending[$iSlot][1] = $iId
		$g_EX_aPending[$iSlot][2] = $iA + $iB
		$g_EX_aPending[$iSlot][3] = TimerInit()
		_Log("Accepted request " & $iId & " for allowlisted add(" & $iA & ", " & $iB & "); reply deferred.")
	Until True
	Return
EndFunc   ;==>_OnWebMessage

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _ProcessReady
; Description ...: Issues a random session token only to the currently trusted page.
; Syntax ........: _ProcessReady()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Runs outside the native COM callback.
; Related .......: _GenerateSession
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _ProcessReady()
	Do
		If Not $g_EX_bReady Then ExitLoop 1
		$g_EX_bReady = False
		If _WebView2_GetSource($g_EX_iWebView) <> $g_EX_sTrustedPage Then ExitLoop 1
		$g_EX_sSession = _GenerateSession()
		If $g_EX_sSession = "" Then
			_Log("Secure session generation failed.")
			ExitLoop 1
		EndIf
		If _WebView2_PostWebMessageAsJson($g_EX_iWebView, '{"protocol":"wv2-rpc/1","kind":"session","session":"' & $g_EX_sSession & '"}') Then
			_Log("Issued a new short-lived session to the trusted page.")
		Else
			$g_EX_sSession = ""
			_Log("Could not issue the session: " & _WebView2_Error_GetDescription())
		EndIf
	Until True
	Return
EndFunc   ;==>_ProcessReady

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _ProcessPending
; Description ...: Completes due prototype requests from the ordinary GUI loop.
; Syntax ........: _ProcessPending()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Invalidates results after navigation instead of delivering them to another document.
; Related .......: _OnWebMessage
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _ProcessPending()
	For $i = 0 To 3
		If Not $g_EX_aPending[$i][0] Then ContinueLoop
		If TimerDiff($g_EX_aPending[$i][3]) < 350 Then ContinueLoop
		If $g_EX_sSession <> "" And _WebView2_GetSource($g_EX_iWebView) = $g_EX_sTrustedPage Then
			Local $sJSON = '{"protocol":"wv2-rpc/1","kind":"response","session":"' & $g_EX_sSession & '","id":' & $g_EX_aPending[$i][1] & ',"ok":true,"result":' & $g_EX_aPending[$i][2] & '}'
			If _WebView2_PostWebMessageAsJson($g_EX_iWebView, $sJSON) Then _Log("Answered request " & $g_EX_aPending[$i][1] & " with " & $g_EX_aPending[$i][2] & ".")
		EndIf
		$g_EX_aPending[$i][0] = False
	Next
	Return
EndFunc   ;==>_ProcessPending

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _GenerateSession
; Description ...: Obtains 128 bits from the Windows system cryptographic random source.
; Syntax ........: _GenerateSession()
; Parameters ....: None.
; Return values .: Uppercase 32-character hexadecimal token or an empty string on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This token is never written to the operation log.
; Related .......: _ProcessReady
; Link ..........: https://learn.microsoft.com/windows/win32/api/ntsecapi/nf-ntsecapi-rtlgenrandom
; Example .......: Yes
; ===============================================================================================================================
Func _GenerateSession()
	Local $sToken = ""
	Do
		Local $tBytes = DllStructCreate("byte[16]")
		Local $aCall = DllCall("advapi32.dll", "bool", "SystemFunction036", "struct*", $tBytes, "ulong", 16)
		If @error Or Not IsArray($aCall) Or Not $aCall[0] Then ExitLoop 1
		$sToken = Hex(DllStructGetData($tBytes, 1))
	Until True
	Return $sToken
EndFunc   ;==>_GenerateSession

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Layout
; Description ...: Fits the native log and guide to the window client area.
; Syntax ........: _Layout($aClient)
; Parameters ....: $aClient - GUI client dimensions.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetBounds
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Layout($aClient)
	If IsArray($aClient) Then
		GUICtrlSetPos($g_EX_idLog, 8, 68, 285, $aClient[1] - 78)
		GUICtrlSetPos($g_EX_idGuide, 305, $aClient[1] - 222, $aClient[0] - 313, 212)
	EndIf
	Return
EndFunc   ;==>_Layout

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _SyncHost
; Description ...: Aligns the separate WebView-only window with the main GUI's browser panel.
; Syntax ........: _SyncHost()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Geometry is checked in the GUI loop; native controls remain in the main window.
; Related .......: _Layout, _WebView2_SetBounds
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _SyncHost()
	Do
		If Not $g_EX_hHost Then ExitLoop 1
		Local $aClient = WinGetClientSize($g_EX_hGUI)
		If Not IsArray($aClient) Then ExitLoop 1
		Local $tPoint = DllStructCreate("long X;long Y")
		DllStructSetData($tPoint, "X", 305)
		DllStructSetData($tPoint, "Y", 48)
		Local $aCall = DllCall("user32.dll", "bool", "ClientToScreen", "hwnd", $g_EX_hGUI, "struct*", $tPoint)
		If @error Then ExitLoop 1
		If Not $aCall[0] Then ExitLoop 1
		Local $iWidth = $aClient[0] - 313, $iHeight = $aClient[1] - 280
		If $iWidth < 1 Then $iWidth = 1
		If $iHeight < 1 Then $iHeight = 1
		Local $sGeometry = DllStructGetData($tPoint, "X") & ":" & DllStructGetData($tPoint, "Y") & ":" & $iWidth & ":" & $iHeight
		If $sGeometry = $g_EX_sHostGeometry Then ExitLoop 1
		$g_EX_sHostGeometry = $sGeometry
		_Layout($aClient)
		WinMove($g_EX_hHost, "", DllStructGetData($tPoint, "X"), DllStructGetData($tPoint, "Y"), $iWidth, $iHeight)
		If $g_EX_iWebView >= 0 Then _WebView2_SetBounds($g_EX_iWebView, 0, 0, $iWidth, $iHeight)
	Until True
	Return
EndFunc   ;==>_SyncHost

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Log
; Description ...: Appends a time-stamped line and scrolls to the newest message.
; Syntax ........: _Log($sMessage)
; Parameters ....: $sMessage - Message to append.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Log($sMessage)
	_GUICtrlEdit_AppendText($g_EX_idLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sMessage & @CRLF)
	GUICtrlSendMsg($g_EX_idLog, $EM_SCROLLCARET, 0, 0)
	Return
EndFunc   ;==>_Log

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Click
; Description ...: Starts a separate log group for one AutoIt button click.
; Syntax ........: _Click($sCaption)
; Parameters ....: $sCaption - Visible button caption.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Click($sCaption)
	_GUICtrlEdit_AppendText($g_EX_idLog, @CRLF & "[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [AutoIt]: " & $sCaption & " was clicked." & @CRLF)
	GUICtrlSendMsg($g_EX_idLog, $EM_SCROLLCARET, 0, 0)
	Return
EndFunc   ;==>_Click
