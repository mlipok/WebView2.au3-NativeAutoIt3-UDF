#include-once
#Tidy_ILC_Pos=44

; #INDEX# =======================================================================================================================
; Title .........: WebView2_Frame.au3
; Description ...: Native frame tracking, messaging and script execution.
; Author(s) .....: mLipok
; Version .......: 0.5.0
; ===============================================================================================================================

Global Const $__WEBVIEW2_MAX_FRAMES = 256
Global Enum _
		$__WEBVIEW2_FRAME_ID, _
		$__WEBVIEW2_FRAME_OWNER, _
		$__WEBVIEW2_FRAME_POINTER, _
		$__WEBVIEW2_FRAME_OBJECT, _
		$__WEBVIEW2_FRAME_OBJECT2, _
		$__WEBVIEW2_FRAME_DESTROY_TOKEN, _
		$__WEBVIEW2_FRAME_MESSAGE_TOKEN, _
		$__WEBVIEW2_FRAME_ACTIVE, _
		$__WEBVIEW2_FRAME_FIELDS
Global $__g_aWebView2_Frames[$__WEBVIEW2_MAX_FRAMES][$__WEBVIEW2_FRAME_FIELDS]
Global $__g_iWebView2_NextFrameId = 1
Global $__g_aWebView2_FrameCore4[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_FrameToken[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_FrameCreatedCallback[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_FrameDestroyedCallback[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_FrameMessageCallback[$WEBVIEW2_MAX_INSTANCES]

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Frame_QueryInterface
; Description ...: Obtains a native interface wrapper by IID and dtag.
; Syntax ........: __WebView2_Frame_QueryInterface($pObject, $sIID, $sDTag)
; Parameters ....: $pObject - Native COM pointer.
;                  $sIID - Requested interface IID.
;                  $sDTag - Interface method signatures.
; Return values .: COM wrapper or Null with @error set.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Frame_QueryInterface($pObject, $sIID, $sDTag)
	Local $oResult = Null, $iError = 0, $iExtended = 0
	Do
		If Not $pObject Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $tVTable = DllStructCreate("ptr", $pObject)
		Local $tQuery = DllStructCreate("ptr", DllStructGetData($tVTable, 1))
		Local $tIID = DllStructCreate($tagGUID)
		Local $aIID = DllCall("ole32.dll", "long", "IIDFromString", "wstr", $sIID, "ptr", DllStructGetPtr($tIID))
		Local $iDllError = @error
		If $iDllError Then
			$iError = $WEBVIEW2_ERR_DLLCALL
			ExitLoop 1
		EndIf
		If $aIID[0] <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $aIID[0]
			ExitLoop 1
		EndIf
		Local $aQuery = DllCallAddress("long", DllStructGetData($tQuery, 1), "ptr", $pObject, "ptr", DllStructGetPtr($tIID), "ptr*", 0)
		If @error Then
			$iError = $WEBVIEW2_ERR_DLLCALL
			ExitLoop 1
		EndIf
		If $aQuery[0] <> $WEBVIEW2_S_OK Or Not $aQuery[3] Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $aQuery[0]
			ExitLoop 1
		EndIf
		$oResult = ObjCreateInterface($aQuery[3], $sIID, $sDTag)
		If Not IsObj($oResult) Then $iError = $WEBVIEW2_ERR_HRESULT
	Until True
	Return SetError($iError, $iExtended, $oResult)
EndFunc   ;==>__WebView2_Frame_QueryInterface

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Frame_SetCallback
; Description ...: Lazily subscribes to native frame creation and retains the user callback.
; Syntax ........: __WebView2_Frame_SetCallback($iWebView, $iEvent, $fnCallback)
; Parameters ....: $iWebView - WebView2 instance ID.
;                  $iEvent - Frame event constant.
;                  $fnCallback - AutoIt function reference.
; Return values .: True or False with @error set.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Frame_SetCallback($iWebView, $iEvent, $fnCallback)
	Local $iError = 0, $iExtended = 0, $bResult = False
	Do
		If Not $__g_aWebView2_FrameToken[$iWebView] Then
			If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_CREATED) Then
				If Not __WebView2_Callback_Create($__WEBVIEW2_CB_FRAME_CREATED, __WebView2_FrameCreated_Invoke, "ptr;ptr;ptr") Then
					$iError = $WEBVIEW2_ERR_CALLBACK
					ExitLoop 1
				EndIf
			EndIf
			If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_DESTROYED) Then
				If Not __WebView2_Callback_Create($__WEBVIEW2_CB_FRAME_DESTROYED, __WebView2_FrameDestroyed_Invoke, "ptr;ptr;ptr") Then
					$iError = $WEBVIEW2_ERR_CALLBACK
					ExitLoop 1
				EndIf
			EndIf
			If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_MESSAGE) Then
				If Not __WebView2_Callback_Create($__WEBVIEW2_CB_FRAME_MESSAGE, __WebView2_FrameMessage_Invoke, "ptr;ptr;ptr") Then
					$iError = $WEBVIEW2_ERR_CALLBACK
					ExitLoop 1
				EndIf
			EndIf
			Local $pCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE_POINTER]
			Local $oCore4 = __WebView2_Frame_QueryInterface($pCore, $WEBVIEW2_IID_ICoreWebView2_4, $WEBVIEW2_DTAG_ICoreWebView2_4)
			$iError = @error
			$iExtended = @extended
			If $iError Then ExitLoop 1
			Local $tToken = DllStructCreate("int64")
			Local $iResult = $oCore4.add_FrameCreated(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_CREATED), $tToken)
			If @error Or $iResult <> $WEBVIEW2_S_OK Then
				$iError = $WEBVIEW2_ERR_HRESULT
				$iExtended = $iResult
				ExitLoop 1
			EndIf
			$__g_aWebView2_FrameCore4[$iWebView] = $oCore4
			$__g_aWebView2_FrameToken[$iWebView] = DllStructGetData($tToken, 1)
		EndIf
		Switch $iEvent
			Case $WEBVIEW2_EVENT_FRAME_CREATED
				$__g_aWebView2_FrameCreatedCallback[$iWebView] = $fnCallback
			Case $WEBVIEW2_EVENT_FRAME_DESTROYED
				$__g_aWebView2_FrameDestroyedCallback[$iWebView] = $fnCallback
			Case $WEBVIEW2_EVENT_FRAME_WEB_MESSAGE_RECEIVED
				$__g_aWebView2_FrameMessageCallback[$iWebView] = $fnCallback
		EndSwitch
		$bResult = True
	Until True
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>__WebView2_Frame_SetCallback

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Frame_Find
; Description ...: Finds a registered frame by public ID or native pointer.
; Syntax ........: __WebView2_Frame_Find($iValue[, $bPointer = False])
; Parameters ....: $iValue - Frame ID or pointer.
;                  $bPointer - True to search by pointer.
; Return values .: Registry slot or -1.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Frame_Find($iValue, $bPointer = False)
	Local $iResult = -1
	For $i = 0 To $__WEBVIEW2_MAX_FRAMES - 1
		If $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_ACTIVE] Then
			If $bPointer Then
				If $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_POINTER] = $iValue Then $iResult = $i
			Else
				If $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_ID] = $iValue Then $iResult = $i
			EndIf
			If $iResult >= 0 Then ExitLoop
		EndIf
	Next
	Return $iResult
EndFunc   ;==>__WebView2_Frame_Find

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_FrameCreated_Invoke
; Description ...: Registers a newly created native iframe.
; Syntax ........: __WebView2_FrameCreated_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: Native callback pointers.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_FrameCreated_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Do
		Local $iView = __WebView2_Instance_FindByCorePointer($pSender)
		If $iView < 0 Or Not $pArgs Then ExitLoop 1
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2FrameCreatedEventArgs, $WEBVIEW2_DTAG_ICoreWebView2FrameCreatedEventArgs)
		If Not IsObj($oArgs) Then ExitLoop 1
		$oArgs.AddRef()
		Local $pFrame = 0
		Local $iResult = $oArgs.get_Frame($pFrame)
		If @error Or $iResult <> $WEBVIEW2_S_OK Or Not $pFrame Then ExitLoop 1
		Local $iSlot = -1
		For $i = 0 To $__WEBVIEW2_MAX_FRAMES - 1
			If Not $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_ACTIVE] Then
				$iSlot = $i
				ExitLoop
			EndIf
		Next
		If $iSlot < 0 Then ExitLoop 1
		Local $oFrame = ObjCreateInterface($pFrame, $WEBVIEW2_IID_ICoreWebView2Frame, $WEBVIEW2_DTAG_ICoreWebView2Frame)
		If Not IsObj($oFrame) Then ExitLoop 1
		$oFrame.AddRef()
		Local $oFrame2 = __WebView2_Frame_QueryInterface($pFrame, $WEBVIEW2_IID_ICoreWebView2Frame2, $WEBVIEW2_DTAG_ICoreWebView2Frame2)
		If @error Then $oFrame2 = Null
		Local $tDestroyed = DllStructCreate("int64")
		$iResult = $oFrame.add_Destroyed(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_DESTROYED), $tDestroyed)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then ExitLoop 1
		Local $iMessageToken = 0
		If IsObj($oFrame2) Then
			Local $tMessage = DllStructCreate("int64")
			$iResult = $oFrame2.add_WebMessageReceived(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_MESSAGE), $tMessage)
			If Not @error And $iResult = $WEBVIEW2_S_OK Then $iMessageToken = DllStructGetData($tMessage, 1)
		EndIf
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ID] = $__g_iWebView2_NextFrameId
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OWNER] = $iView
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_POINTER] = $pFrame
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT] = $oFrame
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT2] = $oFrame2
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_DESTROY_TOKEN] = DllStructGetData($tDestroyed, 1)
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_MESSAGE_TOKEN] = $iMessageToken
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ACTIVE] = True
		$__g_iWebView2_NextFrameId += 1
		Local $fnCallback = $__g_aWebView2_FrameCreatedCallback[$iView]
		If IsFunc($fnCallback) Then Call($fnCallback, $iView, $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ID])
	Until True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_FrameCreated_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_FrameDestroyed_Invoke
; Description ...: Invalidates the frame when WebView2 destroys it.
; Syntax ........: __WebView2_FrameDestroyed_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: Native callback pointers.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_FrameDestroyed_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf, $pArgs
	Local $iSlot = __WebView2_Frame_Find($pSender, True)
	If $iSlot >= 0 Then
		Local $iView = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OWNER]
		Local $fnCallback = $__g_aWebView2_FrameDestroyedCallback[$iView]
		If IsFunc($fnCallback) Then Call($fnCallback, $iView, $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ID])
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ACTIVE] = False
		Local $oFrame = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT]
		If IsObj($oFrame) And $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_DESTROY_TOKEN] Then $oFrame.remove_Destroyed($__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_DESTROY_TOKEN])
		Local $oFrame2 = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT2]
		If IsObj($oFrame2) And $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_MESSAGE_TOKEN] Then $oFrame2.remove_WebMessageReceived($__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_MESSAGE_TOKEN])
		For $i = 0 To $__WEBVIEW2_FRAME_FIELDS - 1
			$__g_aWebView2_Frames[$iSlot][$i] = Null
		Next
	EndIf
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_FrameDestroyed_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_FrameMessage_Invoke
; Description ...: Delivers a WebMessageReceived event from a frame.
; Syntax ........: __WebView2_FrameMessage_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: Native callback pointers.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_FrameMessage_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Do
		Local $iSlot = __WebView2_Frame_Find($pSender, True)
		If $iSlot < 0 Or Not $pArgs Then ExitLoop 1
		Local $iView = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OWNER]
		Local $fnCallback = $__g_aWebView2_FrameMessageCallback[$iView]
		If Not IsFunc($fnCallback) Then ExitLoop 1
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2WebMessageReceivedEventArgs, $WEBVIEW2_DTAG_ICoreWebView2WebMessageReceivedEventArgs)
		If Not IsObj($oArgs) Then ExitLoop 1
		$oArgs.AddRef()
		Local $pSource = 0, $pMessage = 0, $bJSON = False
		$oArgs.get_Source($pSource)
		Local $sSource = __WebView2_CoTaskMemString_ReadAndFree($pSource)
		Local $iResult = $oArgs.TryGetWebMessageAsString($pMessage)
		Local $sMessage = ""
		If Not @error And $iResult = $WEBVIEW2_S_OK Then
			$sMessage = __WebView2_CoTaskMemString_ReadAndFree($pMessage)
		Else
			$pMessage = 0
			$oArgs.get_WebMessageAsJson($pMessage)
			$sMessage = __WebView2_CoTaskMemString_ReadAndFree($pMessage)
			$bJSON = True
		EndIf
		Call($fnCallback, $iView, $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ID], $sMessage, $sSource, $bJSON)
	Until True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_FrameMessage_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Frame_Cleanup
; Description ...: Removes frame subscriptions before the controller is closed.
; Syntax ........: __WebView2_Frame_Cleanup($iView)
; Parameters ....: $iView - WebView2 instance ID.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Frame_Cleanup($iView)
	For $i = 0 To $__WEBVIEW2_MAX_FRAMES - 1
		If $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_ACTIVE] And $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_OWNER] = $iView Then
			Local $oFrame = $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_OBJECT]
			Local $oFrame2 = $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_OBJECT2]
			If IsObj($oFrame2) And $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_MESSAGE_TOKEN] Then $oFrame2.remove_WebMessageReceived($__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_MESSAGE_TOKEN])
			If IsObj($oFrame) And $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_DESTROY_TOKEN] Then $oFrame.remove_Destroyed($__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_DESTROY_TOKEN])
			For $j = 0 To $__WEBVIEW2_FRAME_FIELDS - 1
				$__g_aWebView2_Frames[$i][$j] = Null
			Next
		EndIf
	Next
	If IsObj($__g_aWebView2_FrameCore4[$iView]) And $__g_aWebView2_FrameToken[$iView] Then $__g_aWebView2_FrameCore4[$iView].remove_FrameCreated($__g_aWebView2_FrameToken[$iView])
	$__g_aWebView2_FrameCore4[$iView] = Null
	$__g_aWebView2_FrameToken[$iView] = 0
	$__g_aWebView2_FrameCreatedCallback[$iView] = Null
	$__g_aWebView2_FrameDestroyedCallback[$iView] = Null
	$__g_aWebView2_FrameMessageCallback[$iView] = Null
	Return
EndFunc   ;==>__WebView2_Frame_Cleanup

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Frame_List
; Description ...: Lists active native frames tracked for one WebView2 instance.
; Syntax ........: _WebView2_Frame_List($iWebView)
; Parameters ....: $iWebView - WebView2 instance ID.
; Return values .: Array of frame IDs, or empty array; @error on invalid instance.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Register a frame callback before navigating to capture newly created frames.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_Frame_List($iWebView)
	Local Const $sFuncName = "_WebView2_Frame_List"
	Local $sMessage = "Invalid WebView2 instance."
	Local $aResult[0], $iError = 0
	If Not __WebView2_Instance_IsValid($iWebView) Then
		$iError = $WEBVIEW2_ERR_INVALID_INSTANCE
	Else
		For $i = 0 To $__WEBVIEW2_MAX_FRAMES - 1
			If $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_ACTIVE] And $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_OWNER] = $iWebView Then
				ReDim $aResult[UBound($aResult) + 1]
				$aResult[UBound($aResult) - 1] = $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_ID]
			EndIf
		Next
	EndIf
	If $iError Then __WebView2_Error($sFuncName, $iError, $sMessage, 0)
	Return SetError($iError, 0, $aResult)
EndFunc   ;==>_WebView2_Frame_List

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Frame_GetName
; Description ...: Reads the native iframe window.name value.
; Syntax ........: _WebView2_Frame_GetName($iFrame)
; Parameters ....: $iFrame - Tracked frame ID.
; Return values .: Name string, or empty string with @error set.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_Frame_GetName($iFrame)
	Local Const $sFuncName = "_WebView2_Frame_GetName"
	Local $sMessage = "Cannot read the native frame name."
	Local $sResult = "", $iError = 0, $iExtended = 0
	Do
		Local $iSlot = __WebView2_Frame_Find($iFrame)
		If $iSlot < 0 Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $oFrame = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT]
		Local $pName = 0
		Local $iResult = $oFrame.get_Name($pName)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop 1
		EndIf
		$sResult = __WebView2_CoTaskMemString_ReadAndFree($pName)
	Until True
	If $iError Then __WebView2_Error($sFuncName, $iError, $sMessage, $iExtended)
	Return SetError($iError, $iExtended, $sResult)
EndFunc   ;==>_WebView2_Frame_GetName

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Frame_ExecuteScript
; Description ...: Executes JavaScript in one frame and returns its JSON result.
; Syntax ........: _WebView2_Frame_ExecuteScript($iFrame, $sScript[, $iTimeoutMs = 30000])
; Parameters ....: $iFrame - Tracked frame ID.
;                  $sScript - JavaScript source.
;                  $iTimeoutMs - Maximum wait time.
; Return values .: JSON result or empty string with @error set.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Shares the serialized result channel with top-level ExecuteScript.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_Frame_ExecuteScript($iFrame, $sScript, $iTimeoutMs = 30000)
	Local Const $sFuncName = "_WebView2_Frame_ExecuteScript"
	Local $sMessage = "Frame script execution failed."
	Local $sResult = "", $iError = 0, $iExtended = 0
	Do
		Local $iSlot = __WebView2_Frame_Find($iFrame)
		If $iSlot < 0 Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $oFrame2 = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT2]
		If Not IsObj($oFrame2) Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $WEBVIEW2_E_NOINTERFACE
			ExitLoop 1
		EndIf
		If $__g_bWebView2_ScriptBusy Then
			$iError = $WEBVIEW2_ERR_BUSY
			ExitLoop 1
		EndIf
		$__g_bWebView2_ScriptBusy = True
		$__g_bWebView2_ScriptDone = False
		$__g_iWebView2_ScriptHRESULT = 0
		$__g_sWebView2_ScriptResult = ""
		Local $iResult = $oFrame2.ExecuteScript($sScript, __WebView2_Callback_GetPointer($__WEBVIEW2_CB_EXECUTE_SCRIPT))
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$__g_bWebView2_ScriptBusy = False
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop 1
		EndIf
		Local $bWait = __WebView2_WaitForFlag($__g_bWebView2_ScriptDone, $iTimeoutMs)
		Local $iWaitError = @error, $iWaitExtended = @extended
		$__g_bWebView2_ScriptBusy = False
		If Not $bWait Then
			$iError = $iWaitError
			$iExtended = $iWaitExtended
			ExitLoop 1
		EndIf
		If $__g_iWebView2_ScriptHRESULT <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $__g_iWebView2_ScriptHRESULT
			ExitLoop 1
		EndIf
		$sResult = $__g_sWebView2_ScriptResult
	Until True
	If $iError Then __WebView2_Error($sFuncName, $iError, $sMessage, $iExtended)
	Return SetError($iError, $iExtended, $sResult)
EndFunc   ;==>_WebView2_Frame_ExecuteScript

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Frame_PostWebMessageAsJson
; Description ...: Posts JSON to one frame.
; Syntax ........: _WebView2_Frame_PostWebMessageAsJson($iFrame, $sJSON)
; Parameters ....: $iFrame - Tracked frame ID.
;                  $sJSON - Valid JSON text.
; Return values .: True or False with @error set.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_Frame_PostWebMessageAsJson($iFrame, $sJSON)
	Local Const $sFuncName = "_WebView2_Frame_PostWebMessageAsJson"
	Local $sMessage = "Cannot post JSON to the frame."
	Local $bResult = False, $iError = 0, $iExtended = 0
	Do
		Local $iSlot = __WebView2_Frame_Find($iFrame)
		If $iSlot < 0 Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $oFrame2 = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT2]
		If Not IsObj($oFrame2) Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $WEBVIEW2_E_NOINTERFACE
			ExitLoop 1
		EndIf
		Local $iResult = $oFrame2.PostWebMessageAsJson($sJSON)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop 1
		EndIf
		$bResult = True
	Until True
	If $iError Then __WebView2_Error($sFuncName, $iError, $sMessage, $iExtended)
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_Frame_PostWebMessageAsJson

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Frame_PostWebMessageAsString
; Description ...: Posts a string to one frame.
; Syntax ........: _WebView2_Frame_PostWebMessageAsString($iFrame, $sMessage)
; Parameters ....: $iFrame - Tracked frame ID.
;                  $sMessage - Message text.
; Return values .: True or False with @error set.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_Frame_PostWebMessageAsString($iFrame, $sMessage)
	Local Const $sFuncName = "_WebView2_Frame_PostWebMessageAsString"
	Local $sErrorMessage = "Cannot post a string to the frame."
	Local $bResult = False, $iError = 0, $iExtended = 0
	Do
		Local $iSlot = __WebView2_Frame_Find($iFrame)
		If $iSlot < 0 Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $oFrame2 = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT2]
		If Not IsObj($oFrame2) Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $WEBVIEW2_E_NOINTERFACE
			ExitLoop 1
		EndIf
		Local $iResult = $oFrame2.PostWebMessageAsString($sMessage)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop 1
		EndIf
		$bResult = True
	Until True
	If $iError Then __WebView2_Error($sFuncName, $iError, $sErrorMessage, $iExtended)
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_Frame_PostWebMessageAsString
