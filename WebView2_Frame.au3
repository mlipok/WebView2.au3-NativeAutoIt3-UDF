#include-once
#Tidy_ILC_Pos=44

; #INDEX# =======================================================================================================================
; Title .........: WebView2_Frame.au3
; Description ...: Native frame tracking, messaging, script execution and host objects.
; Author(s) .....: mLipok
; Version .......: 0.6.0
; ===============================================================================================================================

Global Const $__WEBVIEW2_MAX_FRAMES = 256
Global Enum _
		$__WEBVIEW2_FRAME_ID, _
		$__WEBVIEW2_FRAME_OWNER, _
		$__WEBVIEW2_FRAME_POINTER, _
		$__WEBVIEW2_FRAME_OBJECT, _
		$__WEBVIEW2_FRAME_OBJECT2, _
		$__WEBVIEW2_FRAME_OBJECT3, _
		$__WEBVIEW2_FRAME_OBJECT6, _
		$__WEBVIEW2_FRAME_DESTROY_TOKEN, _
		$__WEBVIEW2_FRAME_MESSAGE_TOKEN, _
		$__WEBVIEW2_FRAME_NAV_START_TOKEN, _
		$__WEBVIEW2_FRAME_NAV_COMPLETE_TOKEN, _
		$__WEBVIEW2_FRAME_PERMISSION_TOKEN, _
		$__WEBVIEW2_FRAME_CAPTURE_TOKEN, _
		$__WEBVIEW2_FRAME_ACTIVE, _
		$__WEBVIEW2_FRAME_PARENT_ID, _
		$__WEBVIEW2_FRAME_OBJECT7, _
		$__WEBVIEW2_FRAME_CHILD_TOKEN, _
		$__WEBVIEW2_FRAME_OBJECT8, _
		$__WEBVIEW2_FRAME_WORKER_TOKEN, _
		$__WEBVIEW2_FRAME_NAME_TOKEN, _
		$__WEBVIEW2_FRAME_CONTENT_TOKEN, _
		$__WEBVIEW2_FRAME_DOM_TOKEN, _
		$__WEBVIEW2_FRAME_FIELDS
Global $__g_aWebView2_Frames[$__WEBVIEW2_MAX_FRAMES][$__WEBVIEW2_FRAME_FIELDS]
Global $__g_iWebView2_NextFrameId = 1
Global $__g_aWebView2_FrameCore4[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_FrameToken[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_FrameCreatedCallback[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_FrameDestroyedCallback[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_FrameMessageCallback[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_FrameNavStartCallback[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_FrameNavCompleteCallback[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_FramePermissionCallback[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_FrameCaptureCallback[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_FrameWorkerCreatedCallback[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_FrameNameCallback[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_FrameContentCallback[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_FrameDOMCallback[$WEBVIEW2_MAX_INSTANCES]

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
		If $iEvent = $WEBVIEW2_EVENT_WORKER_CREATED Or $iEvent = $WEBVIEW2_EVENT_WORKER_WEB_MESSAGE_RECEIVED Or $iEvent = $WEBVIEW2_EVENT_WORKER_DESTROYING Then
			If Not __WebView2_Worker_PrepareCallbacks() Then
				$iError = $WEBVIEW2_ERR_CALLBACK
				ExitLoop 1
			EndIf
		EndIf
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
			If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_NAV_START) Then
				If Not __WebView2_Callback_Create($__WEBVIEW2_CB_FRAME_NAV_START, __WebView2_FrameNavStart_Invoke, "ptr;ptr;ptr") Then
					$iError = $WEBVIEW2_ERR_CALLBACK
					ExitLoop 1
				EndIf
			EndIf
			If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_NAV_COMPLETE) Then
				If Not __WebView2_Callback_Create($__WEBVIEW2_CB_FRAME_NAV_COMPLETE, __WebView2_FrameNavComplete_Invoke, "ptr;ptr;ptr") Then
					$iError = $WEBVIEW2_ERR_CALLBACK
					ExitLoop 1
				EndIf
			EndIf
			If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_PERMISSION) Then
				If Not __WebView2_Callback_Create($__WEBVIEW2_CB_FRAME_PERMISSION, __WebView2_FramePermission_Invoke, "ptr;ptr;ptr") Then
					$iError = $WEBVIEW2_ERR_CALLBACK
					ExitLoop 1
				EndIf
			EndIf
			If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_SCREEN_CAPTURE) Then
				If Not __WebView2_Callback_Create($__WEBVIEW2_CB_FRAME_SCREEN_CAPTURE, __WebView2_FrameCapture_Invoke, "ptr;ptr;ptr") Then
					$iError = $WEBVIEW2_ERR_CALLBACK
					ExitLoop 1
				EndIf
			EndIf
			If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_CHILD_CREATED) Then
				If Not __WebView2_Callback_Create($__WEBVIEW2_CB_FRAME_CHILD_CREATED, __WebView2_FrameChildCreated_Invoke, "ptr;ptr;ptr") Then
					$iError = $WEBVIEW2_ERR_CALLBACK
					ExitLoop 1
				EndIf
			EndIf
			If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_DEDICATED_WORKER_CREATED) Then
				If Not __WebView2_Callback_Create($__WEBVIEW2_CB_FRAME_DEDICATED_WORKER_CREATED, __WebView2_FrameWorkerCreated_Invoke, "ptr;ptr;ptr") Then
					$iError = $WEBVIEW2_ERR_CALLBACK
					ExitLoop 1
				EndIf
			EndIf
			If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_NAME_CHANGED) Then
				If Not __WebView2_Callback_Create($__WEBVIEW2_CB_FRAME_NAME_CHANGED, __WebView2_FrameNameChanged_Invoke, "ptr;ptr;ptr") Then
					$iError = $WEBVIEW2_ERR_CALLBACK
					ExitLoop 1
				EndIf
			EndIf
			If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_CONTENT_LOADING) Then
				If Not __WebView2_Callback_Create($__WEBVIEW2_CB_FRAME_CONTENT_LOADING, __WebView2_FrameContentLoading_Invoke, "ptr;ptr;ptr") Then
					$iError = $WEBVIEW2_ERR_CALLBACK
					ExitLoop 1
				EndIf
			EndIf
			If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_DOM_CONTENT_LOADED) Then
				If Not __WebView2_Callback_Create($__WEBVIEW2_CB_FRAME_DOM_CONTENT_LOADED, __WebView2_FrameDOMContentLoaded_Invoke, "ptr;ptr;ptr") Then
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
			Case $WEBVIEW2_EVENT_FRAME_NAVIGATION_STARTING
				$__g_aWebView2_FrameNavStartCallback[$iWebView] = $fnCallback
			Case $WEBVIEW2_EVENT_FRAME_NAVIGATION_COMPLETED
				$__g_aWebView2_FrameNavCompleteCallback[$iWebView] = $fnCallback
			Case $WEBVIEW2_EVENT_FRAME_PERMISSION_REQUESTED
				$__g_aWebView2_FramePermissionCallback[$iWebView] = $fnCallback
			Case $WEBVIEW2_EVENT_FRAME_SCREEN_CAPTURE_STARTING
				$__g_aWebView2_FrameCaptureCallback[$iWebView] = $fnCallback
			Case $WEBVIEW2_EVENT_FRAME_DEDICATED_WORKER_CREATED
				$__g_aWebView2_FrameWorkerCreatedCallback[$iWebView] = $fnCallback
			Case $WEBVIEW2_EVENT_FRAME_NAME_CHANGED
				$__g_aWebView2_FrameNameCallback[$iWebView] = $fnCallback
			Case $WEBVIEW2_EVENT_FRAME_CONTENT_LOADING
				$__g_aWebView2_FrameContentCallback[$iWebView] = $fnCallback
			Case $WEBVIEW2_EVENT_FRAME_DOM_CONTENT_LOADED
				$__g_aWebView2_FrameDOMCallback[$iWebView] = $fnCallback
			Case $WEBVIEW2_EVENT_WORKER_CREATED, $WEBVIEW2_EVENT_WORKER_WEB_MESSAGE_RECEIVED, $WEBVIEW2_EVENT_WORKER_DESTROYING
				__WebView2_Worker_SetCallback($iWebView, $iEvent, $fnCallback)
		EndSwitch
		If $iEvent = $WEBVIEW2_EVENT_FRAME_DEDICATED_WORKER_CREATED Or $iEvent = $WEBVIEW2_EVENT_WORKER_CREATED Or _
				$iEvent = $WEBVIEW2_EVENT_WORKER_WEB_MESSAGE_RECEIVED Or $iEvent = $WEBVIEW2_EVENT_WORKER_DESTROYING Then
			For $i = 0 To $__WEBVIEW2_MAX_FRAMES - 1
				If $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_ACTIVE] And $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_OWNER] = $iWebView Then __WebView2_Frame_SubscribeWorkerCreated($i)
			Next
			If __WebView2_Worker_HasCallback($iWebView) Then __WebView2_Worker_SubscribeTopLevel($iWebView)
		EndIf
		$bResult = True
	Until True
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>__WebView2_Frame_SetCallback

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Frame_SubscribeWorkerCreated
; Description ...: Subscribes one tracked frame to native dedicated-worker creation when supported.
; Syntax ........: __WebView2_Frame_SubscribeWorkerCreated($iSlot)
; Parameters ....: $iSlot - Active frame registry slot.
; Return values .: True when subscribed, False when Frame8 is unavailable or subscription fails.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Subscriptions are optional and are removed with the frame.
; Related .......: __WebView2_FrameWorkerCreated_Invoke
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2frame8
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Frame_SubscribeWorkerCreated($iSlot)
	Local $bResult = False
	Do
		If $iSlot < 0 Or $iSlot >= $__WEBVIEW2_MAX_FRAMES Then ExitLoop 1
		If Not $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ACTIVE] Then ExitLoop 1
		If $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_WORKER_TOKEN] Then
			$bResult = True
			ExitLoop 1
		EndIf
		Local $iView = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OWNER]
		If Not IsFunc($__g_aWebView2_FrameWorkerCreatedCallback[$iView]) And Not __WebView2_Worker_HasCallback($iView) Then ExitLoop 1
		Local $oFrame8 = __WebView2_Frame_QueryInterface($__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_POINTER], _
				$WEBVIEW2_IID_ICoreWebView2Frame8, $WEBVIEW2_DTAG_ICoreWebView2Frame8)
		If @error Then ExitLoop 1
		Local $tToken = DllStructCreate("int64")
		Local $iHRESULT = $oFrame8.add_DedicatedWorkerCreated(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_DEDICATED_WORKER_CREATED), $tToken)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT8] = $oFrame8
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_WORKER_TOKEN] = DllStructGetData($tToken, 1)
		$bResult = True
	Until True
	Return $bResult
EndFunc   ;==>__WebView2_Frame_SubscribeWorkerCreated

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
		__WebView2_Frame_Register($iView, $pFrame, 0)
	Until True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_FrameCreated_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_FrameChildCreated_Invoke
; Description ...: Registers a direct child of an already tracked frame.
; Syntax ........: __WebView2_FrameChildCreated_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: Native callback pointers.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The sender is the parent ICoreWebView2Frame.
; Related .......: __WebView2_Frame_Register
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_FrameChildCreated_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Do
		Local $iParentSlot = __WebView2_Frame_Find($pSender, True)
		If $iParentSlot < 0 Or Not $pArgs Then ExitLoop 1
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2FrameCreatedEventArgs, $WEBVIEW2_DTAG_ICoreWebView2FrameCreatedEventArgs)
		If Not IsObj($oArgs) Then ExitLoop 1
		$oArgs.AddRef()
		Local $pFrame = 0
		Local $iResult = $oArgs.get_Frame($pFrame)
		If @error Or $iResult <> $WEBVIEW2_S_OK Or Not $pFrame Then ExitLoop 1
		__WebView2_Frame_Register($__g_aWebView2_Frames[$iParentSlot][$__WEBVIEW2_FRAME_OWNER], $pFrame, $__g_aWebView2_Frames[$iParentSlot][$__WEBVIEW2_FRAME_ID])
	Until True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_FrameChildCreated_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_FrameWorkerCreated_Invoke
; Description ...: Reports a dedicated worker created by a tracked iframe.
; Syntax ........: __WebView2_FrameWorkerCreated_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: Native callback pointers.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Passes values only; the worker COM object is not retained by the UDF.
; Related .......: __WebView2_Frame_SubscribeWorkerCreated
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2dedicatedworkercreatedeventargs
; Example .......: No
; ===============================================================================================================================
Func __WebView2_FrameWorkerCreated_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Do
		Local $iSlot = __WebView2_Frame_Find($pSender, True)
		If $iSlot < 0 Or Not $pArgs Then ExitLoop 1
		Local $iView = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OWNER]
		Local $fnCallback = $__g_aWebView2_FrameWorkerCreatedCallback[$iView]
		If Not IsFunc($fnCallback) And Not __WebView2_Worker_HasCallback($iView) Then ExitLoop 1
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2DedicatedWorkerCreatedEventArgs, $WEBVIEW2_DTAG_ICoreWebView2DedicatedWorkerCreatedEventArgs)
		If Not IsObj($oArgs) Then ExitLoop 1
		$oArgs.AddRef()
		Local $pWorker = 0
		Local $iHRESULT = $oArgs.get_Worker($pWorker)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Or Not $pWorker Then ExitLoop 1
		Local $oWorker = ObjCreateInterface($pWorker, $WEBVIEW2_IID_ICoreWebView2DedicatedWorker, $WEBVIEW2_DTAG_ICoreWebView2DedicatedWorker)
		If Not IsObj($oWorker) Then ExitLoop 1
		Local $pScriptURI = 0
		$iHRESULT = $oWorker.get_ScriptUri($pScriptURI)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
			If $pScriptURI Then __WebView2_CoTaskMemString_ReadAndFree($pScriptURI)
			ExitLoop 1
		EndIf
		Local $sScriptURI = __WebView2_CoTaskMemString_ReadAndFree($pScriptURI)
		Local $iFrame = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ID]
		If __WebView2_Worker_HasCallback($iView) Then __WebView2_Worker_Register($iView, $iFrame, $pWorker, $oWorker, $sScriptURI)
		If IsFunc($fnCallback) Then Call($fnCallback, $iView, $iFrame, $sScriptURI)
	Until True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_FrameWorkerCreated_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Frame_Register
; Description ...: Tracks one frame and subscribes to direct children when Frame7 is available.
; Syntax ........: __WebView2_Frame_Register($iView, $pFrame, $iParentId)
; Parameters ....: $iView - Owner WebView2 instance.
;                  $pFrame - Native ICoreWebView2Frame pointer.
;                  $iParentId - Tracked parent ID, or zero for a top-level iframe.
; Return values .: Tracked frame ID, or zero if registration fails.
; Author ........: mLipok
; Modified ......:
; Remarks .......: A later child callback can supply the parent for a frame seen first by the top-level callback.
; Related .......: __WebView2_FrameCreated_Invoke, __WebView2_FrameChildCreated_Invoke
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Frame_Register($iView, $pFrame, $iParentId)
	Local $iFrameId = 0
	Do
		Local $iSlot = __WebView2_Frame_Find($pFrame, True)
		If $iSlot >= 0 Then
			If $iParentId > 0 Then $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_PARENT_ID] = $iParentId
			$iFrameId = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ID]
			ExitLoop 1
		EndIf
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
		Local $oFrame3 = __WebView2_Frame_QueryInterface($pFrame, $WEBVIEW2_IID_ICoreWebView2Frame3, $WEBVIEW2_DTAG_ICoreWebView2Frame3)
		If @error Then $oFrame3 = Null
		Local $oFrame6 = __WebView2_Frame_QueryInterface($pFrame, $WEBVIEW2_IID_ICoreWebView2Frame6, $WEBVIEW2_DTAG_ICoreWebView2Frame6)
		If @error Then $oFrame6 = Null
		Local $oFrame7 = __WebView2_Frame_QueryInterface($pFrame, $WEBVIEW2_IID_ICoreWebView2Frame7, $WEBVIEW2_DTAG_ICoreWebView2Frame7)
		If @error Then $oFrame7 = Null
		Local $tDestroyed = DllStructCreate("int64")
		Local $iResult = $oFrame.add_Destroyed(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_DESTROYED), $tDestroyed)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then ExitLoop 1
		Local $iNameToken = 0
		Local $tName = DllStructCreate("int64")
		$iResult = $oFrame.add_NameChanged(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_NAME_CHANGED), $tName)
		If Not @error And $iResult = $WEBVIEW2_S_OK Then $iNameToken = DllStructGetData($tName, 1)
		Local $iMessageToken = 0
		Local $iNavStartToken = 0, $iNavCompleteToken = 0
		Local $iContentToken = 0, $iDOMToken = 0
		If IsObj($oFrame2) Then
			Local $tMessage = DllStructCreate("int64")
			$iResult = $oFrame2.add_WebMessageReceived(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_MESSAGE), $tMessage)
			If Not @error And $iResult = $WEBVIEW2_S_OK Then $iMessageToken = DllStructGetData($tMessage, 1)
			Local $tNavStart = DllStructCreate("int64")
			$iResult = $oFrame2.add_NavigationStarting(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_NAV_START), $tNavStart)
			If Not @error And $iResult = $WEBVIEW2_S_OK Then $iNavStartToken = DllStructGetData($tNavStart, 1)
			Local $tNavComplete = DllStructCreate("int64")
			$iResult = $oFrame2.add_NavigationCompleted(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_NAV_COMPLETE), $tNavComplete)
			If Not @error And $iResult = $WEBVIEW2_S_OK Then $iNavCompleteToken = DllStructGetData($tNavComplete, 1)
			Local $tContent = DllStructCreate("int64")
			$iResult = $oFrame2.add_ContentLoading(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_CONTENT_LOADING), $tContent)
			If Not @error And $iResult = $WEBVIEW2_S_OK Then $iContentToken = DllStructGetData($tContent, 1)
			Local $tDOM = DllStructCreate("int64")
			$iResult = $oFrame2.add_DOMContentLoaded(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_DOM_CONTENT_LOADED), $tDOM)
			If Not @error And $iResult = $WEBVIEW2_S_OK Then $iDOMToken = DllStructGetData($tDOM, 1)
		EndIf
		Local $iPermissionToken = 0, $iCaptureToken = 0
		If IsObj($oFrame3) Then
			Local $tPermission = DllStructCreate("int64")
			$iResult = $oFrame3.add_PermissionRequested(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_PERMISSION), $tPermission)
			If Not @error And $iResult = $WEBVIEW2_S_OK Then $iPermissionToken = DllStructGetData($tPermission, 1)
		EndIf
		If IsObj($oFrame6) Then
			Local $tCapture = DllStructCreate("int64")
			$iResult = $oFrame6.add_ScreenCaptureStarting(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_SCREEN_CAPTURE), $tCapture)
			If Not @error And $iResult = $WEBVIEW2_S_OK Then $iCaptureToken = DllStructGetData($tCapture, 1)
		EndIf
		$iFrameId = $__g_iWebView2_NextFrameId
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ID] = $iFrameId
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OWNER] = $iView
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_POINTER] = $pFrame
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT] = $oFrame
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT2] = $oFrame2
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT3] = $oFrame3
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT6] = $oFrame6
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT7] = $oFrame7
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_PARENT_ID] = $iParentId
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_DESTROY_TOKEN] = DllStructGetData($tDestroyed, 1)
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_NAME_TOKEN] = $iNameToken
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_MESSAGE_TOKEN] = $iMessageToken
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_NAV_START_TOKEN] = $iNavStartToken
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_NAV_COMPLETE_TOKEN] = $iNavCompleteToken
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_CONTENT_TOKEN] = $iContentToken
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_DOM_TOKEN] = $iDOMToken
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_PERMISSION_TOKEN] = $iPermissionToken
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_CAPTURE_TOKEN] = $iCaptureToken
		$__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ACTIVE] = True
		$__g_iWebView2_NextFrameId += 1
		If IsObj($oFrame7) Then
			Local $tChildToken = DllStructCreate("int64")
			$iResult = $oFrame7.add_FrameCreated(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_FRAME_CHILD_CREATED), $tChildToken)
			If Not @error And $iResult = $WEBVIEW2_S_OK Then $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_CHILD_TOKEN] = DllStructGetData($tChildToken, 1)
		EndIf
		__WebView2_Frame_SubscribeWorkerCreated($iSlot)
		Local $fnCallback = $__g_aWebView2_FrameCreatedCallback[$iView]
		If IsFunc($fnCallback) Then Call($fnCallback, $iView, $iFrameId)
	Until True
	Return $iFrameId
EndFunc   ;==>__WebView2_Frame_Register

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
		__WebView2_Worker_CleanupFrame($__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ID])
		Local $oFrame = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT]
		If IsObj($oFrame) And $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_DESTROY_TOKEN] Then $oFrame.remove_Destroyed($__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_DESTROY_TOKEN])
		If IsObj($oFrame) And $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_NAME_TOKEN] Then $oFrame.remove_NameChanged($__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_NAME_TOKEN])
		Local $oFrame2 = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT2]
		If IsObj($oFrame2) And $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_MESSAGE_TOKEN] Then $oFrame2.remove_WebMessageReceived($__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_MESSAGE_TOKEN])
		If IsObj($oFrame2) And $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_NAV_START_TOKEN] Then $oFrame2.remove_NavigationStarting($__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_NAV_START_TOKEN])
		If IsObj($oFrame2) And $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_NAV_COMPLETE_TOKEN] Then $oFrame2.remove_NavigationCompleted($__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_NAV_COMPLETE_TOKEN])
		If IsObj($oFrame2) And $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_CONTENT_TOKEN] Then $oFrame2.remove_ContentLoading($__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_CONTENT_TOKEN])
		If IsObj($oFrame2) And $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_DOM_TOKEN] Then $oFrame2.remove_DOMContentLoaded($__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_DOM_TOKEN])
		Local $oFrame3 = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT3]
		If IsObj($oFrame3) And $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_PERMISSION_TOKEN] Then $oFrame3.remove_PermissionRequested($__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_PERMISSION_TOKEN])
		Local $oFrame6 = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT6]
		If IsObj($oFrame6) And $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_CAPTURE_TOKEN] Then $oFrame6.remove_ScreenCaptureStarting($__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_CAPTURE_TOKEN])
		Local $oFrame7 = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT7]
		If IsObj($oFrame7) And $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_CHILD_TOKEN] Then $oFrame7.remove_FrameCreated($__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_CHILD_TOKEN])
		Local $oFrame8 = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT8]
		If IsObj($oFrame8) And $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_WORKER_TOKEN] Then $oFrame8.remove_DedicatedWorkerCreated($__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_WORKER_TOKEN])
		For $i = 0 To $__WEBVIEW2_FRAME_FIELDS - 1
			$__g_aWebView2_Frames[$iSlot][$i] = Null
		Next
	EndIf
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_FrameDestroyed_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_FrameNameChanged_Invoke
; Description ...: Reports the current name of a tracked frame after it changes.
; Syntax ........: __WebView2_FrameNameChanged_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: Native callback pointers.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Reads the name immediately; no blocking WebView2 helper is called.
; Related .......: _WebView2_Frame_GetName
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2frame
; Example .......: No
; ===============================================================================================================================
Func __WebView2_FrameNameChanged_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf, $pArgs
	Do
		Local $iSlot = __WebView2_Frame_Find($pSender, True)
		If $iSlot < 0 Then ExitLoop 1
		Local $iView = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OWNER]
		Local $fnCallback = $__g_aWebView2_FrameNameCallback[$iView]
		If Not IsFunc($fnCallback) Then ExitLoop 1
		Local $oFrame = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT]
		Local $pName = 0
		Local $iHRESULT = $oFrame.get_Name($pName)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		Local $sName = __WebView2_CoTaskMemString_ReadAndFree($pName)
		Call($fnCallback, $iView, $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ID], $sName)
	Until True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_FrameNameChanged_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_FrameContentLoading_Invoke
; Description ...: Reports an iframe's content-loading stage and navigation ID.
; Syntax ........: __WebView2_FrameContentLoading_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: Native callback pointers.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The callback is observational; avoid synchronous WebView2 calls from the user callback.
; Related .......: __WebView2_FrameDOMContentLoaded_Invoke
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2frame2
; Example .......: No
; ===============================================================================================================================
Func __WebView2_FrameContentLoading_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Do
		Local $iSlot = __WebView2_Frame_Find($pSender, True)
		If $iSlot < 0 Or Not $pArgs Then ExitLoop 1
		Local $iView = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OWNER]
		Local $fnCallback = $__g_aWebView2_FrameContentCallback[$iView]
		If Not IsFunc($fnCallback) Then ExitLoop 1
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2ContentLoadingEventArgs, $WEBVIEW2_DTAG_ICoreWebView2ContentLoadingEventArgs)
		If Not IsObj($oArgs) Then ExitLoop 1
		$oArgs.AddRef()
		Local $bErrorPage = False, $iNavigationId = 0
		Local $iHRESULT = $oArgs.get_IsErrorPage($bErrorPage)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		$iHRESULT = $oArgs.get_NavigationId($iNavigationId)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		Call($fnCallback, $iView, $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ID], $bErrorPage, $iNavigationId)
	Until True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_FrameContentLoading_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_FrameDOMContentLoaded_Invoke
; Description ...: Reports that an iframe document has been parsed.
; Syntax ........: __WebView2_FrameDOMContentLoaded_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: Native callback pointers.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The navigation ID corresponds to the content-loading ID for the same navigation.
; Related .......: __WebView2_FrameContentLoading_Invoke
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2frame2
; Example .......: No
; ===============================================================================================================================
Func __WebView2_FrameDOMContentLoaded_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Do
		Local $iSlot = __WebView2_Frame_Find($pSender, True)
		If $iSlot < 0 Or Not $pArgs Then ExitLoop 1
		Local $iView = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OWNER]
		Local $fnCallback = $__g_aWebView2_FrameDOMCallback[$iView]
		If Not IsFunc($fnCallback) Then ExitLoop 1
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2DOMContentLoadedEventArgs, $WEBVIEW2_DTAG_ICoreWebView2DOMContentLoadedEventArgs)
		If Not IsObj($oArgs) Then ExitLoop 1
		$oArgs.AddRef()
		Local $iNavigationId = 0
		Local $iHRESULT = $oArgs.get_NavigationId($iNavigationId)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		Call($fnCallback, $iView, $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ID], $iNavigationId)
	Until True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_FrameDOMContentLoaded_Invoke

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
; Name ..........: __WebView2_FrameNavStart_Invoke
; Description ...: Forwards one frame navigation start and permits an immediate cancellation.
; ===============================================================================================================================
Func __WebView2_FrameNavStart_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Do
		Local $iSlot = __WebView2_Frame_Find($pSender, True)
		If $iSlot < 0 Or Not $pArgs Then ExitLoop 1
		Local $iView = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OWNER]
		Local $fnCallback = $__g_aWebView2_FrameNavStartCallback[$iView]
		If Not IsFunc($fnCallback) Then ExitLoop 1
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2NavigationStartingEventArgs, $WEBVIEW2_DTAG_ICoreWebView2NavigationStartingEventArgs)
		If Not IsObj($oArgs) Then ExitLoop 1
		$oArgs.AddRef()
		Local $pURI = 0, $bUserInitiated = False, $bRedirected = False
		Local $iHRESULT = $oArgs.get_Uri($pURI)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		Local $sURI = __WebView2_CoTaskMemString_ReadAndFree($pURI)
		$oArgs.get_IsUserInitiated($bUserInitiated)
		$oArgs.get_IsRedirected($bRedirected)
		Local $vCancel = Call($fnCallback, $iView, $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ID], $sURI, $bUserInitiated, $bRedirected)
		If Not @error And $vCancel Then $oArgs.put_Cancel(True)
	Until True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_FrameNavStart_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_FrameNavComplete_Invoke
; Description ...: Forwards one completed frame navigation to the host callback.
; ===============================================================================================================================
Func __WebView2_FrameNavComplete_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Do
		Local $iSlot = __WebView2_Frame_Find($pSender, True)
		If $iSlot < 0 Or Not $pArgs Then ExitLoop 1
		Local $iView = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OWNER]
		Local $fnCallback = $__g_aWebView2_FrameNavCompleteCallback[$iView]
		If Not IsFunc($fnCallback) Then ExitLoop 1
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2NavigationCompletedEventArgs, $WEBVIEW2_DTAG_ICoreWebView2NavigationCompletedEventArgs)
		If Not IsObj($oArgs) Then ExitLoop 1
		$oArgs.AddRef()
		Local $bSuccess = False, $iWebError = 0
		Local $iHRESULT = $oArgs.get_IsSuccess($bSuccess)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		$oArgs.get_WebErrorStatus($iWebError)
		Call($fnCallback, $iView, $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ID], $bSuccess, $iWebError)
	Until True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_FrameNavComplete_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_FramePermission_Invoke
; Description ...: Applies an immediate permission decision for a tracked frame.
; ===============================================================================================================================
Func __WebView2_FramePermission_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Do
		Local $iSlot = __WebView2_Frame_Find($pSender, True)
		If $iSlot < 0 Or Not $pArgs Then ExitLoop 1
		Local $iView = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OWNER]
		Local $fnCallback = $__g_aWebView2_FramePermissionCallback[$iView]
		If Not IsFunc($fnCallback) Then ExitLoop 1
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2PermissionRequestedEventArgs, $WEBVIEW2_DTAG_ICoreWebView2PermissionRequestedEventArgs)
		If Not IsObj($oArgs) Then ExitLoop 1
		$oArgs.AddRef()
		Local $pURI = 0, $iKind = 0, $bUserInitiated = False
		Local $iHRESULT = $oArgs.get_Uri($pURI)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		Local $sURI = __WebView2_CoTaskMemString_ReadAndFree($pURI)
		$iHRESULT = $oArgs.get_PermissionKind($iKind)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		$iHRESULT = $oArgs.get_IsUserInitiated($bUserInitiated)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		Local $vDecision = Call($fnCallback, $iView, $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ID], $sURI, $iKind, $bUserInitiated)
		If @error Then ExitLoop 1
		Local $iState = $vDecision
		If IsArray($vDecision) Then
			If UBound($vDecision) <> 2 Then ExitLoop 1
			$iState = $vDecision[0]
		EndIf
		If Not IsInt($iState) Or $iState < $WEBVIEW2_PERMISSION_STATE_ALLOW Or $iState > $WEBVIEW2_PERMISSION_STATE_DENY Then ExitLoop 1
		Local $oArgs2 = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2PermissionRequestedEventArgs2, $WEBVIEW2_DTAG_ICoreWebView2PermissionRequestedEventArgs2)
		If Not IsObj($oArgs2) Then ExitLoop 1
		$oArgs2.AddRef()
		If IsArray($vDecision) Then
			Local $oArgs3 = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2PermissionRequestedEventArgs3, $WEBVIEW2_DTAG_ICoreWebView2PermissionRequestedEventArgs3)
			If Not IsObj($oArgs3) Then ExitLoop 1
			$oArgs3.AddRef()
			$iHRESULT = $oArgs3.put_SavesInProfile($vDecision[1])
			If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		EndIf
		$iHRESULT = $oArgs.put_State($iState)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		$oArgs2.put_Handled(True)
	Until True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_FramePermission_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_FrameCapture_Invoke
; Description ...: Permits a tracked frame to cancel its screen capture request.
; ===============================================================================================================================
Func __WebView2_FrameCapture_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Do
		Local $iSlot = __WebView2_Frame_Find($pSender, True)
		If $iSlot < 0 Or Not $pArgs Then ExitLoop 1
		Local $iView = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OWNER]
		Local $fnCallback = $__g_aWebView2_FrameCaptureCallback[$iView]
		If Not IsFunc($fnCallback) Then ExitLoop 1
		Local $vCancel = Call($fnCallback, $iView, $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_ID])
		If @error Or Not $vCancel Then ExitLoop 1
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2ScreenCaptureStartingEventArgs, $WEBVIEW2_DTAG_ICoreWebView2ScreenCaptureStartingEventArgs)
		If Not IsObj($oArgs) Then ExitLoop 1
		$oArgs.AddRef()
		Local $iHRESULT = $oArgs.put_Cancel(True)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		$oArgs.put_Handled(True)
	Until True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_FrameCapture_Invoke

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
	__WebView2_Worker_CleanupView($iView)
	For $i = 0 To $__WEBVIEW2_MAX_FRAMES - 1
		If $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_ACTIVE] And $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_OWNER] = $iView Then
			Local $oFrame = $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_OBJECT]
			Local $oFrame2 = $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_OBJECT2]
			Local $oFrame3 = $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_OBJECT3]
			Local $oFrame6 = $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_OBJECT6]
			Local $oFrame7 = $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_OBJECT7]
			Local $oFrame8 = $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_OBJECT8]
			If IsObj($oFrame2) And $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_MESSAGE_TOKEN] Then $oFrame2.remove_WebMessageReceived($__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_MESSAGE_TOKEN])
			If IsObj($oFrame2) And $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_NAV_START_TOKEN] Then $oFrame2.remove_NavigationStarting($__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_NAV_START_TOKEN])
			If IsObj($oFrame2) And $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_NAV_COMPLETE_TOKEN] Then $oFrame2.remove_NavigationCompleted($__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_NAV_COMPLETE_TOKEN])
			If IsObj($oFrame2) And $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_CONTENT_TOKEN] Then $oFrame2.remove_ContentLoading($__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_CONTENT_TOKEN])
			If IsObj($oFrame2) And $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_DOM_TOKEN] Then $oFrame2.remove_DOMContentLoaded($__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_DOM_TOKEN])
			If IsObj($oFrame3) And $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_PERMISSION_TOKEN] Then $oFrame3.remove_PermissionRequested($__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_PERMISSION_TOKEN])
			If IsObj($oFrame6) And $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_CAPTURE_TOKEN] Then $oFrame6.remove_ScreenCaptureStarting($__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_CAPTURE_TOKEN])
			If IsObj($oFrame7) And $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_CHILD_TOKEN] Then $oFrame7.remove_FrameCreated($__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_CHILD_TOKEN])
			If IsObj($oFrame8) And $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_WORKER_TOKEN] Then $oFrame8.remove_DedicatedWorkerCreated($__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_WORKER_TOKEN])
			If IsObj($oFrame) And $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_DESTROY_TOKEN] Then $oFrame.remove_Destroyed($__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_DESTROY_TOKEN])
			If IsObj($oFrame) And $__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_NAME_TOKEN] Then $oFrame.remove_NameChanged($__g_aWebView2_Frames[$i][$__WEBVIEW2_FRAME_NAME_TOKEN])
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
	$__g_aWebView2_FrameNavStartCallback[$iView] = Null
	$__g_aWebView2_FrameNavCompleteCallback[$iView] = Null
	$__g_aWebView2_FramePermissionCallback[$iView] = Null
	$__g_aWebView2_FrameCaptureCallback[$iView] = Null
	$__g_aWebView2_FrameWorkerCreatedCallback[$iView] = Null
	$__g_aWebView2_FrameNameCallback[$iView] = Null
	$__g_aWebView2_FrameContentCallback[$iView] = Null
	$__g_aWebView2_FrameDOMCallback[$iView] = Null
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
; Name ..........: _WebView2_Frame_GetParentId
; Description ...: Returns the tracked parent frame ID for a native iframe.
; Syntax ........: _WebView2_Frame_GetParentId($iFrame)
; Parameters ....: $iFrame - Tracked UDF frame ID returned by _WebView2_Frame_List().
; Return values .: Parent frame ID, zero for a top-level iframe, or -1 with @error for an invalid frame.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Nested frames are tracked when the runtime provides ICoreWebView2Frame7.
; Related .......: _WebView2_Frame_List
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2frame7
; Example .......: examples/028_NestedFrames.au3
; ===============================================================================================================================
Func _WebView2_Frame_GetParentId($iFrame)
	Local $iResult = -1, $iError = 0
	Local $iSlot = __WebView2_Frame_Find($iFrame)
	If $iSlot < 0 Then
		$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
	Else
		$iResult = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_PARENT_ID]
	EndIf
	Return SetError($iError, 0, $iResult)
EndFunc   ;==>_WebView2_Frame_GetParentId

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Frame_GetNativeId
; Description ...: Reads the runtime's FrameId through ICoreWebView2Frame5.
; Syntax ........: _WebView2_Frame_GetNativeId($iFrame)
; Parameters ....: $iFrame - Tracked UDF frame ID returned by _WebView2_Frame_List().
; Return values .: Native UINT32 FrameId on success; -1 with @error on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The native ID and the UDF's tracked frame ID are different identifiers.
; Related .......: _WebView2_Frame_List
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2frame5#get_frameid
; ===============================================================================================================================
Func _WebView2_Frame_GetNativeId($iFrame)
	Local $iResult = -1, $iError = 0, $iExtended = 0
	Do
		Local $iSlot = __WebView2_Frame_Find($iFrame)
		If $iSlot < 0 Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $oFrame5 = __WebView2_Frame_QueryInterface($__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_POINTER], _
				$WEBVIEW2_IID_ICoreWebView2Frame5, $WEBVIEW2_DTAG_ICoreWebView2Frame5)
		$iError = @error
		$iExtended = @extended
		If $iError Then ExitLoop 1
		Local $iNativeId = 0
		Local $iHRESULT = $oFrame5.get_FrameId($iNativeId)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iHRESULT
			ExitLoop 1
		EndIf
		$iResult = $iNativeId
	Until True
	Return SetError($iError, $iExtended, $iResult)
EndFunc   ;==>_WebView2_Frame_GetNativeId

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
; Name ..........: _WebView2_Frame_PostSharedBuffer
; Description ...: Sends binary data to one frame as a read-only shared ArrayBuffer.
; Syntax ........: _WebView2_Frame_PostSharedBuffer($iFrame, $bData[, $sAdditionalJSON = ""])
; Parameters ....: $iFrame - Tracked frame ID.
;                  $bData - Nonempty AutoIt binary value (less than 2 GB).
;                  $sAdditionalJSON - Optional JSON metadata delivered with the buffer.
; Return values .: True, or False with @error set; @extended contains the native HRESULT.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Script handles sharedbufferreceived and calls chrome.webview.releaseBuffer on the received ArrayBuffer.
; Related .......: _WebView2_Frame_List
; Link ..........: https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2frame4
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Frame_PostSharedBuffer($iFrame, $bData, $sAdditionalJSON = "")
	Local Const $sFuncName = "_WebView2_Frame_PostSharedBuffer"
	Local $sMessage = "Frame shared buffer delivery failed."
	Local $bResult = False, $iError = 0, $iExtended = 0
	Do
		Local $iSlot = __WebView2_Frame_Find($iFrame)
		If $iSlot < 0 Or Not IsBinary($bData) Or Not IsString($sAdditionalJSON) Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $iSize = BinaryLen($bData)
		If $iSize < 1 Or $iSize >= 2147483648 Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $oFrame4 = __WebView2_Frame_QueryInterface($__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_POINTER], _
				$WEBVIEW2_IID_ICoreWebView2Frame4, $WEBVIEW2_DTAG_ICoreWebView2Frame4)
		$iError = @error
		$iExtended = @extended
		If $iError Then ExitLoop 1
		Local $oEnvironment12 = __WebView2_Frame_QueryInterface($__g_pWebView2_Environment, _
				$WEBVIEW2_IID_ICoreWebView2Environment12, $WEBVIEW2_DTAG_ICoreWebView2Environment12)
		$iError = @error
		$iExtended = @extended
		If $iError Then ExitLoop 1
		Local $pBuffer = 0
		Local $iHRESULT = $oEnvironment12.CreateSharedBuffer($iSize, $pBuffer)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Or Not $pBuffer Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iHRESULT
			ExitLoop 1
		EndIf
		Local $oBuffer = ObjCreateInterface($pBuffer, $WEBVIEW2_IID_ICoreWebView2SharedBuffer, $WEBVIEW2_DTAG_ICoreWebView2SharedBuffer)
		If Not IsObj($oBuffer) Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $WEBVIEW2_E_NOINTERFACE
			ExitLoop 1
		EndIf
		Local $pBytes = 0
		$iHRESULT = $oBuffer.get_Buffer($pBytes)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Or Not $pBytes Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iHRESULT
			ExitLoop 1
		EndIf
		Local $tBytes = DllStructCreate("byte[" & $iSize & "]", $pBytes)
		If @error Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		DllStructSetData($tBytes, 1, $bData)
		If @error Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		$iHRESULT = $oFrame4.PostSharedBufferToScript($pBuffer, $WEBVIEW2_SHARED_BUFFER_READ_ONLY, $sAdditionalJSON)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iHRESULT
			ExitLoop 1
		EndIf
		$bResult = True
	Until True
	If $iError Then __WebView2_Error($sFuncName, $iError, $sMessage, $iExtended)
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_Frame_PostSharedBuffer

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

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Frame_AddHostObjectToScriptWithOrigins
; Description ...: Exposes an IDispatch host object to a frame at explicit origins.
; Syntax ........: _WebView2_Frame_AddHostObjectToScriptWithOrigins($iFrame, $sName, $oHost, $aOrigins)
; Parameters ....: $iFrame - Tracked frame ID.
;                  $sName - Script-facing object name.
;                  $oHost - COM IDispatch object.
;                  $aOrigins - Array of allowed origin strings; do not use wildcard for untrusted frames.
; Return values .: True or False with @error set.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_Frame_AddHostObjectToScriptWithOrigins($iFrame, $sName, $oHost, $aOrigins)
	Local Const $sFuncName = "_WebView2_Frame_AddHostObjectToScriptWithOrigins"
	Local $sMessage = "Cannot add the origin-scoped host object to the frame."
	Local $bResult = False, $iError = 0, $iExtended = 0
	Do
		Local $iSlot = __WebView2_Frame_Find($iFrame)
		If $iSlot < 0 Or Not IsObj($oHost) Or Not IsArray($aOrigins) Or Not IsString($sName) Or $sName = "" Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $iCount = UBound($aOrigins)
		If $iCount < 1 Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $aStrings[$iCount]
		Local $tPointers = DllStructCreate("ptr[" & $iCount & "]")
		Local $bOriginsValid = True
		For $i = 0 To $iCount - 1
			If Not IsString($aOrigins[$i]) Or $aOrigins[$i] = "" Or $aOrigins[$i] = "*" Then
				$bOriginsValid = False
				ExitLoop
			EndIf
			$aStrings[$i] = DllStructCreate("wchar[" & (StringLen($aOrigins[$i]) + 1) & "]")
			DllStructSetData($aStrings[$i], 1, $aOrigins[$i])
			DllStructSetData($tPointers, 1, DllStructGetPtr($aStrings[$i]), $i + 1)
		Next
		If Not $bOriginsValid Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $tVariant = DllStructCreate(@AutoItX64 ? "ushort vt;ushort r1;ushort r2;ushort r3;ptr dispatch;int64 pad" : "ushort vt;ushort r1;ushort r2;ushort r3;ptr dispatch;uint pad")
		DllStructSetData($tVariant, "vt", 9)
		DllStructSetData($tVariant, "dispatch", Ptr($oHost))
		Local $oFrame = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT]
		Local $iResult = $oFrame.AddHostObjectToScriptWithOrigins($sName, DllStructGetPtr($tVariant), $iCount, DllStructGetPtr($tPointers))
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop 1
		EndIf
		$bResult = True
	Until True
	If $iError Then __WebView2_Error($sFuncName, $iError, $sMessage, $iExtended)
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_Frame_AddHostObjectToScriptWithOrigins

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Frame_RemoveHostObjectFromScript
; Description ...: Removes a named host object from one frame.
; Syntax ........: _WebView2_Frame_RemoveHostObjectFromScript($iFrame, $sName)
; Parameters ....: $iFrame - Tracked frame ID.
;                  $sName - Script-facing object name.
; Return values .: True or False with @error set.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_Frame_RemoveHostObjectFromScript($iFrame, $sName)
	Local Const $sFuncName = "_WebView2_Frame_RemoveHostObjectFromScript"
	Local $sMessage = "Cannot remove the host object from the frame."
	Local $bResult = False, $iError = 0, $iExtended = 0
	Do
		Local $iSlot = __WebView2_Frame_Find($iFrame)
		If $iSlot < 0 Or Not IsString($sName) Or $sName = "" Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $oFrame = $__g_aWebView2_Frames[$iSlot][$__WEBVIEW2_FRAME_OBJECT]
		Local $iResult = $oFrame.RemoveHostObjectFromScript($sName)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop 1
		EndIf
		$bResult = True
	Until True
	If $iError Then __WebView2_Error($sFuncName, $iError, $sMessage, $iExtended)
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_Frame_RemoveHostObjectFromScript
