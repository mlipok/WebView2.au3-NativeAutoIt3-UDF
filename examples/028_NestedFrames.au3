#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <WinAPIGdi.au3>
#include <WindowsConstants.au3>
#include "..\WebView2.au3"

Opt("MustDeclareVars", 1)

Global $g_iView = -1
Global $g_idStatus = 0, $g_idLog = 0, $g_idGuide = 0
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
	Local $hGUI = GUICreate("WebView2 - Nested frames", 1000, 700, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPCHILDREN))
	Local $idList = GUICtrlCreateButton("List all frames", 12, 10, 150, 30)
	Local $idStep = GUICtrlCreateButton("Update next frame label", 174, 10, 190, 30)
	Local $idDirect = GUICtrlCreateButton("Update FRAME_0_1_1 to v3", 376, 10, 205, 30)
	GUICtrlSetBkColor($idStep, $g_iUpdateButtonReadyColor)
	GUICtrlSetBkColor($idDirect, $g_iUpdateButtonReadyColor)
	$g_idStatus = GUICtrlCreateLabel("Initializing...", 595, 16, 390, 22)
	GUICtrlSetResizing($idList, $GUI_DOCKALL)
	GUICtrlSetResizing($idStep, $GUI_DOCKALL)
	GUICtrlSetResizing($idDirect, $GUI_DOCKALL)
	GUICtrlSetResizing($g_idStatus, $GUI_DOCKALL)
	GUICtrlCreateLabel("Operation log", 5, 53, 290, 18)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	$g_idLog = GUICtrlCreateEdit("", 5, 74, 290, 616, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetBkColor($g_idLog, 0xE2F0E4)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	Local $sGuide = "TEST PROCEDURE" & @CRLF & "1. Click List all frames; click Update next frame label repeatedly, then Update FRAME_0_1_1 to v3." & @CRLF & "EXPECTED RESULT" & @CRLF & "One visible label gains _v2 per click; the named frame gains _v3. The tree has 15 frames." & @CRLF & "HOW IT WORKS" & @CRLF & "The UDF lists tracked nested iframe IDs and runs a script in the selected frame."
	$g_idGuide = GUICtrlCreateEdit($sGuide, 305, 520, 790, 170, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	GUICtrlSetBkColor(-1, 0xFFF4C2)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	GUISetState(@SW_MAXIMIZE, $hGUI)
	Local $aPanelSize = WinGetClientSize($hGUI)
	If IsArray($aPanelSize) Then
		GUICtrlSetPos($g_idLog, 5, 74, 290, $aPanelSize[1] - 84)
		GUICtrlSetPos($g_idGuide, 305, $aPanelSize[1] - 180, $aPanelSize[0] - 310, 170)
	EndIf
	Local $sProfile = @LocalAppDataDir & "\WebView2.au3\Examples\028_NestedFrames_" & (@AutoItX64 ? "x64" : "x86")
	If Not _WebView2_Init(Default, $sProfile) Then
		_Example_Status("Initialization failed: " & _WebView2_Error_GetDescription())
	Else
		Local $aSize = WinGetClientSize($hGUI)
		$g_iView = _WebView2_Create($hGUI, 305, 50, $aSize[0] - 310, $aSize[1] - 240)
		If @error Then
			_Example_Status("Creation failed: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_CREATED, _OnFrameCreated) Then
			_Example_Status("Frame tracking failed: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_NAVIGATION_STARTING, _OnFrameNavStart) Or _
				Not _WebView2_SetCallback($g_iView, $WEBVIEW2_EVENT_FRAME_NAVIGATION_COMPLETED, _OnFrameNavComplete) Then
			_Example_Status("Frame navigation events failed: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_SetVirtualHostNameToFolderMapping($g_iView, "udf-virtual-host.example", @ScriptDir & "\028_NestedFrames", $WEBVIEW2_HOST_RESOURCE_ACCESS_DENY) Then
			_Example_Status("Mapping failed: " & _WebView2_Error_GetDescription())
		ElseIf Not _WebView2_Navigate($g_iView, "https://udf-virtual-host.example/index.html") Then
			_Example_Status("Navigation failed: " & _WebView2_Error_GetDescription())
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
				$bSmokePassed = UBound($aNativeFrames) = 15 And $g_iFrameNavStarted > 0 And $g_iFrameNavCompleted > 0
				If $bSmokePassed Then $bSmokePassed = _ValidateNativeHierarchy($aNativeFrames)
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
					If IsArray($aSize) Then
						GUICtrlSetPos($g_idLog, 5, 74, 290, $aSize[1] - 84)
						GUICtrlSetPos($g_idGuide, 305, $aSize[1] - 180, $aSize[0] - 310, 170)
						_WebView2_SetBounds($g_iView, 305, 50, $aSize[0] - 310, $aSize[1] - 240)
					EndIf
				EndIf
			Case $idList
				If $g_iView >= 0 Then
					Local $sTree = _WebView2_GetFrameTree($g_iView)
					If @error Then
						_Example_Status("Frame tree failed: " & _WebView2_Error_GetDescription())
					Else
						ConsoleWrite("CDP frame tree: " & $sTree & @CRLF)
						Local $sPaths = _WebView2_ExecuteScript($g_iView, "window.listFramePaths()")
						ConsoleWrite("Zero-based child paths: " & $sPaths & @CRLF)
						$aNativeFrames = _WebView2_Frame_List($g_iView)
						For $iFrame = 0 To UBound($aNativeFrames) - 1
							$iNativeId = _WebView2_Frame_GetNativeId($aNativeFrames[$iFrame])
							Local $sNativeId = @error ? "unavailable" : $iNativeId
							Local $iParentId = _WebView2_Frame_GetParentId($aNativeFrames[$iFrame])
							Local $sFrameName = _WebView2_Frame_GetName($aNativeFrames[$iFrame])
							ConsoleWrite("Tracked frame=" & $aNativeFrames[$iFrame] & " parent=" & $iParentId & " native FrameId=" & $sNativeId & " name=" & $sFrameName & @CRLF)
						Next
						_Example_Status("Frame tree and paths written to console (15 if fully loaded)")
					EndIf
				EndIf
			Case $idStep
				If $g_iView >= 0 Then
					_SetUpdateButtonBusy($idStep, True)
					Local $sResult = _StepDeeper()
					Local $iStepError = @error
					_SetUpdateButtonBusy($idStep, False)
					_Example_Status($iStepError ? "Step failed" : "Next label changed: " & $sResult)
				EndIf
			Case $idDirect
				If $g_iView >= 0 Then
					_SetUpdateButtonBusy($idDirect, True)
					Local $iDirectChanged = _UpdateDirectFrameLabel()
					Local $iDirectError = @error
					_SetUpdateButtonBusy($idDirect, False)
					_Example_Status($iDirectError ? "Direct update failed" : "FRAME_0_1_1: " & ($iDirectChanged ? "added _v3" : "already has _v3"))
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
; Description ...: Iterates native frames by name and updates the first unchanged label.
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
		Local $iNextFrame = -1, $sNextName = ""
		For $i = 0 To UBound($aFrames) - 1
			Local $sName = _WebView2_Frame_GetName($aFrames[$i])
			If @error Then
				$iError = 1
				ExitLoop
			EndIf
			Local $sLabel = _WebView2_Frame_ExecuteScript($aFrames[$i], "document.getElementById('frame-label').textContent")
			If @error Then
				$iError = 1
				ExitLoop
			EndIf
			If Not StringInStr($sLabel, "_v2") And ($iNextFrame < 0 Or StringCompare($sName, $sNextName) < 0) Then
				$iNextFrame = $aFrames[$i]
				$sNextName = $sName
			EndIf
		Next
		If Not $iError And $iNextFrame >= 0 Then
			Local $sResult = _WebView2_Frame_ExecuteScript($iNextFrame, "document.getElementById('frame-label').textContent+='_v2'")
			If @error Or Not StringInStr($sResult, "_v2") Then
				$iError = 1
			Else
				$iChanged = 1
			EndIf
		EndIf
	EndIf
	Return SetError($iError, 0, $iChanged)
EndFunc   ;==>_StepDeeper

; #FUNCTION# ====================================================================================================================
; Name ..........: _UpdateDirectFrameLabel
; Description ...: Finds a named frame in the CDP and native lists and updates its label.
; Syntax ........: _UpdateDirectFrameLabel()
; Parameters ....: None.
; Return values .: 1 when changed, 0 when already suffixed; @error on failure.
; Author ........: ioa747
; Modified ......: mLipok
; ===============================================================================================================================
Func _UpdateDirectFrameLabel()
	Local Const $sTargetName = "FRAME_0_1_1"
	Local $iError = 0, $iChanged = 0, $iTargetFrame = -1
	Do
		Local $sTree = _WebView2_GetFrameTree($g_iView)
		If @error Or Not StringRegExp($sTree, '"name"\s*:\s*"' & $sTargetName & '"') Then
			$iError = 1
			ExitLoop 1
		EndIf
		Local $aFrames = _WebView2_Frame_List($g_iView)
		If @error Then
			$iError = 1
			ExitLoop 1
		EndIf
		For $i = 0 To UBound($aFrames) - 1
			Local $sName = _WebView2_Frame_GetName($aFrames[$i])
			If Not @error And $sName = $sTargetName Then
				$iTargetFrame = $aFrames[$i]
				ExitLoop
			EndIf
		Next
		If $iTargetFrame < 0 Then
			$iError = 1
			ExitLoop 1
		EndIf
		Local $sLabel = _WebView2_Frame_ExecuteScript($iTargetFrame, "document.getElementById('frame-label').textContent")
		If @error Or Not StringInStr($sLabel, $sTargetName) Then
			$iError = 1
			ExitLoop 1
		EndIf
		If StringInStr($sLabel, "_v3") Then ExitLoop 1
		Local $sResult = _WebView2_Frame_ExecuteScript($iTargetFrame, "document.getElementById('frame-label').textContent+='_v3'")
		If @error Or Not StringInStr($sResult, "_v3") Then
			$iError = 1
		Else
			$iChanged = 1
		EndIf
	Until True
	Return SetError($iError, 0, $iChanged)
EndFunc   ;==>_UpdateDirectFrameLabel

; #FUNCTION# ====================================================================================================================
; Name ..........: _ValidateNativeHierarchy
; Description ...: Checks tracked names and parent IDs across all four iframe levels.
; Syntax ........: _ValidateNativeHierarchy($aFrames)
; Parameters ....: $aFrames - Tracked frame IDs.
; Return values .: True when the expected 1 + 2 + 6 + 6 hierarchy is complete.
; Author ........: ioa747
; Modified ......: mLipok
; ===============================================================================================================================
Func _ValidateNativeHierarchy($aFrames)
	Local $bValid = UBound($aFrames) = 15
	Local $aExpected[4] = [1, 2, 6, 6], $aCounts[4] = [0, 0, 0, 0]
	If $bValid Then
		For $i = 0 To UBound($aFrames) - 1
			Local $sName = _WebView2_Frame_GetName($aFrames[$i])
			If @error Or Not StringRegExp($sName, '^FRAME_0(?:_[0-9]+){0,3}$') Then
				$bValid = False
				ExitLoop
			EndIf
			Local $iLevel = UBound(StringSplit($sName, "_")) - 2
			If $iLevel < 1 Or $iLevel > 4 Then
				$bValid = False
				ExitLoop
			EndIf
			$aCounts[$iLevel - 1] += 1
			Local $iParentId = _WebView2_Frame_GetParentId($aFrames[$i])
			If @error Then
				$bValid = False
				ExitLoop
			EndIf
			If $iLevel = 1 Then
				If $iParentId <> 0 Then $bValid = False
			Else
				Local $sParentName = StringRegExpReplace($sName, '_[0-9]+$', '')
				Local $bParentFound = False
				For $j = 0 To UBound($aFrames) - 1
					If $aFrames[$j] = $iParentId Then
						$bParentFound = _WebView2_Frame_GetName($aFrames[$j]) = $sParentName
						ExitLoop
					EndIf
				Next
				If Not $bParentFound Then $bValid = False
			EndIf
			If Not $bValid Then ExitLoop
		Next
	EndIf
	If $bValid Then
		For $i = 0 To 3
			If $aCounts[$i] <> $aExpected[$i] Then $bValid = False
		Next
	EndIf
	Return $bValid
EndFunc   ;==>_ValidateNativeHierarchy

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

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Example_Status
; Description ...: Updates the native status label and operation log.
; Syntax ........: _Example_Status($sText)
; Parameters ....: $sText - Status message.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Keeps the newest entry visible.
; Related .......: _Example
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Example_Status($sText)
	GUICtrlSetData($g_idStatus, $sText)
	_GUICtrlEdit_AppendText($g_idLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sText & @CRLF)
	GUICtrlSendMsg($g_idLog, $EM_SCROLLCARET, 0, 0)
	Return
EndFunc   ;==>_Example_Status
