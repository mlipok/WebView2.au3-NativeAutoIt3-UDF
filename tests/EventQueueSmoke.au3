#Tidy_ILC_Pos=44
#include <GUIConstantsEx.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_EX_sMessages = "", $g_EX_iCount = 0

Exit _Smoke()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Smoke
; Description ...: Checks bounded queue overflow and FIFO dispatch with an isolated profile.
; Syntax ........: _Smoke()
; Parameters ....: None.
; Return values .: Zero on success, nonzero on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: WEBVIEW2_TEST_LOADER may point to a local native loader DLL.
; Related .......: _WebView2_EventQueue_Enable, _WebView2_EventQueue_Dispatch
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Smoke()
	Local $sArch = @AutoItX64 ? "x64" : "x86"
	Local $sLoader = EnvGet("WEBVIEW2_TEST_LOADER")
	If $sLoader = "" Then $sLoader = Default
	Local $sProfile = @ScriptDir & "\..\..\profiles\03-event-queue-" & $sArch
	DirCreate($sProfile)
	Local $hGUI = GUICreate("Event queue smoke", 640, 480)
	Local $iExit = 1, $iView = -1, $sStage = "init", $aStats
	Do
		If Not _WebView2_Init($sLoader, $sProfile) Then ExitLoop 1
		$sStage = "create"
		$iView = _WebView2_Create($hGUI, 0, 0, 640, 480)
		If @error Then ExitLoop 1
		$sStage = "callback"
		If Not _WebView2_SetCallback($iView, $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED, _OnMessage) Then ExitLoop 1
		$sStage = "enable"
		If Not _WebView2_EventQueue_Enable($iView, 2) Then ExitLoop 1
		$sStage = "mapping"
		If Not _WebView2_SetVirtualHostNameToFolderMapping($iView, "udf-virtual-host.example", @ScriptDir & "\..\examples\assets\native") Then ExitLoop 1
		$sStage = "navigate"
		If Not _WebView2_Navigate($iView, "https://udf-virtual-host.example/045.html") Then ExitLoop 1
		$sStage = "wait document"
		Local $iTimer = TimerInit()
		While TimerDiff($iTimer) < 10000
			GUIGetMsg()
			If _WebView2_ExecuteScript($iView, "document.readyState", 1000) = '"complete"' Then ExitLoop
			Sleep(10)
		WEnd
		$sStage = "burst"
		_WebView2_ExecuteScript($iView, "for(let i=1;i<=5;i++)window.chrome.webview.postMessage({kind:'item',index:i});true")
		If @error Then ExitLoop 1
		$sStage = "wait queue"
		$iTimer = TimerInit()
		While TimerDiff($iTimer) < 10000
			GUIGetMsg()
			$aStats = _WebView2_EventQueue_GetStats($iView)
			If IsArray($aStats) And $aStats[0] = 2 And $aStats[1] = 3 Then ExitLoop
			Sleep(10)
		WEnd
		If Not IsArray($aStats) Then ExitLoop 1
		If $aStats[0] <> 2 Or $aStats[1] <> 3 Then ExitLoop 1
		$sStage = "dispatch"
		If _WebView2_EventQueue_Dispatch($iView, 1) <> 1 Then ExitLoop 1
		If _WebView2_EventQueue_Dispatch($iView, 1) <> 1 Then ExitLoop 1
		If $g_EX_iCount <> 2 Or Not StringInStr($g_EX_sMessages, '"index":1') Or Not StringInStr($g_EX_sMessages, '"index":2') Then ExitLoop 1
		$aStats = _WebView2_EventQueue_GetStats($iView)
		If $aStats[0] <> 0 Or $aStats[1] <> 3 Then ExitLoop 1
		$iExit = 0
	Until True
	Local $sLine = "QUEUE_SMOKE arch=" & $sArch & " exit=" & $iExit & " stage=" & $sStage & " count=" & $g_EX_iCount & " messages=" & $g_EX_sMessages & " error=" & _WebView2_Error_GetDescription()
	ConsoleWrite($sLine & @CRLF)
	FileWrite(@ScriptDir & "\EventQueueSmoke.result.txt", $sLine & @CRLF)
	_WebView2_Cleanup()
	GUIDelete($hGUI)
	Return $iExit
EndFunc   ;==>_Smoke

; #FUNCTION# ====================================================================================================================
; Name ..........: _OnMessage
; Description ...: Records one queued web message in dispatch order.
; Syntax ........: _OnMessage($iWebView, $sMessage, $sSource, $bJSON)
; Parameters ....: Native web-message callback values.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Called by explicit queue dispatch from the smoke loop.
; Related .......: _Smoke
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _OnMessage($iWebView, $sMessage, $sSource, $bJSON)
	#forceref $iWebView, $sSource, $bJSON
	$g_EX_iCount += 1
	$g_EX_sMessages &= $sMessage & ";"
	Return
EndFunc   ;==>_OnMessage
