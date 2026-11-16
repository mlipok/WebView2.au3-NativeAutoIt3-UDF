#Tidy_ILC_Pos=44
#include <GUIConstantsEx.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Exit _Smoke()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Smoke
; Description ...: Checks two overlapping asynchronous script results with an isolated profile.
; Syntax ........: _Smoke()
; Parameters ....: None.
; Return values .: Zero on success, nonzero on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: WEBVIEW2_TEST_LOADER may point to a local native loader DLL.
; Related .......: _WebView2_ExecuteScriptAsyncStart, _WebView2_ExecuteScriptAsyncPoll
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Smoke()
	Local $sArch = @AutoItX64 ? "x64" : "x86"
	Local $sLoader = EnvGet("WEBVIEW2_TEST_LOADER")
	If $sLoader = "" Then $sLoader = Default
	Local $sProfile = @ScriptDir & "\..\..\profiles\02-async-" & $sArch
	DirCreate($sProfile)
	Local $hGUI = GUICreate("Async smoke", 640, 480)
	Local $iExit = 1, $iView = -1, $iA = 0, $iB = 0, $sA = "", $sB = ""
	Local $sStage = "init"
	Do
		If Not _WebView2_Init($sLoader, $sProfile) Then ExitLoop 1
		$sStage = "create"
		$iView = _WebView2_Create($hGUI, 0, 0, 640, 480)
		If @error Then ExitLoop 1
		$sStage = "navigate"
		If Not _WebView2_NavigateToString($iView, "<!doctype html><title>Async smoke</title>") Then ExitLoop 1
		$sStage = "wait document"
		Local $iTimer = TimerInit()
		While TimerDiff($iTimer) < 10000
			GUIGetMsg()
			If _WebView2_ExecuteScript($iView, "document.readyState", 1000) = '"complete"' Then ExitLoop
			Sleep(10)
		WEnd
		$sStage = "start A"
		$iA = _WebView2_ExecuteScriptAsyncStart($iView, "1+1")
		If @error Or $iA <= 0 Then ExitLoop 1
		$sStage = "start B"
		$iB = _WebView2_ExecuteScriptAsyncStart($iView, "2+2")
		If @error Or $iB <= $iA Then ExitLoop 1
		$sStage = "poll"
		$iTimer = TimerInit()
		While TimerDiff($iTimer) < 10000 And ($iA Or $iB)
			GUIGetMsg()
			If $iA Then
				Local $iStateA = _WebView2_ExecuteScriptAsyncPoll($iA, $sA)
				If $iStateA = 1 Then
					$iA = 0
				ElseIf $iStateA < 0 Then
					ExitLoop
				EndIf
			EndIf
			If $iB Then
				Local $iStateB = _WebView2_ExecuteScriptAsyncPoll($iB, $sB)
				If $iStateB = 1 Then
					$iB = 0
				ElseIf $iStateB < 0 Then
					ExitLoop
				EndIf
			EndIf
			Sleep(10)
		WEnd
		If $iA = 0 And $iB = 0 And $sA = "2" And $sB = "4" Then $iExit = 0
	Until True
	Local $sLine = "ASYNC_SMOKE arch=" & $sArch & " exit=" & $iExit & " stage=" & $sStage & " A=" & $sA & " B=" & $sB & " error=" & _WebView2_Error_GetDescription()
	ConsoleWrite($sLine & @CRLF)
	FileWrite(@ScriptDir & "\AsyncSmoke.result.txt", $sLine & @CRLF)
	If $iA Then _WebView2_ExecuteScriptAsyncForget($iA)
	If $iB Then _WebView2_ExecuteScriptAsyncForget($iB)
	_WebView2_Cleanup()
	GUIDelete($hGUI)
	Return $iExit
EndFunc   ;==>_Smoke
