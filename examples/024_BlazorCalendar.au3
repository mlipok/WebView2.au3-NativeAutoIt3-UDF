#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global Const $g_sCalendarHost = "autoit-calendar.example"
Global Const $g_sCalendarOrigin = "https://" & $g_sCalendarHost & "/"
Global $g_iCalendarView = -1
Global $g_idCalendarStatus = 0
Global $g_bCalendarReady = False

_Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Hosts the bundled standalone Blazor WebAssembly calendar in native WebView2.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: All files under 024_BlazorCalendar/published are loaded through a virtual HTTPS host.
; Related .......: _WebView2_SetVirtualHostNameToFolderMapping
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example()
	Local $hGUI = GUICreate("WebView2 - Blazor Calendar", 1200, 800, -1, -1, $WS_OVERLAPPEDWINDOW)
	Local $idYear = GUICtrlCreateButton("Year", 10, 8, 75, 28)
	Local $idMonth = GUICtrlCreateButton("Month", 90, 8, 75, 28)
	Local $idWeek = GUICtrlCreateButton("Week", 170, 8, 75, 28)
	Local $idReloadData = GUICtrlCreateButton("Reload sample events", 255, 8, 150, 28)
	$g_idCalendarStatus = GUICtrlCreateLabel("Starting WebView2...", 415, 14, 770, 22)
	GUISetState(@SW_SHOW, $hGUI)

	If Not _WebView2_Init() Then
		_Example_Status("WebView2 initialization failed: " & _WebView2_Error_GetDescription())
	Else
		Local $aClient = WinGetClientSize($hGUI)
		$g_iCalendarView = _WebView2_Create($hGUI, 0, 44, $aClient[0], $aClient[1] - 44)
		If @error Then
			_Example_Status("WebView2 creation failed: " & _WebView2_Error_GetDescription())
		Else
			_WebView2_SetCallback($g_iCalendarView, $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED, _Example_OnMessage)
			_WebView2_SetCallback($g_iCalendarView, $WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _Example_OnNavigationCompleted)
			Local $sWebRoot = @ScriptDir & "\024_BlazorCalendar\published"
			If Not FileExists($sWebRoot & "\index.html") Then
				_Example_Status("Published WebAssembly files are missing: " & $sWebRoot)
			ElseIf Not _WebView2_SetVirtualHostNameToFolderMapping($g_iCalendarView, $g_sCalendarHost, $sWebRoot, $WEBVIEW2_HOST_RESOURCE_ACCESS_DENY) Then
				_Example_Status("Virtual host mapping failed: " & _WebView2_Error_GetDescription())
			ElseIf Not _WebView2_Navigate($g_iCalendarView, $g_sCalendarOrigin & "index.html") Then
				_Example_Status("Navigation failed: " & _WebView2_Error_GetDescription())
			Else
				_Example_Status("Loading local WebAssembly assets...")
			EndIf
		EndIf
	EndIf

	While True
		If $g_bCalendarReady Then
			$g_bCalendarReady = False
			_Example_SendInitialData()
		EndIf
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
				If $g_iCalendarView >= 0 Then
					$aClient = WinGetClientSize($hGUI)
					If IsArray($aClient) Then _WebView2_SetBounds($g_iCalendarView, 0, 44, $aClient[0], $aClient[1] - 44)
				EndIf
			Case $idYear
				_Example_SetView("year")
			Case $idMonth
				_Example_SetView("month")
			Case $idWeek
				_Example_SetView("week")
			Case $idReloadData
				_Example_SendInitialData()
		EndSwitch
	WEnd
	_WebView2_Cleanup()
	GUIDelete($hGUI)
	Return
EndFunc   ;==>_Example

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_SendInitialData
; Description ...: Sends fixed sample data using the version 1 JSON protocol.
; Syntax ........: _Example_SendInitialData()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The end of every interval is exclusive. All offsets match Europe/Warsaw on 2026-10-13.
; Related .......: _WebView2_PostWebMessageAsJson
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_SendInitialData()
	If $g_iCalendarView >= 0 Then
		Local $sJSON = '{"type":"initialize","requestId":"sample-1","timeZone":"Europe/Warsaw","view":"week","date":"2026-10-13T12:00:00+02:00","events":[' & _
				'{"id":101,"title":"Planning","start":"2026-10-13T09:00:00+02:00","end":"2026-10-13T10:30:00+02:00","color":"#3984c6"},' & _
				'{"id":102,"title":"Review","start":"2026-10-13T09:30:00+02:00","end":"2026-10-13T11:00:00+02:00","color":"#cc7b37"},' & _
				'{"id":103,"title":"All-day sample","start":"2026-10-14T00:00:00+02:00","end":"2026-10-15T00:00:00+02:00","allDay":true,"color":"#6c9b54"}' & _
				']}'
		If Not _WebView2_PostWebMessageAsJson($g_iCalendarView, $sJSON) Then _Example_Status("Data send failed: " & _WebView2_Error_GetDescription())
	EndIf
	Return
EndFunc   ;==>_Example_SendInitialData

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_SetView
; Description ...: Changes the displayed calendar view.
; Syntax ........: _Example_SetView($sView)
; Parameters ....: $sView - year, month or week.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_PostWebMessageAsJson
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_SetView($sView)
	If $g_iCalendarView >= 0 Then
		Local $sJSON = '{"type":"setView","requestId":"view-change","view":"' & $sView & '"}'
		If Not _WebView2_PostWebMessageAsJson($g_iCalendarView, $sJSON) Then _Example_Status("View change failed: " & _WebView2_Error_GetDescription())
	EndIf
	Return
EndFunc   ;==>_Example_SetView

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_OnMessage
; Description ...: Receives and reports calendar JSON messages.
; Syntax ........: _Example_OnMessage($iWebView, $sMessage, $sSource, $bJSON)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sMessage - JSON message text.
;                  $sSource - Document URI.
;                  $bJSON - True for an object message retrieved as JSON.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Only messages from the mapped origin are accepted; no privileged action is dispatched.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_OnMessage($iWebView, $sMessage, $sSource, $bJSON)
	If $iWebView = $g_iCalendarView And $bJSON And StringLeft($sSource, StringLen($g_sCalendarOrigin)) = $g_sCalendarOrigin And StringLen($sMessage) <= 8192 Then
		Local $aType = StringRegExp($sMessage, '"type"\s*:\s*"([A-Za-z]+)"', 1)
		If IsArray($aType) Then
			Switch $aType[0]
				Case "ready"
					$g_bCalendarReady = True
					_Example_Status("Calendar ready; sending sample events.")
				Case "ack", "rangeSelected", "eventClicked", "dayDoubleClicked"
					_Example_Status($sMessage)
				Case "error"
					_Example_Status("Calendar error: " & $sMessage)
			EndSwitch
		EndIf
	EndIf
	Return
EndFunc   ;==>_Example_OnMessage

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_OnNavigationCompleted
; Description ...: Reports page-navigation errors before Blazor initialization.
; Syntax ........: _Example_OnNavigationCompleted($iWebView, $bSuccess, $iWebErrorStatus, $iNavigationId)
; Parameters ....: $iWebView - WebView instance ID.
;                  $bSuccess - Navigation result.
;                  $iWebErrorStatus - Native WebView2 status.
;                  $iNavigationId - Navigation identifier.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_OnNavigationCompleted($iWebView, $bSuccess, $iWebErrorStatus, $iNavigationId)
	#forceref $iNavigationId
	If $iWebView = $g_iCalendarView And Not $bSuccess Then _Example_Status("Navigation error: " & $iWebErrorStatus)
	Return
EndFunc   ;==>_Example_OnNavigationCompleted

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example_Status
; Description ...: Displays diagnostic status in the host window and console.
; Syntax ........: _Example_Status($sText)
; Parameters ....: $sText - Message text.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_Status($sText)
	GUICtrlSetData($g_idCalendarStatus, StringLeft($sText, 180))
	ConsoleWrite($sText & @CRLF)
	Return
EndFunc   ;==>_Example_Status
