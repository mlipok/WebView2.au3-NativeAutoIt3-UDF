#include-once
#Tidy_ILC_Pos=44

; #INDEX# =======================================================================================================================
; Title .........: WebView2_Worker.au3
; Description ...: Tracked page-, iframe- and worker-owned dedicated workers, JSON messages and lifetime callbacks.
; Author(s) .....: mLipok
; Version .......: 0.6.0
; ===============================================================================================================================

Global Const $__WEBVIEW2_MAX_WORKERS = 256
Global Enum _
		$__WEBVIEW2_WORKER_ID, _
		$__WEBVIEW2_WORKER_OWNER, _
		$__WEBVIEW2_WORKER_FRAME_ID, _
		$__WEBVIEW2_WORKER_PARENT_ID, _
		$__WEBVIEW2_WORKER_POINTER, _
		$__WEBVIEW2_WORKER_OBJECT, _
		$__WEBVIEW2_WORKER_URI, _
		$__WEBVIEW2_WORKER_MESSAGE_TOKEN, _
		$__WEBVIEW2_WORKER_DESTROY_TOKEN, _
		$__WEBVIEW2_WORKER_CHILD_TOKEN, _
		$__WEBVIEW2_WORKER_ACTIVE, _
		$__WEBVIEW2_WORKER_FIELDS
Global $__g_aWebView2_Workers[$__WEBVIEW2_MAX_WORKERS][$__WEBVIEW2_WORKER_FIELDS]
Global $__g_iWebView2_NextWorkerId = 1
Global $__g_aWebView2_WorkerCreatedCallback[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_WorkerMessageCallback[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_WorkerDestroyingCallback[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_CoreWorker29[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_CoreWorkerToken[$WEBVIEW2_MAX_INSTANCES]

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Worker_PrepareCallbacks
; Description ...: Creates native worker message, destruction and creation handlers when first needed.
; Syntax ........: __WebView2_Worker_PrepareCallbacks()
; Parameters ....: None.
; Return values .: True when ready, False when a callback object cannot be created.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The common callback factory releases these objects during global cleanup.
; Related .......: __WebView2_Worker_Register
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Worker_PrepareCallbacks()
	Local $bResult = False
	Do
		If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_WORKER_WEB_MESSAGE_RECEIVED) Then
			If Not __WebView2_Callback_Create($__WEBVIEW2_CB_WORKER_WEB_MESSAGE_RECEIVED, __WebView2_WorkerMessage_Invoke, "ptr;ptr;ptr") Then ExitLoop 1
		EndIf
		If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_WORKER_DESTROYING) Then
			If Not __WebView2_Callback_Create($__WEBVIEW2_CB_WORKER_DESTROYING, __WebView2_WorkerDestroying_Invoke, "ptr;ptr;ptr") Then ExitLoop 1
		EndIf
		If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_CORE_DEDICATED_WORKER_CREATED) Then
			If Not __WebView2_Callback_Create($__WEBVIEW2_CB_CORE_DEDICATED_WORKER_CREATED, __WebView2_CoreWorkerCreated_Invoke, "ptr;ptr;ptr") Then ExitLoop 1
		EndIf
		If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_WORKER_CHILD_CREATED) Then
			If Not __WebView2_Callback_Create($__WEBVIEW2_CB_WORKER_CHILD_CREATED, __WebView2_WorkerChildCreated_Invoke, "ptr;ptr;ptr") Then ExitLoop 1
		EndIf
		$bResult = True
	Until True
	Return $bResult
EndFunc   ;==>__WebView2_Worker_PrepareCallbacks

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Worker_SubscribeTopLevel
; Description ...: Subscribes the main document to dedicated-worker creation when CoreWebView2_29 is available.
; Syntax ........: __WebView2_Worker_SubscribeTopLevel($iWebView)
; Parameters ....: $iWebView - WebView2 instance ID.
; Return values .: True when subscribed; False when the interface or subscription is unavailable.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The 48 reserved slots are the methods added by ICoreWebView2_9 through _28 in WebView2.idl.
; Related .......: __WebView2_CoreWorkerCreated_Invoke
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_29
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Worker_SubscribeTopLevel($iWebView)
	Local $bResult = False
	Do
		If $__g_aWebView2_CoreWorkerToken[$iWebView] Then
			$bResult = True
			ExitLoop 1
		EndIf
		Local $sTag = $WEBVIEW2_DTAG_ICoreWebView2_8
		For $i = 1 To 48
			$sTag &= "ReservedWorker" & $i & " hresult();"
		Next
		$sTag &= "add_DedicatedWorkerCreated hresult(ptr;struct*);remove_DedicatedWorkerCreated hresult(int64);"
		Local $pCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE_POINTER]
		Local $oCore29 = __WebView2_Frame_QueryInterface($pCore, $WEBVIEW2_IID_ICoreWebView2_29, $sTag)
		If @error Then ExitLoop 1
		Local $tToken = DllStructCreate("int64")
		Local $iHRESULT = $oCore29.add_DedicatedWorkerCreated(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_CORE_DEDICATED_WORKER_CREATED), $tToken)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		$__g_aWebView2_CoreWorker29[$iWebView] = $oCore29
		$__g_aWebView2_CoreWorkerToken[$iWebView] = DllStructGetData($tToken, 1)
		$bResult = True
	Until True
	Return $bResult
EndFunc   ;==>__WebView2_Worker_SubscribeTopLevel

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Worker_RegisterFromArgs
; Description ...: Reads a native worker-created event and registers its worker.
; Syntax ........: __WebView2_Worker_RegisterFromArgs($iWebView, $iFrame, $iParentWorker, $pArgs)
; Parameters ....: $iWebView - Owning WebView2 instance.
;                  $iFrame - Owning tracked iframe ID, or zero for the main document.
;                  $iParentWorker - Parent worker ID, or zero for a document-owned worker.
;                  $pArgs - Native event-argument pointer.
; Return values .: Registered worker ID, or zero on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The native get_Worker output reference is owned by its AutoIt COM wrapper.
; Related .......: __WebView2_Worker_Register
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2dedicatedworkercreatedeventargs
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Worker_RegisterFromArgs($iWebView, $iFrame, $iParentWorker, $pArgs)
	Local $iWorker = 0
	Do
		If Not $pArgs Then ExitLoop 1
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
		$iWorker = __WebView2_Worker_Register($iWebView, $iFrame, $pWorker, $oWorker, $sScriptURI, $iParentWorker)
	Until True
	Return $iWorker
EndFunc   ;==>__WebView2_Worker_RegisterFromArgs

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_CoreWorkerCreated_Invoke
; Description ...: Tracks a worker created by the main document.
; Syntax ........: __WebView2_CoreWorkerCreated_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: Native callback pointers.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......: A zero frame ID denotes the main document in the existing worker callbacks.
; Related .......: __WebView2_Worker_SubscribeTopLevel
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_29
; Example .......: No
; ===============================================================================================================================
Func __WebView2_CoreWorkerCreated_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Local $iView = __WebView2_Instance_FindByCorePointer($pSender)
	If $iView >= 0 And __WebView2_Worker_HasCallback($iView) Then __WebView2_Worker_RegisterFromArgs($iView, 0, 0, $pArgs)
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_CoreWorkerCreated_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_WorkerChildCreated_Invoke
; Description ...: Tracks a worker created by an already tracked worker.
; Syntax ........: __WebView2_WorkerChildCreated_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: Native callback pointers.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......: A child inherits its original document's frame ID and records its immediate parent worker ID.
; Related .......: _WebView2_Worker_GetParentId
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2dedicatedworker
; Example .......: No
; ===============================================================================================================================
Func __WebView2_WorkerChildCreated_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Local $iSlot = __WebView2_Worker_Find($pSender, True)
	If $iSlot >= 0 Then
		__WebView2_Worker_RegisterFromArgs($__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_OWNER], _
				$__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_FRAME_ID], _
				$__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_ID], $pArgs)
	EndIf
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_WorkerChildCreated_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Worker_SetCallback
; Description ...: Stores a user callback for one worker event.
; Syntax ........: __WebView2_Worker_SetCallback($iWebView, $iEvent, $fnCallback)
; Parameters ....: $iWebView - WebView2 instance ID.
;                  $iEvent - Worker event constant.
;                  $fnCallback - AutoIt function reference.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The public callback setter validates the instance and function.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Worker_SetCallback($iWebView, $iEvent, $fnCallback)
	Switch $iEvent
		Case $WEBVIEW2_EVENT_WORKER_CREATED
			$__g_aWebView2_WorkerCreatedCallback[$iWebView] = $fnCallback
		Case $WEBVIEW2_EVENT_WORKER_WEB_MESSAGE_RECEIVED
			$__g_aWebView2_WorkerMessageCallback[$iWebView] = $fnCallback
		Case $WEBVIEW2_EVENT_WORKER_DESTROYING
			$__g_aWebView2_WorkerDestroyingCallback[$iWebView] = $fnCallback
	EndSwitch
	Return
EndFunc   ;==>__WebView2_Worker_SetCallback

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Worker_HasCallback
; Description ...: Checks whether a view requested tracked worker objects.
; Syntax ........: __WebView2_Worker_HasCallback($iWebView)
; Parameters ....: $iWebView - WebView2 instance ID.
; Return values .: True when any worker callback is registered, otherwise False.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: __WebView2_Frame_SubscribeWorkerCreated
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Worker_HasCallback($iWebView)
	Local $bResult = IsFunc($__g_aWebView2_WorkerCreatedCallback[$iWebView]) Or _
			IsFunc($__g_aWebView2_WorkerMessageCallback[$iWebView]) Or IsFunc($__g_aWebView2_WorkerDestroyingCallback[$iWebView])
	Return $bResult
EndFunc   ;==>__WebView2_Worker_HasCallback

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Worker_Find
; Description ...: Finds an active worker by public ID or native interface pointer.
; Syntax ........: __WebView2_Worker_Find($iValue[, $bPointer = False])
; Parameters ....: $iValue - Worker ID or native pointer.
;                  $bPointer - True to match the native pointer.
; Return values .: Registry slot, or -1 when absent.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: __WebView2_Worker_Register
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Worker_Find($iValue, $bPointer = False)
	Local $iSlot = -1
	For $i = 0 To $__WEBVIEW2_MAX_WORKERS - 1
		If Not $__g_aWebView2_Workers[$i][$__WEBVIEW2_WORKER_ACTIVE] Then ContinueLoop
		If $bPointer Then
			If $__g_aWebView2_Workers[$i][$__WEBVIEW2_WORKER_POINTER] <> $iValue Then ContinueLoop
		Else
			If $__g_aWebView2_Workers[$i][$__WEBVIEW2_WORKER_ID] <> $iValue Then ContinueLoop
		EndIf
		$iSlot = $i
		ExitLoop
	Next
	Return $iSlot
EndFunc   ;==>__WebView2_Worker_Find

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Worker_Register
; Description ...: Retains one worker and subscribes to messages and destruction.
; Syntax ........: __WebView2_Worker_Register($iWebView, $iFrame, $pWorker, $oWorker, $sScriptURI[, $iParentWorker = 0])
; Parameters ....: $iWebView - Owner WebView2 instance.
;                  $iFrame - Owner iframe ID.
;                  $pWorker - Native worker interface pointer.
;                  $oWorker - Worker COM wrapper.
;                  $sScriptURI - Fully qualified worker script address.
;                  $iParentWorker - Immediate parent worker ID, or zero for a document-owned worker.
; Return values .: Positive worker ID on success, or zero on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Worker IDs are monotonic; capacity is bounded to 256 simultaneously active workers.
; Related .......: __WebView2_FrameWorkerCreated_Invoke
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2dedicatedworker
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Worker_Register($iWebView, $iFrame, $pWorker, $oWorker, $sScriptURI, $iParentWorker = 0)
	Local $iWorker = 0
	Do
		If Not $pWorker Or Not IsObj($oWorker) Then ExitLoop 1
		Local $iSlot = __WebView2_Worker_Find($pWorker, True)
		If $iSlot >= 0 Then
			$iWorker = $__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_ID]
			ExitLoop 1
		EndIf
		For $i = 0 To $__WEBVIEW2_MAX_WORKERS - 1
			If Not $__g_aWebView2_Workers[$i][$__WEBVIEW2_WORKER_ACTIVE] Then
				$iSlot = $i
				ExitLoop
			EndIf
		Next
		If $iSlot < 0 Then ExitLoop 1
		Local $tDestroy = DllStructCreate("int64")
		Local $iHRESULT = $oWorker.add_Destroying(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_WORKER_DESTROYING), $tDestroy)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		Local $iDestroyToken = DllStructGetData($tDestroy, 1)
		Local $tMessage = DllStructCreate("int64")
		$iHRESULT = $oWorker.add_WebMessageReceived(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_WORKER_WEB_MESSAGE_RECEIVED), $tMessage)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
			$oWorker.remove_Destroying($iDestroyToken)
			ExitLoop 1
		EndIf
		$iWorker = $__g_iWebView2_NextWorkerId
		$__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_ID] = $iWorker
		$__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_OWNER] = $iWebView
		$__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_FRAME_ID] = $iFrame
		$__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_PARENT_ID] = $iParentWorker
		$__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_POINTER] = $pWorker
		$__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_OBJECT] = $oWorker
		$__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_URI] = $sScriptURI
		$__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_MESSAGE_TOKEN] = DllStructGetData($tMessage, 1)
		$__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_DESTROY_TOKEN] = $iDestroyToken
		$__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_ACTIVE] = True
		$__g_iWebView2_NextWorkerId += 1
		Local $tChild = DllStructCreate("int64")
		$iHRESULT = $oWorker.add_DedicatedWorkerCreated(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_WORKER_CHILD_CREATED), $tChild)
		If Not @error And $iHRESULT = $WEBVIEW2_S_OK Then $__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_CHILD_TOKEN] = DllStructGetData($tChild, 1)
		Local $fnCallback = $__g_aWebView2_WorkerCreatedCallback[$iWebView]
		If IsFunc($fnCallback) Then Call($fnCallback, $iWebView, $iFrame, $iWorker, $sScriptURI)
	Until True
	Return $iWorker
EndFunc   ;==>__WebView2_Worker_Register

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Worker_Release
; Description ...: Invalidates one worker ID and removes its native subscriptions.
; Syntax ........: __WebView2_Worker_Release($iSlot)
; Parameters ....: $iSlot - Active worker registry slot.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Does not call the user Destroying callback for host-initiated cleanup.
; Related .......: __WebView2_WorkerDestroying_Invoke
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Worker_Release($iSlot)
	Do
		If $iSlot < 0 Or $iSlot >= $__WEBVIEW2_MAX_WORKERS Then ExitLoop 1
		If Not $__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_ACTIVE] Then ExitLoop 1
		$__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_ACTIVE] = False
		Local $iWorker = $__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_ID]
		For $i = 0 To $__WEBVIEW2_MAX_WORKERS - 1
			If $__g_aWebView2_Workers[$i][$__WEBVIEW2_WORKER_ACTIVE] And $__g_aWebView2_Workers[$i][$__WEBVIEW2_WORKER_PARENT_ID] = $iWorker Then __WebView2_Worker_Release($i)
		Next
		Local $oWorker = $__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_OBJECT]
		If IsObj($oWorker) Then
			If $__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_CHILD_TOKEN] Then $oWorker.remove_DedicatedWorkerCreated($__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_CHILD_TOKEN])
			If $__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_MESSAGE_TOKEN] Then $oWorker.remove_WebMessageReceived($__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_MESSAGE_TOKEN])
			If $__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_DESTROY_TOKEN] Then $oWorker.remove_Destroying($__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_DESTROY_TOKEN])
		EndIf
		For $i = 0 To $__WEBVIEW2_WORKER_FIELDS - 1
			$__g_aWebView2_Workers[$iSlot][$i] = Null
		Next
	Until True
	Return
EndFunc   ;==>__WebView2_Worker_Release

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_WorkerMessage_Invoke
; Description ...: Forwards a worker's JSON web message to AutoIt.
; Syntax ........: __WebView2_WorkerMessage_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: Native callback pointers.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......: User callbacks must avoid blocking WebView2 operations.
; Related .......: _WebView2_Worker_PostWebMessageAsJson
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_WorkerMessage_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Do
		Local $iSlot = __WebView2_Worker_Find($pSender, True)
		If $iSlot < 0 Or Not $pArgs Then ExitLoop 1
		Local $iView = $__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_OWNER]
		Local $fnCallback = $__g_aWebView2_WorkerMessageCallback[$iView]
		If Not IsFunc($fnCallback) Then ExitLoop 1
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2WebMessageReceivedEventArgs, $WEBVIEW2_DTAG_ICoreWebView2WebMessageReceivedEventArgs)
		If Not IsObj($oArgs) Then ExitLoop 1
		$oArgs.AddRef()
		Local $pMessage = 0, $pSource = 0
		Local $iHRESULT = $oArgs.get_Source($pSource)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		Local $sSource = __WebView2_CoTaskMemString_ReadAndFree($pSource)
		$iHRESULT = $oArgs.get_WebMessageAsJson($pMessage)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		Local $sJSON = __WebView2_CoTaskMemString_ReadAndFree($pMessage)
		Call($fnCallback, $iView, $__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_FRAME_ID], _
				$__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_ID], $sJSON, $sSource)
	Until True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_WorkerMessage_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_WorkerDestroying_Invoke
; Description ...: Invalidates a terminating worker and reports its former identity.
; Syntax ........: __WebView2_WorkerDestroying_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: Native callback pointers.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The ID is invalid when the user callback runs.
; Related .......: __WebView2_Worker_Release
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_WorkerDestroying_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf, $pArgs
	Local $iSlot = __WebView2_Worker_Find($pSender, True)
	If $iSlot >= 0 Then
		Local $iView = $__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_OWNER]
		Local $iFrame = $__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_FRAME_ID]
		Local $iWorker = $__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_ID]
		Local $sScriptURI = $__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_URI]
		Local $fnCallback = $__g_aWebView2_WorkerDestroyingCallback[$iView]
		__WebView2_Worker_Release($iSlot)
		If IsFunc($fnCallback) Then Call($fnCallback, $iView, $iFrame, $iWorker, $sScriptURI)
	EndIf
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_WorkerDestroying_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Worker_CleanupFrame
; Description ...: Releases workers associated with one tracked frame.
; Syntax ........: __WebView2_Worker_CleanupFrame($iFrame)
; Parameters ....: $iFrame - Tracked frame ID.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: __WebView2_Worker_CleanupView
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Worker_CleanupFrame($iFrame)
	For $i = 0 To $__WEBVIEW2_MAX_WORKERS - 1
		If $__g_aWebView2_Workers[$i][$__WEBVIEW2_WORKER_ACTIVE] And $__g_aWebView2_Workers[$i][$__WEBVIEW2_WORKER_FRAME_ID] = $iFrame Then __WebView2_Worker_Release($i)
	Next
	Return
EndFunc   ;==>__WebView2_Worker_CleanupFrame

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Worker_CleanupView
; Description ...: Releases all worker handles and callbacks owned by one WebView2 instance.
; Syntax ........: __WebView2_Worker_CleanupView($iWebView)
; Parameters ....: $iWebView - WebView2 instance ID.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: __WebView2_Frame_Cleanup
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Worker_CleanupView($iWebView)
	Local $oCore29 = $__g_aWebView2_CoreWorker29[$iWebView]
	If IsObj($oCore29) And $__g_aWebView2_CoreWorkerToken[$iWebView] Then $oCore29.remove_DedicatedWorkerCreated($__g_aWebView2_CoreWorkerToken[$iWebView])
	$__g_aWebView2_CoreWorkerToken[$iWebView] = 0
	$__g_aWebView2_CoreWorker29[$iWebView] = Null
	For $i = 0 To $__WEBVIEW2_MAX_WORKERS - 1
		If $__g_aWebView2_Workers[$i][$__WEBVIEW2_WORKER_ACTIVE] And $__g_aWebView2_Workers[$i][$__WEBVIEW2_WORKER_OWNER] = $iWebView Then __WebView2_Worker_Release($i)
	Next
	$__g_aWebView2_WorkerCreatedCallback[$iWebView] = Null
	$__g_aWebView2_WorkerMessageCallback[$iWebView] = Null
	$__g_aWebView2_WorkerDestroyingCallback[$iWebView] = Null
	Return
EndFunc   ;==>__WebView2_Worker_CleanupView

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Worker_List
; Description ...: Lists active workers tracked for one WebView2 instance.
; Syntax ........: _WebView2_Worker_List($iWebView)
; Parameters ....: $iWebView - WebView2 instance ID.
; Return values .: On Success - Array of active worker IDs, possibly empty.
;                  On Failure - Empty array and sets @error to $WEBVIEW2_ERR_INVALID_INSTANCE.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Register a worker callback before worker creation. IDs become invalid on worker destruction.
; Related .......: _WebView2_Worker_PostWebMessageAsJson
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Worker_List($iWebView)
	Local Const $sFuncName = "_WebView2_Worker_List"
	Local $sMessage = "Invalid WebView2 instance."
	Local $aResult[0], $iError = 0
	If Not __WebView2_Instance_IsValid($iWebView) Then
		$iError = $WEBVIEW2_ERR_INVALID_INSTANCE
	Else
		For $i = 0 To $__WEBVIEW2_MAX_WORKERS - 1
			If $__g_aWebView2_Workers[$i][$__WEBVIEW2_WORKER_ACTIVE] And $__g_aWebView2_Workers[$i][$__WEBVIEW2_WORKER_OWNER] = $iWebView Then
				ReDim $aResult[UBound($aResult) + 1]
				$aResult[UBound($aResult) - 1] = $__g_aWebView2_Workers[$i][$__WEBVIEW2_WORKER_ID]
			EndIf
		Next
	EndIf
	If $iError Then __WebView2_Error($sFuncName, $iError, $sMessage, 0)
	Return SetError($iError, 0, $aResult)
EndFunc   ;==>_WebView2_Worker_List

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Worker_GetParentId
; Description ...: Returns the immediate parent worker of an active dedicated worker.
; Syntax ........: _WebView2_Worker_GetParentId($iWorker)
; Parameters ....: $iWorker - Active tracked worker ID.
; Return values .: On Success - Parent worker ID, or zero when a document created the worker.
;                  On Failure - Zero and sets @error to $WEBVIEW2_ERR_INVALID_PARAMETER.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The existing worker callbacks carry the original frame ID; zero means the main document.
; Related .......: _WebView2_Worker_List
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2dedicatedworker
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Worker_GetParentId($iWorker)
	Local Const $sFuncName = "_WebView2_Worker_GetParentId"
	Local $sMessage = "Invalid or stale worker ID."
	Local $iParent = 0, $iError = 0
	Local $iSlot = __WebView2_Worker_Find($iWorker)
	If $iSlot < 0 Then
		$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
		__WebView2_Error($sFuncName, $iError, $sMessage, 0)
	Else
		$iParent = $__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_PARENT_ID]
	EndIf
	Return SetError($iError, 0, $iParent)
EndFunc   ;==>_WebView2_Worker_GetParentId

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Worker_PostWebMessageAsJson
; Description ...: Sends JSON from AutoIt to one active dedicated worker.
; Syntax ........: _WebView2_Worker_PostWebMessageAsJson($iWorker, $sJSON)
; Parameters ....: $iWorker - Active tracked worker ID.
;                  $sJSON - Valid JSON text.
; Return values .: On Success - True when WebView2 accepts the asynchronous send.
;                  On Failure - False and sets @error to one of the following:
;                    $WEBVIEW2_ERR_INVALID_PARAMETER = Invalid or stale worker ID, or empty JSON.
;                    $WEBVIEW2_ERR_HRESULT = Native send failed; @extended contains the HRESULT.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Acceptance does not guarantee delivery. The worker must listen to self.chrome.webview message events.
; Related .......: _WebView2_Worker_List
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2dedicatedworker
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Worker_PostWebMessageAsJson($iWorker, $sJSON)
	Local Const $sFuncName = "_WebView2_Worker_PostWebMessageAsJson"
	Local $sMessage = "Cannot post JSON to the dedicated worker."
	Local $bResult = False, $iError = 0, $iExtended = 0
	Do
		Local $iSlot = __WebView2_Worker_Find($iWorker)
		If $iSlot < 0 Or Not IsString($sJSON) Or StringStripWS($sJSON, 8) = "" Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $oWorker = $__g_aWebView2_Workers[$iSlot][$__WEBVIEW2_WORKER_OBJECT]
		If Not IsObj($oWorker) Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $WEBVIEW2_E_NOINTERFACE
			ExitLoop 1
		EndIf
		Local $iHRESULT = $oWorker.PostWebMessageAsJson($sJSON)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iHRESULT
			ExitLoop 1
		EndIf
		$bResult = True
	Until True
	If $iError Then __WebView2_Error($sFuncName, $iError, $sMessage, $iExtended)
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_Worker_PostWebMessageAsJson
