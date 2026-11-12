#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <GUIConstantsEx.au3>
#include <WinAPIGdi.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_iView = -1
Global $g_idStatus = 0
Global $g_iFrameNavStarted = 0, $g_iFrameNavCompleted = 0
Global Const $g_iUpdateButtonReadyColor = 0xDCEBFA
Global Const $g_iUpdateButtonBusyColor = 0x8FA9C2

_Example()

; #FUNCTION# ====================================================================================================================
; Name ..........: _Example
; Description ...: Shows a 1-2-3-1 nested iframe tree and zero-based child paths.
; Syntax ........: _Example()
; Parameters ....: None.
; Return values .: None.
; Author ........: ioa747
; Modified ......: mLipok
; Remarks .......: All pages use the same virtual HTTPS origin. The update button visits every frame.
; ===============================================================================================================================
Func _Example()
	Local $aNativeFrames[0], $iNativeId = -1
	Local $hGUI = GUICreate("WebView2 - Nested frames", 1000, 700, -1, -1, $WS_OVERLAPPEDWINDOW)
	Local $idList = GUICtrlCreateButton("List all frames", 12, 10, 150, 30)
	Local $idStep = GUICtrlCreateButton("Update next frame label", 174, 10, 190, 30)
	Local $idDirect = GUICtrlCreateButton("Update FRAME_0_1_1 to v3", 376, 10, 205, 30)
	GUICtrlSetBkColor($idStep, $g_iUpdateButtonReadyColor)
	GUICtrlSetBkColor($idDirect, $g_iUpdateButtonReadyColor)
	$g_idStatus = GUICtrlCreateLabel("Initializing...", 595, 16, 390, 22)
	GUISetState(@SW_MAXIMIZE, $hGUI)
	Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\028_NestedFrames_" & (@AutoItX64 ? "x64" : "x86")
	If Not _WebView2_Init(Default, $sProfile) Then
		GUICtrlSetData($g_idStatus, "Initialization failed: " & _WebView2_Error_GetDescription())
	Else
		Local $aSize = WinGetClientSize($hGUI)
		$g_iView = _WebView2_Create($hGUI, 0, 50, $aSize[0], $aSize[1] - 50)
		If @error Then
			GUICtrlSetData($g_idStatus, "Creation failed: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_CREATED, _OnFrameCreated) Then
			GUICtrlSetData($g_idStatus, "Frame tracking failed: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_NAVIGATION_STARTING, _OnFrameNavStart) Or _
				Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_NAVIGATION_COMPLETED, _OnFrameNavComplete) Then
			GUICtrlSetData($g_idStatus, "Frame navigation events failed: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_SetVirtualHostNameToFolderMapping($g_iView, "nested-frames.example", @ScriptDir & "\028_NestedFrames", $WEBVIEW2_HOST_RESOURCE_ACCESS_DENY) Then
			GUICtrlSetData($g_idStatus, "Mapping failed: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_Navigate($g_iView, "https://nested-frames.example/index.html") Then
			GUICtrlSetData($g_idStatus, "Navigation failed: " & _WebView2_Error_GetDescription())
		EndIf
	EndIf
	Local $bSmoke = $CmdLine[0] > 0 And $CmdLine[1] = "--smoke"
	Local $tSmoke = TimerInit(), $bSmokePassed = False
	While True
		If $bSmoke And $g_iView >= 0 And TimerDiff($tSmoke) > 1000 Then
			Local $sCount = _WebView2_ExecuteScript($g_iView, "window.listFramePaths().split(String.fromCharCode(10)).length", 1000)
			If Not @error And $sCount = "15" Then
				$bSmokePassed = True
				$aNativeFrames = _WebView2_Frame_List($g_iView)
				$bSmokePassed = UBound($aNativeFrames) > 0 And $g_iFrameNavStarted > 0 And $g_iFrameNavCompleted > 0
				If $bSmokePassed Then
					$iNativeId = _WebView2_Frame_GetNativeId($aNativeFrames[0])
					$bSmokePassed = Not @error And $iNativeId > 0
				EndIf
				For $iLevel = 1 To 15
					Local $iChanged = _StepDeeper()
					If @error Or $iChanged <> 1 Then
						$bSmokePassed = False
						ExitLoop
					EndIf
				Next
				If $bSmokePassed Then
					$iChanged = _StepDeeper()
					$bSmokePassed = Not @error And $iChanged = 0
				EndIf
				If $bSmokePassed Then
					$iChanged = _UpdateDirectFrameLabel()
					$bSmokePassed = Not @error And $iChanged = 1
				EndIf
				If $bSmokePassed Then
					$iChanged = _UpdateDirectFrameLabel()
					$bSmokePassed = Not @error And $iChanged = 0
				EndIf
				ExitLoop
			EndIf
		EndIf
		If $bSmoke And TimerDiff($tSmoke) > 15000 Then ExitLoop
		Local $iMessage = GUIGetMsg()
		Switch $iMessage
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
				If $g_iView >= 0 Then
					$aSize = WinGetClientSize($hGUI)
					If IsArray($aSize) Then _WebView2_SetBounds($g_iView, 0, 50, $aSize[0], $aSize[1] - 50)
				EndIf
			Case $idList
				If $g_iView >= 0 Then
					Local $sTree = _WebView2_GetFrameTree($g_iView)
					If @error Then
						GUICtrlSetData($g_idStatus, "Frame tree failed: " & _WebView2_Error_GetDescription())
					Else
						ConsoleWrite("CDP frame tree: " & $sTree & @CRLF)
						Local $sPaths = _WebView2_ExecuteScript($g_iView, "window.listFramePaths()")
						ConsoleWrite("Zero-based child paths: " & $sPaths & @CRLF)
						$aNativeFrames = _WebView2_Frame_List($g_iView)
						For $iFrame = 0 To UBound($aNativeFrames) - 1
							$iNativeId = _WebView2_Frame_GetNativeId($aNativeFrames[$iFrame])
							ConsoleWrite("Tracked frame=" & $aNativeFrames[$iFrame] & " native FrameId=" & (@error ? "unavailable" : $iNativeId) & @CRLF)
						Next
						GUICtrlSetData($g_idStatus, "Frame tree and paths written to console (15 if fully loaded)")
					EndIf
				EndIf
			Case $idStep
				If $g_iView >= 0 Then
					_SetUpdateButtonBusy($idStep, True)
					Local $sResult = _StepDeeper()
					Local $iStepError = @error
					_SetUpdateButtonBusy($idStep, False)
					GUICtrlSetData($g_idStatus, $iStepError ? "Step failed" : "Next label changed: " & $sResult)
				EndIf
			Case $idDirect
				If $g_iView >= 0 Then
					_SetUpdateButtonBusy($idDirect, True)
					Local $iDirectChanged = _UpdateDirectFrameLabel()
					Local $iDirectError = @error
					_SetUpdateButtonBusy($idDirect, False)
					GUICtrlSetData($g_idStatus, $iDirectError ? "Direct update failed" : "FRAME_0_1_1: " & ($iDirectChanged ? "added _v3" : "already has _v3"))
				EndIf
		EndSwitch
	WEnd
	If $bSmoke Then ConsoleWrite("Nested frame smoke: " & ($bSmokePassed ? "PASS (15 frames)" : "FAIL") & @CRLF)
	_WebView2_Cleanup()
	GUIDelete($hGUI)
	If $bSmoke And Not $bSmokePassed Then Exit 1
	Return
EndFunc   ;==>_Example

; #FUNCTION# ====================================================================================================================
; Name ..........: _SetUpdateButtonBusy
; Description ...: Disables and darkens an update button until its operation finishes.
; Syntax ........: _SetUpdateButtonBusy($idButton, $bBusy)
; Parameters ....: $idButton - Update button control ID.
;                  $bBusy - True while the button's operation is running.
; Return values .: None.
; Author ........: ioa747
; Modified ......: mLipok
; ===============================================================================================================================
Func _SetUpdateButtonBusy($idButton, $bBusy)
	GUICtrlSetBkColor($idButton, $bBusy ? $g_iUpdateButtonBusyColor : $g_iUpdateButtonReadyColor)
	GUICtrlSetState($idButton, $bBusy ? $GUI_DISABLE : $GUI_ENABLE)
	_WinAPI_RedrawWindow(GUICtrlGetHandle($idButton), 0, 0, BitOR($RDW_INVALIDATE, $RDW_UPDATENOW))
	Return
EndFunc   ;==>_SetUpdateButtonBusy

; #FUNCTION# ====================================================================================================================
; Name ..........: _StepDeeper
; Description ...: Iterates tracked frames and updates the first unchanged label.
; Syntax ........: _StepDeeper()
; Parameters ....: None.
; Return values .: Number of changed labels; @error on failure.
; Author ........: ioa747
; Modified ......: mLipok
; ===============================================================================================================================
Func _StepDeeper()
	Local $aFrames = _WebView2_Frame_List($g_iView)
	Local $iError = @error, $iChanged = 0
	If Not $iError And UBound($aFrames) = 0 Then $iError = 1
	If Not $iError Then
		For $i = 0 To UBound($aFrames) - 1
			$iChanged += _UpdateFrameLabels($aFrames[$i], "document")
			If @error Then
				$iError = 1
				ExitLoop
			EndIf
			If $iChanged = 1 Then ExitLoop
		Next
	EndIf
	Return SetError($iError, 0, $iChanged)
EndFunc   ;==>_StepDeeper

; #FUNCTION# ====================================================================================================================
; Name ..........: _UpdateDirectFrameLabel
; Description ...: Finds a named frame in the CDP list and updates its label.
; Syntax ........: _UpdateDirectFrameLabel()
; Parameters ....: None.
; Return values .: 1 when changed, 0 when already suffixed; @error on failure.
; Author ........: ioa747
; Modified ......: mLipok
; ===============================================================================================================================
Func _UpdateDirectFrameLabel()
	Local Const $sTargetName = "FRAME_0_1_1"
	Local $sTree = _WebView2_GetFrameTree($g_iView)
	If @error Or Not StringRegExp($sTree, '"name"\s*:\s*"' & $sTargetName & '"') Then Return SetError(1, 0, 0)
	Local $aFrames = _WebView2_Frame_List($g_iView)
	If @error Or UBound($aFrames) = 0 Then Return SetError(1, 0, 0)
	Local $sFind = "const find=(w)=>{if(w.name==='" & $sTargetName & "')return w;for(let i=0;i<w.frames.length;i++){const r=find(w.frames[i]);if(r)return r;}return null;};const f=find(window);if(!f)return null;const l=f.document.getElementById('frame-label');if(!l)return null;"
	Local $sLabel = _WebView2_Frame_ExecuteScript($aFrames[0], "(()=>{" & $sFind & "return l.textContent;})()")
	If @error Then Return SetError(1, 0, 0)
	$sLabel = StringReplace($sLabel, '"', "")
	If Not StringInStr($sLabel, $sTargetName) Then Return SetError(1, 0, 0)
	If StringRight($sLabel, 3) = "_v3" Then Return 0
	Local $sNewLabel = $sLabel & "_v3"
	Local $sResult = _WebView2_Frame_ExecuteScript($aFrames[0], "(()=>{" & $sFind & "l.textContent='" & $sNewLabel & "';return l.textContent;})()")
	If @error Or Not StringInStr($sResult, $sNewLabel) Then Return SetError(1, 0, 0)
	Return 1
EndFunc   ;==>_UpdateDirectFrameLabel

; #FUNCTION# ====================================================================================================================
; Name ..........: _UpdateFrameLabels
; Description ...: Walks one same-origin frame subtree until one label changes.
; Syntax ........: _UpdateFrameLabels($iFrame, $sDocument)
; Parameters ....: $iFrame - Tracked native root frame ID.
;                  $sDocument - JavaScript expression for the current document.
; Return values .: Number of changed labels; @error on failure.
; Author ........: ioa747
; Modified ......: mLipok
; ===============================================================================================================================
Func _UpdateFrameLabels($iFrame, $sDocument)
	Local $iChanged = 0, $iError = 0
	Local $sLabel = _WebView2_Frame_ExecuteScript($iFrame, $sDocument & ".getElementById('frame-label').textContent")
	If @error Then Return SetError(1, 0, 0)
	If Not StringInStr($sLabel, "_v2") Then
		Local $sNewLabel = StringReplace($sLabel, '"', "") & "_v2"
		_WebView2_Frame_ExecuteScript($iFrame, $sDocument & ".getElementById('frame-label').textContent='" & $sNewLabel & "'")
		If @error Then Return SetError(1, 0, 0)
		$iChanged = 1
		Return SetError(0, 0, $iChanged)
	EndIf
	Local $sCount = _WebView2_Frame_ExecuteScript($iFrame, $sDocument & ".querySelectorAll('iframe').length")
	If @error Then Return SetError(1, 0, $iChanged)
	For $iChild = 0 To Number($sCount) - 1
		Local $sChild = $sDocument & ".querySelectorAll('iframe')[" & $iChild & "].contentDocument"
		$iChanged += _UpdateFrameLabels($iFrame, $sChild)
		If @error Then
			$iError = 1
			ExitLoop
		EndIf
		If $iChanged = 1 Then ExitLoop
	Next
	Return SetError($iError, 0, $iChanged)
EndFunc   ;==>_UpdateFrameLabels

; #FUNCTION# ====================================================================================================================
; Name ..........: _OnFrameCreated
; Description ...: Keeps native frame tracking active before navigation.
; Syntax ........: _OnFrameCreated($iView, $iFrame)
; Parameters ....: $iView - WebView2 instance ID.
;                  $iFrame - Native frame ID.
; Return values .: None.
; Author ........: ioa747
; Modified ......: mLipok
; ===============================================================================================================================
Func _OnFrameCreated($iView, $iFrame)
	#forceref $iView, $iFrame
	Return
EndFunc   ;==>_OnFrameCreated

; #FUNCTION# ====================================================================================================================
; Name ..........: _OnFrameNavStart
; Description ...: Counts native iframe navigation starts without cancelling them.
; ===============================================================================================================================
Func _OnFrameNavStart($iView, $iFrame, $sURI, $bUserInitiated, $bRedirected)
	#forceref $iView, $iFrame, $sURI, $bUserInitiated, $bRedirected
	$g_iFrameNavStarted += 1
	Return False
EndFunc   ;==>_OnFrameNavStart

; #FUNCTION# ====================================================================================================================
; Name ..........: _OnFrameNavComplete
; Description ...: Counts completed native iframe navigations.
; ===============================================================================================================================
Func _OnFrameNavComplete($iView, $iFrame, $bSuccess, $iWebError)
	#forceref $iView, $iFrame, $bSuccess, $iWebError
	$g_iFrameNavCompleted += 1
	Return
EndFunc   ;==>_OnFrameNavComplete
