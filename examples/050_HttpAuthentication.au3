#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
; #WIP - Work in Progress: visible credential popup and the complete interactive sequence need confirmation.
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiEdit.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"
Opt("MustDeclareVars", 1)
Opt("TCPTimeout", 1)
Opt("GUIResizeMode", $GUI_DOCKALL)
Global $g_EX_hGUI = 0, $g_EX_hHost = 0, $g_EX_hLogin = 0, $g_EX_idLog = 0, $g_EX_idGuide = 0, $g_EX_iView = -1
Global $g_EX_idUser = 0, $g_EX_idPassword = 0, $g_EX_idLogin = 0, $g_EX_idCancel = 0
Global $g_EX_sGeometry = "", $g_EX_sOrigin = "", $g_EX_sRealm = "", $g_EX_iMode = 0, $g_EX_iSequence = 0
Global $g_EX_iPending = 0, $g_EX_iAuthCount = 0, $g_EX_bShowLogin = False, $g_EX_bNavigationDone = False, $g_EX_bNavigationSuccess = False
Global $g_EX_iListener = -1, $g_EX_aClients[8][4], $g_EX_iAccepted = 0, $g_EX_iRejected = 0, $g_EX_iExpectedAccepted = 0, $g_EX_sChallengedRealm = "", $g_EX_sUsedPorts = "|"
Global $g_EX_bSmoke = False, $g_EX_sSmokeFailure = ""
If $CmdLine[0] Then $g_EX_bSmoke = $CmdLine[1] = "--smoke"
Exit _Example()

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Example
; Description ...: Runs the offline native HTTP authentication demonstration.
; Syntax ........: _Example()
; Parameters ....: See signature.
; Return values .: 0 on normal close or successful smoke; 1 on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	Local $iExit = 1
	Do
		$g_EX_hGUI = GUICreate("WebView2 - HTTP authentication", 1200, 800, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		Local $idAuto = GUICtrlCreateButton("Automatic login", 8, 8, 145, 30)
		Local $idAsk = GUICtrlCreateButton("Ask for credentials", 163, 8, 160, 30)
		Local $idCancel = GUICtrlCreateButton("Cancel authentication", 333, 8, 165, 30)
		Local $idTimeout = GUICtrlCreateButton("Timeout (5 s)", 508, 8, 140, 30)
		Local $idWrong = GUICtrlCreateButton("Wrong password", 658, 8, 145, 30)
		Local $idLeave = GUICtrlCreateButton("Leave page", 813, 8, 120, 30)
		GUICtrlCreateLabel("AutoIt operation log", 8, 50, 330, 18)
		$g_EX_idLog = GUICtrlCreateEdit("", 8, 70, 330, 600, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idLog, 0xE2F0E4)
		$g_EX_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
				"1. Click Automatic login: AutoIt supplies demo / demo; the blue page reports Authentication accepted." & @CRLF & _
				"2. Click Ask for credentials: an AutoIt-owned popup shows the requesting address and challenge. Enter demo / demo and click Log in. Cancel or the popup close button cancels the pending request." & @CRLF & _
				"3. Click Cancel authentication: access must not be granted. Click Wrong password: the server rejects it; AutoIt cancels the second challenge instead of looping." & @CRLF & _
				"4. Click Timeout (5 s): the request waits while this window remains responsive, then AutoIt cancels it. Leave page and window closure also cancel pending requests." & @CRLF & _
				"HOW IT WORKS" & @CRLF & _
				"A small AutoIt TCP server listens only on 127.0.0.1 at an automatically assigned port and returns HTTP 401 with WWW-Authenticate: Basic. WebView2 raises BasicAuthenticationRequested. The UDF retains a native deferral until AutoIt responds. This is HTTP authentication, not an HTML login form. Each test uses a fresh loopback port and realm to avoid cached credentials bypassing the callback. Only dummy demo credentials are used; HTTPS is required for real remote services. No Internet, Python, firewall rule or external account is required.", _
				350, 570, 840, 220, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idGuide, 0xFFF1BF)
		If Not $g_EX_bSmoke Then
			GUISetState(@SW_MAXIMIZE, $g_EX_hGUI)
			GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hGUI)
		EndIf
		$g_EX_hHost = GUICreate("", 1, 1, 0, 0, $WS_POPUP, $WS_EX_NOREDIRECTIONBITMAP, $g_EX_hGUI)
		_SyncHost()
		If Not $g_EX_bSmoke Then GUISetState(@SW_SHOWNOACTIVATE, $g_EX_hHost)
		If Not _ServerStart() Then ExitLoop
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\050_HttpAuthentication"
		If $g_EX_bSmoke Then $sProfile = @TempDir & "\WebView2-HttpAuth-" & @AutoItPID
		_Log("Starting WebView2; local server at " & $g_EX_sOrigin)
		If Not _WebView2_Init(Default, $sProfile) Then ExitLoop
		Local $aSize = WinGetClientSize($g_EX_hHost)
		$g_EX_iView = _WebView2_Create($g_EX_hHost, 0, 0, $aSize[0], $aSize[1])
		If @error Then ExitLoop
		If Not _WebView2_SetCallback($g_EX_iView, $WEBVIEW2_EVENT_BASIC_AUTHENTICATION_REQUESTED, _OnAuthentication) Then ExitLoop
		If Not _WebView2_SetCallback($g_EX_iView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _OnNavigation) Then ExitLoop
		If Not _WebView2_Navigate($g_EX_iView, $g_EX_sOrigin & "/") Then ExitLoop
		If $g_EX_bSmoke Then
			$iExit = _Smoke()
			ExitLoop
		EndIf
		While True
			Local $aMsg = GUIGetMsg(1)
			Switch $aMsg[0]
				Case $GUI_EVENT_CLOSE
					If $aMsg[1] = $g_EX_hLogin And $g_EX_hLogin Then
						_Click("Close credentials window")
						_Answer(True)
					ElseIf $aMsg[1] = $g_EX_hGUI Then
						$iExit = 0
						ExitLoop
					EndIf
				Case $idAuto, $idAsk, $idCancel, $idTimeout, $idWrong
					_Click(GUICtrlRead($aMsg[0]))
					Local $iMode = 0
					If $aMsg[0] = $idAsk Then $iMode = 1
					If $aMsg[0] = $idCancel Then $iMode = 2
					If $aMsg[0] = $idTimeout Then $iMode = 3
					If $aMsg[0] = $idWrong Then $iMode = 4
					_Begin($iMode)
				Case $idLeave
					_Click("Leave page")
					_CloseLogin()
					_WebView2_Navigate($g_EX_iView, $g_EX_sOrigin & "/")
				Case $g_EX_idLogin
					If $g_EX_hLogin Then
						_Click("Log in")
						_Answer(False)
					EndIf
				Case $g_EX_idCancel
					If $g_EX_hLogin Then
						_Click("Cancel")
						_Answer(True)
					EndIf
			EndSwitch
			_Pump()
		WEnd
	Until True
	If $iExit Then _Log("Example failed: " & _WebView2_Error_GetDescription() & " " & $g_EX_sSmokeFailure)
	_CloseLogin()
	_WebView2_Cleanup()
	_ServerStop()
	If $g_EX_hHost Then GUIDelete($g_EX_hHost)
	If $g_EX_hGUI Then GUIDelete($g_EX_hGUI)
	If $g_EX_bSmoke Then FileWrite(@ScriptDir & "\050_HttpAuthentication.result.txt", "HTTP_AUTH_SMOKE arch=" & (@AutoItX64 ? "x64" : "x86") & " exit=" & $iExit & " " & $g_EX_sSmokeFailure & @CRLF)
	Return $iExit
EndFunc   ;==>_Example

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Begin
; Description ...: Starts one protected navigation with a new authentication realm.
; Syntax ........: _Begin($iMode)
; Parameters ....: See signature.
; Return values .: True if navigation was accepted.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _Begin($iMode)
	Local $aOld = _WebView2_Authentication_Request_List($g_EX_iView)
	If @error Then Return False
	For $i = 1 To $aOld[0][0]
		_WebView2_Authentication_Request_Respond($aOld[$i][0], "", "", True)
	Next
	_ServerStop()
	If Not _ServerStart() Then Return False
	_CloseLogin()
	$g_EX_bShowLogin = False
	$g_EX_iPending = 0
	$g_EX_iMode = $iMode
	$g_EX_iExpectedAccepted = $g_EX_iAccepted + 1
	$g_EX_iAuthCount = 0
	$g_EX_iSequence += 1
	$g_EX_sRealm = "WV2-example-" & @AutoItPID & "-" & $g_EX_iSequence
	$g_EX_bNavigationDone = False
	$g_EX_bNavigationSuccess = False
	Local $bResult = _WebView2_Navigate($g_EX_iView, $g_EX_sOrigin & "/protected/" & $g_EX_sRealm)
	If Not $bResult Then _Log("Protected navigation could not start.")
	Return $bResult
EndFunc   ;==>_Begin

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _OnAuthentication
; Description ...: Accepts only the expected loopback server and bounded retry count.
; Syntax ........: _OnAuthentication($iView, $iRequest, $sURI, $sChallenge)
; Parameters ....: See signature.
; Return values .: Two-string credentials array, AUTH_CANCEL or AUTH_DEFER.
; Author ........: mLipok
; Modified ......:
; Remarks .......: No window or blocking WebView2 operation is started inside the native callback.
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _OnAuthentication($iView, $iRequest, $sURI, $sChallenge)
	#forceref $iView
	$g_EX_iAuthCount += 1
	_Log("Authentication request " & $iRequest & " from " & $sURI & "; challenge: " & $sChallenge)
	If StringLeft($sURI, StringLen($g_EX_sOrigin) + 1) <> $g_EX_sOrigin & "/" Or Not StringInStr($sChallenge, $g_EX_sRealm) Then Return $WEBVIEW2_AUTH_CANCEL
	If $g_EX_iAuthCount > 1 Then
		_Log("Repeated challenge cancelled; credentials were not accepted.")
		Return $WEBVIEW2_AUTH_CANCEL
	EndIf
	Switch $g_EX_iMode
		Case 0
			Local $aCorrect = ["demo", "demo"]
			_Log("Returning test credentials; password is not logged.")
			Return $aCorrect
		Case 4
			Local $aWrong = ["demo", "wrong"]
			_Log("Returning deliberately incorrect test credentials.")
			Return $aWrong
		Case 5
			Return "invalid decision"
		Case 2
			_Log("Authentication cancelled by host policy.")
			Return $WEBVIEW2_AUTH_CANCEL
		Case Else
			$g_EX_iPending = $iRequest
			$g_EX_bShowLogin = $g_EX_iMode = 1 And Not $g_EX_bSmoke
			_Log("Request deferred; the AutoIt event loop remains responsive.")
			Return $WEBVIEW2_AUTH_DEFER
	EndSwitch
EndFunc   ;==>_OnAuthentication

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _OnNavigation
; Description ...: Records navigation completion without blocking the callback.
; Syntax ........: _OnNavigation($iView, $bSuccess, $iWebErrorStatus, $iNavigationId)
; Parameters ....: See signature.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _OnNavigation($iView, $bSuccess, $iWebErrorStatus, $iNavigationId)
	#forceref $iView, $iNavigationId
	$g_EX_bNavigationDone = True
	$g_EX_bNavigationSuccess = $bSuccess
	_Log("Navigation completed: success=" & $bSuccess & "; web error=" & $iWebErrorStatus & ".")
EndFunc   ;==>_OnNavigation

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Pump
; Description ...: Services local TCP connections, timeout policy and native GUI layout.
; Syntax ........: _Pump()
; Parameters ....: See signature.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _Pump()
	_ServerPoll()
	Local $iExpired = _WebView2_Authentication_Request_Expire(($g_EX_iMode = 3) ? 5000 : 60000)
	If $iExpired Then _Log("Expired and cancelled authentication requests: " & $iExpired)
	If $g_EX_bShowLogin Then
		$g_EX_bShowLogin = False
		_ShowLogin()
	EndIf
	If $g_EX_hLogin Then
		Local $aPending = _WebView2_Authentication_Request_List($g_EX_iView)
		If Not @error Then
			If $aPending[0][0] = 0 Then _CloseLogin()
		EndIf
	EndIf
	_SyncHost()
	Sleep(10)
EndFunc   ;==>_Pump

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _ShowLogin
; Description ...: Opens a real AutoIt-owned credential popup outside the native callback.
; Syntax ........: _ShowLogin()
; Parameters ....: See signature.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _ShowLogin()
	Local $aRequests = _WebView2_Authentication_Request_List($g_EX_iView)
	If @error Then Return
	If $aRequests[0][0] = 0 Then Return
	$g_EX_hLogin = GUICreate("HTTP authentication - local demo", 540, 240, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), -1, $g_EX_hGUI)
	GUICtrlCreateLabel("Server: " & $aRequests[1][2] & @CRLF & "Challenge: " & $aRequests[1][3], 12, 12, 515, 66)
	GUICtrlCreateLabel("User name", 12, 92, 100, 24)
	$g_EX_idUser = GUICtrlCreateInput("demo", 120, 88, 400, 26)
	GUICtrlCreateLabel("Password", 12, 132, 100, 24)
	$g_EX_idPassword = GUICtrlCreateInput("demo", 120, 128, 400, 26, $ES_PASSWORD)
	$g_EX_idLogin = GUICtrlCreateButton("Log in", 280, 184, 110, 30)
	$g_EX_idCancel = GUICtrlCreateButton("Cancel", 400, 184, 110, 30)
	GUISetState(@SW_DISABLE, $g_EX_hGUI)
	GUISetState(@SW_SHOW, $g_EX_hLogin)
EndFunc   ;==>_ShowLogin

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _CloseLogin
; Description ...: Clears password input and removes the owned credential window.
; Syntax ........: _CloseLogin()
; Parameters ....: See signature.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _CloseLogin()
	If Not $g_EX_hLogin Then Return
	GUICtrlSetData($g_EX_idPassword, "")
	GUISetState(@SW_ENABLE, $g_EX_hGUI)
	GUIDelete($g_EX_hLogin)
	$g_EX_hLogin = 0
	$g_EX_idLogin = 0
	$g_EX_idCancel = 0
EndFunc   ;==>_CloseLogin

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Answer
; Description ...: Completes one deferred authentication request from the main GUI loop.
; Syntax ........: _Answer($bCancel)
; Parameters ....: See signature.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _Answer($bCancel)
	Local $sUser = "", $sPassword = ""
	If Not $bCancel Then
		$sUser = GUICtrlRead($g_EX_idUser)
		$sPassword = GUICtrlRead($g_EX_idPassword)
	EndIf
	Local $bResult = _WebView2_Authentication_Request_Respond($g_EX_iPending, $sUser, $sPassword, $bCancel)
	Local $iError = @error, $iExtended = @extended
	$sPassword = ""
	_Log("Authentication response completed=" & $bResult & "; error=" & $iError & "; extended=" & $iExtended)
	_CloseLogin()
	$g_EX_iPending = 0
EndFunc   ;==>_Answer

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _ServerStart
; Description ...: Binds the demonstration server to loopback at a free high port.
; Syntax ........: _ServerStart()
; Parameters ....: See signature.
; Return values .: True on a successful loopback bind.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _ServerStart()
	For $i = 0 To 7
		$g_EX_aClients[$i][0] = -1
	Next
	If Not TCPStartup() Then
		_Log("TCP startup failed: " & @error)
		Return False
	EndIf
	Local $iPort = 0
	; TCPListen rejects port zero in AutoIt; bind the selected high port directly, retrying collisions.
	For $i = 1 To 16
		$iPort = Random(49152, 65535, 1)
		If StringInStr($g_EX_sUsedPorts, "|" & $iPort & "|") Then ContinueLoop
		$g_EX_iListener = TCPListen("127.0.0.1", $iPort, 8)
		If $g_EX_iListener <> -1 Then ExitLoop
	Next
	If $g_EX_iListener = -1 Then
		_Log("Could not bind a loopback TCP listener after 16 attempts.")
		Return False
	EndIf
	$g_EX_sUsedPorts &= $iPort & "|"
	$g_EX_sOrigin = "http://127.0.0.1:" & $iPort
	Return True
EndFunc   ;==>_ServerStart

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _ServerPoll
; Description ...: Processes bounded HTTP headers and sends short deterministic responses.
; Syntax ........: _ServerPoll()
; Parameters ....: See signature.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _ServerPoll()
	For $i = 0 To 7
		If $g_EX_aClients[$i][0] = -1 Then
			Local $iSocket = TCPAccept($g_EX_iListener)
			If $iSocket <> -1 Then
				$g_EX_aClients[$i][0] = $iSocket
				$g_EX_aClients[$i][1] = ""
				$g_EX_aClients[$i][2] = TimerInit()
				$g_EX_aClients[$i][3] = ""
			EndIf
		EndIf
		If $g_EX_aClients[$i][0] = -1 Then ContinueLoop
		If TimerDiff($g_EX_aClients[$i][2]) > 10000 Then
			_ServerClose($i)
			ContinueLoop
		EndIf
		If $g_EX_aClients[$i][3] = "" Then
			Local $sPart = TCPRecv($g_EX_aClients[$i][0], 4096)
			If @error Then
				_ServerClose($i)
				ContinueLoop
			EndIf
			$g_EX_aClients[$i][1] &= $sPart
			If StringLen($g_EX_aClients[$i][1]) > 16384 Then
				_ServerClose($i)
				ContinueLoop
			EndIf
			If StringInStr($g_EX_aClients[$i][1], @CRLF & @CRLF) Then
				$g_EX_aClients[$i][3] = _ServerResponse($g_EX_aClients[$i][1])
				; Discard headers, including the test Authorization value, immediately.
				$g_EX_aClients[$i][1] = ""
			EndIf
		EndIf
		If $g_EX_aClients[$i][3] <> "" Then
			Local $iSent = TCPSend($g_EX_aClients[$i][0], $g_EX_aClients[$i][3])
			If @error Then
				_ServerClose($i)
				ContinueLoop
			EndIf
			If $iSent > 0 Then $g_EX_aClients[$i][3] = StringTrimLeft($g_EX_aClients[$i][3], $iSent)
			If $g_EX_aClients[$i][3] = "" Then _ServerClose($i)
		EndIf
	Next
EndFunc   ;==>_ServerPoll

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _ServerResponse
; Description ...: Builds a 401 challenge or an authenticated local HTML response.
; Syntax ........: _ServerResponse($sHeaders)
; Parameters ....: See signature.
; Return values .: ASCII HTTP response, including bounded content length.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Dummy demo credentials only. Authorization headers and passwords are never logged.
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _ServerResponse($sHeaders)
	Local $aPath = StringRegExp($sHeaders, "^GET ([^ ]+) HTTP/1\.[01]", 1)
	Local $sStatus = "200 OK", $sExtra = "", $sTitle = "Local HTTP authentication demo"
	If Not IsArray($aPath) Then
		$sStatus = "400 Bad Request"
	ElseIf StringLeft($aPath[0], 11) = "/protected/" Then
		Local $sRealm = StringTrimLeft($aPath[0], 11)
		If Not StringRegExp($sRealm, "^WV2-example-[0-9]+-[0-9]+$") Then
			$sStatus = "400 Bad Request"
		ElseIf $g_EX_sChallengedRealm = $sRealm And StringRegExp($sHeaders, "(?im)^Authorization: Basic ZGVtbzpkZW1v\r?$") Then
			$g_EX_iAccepted += 1
			$sTitle = "Authentication accepted"
			_Log("Local server granted access.")
		Else
			If StringRegExp($sHeaders, "(?im)^Authorization:") Then $g_EX_iRejected += 1
			$g_EX_sChallengedRealm = $sRealm
			$sStatus = "401 Unauthorized"
			$sExtra = 'WWW-Authenticate: Basic realm="' & $sRealm & '"' & @CRLF
			$sTitle = "Authentication required"
		EndIf
	EndIf
	Local $sBody = '<!doctype html><html><head><meta charset="utf-8"><title>' & $sTitle & '</title></head><body style="font:20px Arial;margin:24px"><section style="padding:30px;background:#e8f2ff;border:2px solid #287abd"><h1>' & $sTitle & '</h1><p>This page is served only by the local AutoIt demonstration server.</p><p>Use the AutoIt buttons above the browser to test native HTTP authentication.</p></section></body></html>'
	Return "HTTP/1.1 " & $sStatus & @CRLF & $sExtra & "Content-Type: text/html; charset=utf-8" & @CRLF & "Cache-Control: no-store" & @CRLF & "Connection: close" & @CRLF & "Content-Length: " & StringLen($sBody) & @CRLF & @CRLF & $sBody
EndFunc   ;==>_ServerResponse

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _ServerClose
; Description ...: Closes one example-owned accepted TCP connection.
; Syntax ........: _ServerClose($iSlot)
; Parameters ....: See signature.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _ServerClose($iSlot)
	If $g_EX_aClients[$iSlot][0] <> -1 Then TCPCloseSocket($g_EX_aClients[$iSlot][0])
	$g_EX_aClients[$iSlot][0] = -1
	$g_EX_aClients[$iSlot][1] = ""
	$g_EX_aClients[$iSlot][3] = ""
EndFunc   ;==>_ServerClose

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _ServerStop
; Description ...: Closes only demonstration-owned sockets and the TCP subsystem.
; Syntax ........: _ServerStop()
; Parameters ....: See signature.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _ServerStop()
	For $i = 0 To 7
		_ServerClose($i)
	Next
	If $g_EX_iListener <> -1 Then TCPCloseSocket($g_EX_iListener)
	$g_EX_iListener = -1
	TCPShutdown()
EndFunc   ;==>_ServerStop

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Wait
; Description ...: Pumps native messages and the server until the requested observation.
; Syntax ........: _Wait($sKind, $iTimeoutMs = 10000)
; Parameters ....: See signature.
; Return values .: True on observation; False on timeout.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _Wait($sKind, $iTimeoutMs = 10000)
	Local $iStarted = TimerInit()
	While TimerDiff($iStarted) < $iTimeoutMs
		_Pump()
		Switch $sKind
			Case "navigation"
				If $g_EX_bNavigationDone Then Return True
			Case "granted"
				If $g_EX_iAccepted >= $g_EX_iExpectedAccepted And $g_EX_bNavigationDone And $g_EX_bNavigationSuccess Then Return True
			Case "retry"
				If $g_EX_iAuthCount >= 2 Then Return True
			Case "pending"
				If $g_EX_iPending > 0 Then Return True
		EndSwitch
	WEnd
	$g_EX_sSmokeFailure = "Timed out waiting for " & $sKind
	Return False
EndFunc   ;==>_Wait

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Smoke
; Description ...: Exercises immediate, deferred, failed, expired and destroyed-owner decisions.
; Syntax ........: _Smoke()
; Parameters ....: See signature.
; Return values .: Zero on success; one on the first failed assertion.
; Author ........: mLipok
; Modified ......:
; Remarks .......: No credential popup is displayed by smoke mode.
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _Smoke()
	If Not _Wait("navigation") Then Return 1
	If Not _Begin(0) Or Not _Wait("granted") Then Return 1
	If $g_EX_iAuthCount <> 1 Or $g_EX_iAccepted < 1 Then Return _SmokeFail("Immediate login did not reach server success.")
	; The appended native callback index must not break the existing async callback pool.
	Local $iA = _WebView2_ExecuteScriptAsyncStart($g_EX_iView, "100+1")
	If @error Then Return _SmokeFail("Async request A failed to start.")
	Local $iB = _WebView2_ExecuteScriptAsyncStart($g_EX_iView, "200+2")
	If @error Then Return _SmokeFail("Async request B failed to start.")
	Local $sA = "", $sB = "", $iAsyncStarted = TimerInit()
	While $iA Or $iB
		_Pump()
		If $iA Then
			Local $iPollA = _WebView2_ExecuteScriptAsyncPoll($iA, $sA)
			If @error Then Return _SmokeFail("Async request A failed to poll.")
			If $iPollA = 1 Then $iA = 0
		EndIf
		If $iB Then
			Local $iPollB = _WebView2_ExecuteScriptAsyncPoll($iB, $sB)
			If @error Then Return _SmokeFail("Async request B failed to poll.")
			If $iPollB = 1 Then $iB = 0
		EndIf
		If TimerDiff($iAsyncStarted) > 5000 Then Return _SmokeFail("Async callback regression timed out.")
	WEnd
	If $sA <> "101" Or $sB <> "202" Then Return _SmokeFail("Async callback regression result mismatch.")
	Local $iAccepted = $g_EX_iAccepted
	If Not _Begin(1) Or Not _Wait("pending") Then Return 1
	Local $aList = _WebView2_Authentication_Request_List($g_EX_iView)
	If @error Then Return 1
	If $aList[0][0] <> 1 Or $aList[1][0] <> $g_EX_iPending Then Return _SmokeFail("Pending metadata mismatch.")
	Local $iAnswered = $g_EX_iPending
	_WebView2_Authentication_Request_Respond($iAnswered, 7, "demo")
	If @error <> $WEBVIEW2_ERR_INVALID_PARAMETER Then Return _SmokeFail("Invalid credentials were not rejected.")
	_WebView2_Authentication_Request_Respond($iAnswered, "", "")
	If @error <> $WEBVIEW2_ERR_INVALID_PARAMETER Then Return _SmokeFail("Empty credentials were not rejected.")
	_WebView2_Authentication_Request_Respond($iAnswered, "demo", "x" & Chr(0))
	If @error <> $WEBVIEW2_ERR_INVALID_PARAMETER Then Return _SmokeFail("NUL credentials were not rejected.")
	If Not _WebView2_Authentication_Request_Respond($iAnswered, "demo", "demo") Then Return 1
	If Not _Wait("granted") Then Return 1
	If $g_EX_iAccepted <> $iAccepted + 1 Then Return _SmokeFail("Deferred login did not reach server success.")
	_WebView2_Authentication_Request_Respond($iAnswered, "demo", "demo")
	If @error <> $WEBVIEW2_ERR_NO_MATCH Then Return _SmokeFail("Answered ID remained valid.")
	$iAccepted = $g_EX_iAccepted
	If Not _Begin(2) Or Not _Wait("navigation") Then Return 1
	_Settle()
	If $g_EX_iAccepted <> $iAccepted Or $g_EX_iAuthCount < 1 Then Return _SmokeFail("Cancel did not deny access.")
	If Not _Begin(5) Or Not _Wait("navigation") Then Return 1
	_Settle()
	If $g_EX_iAccepted <> $iAccepted Then Return _SmokeFail("Invalid callback decision granted access.")
	If Not _Begin(4) Or Not _Wait("retry") Then Return 1
	_Settle()
	If $g_EX_iRejected < 1 Or $g_EX_iAuthCount <> 2 Or $g_EX_iAccepted <> $iAccepted Then Return _SmokeFail("Wrong-password retry was not cancelled.")
	If Not _Begin(3) Or Not _Wait("pending") Then Return 1
	Local $iExpiredId = $g_EX_iPending, $iTimer = TimerInit()
	While TimerDiff($iTimer) < 180
		_Pump()
	WEnd
	If _WebView2_Authentication_Request_Expire(150) <> 1 Then Return _SmokeFail("Timeout did not consume pending request.")
	_WebView2_Authentication_Request_Respond($iExpiredId, "demo", "demo")
	If @error <> $WEBVIEW2_ERR_NO_MATCH Then Return _SmokeFail("Expired ID remained valid.")
	If Not _Wait("navigation") Then Return 1
	_Settle()
	If $g_EX_iAccepted <> $iAccepted Then Return _SmokeFail("Timed-out authentication granted access.")
	If Not _Begin(1) Or Not _Wait("pending") Then Return 1
	Local $iNavigatedId = $g_EX_iPending
	$g_EX_bNavigationDone = False
	_WebView2_Navigate($g_EX_iView, $g_EX_sOrigin & "/")
	If Not _Wait("navigation") Then Return 1
	_WebView2_Authentication_Request_Respond($iNavigatedId, "demo", "demo")
	If @error <> $WEBVIEW2_ERR_NO_MATCH Then Return _SmokeFail("Navigated request ID remained valid.")
	If Not _Begin(1) Or Not _Wait("pending") Then Return 1
	Local $iDestroyedId = $g_EX_iPending
	If Not _WebView2_Destroy($g_EX_iView) Then Return 1
	$g_EX_iView = -1
	_WebView2_Authentication_Request_Respond($iDestroyedId, "demo", "demo")
	If @error <> $WEBVIEW2_ERR_NO_MATCH Then Return _SmokeFail("Destroyed-owner ID remained valid.")
	Local $aEmpty = _WebView2_Authentication_Request_List()
	If @error Then Return 1
	If $aEmpty[0][0] <> 0 Then Return _SmokeFail("Pending requests leaked after destruction.")
	; Reuse the controller slot to verify subscription cleanup and fresh native ownership.
	Local $aHostSize = WinGetClientSize($g_EX_hHost)
	$g_EX_iView = _WebView2_Create($g_EX_hHost, 0, 0, $aHostSize[0], $aHostSize[1])
	If @error Then Return 1
	If Not _WebView2_SetCallback($g_EX_iView, $WEBVIEW2_EVENT_BASIC_AUTHENTICATION_REQUESTED, _OnAuthentication) Then Return 1
	If Not _WebView2_SetCallback($g_EX_iView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _OnNavigation) Then Return 1
	If Not _Begin(0) Or Not _Wait("granted") Then Return _SmokeFail("Reused view could not authenticate.")
	If Not _Begin(1) Or Not _Wait("pending") Then Return 1
	Local $iCleanupId = $g_EX_iPending
	If Not _WebView2_Cleanup() Then Return _SmokeFail("Cleanup failed with a pending request.")
	$g_EX_iView = -1
	_WebView2_Authentication_Request_Respond($iCleanupId, "demo", "demo")
	If @error <> $WEBVIEW2_ERR_NO_MATCH Then Return _SmokeFail("Cleanup ID remained valid.")
	_Log("All targeted native HTTP authentication checks passed.")
	Return 0
EndFunc   ;==>_Smoke

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _SmokeFail
; Description ...: Records a precise failed smoke assertion.
; Syntax ........: _SmokeFail($sReason)
; Parameters ....: See signature.
; Return values .: One.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _SmokeFail($sReason)
	$g_EX_sSmokeFailure = $sReason
	Return 1
EndFunc   ;==>_SmokeFail

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _SyncHost
; Description ...: Fits the separate browser host and native panels to the current client rectangle.
; Syntax ........: _SyncHost()
; Parameters ....: See signature.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _SyncHost()
	If Not $g_EX_hHost Then Return
	Local $aClient = WinGetClientSize($g_EX_hGUI)
	If Not IsArray($aClient) Then Return
	Local $iLeft = 350, $iTop = 50, $iGuide = 230
	If $aClient[0] < 800 Then $iLeft = 260
	If $aClient[1] < 600 Then $iGuide = 160
	Local $iWidth = $aClient[0] - $iLeft - 8, $iHeight = $aClient[1] - $iTop - $iGuide - 18
	If $iWidth < 1 Then $iWidth = 1
	If $iHeight < 1 Then $iHeight = 1
	Local $tPoint = DllStructCreate("long X;long Y")
	DllStructSetData($tPoint, "X", $iLeft)
	DllStructSetData($tPoint, "Y", $iTop)
	Local $aCall = DllCall("user32.dll", "bool", "ClientToScreen", "hwnd", $g_EX_hGUI, "struct*", $tPoint)
	If @error Then Return
	If Not $aCall[0] Then Return
	Local $sGeometry = DllStructGetData($tPoint, "X") & ":" & DllStructGetData($tPoint, "Y") & ":" & $iWidth & ":" & $iHeight
	If $sGeometry = $g_EX_sGeometry Then Return
	$g_EX_sGeometry = $sGeometry
	GUICtrlSetPos($g_EX_idLog, 8, 70, $iLeft - 20, $aClient[1] - 80)
	GUICtrlSetPos($g_EX_idGuide, $iLeft, $aClient[1] - $iGuide - 8, $iWidth, $iGuide)
	WinMove($g_EX_hHost, "", DllStructGetData($tPoint, "X"), DllStructGetData($tPoint, "Y"), $iWidth, $iHeight)
	If $g_EX_iView >= 0 Then _WebView2_SetBounds($g_EX_iView, 0, 0, $iWidth, $iHeight)
EndFunc   ;==>_SyncHost

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Log
; Description ...: Appends a timestamped message and scrolls to the latest operation.
; Syntax ........: _Log($sMessage)
; Parameters ....: See signature.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _Log($sMessage)
	ConsoleWrite("[AUTH DEMO] " & $sMessage & @CRLF)
	If Not $g_EX_idLog Then Return
	_GUICtrlEdit_AppendText($g_EX_idLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sMessage & @CRLF)
	GUICtrlSendMsg($g_EX_idLog, $EM_SCROLLCARET, 0, 0)
EndFunc   ;==>_Log

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: _Click
; Description ...: Starts a new log group for a real AutoIt control activation.
; Syntax ........: _Click($sCaption)
; Parameters ....: See signature.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _Click($sCaption)
	_GUICtrlEdit_AppendText($g_EX_idLog, @CRLF & "[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [AutoIt]: " & $sCaption & " was clicked." & @CRLF)
	GUICtrlSendMsg($g_EX_idLog, $EM_SCROLLCARET, 0, 0)
EndFunc   ;==>_Click


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Settle
; Description ...: Pumps outstanding network completions before negative smoke assertions.
; Syntax ........: _Settle()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _Smoke
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _Settle()
	Local $iStarted = TimerInit()
	While TimerDiff($iStarted) < 300
		_Pump()
	WEnd
EndFunc   ;==>_Settle
