#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_iWebView = -1
Global $g_idAudioStatus = 0
Global $g_idMuteStatus = 0, $g_idLog = 0, $g_idGuide = 0

_Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Demonstrates native document-audio and mute-state events.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Press Start tone inside WebView2 to satisfy the browser's user-gesture requirement.
; Related .......: _WebView2_GetIsDocumentPlayingAudio, _WebView2_GetIsMuted, _WebView2_SetIsMuted, _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example()
	Local $hGUI = GUICreate("WebView2 - Audio state", 760, 470, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	$g_idAudioStatus = GUICtrlCreateLabel("Audio: waiting for WebView2", 12, 12, 310, 22)
	$g_idMuteStatus = GUICtrlCreateLabel("Mute: waiting for WebView2", 12, 38, 310, 22)
	Local $idReadState = GUICtrlCreateButton("Read state", 335, 14, 110, 30)
	Local $idMute = GUICtrlCreateButton("Mute", 455, 14, 100, 30)
	Local $idUnmute = GUICtrlCreateButton("Unmute", 565, 14, 100, 30)
	GUICtrlSetResizing($idReadState, $GUI_DOCKALL)
	GUICtrlSetResizing($idMute, $GUI_DOCKALL)
	GUICtrlSetResizing($idUnmute, $GUI_DOCKALL)
	GUICtrlSetResizing($g_idAudioStatus, $GUI_DOCKALL)
	GUICtrlSetResizing($g_idMuteStatus, $GUI_DOCKALL)
	GUICtrlCreateLabel("Operation log", 5, 73, 290, 18)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	$g_idLog = GUICtrlCreateEdit("", 5, 94, 290, 366, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	Local $sGuide = "TEST PROCEDURE" & @CRLF & "1. Click Start tone in the page; click Read state, Mute and Unmute, then Stop tone." & @CRLF & "EXPECTED RESULT" & @CRLF & "The native log shows playing and mute changes; muting does not stop playback." & @CRLF & "HOW IT WORKS" & @CRLF & "An oscillator runs in page JavaScript while WebView2 raises native audio and mute events."
	$g_idGuide = GUICtrlCreateEdit($sGuide, 305, 290, 790, 170, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	GUICtrlSetBkColor(-1, 0xFFF4C2)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	GUISetState(@SW_MAXIMIZE, $hGUI)
	Local $aPanelSize = WinGetClientSize($hGUI)
	If IsArray($aPanelSize) Then
		GUICtrlSetPos($g_idLog, 5, 94, 290, $aPanelSize[1] - 104)
		GUICtrlSetPos($g_idGuide, 305, $aPanelSize[1] - 180, $aPanelSize[0] - 310, 170)
	EndIf

	Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\025_AudioState"
	If Not _WebView2_Init(Default, $sProfile) Then
		_Example_Status($g_idAudioStatus, "Initialization failed: " & _WebView2_Error_GetDescription())
	Else
		Local $aClient = WinGetClientSize($hGUI)
		$g_iWebView = _WebView2_Create($hGUI, 305, 70, $aClient[0] - 310, $aClient[1] - 260)
		If @error Then
			_Example_Status($g_idAudioStatus, "Creation failed: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_SetCallback($g_iWebView, $WEBVIEW2_EVENT_DOCUMENT_PLAYING_AUDIO_CHANGED, _OnAudioChanged) Then
			_Example_Status($g_idAudioStatus, "Audio event unavailable: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_SetCallback($g_iWebView, $WEBVIEW2_EVENT_MUTED_CHANGED, _OnMutedChanged) Then
			_Example_Status($g_idMuteStatus, "Mute event unavailable: " & _WebView2_Error_GetDescription())
		Else
			Local $sHtml = '<!doctype html><html><head><meta charset="utf-8"><title>Audio state demo</title>' & _
					'<style>body{font:20px Segoe UI,Arial,sans-serif;padding:30px}button{font:inherit;padding:12px 20px;margin:10px}</style></head><body>' & _
					'<h1>WebView2 audio and mute state</h1><p>Start the local tone, then use the native Mute and Unmute buttons. Playback state can remain true while muted.</p>' & _
					'<button onclick="startTone()">Start tone</button><button onclick="stopTone()">Stop tone</button>' & _
					'<p id="pageStatus">No audio playing</p><script>let context=null,oscillator=null;' & _
					'async function startTone(){if(oscillator)return;context=new AudioContext();oscillator=context.createOscillator();' & _
					'oscillator.frequency.value=440;oscillator.connect(context.destination);oscillator.start();await context.resume();' & _
					'document.getElementById("pageStatus").textContent="Tone playing";}' & _
					'async function stopTone(){if(!oscillator)return;oscillator.stop();oscillator.disconnect();oscillator=null;' & _
					'await context.close();context=null;document.getElementById("pageStatus").textContent="No audio playing";}' & _
					'</script></body></html>'
			If Not _WebView2_NavigateToString($g_iWebView, $sHtml) Then _Example_Status($g_idAudioStatus, "Navigation failed: " & _WebView2_Error_GetDescription())
			_ReadState()
		EndIf
	EndIf

	While True
		Local $iMessage = GUIGetMsg()
		Switch $iMessage
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
				If $g_iWebView >= 0 Then
					$aClient = WinGetClientSize($hGUI)
					If IsArray($aClient) Then
						GUICtrlSetPos($g_idLog, 5, 94, 290, $aClient[1] - 104)
						GUICtrlSetPos($g_idGuide, 305, $aClient[1] - 180, $aClient[0] - 310, 170)
						_WebView2_SetBounds($g_iWebView, 305, 70, $aClient[0] - 310, $aClient[1] - 260)
					EndIf
				EndIf
			Case $idReadState
				_ReadState()
			Case $idMute, $idUnmute
				If $g_iWebView >= 0 Then
					If Not _WebView2_SetIsMuted($g_iWebView, $idMute = $iMessage) Then _Example_Status($g_idMuteStatus, "Mute change failed: " & _WebView2_Error_GetDescription())
				EndIf
		EndSwitch
	WEnd
	_WebView2_Cleanup()
	GUIDelete($hGUI)
	Return
EndFunc   ;==>_Example

; #FUNCTION# ====================================================================================================================
; Name ..........: _OnAudioChanged
; Description ...: Updates the AutoIt label directly from the native WebView2 event.
; Syntax ........: _OnAudioChanged($iWebView, $bIsPlaying)
; Parameters ....: $iWebView - WebView2 instance ID.
;                  $bIsPlaying - True while the document is playing audio.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: No polling and no JavaScript message bridge are needed.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _OnAudioChanged($iWebView, $bIsPlaying)
	If $iWebView = $g_iWebView Then
		Local $sText = $bIsPlaying ? "Audio: playing" : "Audio: not playing"
		_Example_Status($g_idAudioStatus, $sText)
		ConsoleWrite("Audio event: " & $sText & @CRLF)
	EndIf
	Return
EndFunc   ;==>_OnAudioChanged

; #FUNCTION# ====================================================================================================================
; Name ..........: _OnMutedChanged
; Description ...: Updates the AutoIt label from the native mute-state event.
; Syntax ........: _OnMutedChanged($iWebView, $bMuted)
; Parameters ....: $iWebView - WebView2 instance ID.
;                  $bMuted - True when WebView2 audio is muted.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Muting does not stop the page's oscillator.
; Related .......: _WebView2_SetCallback, _WebView2_SetIsMuted
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _OnMutedChanged($iWebView, $bMuted)
	If $iWebView = $g_iWebView Then
		Local $sText = $bMuted ? "Mute: on" : "Mute: off"
		_Example_Status($g_idMuteStatus, $sText)
		ConsoleWrite("Mute event: " & $sText & @CRLF)
	EndIf
	Return
EndFunc   ;==>_OnMutedChanged

; #FUNCTION# ====================================================================================================================
; Name ..........: _ReadState
; Description ...: Reads the current native audio and mute states on demand.
; Syntax ........: _ReadState()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This button lets the event result be compared with the native property.
; Related .......: _WebView2_GetIsDocumentPlayingAudio, _WebView2_GetIsMuted
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _ReadState()
	If $g_iWebView >= 0 Then
		Local $bPlaying = _WebView2_GetIsDocumentPlayingAudio($g_iWebView)
		If @error Then
			_Example_Status($g_idAudioStatus, "Audio state read failed: " & _WebView2_Error_GetDescription())
		Else
			_Example_Status($g_idAudioStatus, $bPlaying ? "Audio: playing" : "Audio: not playing")
		EndIf
		Local $bMuted = _WebView2_GetIsMuted($g_iWebView)
		If @error Then
			_Example_Status($g_idMuteStatus, "Mute state read failed: " & _WebView2_Error_GetDescription())
		Else
			_Example_Status($g_idMuteStatus, $bMuted ? "Mute: on" : "Mute: off")
		EndIf
	EndIf
	Return
EndFunc   ;==>_ReadState

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Example_Status
; Description ...: Updates an audio-state label and appends it to the native operation log.
; Syntax ........: _Example_Status($idLabel, $sText)
; Parameters ....: $idLabel - Audio or mute status label.
;                  $sText - Status message.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Keeps the newest entry visible.
; Related .......: _ReadState
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_Status($idLabel, $sText)
	GUICtrlSetData($idLabel, $sText)
	_GUICtrlEdit_AppendText($g_idLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sText & @CRLF)
	GUICtrlSendMsg($g_idLog, $EM_SCROLLCARET, 0, 0)
	Return
EndFunc   ;==>_Example_Status
