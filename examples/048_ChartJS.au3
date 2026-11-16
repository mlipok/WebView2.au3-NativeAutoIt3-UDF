#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GuiComboBox.au3>
#include "..\WebView2.au3"
Opt("MustDeclareVars", 1)
Global $g_EX_hGUI = 0, $g_EX_hHost = 0, $g_EX_idLog = 0, $g_EX_idGuide = 0, $g_EX_iWebView = -1
Global $g_EX_sHostGeometry = "", $g_EX_bReady = False, $g_EX_bSmoke = False
If $CmdLine[0] Then $g_EX_bSmoke = $CmdLine[1] = "--smoke"
Exit _Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Demonstrates an offline Chart.js chart with updates and page-to-host messages.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: Zero on success, one on initialization or smoke failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Smoke actions are programmatic and are not logged as user clicks.
; Related .......: _OnWebMessage
; Link ..........: https://www.chartjs.org/
; Example .......: Yes
; ===============================================================================================================================
Func _Example()
	Local $iExit = 1, $iTimer = TimerInit(), $iSmokeStage = 0
	Do
		$g_EX_hGUI = GUICreate("WebView2 - Offline Chart.js", 1100, 720, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
		Local $idUpdate = GUICtrlCreateButton("Update values", 8, 8, 145, 30)
		Local $idReset = GUICtrlCreateButton("Reset values", 163, 8, 145, 30)
		Local $idRead = GUICtrlCreateButton("Read chart data", 318, 8, 145, 30)
		GUICtrlCreateLabel("Chart type", 480, 15, 65, 20)
		Local $idType = GUICtrlCreateCombo("", 550, 10, 200, 28, $CBS_DROPDOWNLIST)
		GUICtrlSetData($idType, "Bar|Line|Pie|Doughnut|Radar|Polar area|Scatter|Bubble|Mixed (bar + line)", "Bar")
		GUICtrlSetState($idType, $GUI_DISABLE)
		GUICtrlSetData($idType, "Bar|Line|Pie|Doughnut|Radar|Polar area|Scatter|Bubble|Mixed (bar + line)", "Bar")
		Local $aTypes = ["bar", "line", "pie", "doughnut", "radar", "polarArea", "scatter", "bubble", "mixed"]
		GUICtrlCreateLabel("AutoIt operation log", 8, 48, 285, 18)
		$g_EX_idLog = GUICtrlCreateEdit("", 8, 68, 285, 450, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
		GUICtrlSetBkColor($g_EX_idLog, 0xE2F0E4)
		$g_EX_idGuide = GUICtrlCreateEdit("TEST PROCEDURE" & @CRLF & _
				"1. Wait for the ready message. The chart should show Alpha=10, Beta=20, Gamma=30." & @CRLF & _
				"2. Click Update values: bars change to 35, 15, 45. The log reports a page acknowledgement." & @CRLF & _
				"3. Click a data item: the log identifies a WebView2 click, its label and value. Blank chart areas produce no bar click." & @CRLF & _
				"4. Choose any Chart type: values should be retained. Scatter uses x=1,2,3 and y=the sample values; Bubble also uses fixed radii. Mixed shows the same values as bars and a line. Resize the window to check chart fit." & @CRLF & _
				"HOW IT WORKS" & @CRLF & _
				"Chart.js renders a canvas from local JavaScript files. AutoIt executes a small update function, and the page sends JSON acknowledgements and trusted bar-click messages. The local folder is mapped to a virtual HTTPS host. No Internet connection or server is required. Chart.js is MIT licensed; its license and source notice are bundled.", _
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
		Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\048_ChartJS"
		If $g_EX_bSmoke Then $sProfile = @ScriptDir & "\..\..\profiles\048-chart-" & (@AutoItX64 ? "x64" : "x86")
		_Log("Starting WebView2...")
		If Not _WebView2_Init(Default, $sProfile) Then ExitLoop 1
		Local $aSize = WinGetClientSize($g_EX_hHost)
		$g_EX_iWebView = _WebView2_Create($g_EX_hHost, 0, 0, $aSize[0], $aSize[1])
		If @error Then ExitLoop 1
		If Not _WebView2_SetCallback($g_EX_iWebView, $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED, _OnWebMessage) Then ExitLoop 1
		If Not _WebView2_SetVirtualHostNameToFolderMapping($g_EX_iWebView, "udf-virtual-host.example", @ScriptDir & "\assets\native\048-chart") Then ExitLoop 1
		If Not _WebView2_Navigate($g_EX_iWebView, "https://udf-virtual-host.example/index.html") Then ExitLoop 1
		While True
			Local $aMsg = GUIGetMsg(1)
			Switch $aMsg[0]
				Case $idType
					_Log("Chart type selection changed to " & GUICtrlRead($idType) & ".")
					If $g_EX_bReady Then
						Local $iType = _GUICtrlComboBox_GetCurSel($idType)
						If $iType >= 0 And $iType < UBound($aTypes) Then
							Local $sTypeResult = _WebView2_ExecuteScript($g_EX_iWebView, 'setChartType("' & $aTypes[$iType] & '")')
							If @error Then
								_Log("Chart type change failed: " & _WebView2_Error_GetDescription())
							Else
								_Log("Chart result: " & $sTypeResult)
							EndIf
						EndIf
					EndIf
				Case $idUpdate, $idReset, $idRead
					_Click(GUICtrlRead($aMsg[0]))
					If $g_EX_bReady Then
						Local $sScript = "readChart()"
						If $aMsg[0] = $idUpdate Then $sScript = "setSample([35,15,45])"
						If $aMsg[0] = $idReset Then $sScript = "setSample([10,20,30])"
						Local $sResult = _WebView2_ExecuteScript($g_EX_iWebView, $sScript)
						If @error Then
							_Log("Script failed: " & _WebView2_Error_GetDescription())
						Else
							_Log("Chart result: " & $sResult)
						EndIf
					Else
						_Log("Wait for Chart.js to become ready.")
					EndIf
				Case $GUI_EVENT_CLOSE
					If $aMsg[1] = $g_EX_hGUI Then
						$iExit = 0
						ExitLoop
					EndIf
			EndSwitch
			_SyncHost()
			If $g_EX_bReady Then GUICtrlSetState($idType, $GUI_ENABLE)
			If $g_EX_bSmoke Then
				If $g_EX_bReady And $iSmokeStage = 0 Then
					_WebView2_ExecuteScript($g_EX_iWebView, "setSample([35,15,45])")
					$iSmokeStage = 1
				EndIf
				If $iSmokeStage = 1 Then
					Local $sSmoke = _WebView2_ExecuteScript($g_EX_iWebView, "readChart()")
					If StringInStr($sSmoke, '"values":[35,15,45]') And StringInStr($sSmoke, '"version":"4.5.1"') Then
						Local $sTypes = _WebView2_ExecuteScript($g_EX_iWebView, "['bar','line','pie','doughnut','radar','polarArea','scatter','bubble','mixed'].every(type=>{const s=setChartType(type);return s.type===type&&s.values.join(',')==='35,15,45'&&s.width>0&&s.height>0})")
						If $sTypes = "true" Then $iExit = 0
						ExitLoop
					EndIf
				EndIf
				If TimerDiff($iTimer) > 15000 Then ExitLoop
			EndIf
		WEnd
	Until True
	If $iExit Then _Log("Example failed: " & _WebView2_Error_GetDescription())
	If $g_EX_bSmoke Then FileWrite(@ScriptDir & "\048_ChartJS.result.txt", "CHART_SMOKE arch=" & (@AutoItX64 ? "x64" : "x86") & " exit=" & $iExit & @CRLF)
	_WebView2_Cleanup()
	If $g_EX_hHost Then GUIDelete($g_EX_hHost)
	If $g_EX_hGUI Then GUIDelete($g_EX_hGUI)
	Return $iExit
EndFunc   ;==>_Example

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _OnWebMessage
; Description ...: Logs messages only from the expected local chart page.
; Syntax ........: _OnWebMessage($iWebView, $sMessage, $sSource, $bJSON)
; Parameters ....: Standard native WebView2 message fields.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Bar clicks require a browser-trusted event in the project-owned page script.
; Related .......: _Example
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _OnWebMessage($iWebView, $sMessage, $sSource, $bJSON)
	#forceref $iWebView
	If $bJSON And $sSource = "https://udf-virtual-host.example/index.html" Then
		If $sMessage = '{"kind":"ready","version":"4.5.1"}' Then $g_EX_bReady = True
		Local $aClick = StringRegExp($sMessage, '^\{"kind":"click","caption":"Data item (Alpha|Beta|Gamma)","label":"\1","value":([0-9]+)\}$', 1)
		If IsArray($aClick) Then
			_GUICtrlEdit_AppendText($g_EX_idLog, @CRLF & "[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [WebView2]: Data item " & $aClick[0] & " was clicked." & @CRLF)
			_Log("Selected " & $aClick[0] & "; value=" & $aClick[1] & ".")
		Else
			_Log("Chart message: " & $sMessage)
		EndIf
	EndIf
	Return
EndFunc   ;==>_OnWebMessage


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Layout
; Description ...: Fits the log and guide to the GUI client area.
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
; Description ...: Appends a time-stamped message and scrolls to the newest line.
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
