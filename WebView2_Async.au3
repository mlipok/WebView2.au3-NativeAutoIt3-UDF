#include-once
#Tidy_ILC_Pos=44

; #INDEX# =======================================================================================================================
; Title .........: WebView2_Async.au3
; Description ...: Optional nonblocking script execution with a callback object per native request.
; Author(s) .....: mLipok
; Version .......: 0.6.0
; ===============================================================================================================================

Global Enum _
		$__WEBVIEW2_ASYNC_USED, _
		$__WEBVIEW2_ASYNC_ID, _
		$__WEBVIEW2_ASYNC_VIEW, _
		$__WEBVIEW2_ASYNC_DONE, _
		$__WEBVIEW2_ASYNC_ABANDONED, _
		$__WEBVIEW2_ASYNC_HRESULT, _
		$__WEBVIEW2_ASYNC_JSON, _
		$__WEBVIEW2_ASYNC_FIELDS

Global $__g_aWebView2_Async[$__WEBVIEW2_ASYNC_REQUEST_CAPACITY][$__WEBVIEW2_ASYNC_FIELDS]
Global $__g_iWebView2_AsyncNextId = 0

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ExecuteScriptAsyncStart
; Description ...: Starts a top-level script request without waiting for its JSON result.
; Syntax ........: _WebView2_ExecuteScriptAsyncStart($iWebView, $sJavaScript)
; Parameters ....: $iWebView - Active WebView2 instance ID.
;                  $sJavaScript - Script to execute in the top-level document.
; Return values .: Positive request ID on success; -1 with @error on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Up to 32 simultaneous requests. Poll or forget each ID; a forgotten pending callback remains alive until completion.
; Related .......: _WebView2_ExecuteScriptAsyncPoll, _WebView2_ExecuteScriptAsyncForget
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2#executescript
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ExecuteScriptAsyncStart($iWebView, $sJavaScript)
	Local $iValue = -1, $iError = 0, $iExtended = 0
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$iError = $WEBVIEW2_ERR_INVALID_INSTANCE
			ExitLoop 1
		EndIf
		If Not IsString($sJavaScript) Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $iSlot = -1
		For $i = 0 To $__WEBVIEW2_ASYNC_REQUEST_CAPACITY - 1
			If Not $__g_aWebView2_Async[$i][$__WEBVIEW2_ASYNC_USED] Then
				$iSlot = $i
				ExitLoop
			EndIf
		Next
		If $iSlot < 0 Then
			$iError = $WEBVIEW2_ERR_BUSY
			ExitLoop 1
		EndIf
		Local $iCallback = $__WEBVIEW2_CB_ASYNC_BASE + $iSlot
		If Not __WebView2_Callback_GetPointer($iCallback) Then
			If Not __WebView2_Callback_Create($iCallback, __WebView2_Async_Completed_Invoke, "ptr;long;wstr") Then
				$iError = $WEBVIEW2_ERR_CALLBACK
				$iExtended = @extended
				ExitLoop 1
			EndIf
		EndIf
		$__g_iWebView2_AsyncNextId += 1
		$__g_aWebView2_Async[$iSlot][$__WEBVIEW2_ASYNC_USED] = True
		$__g_aWebView2_Async[$iSlot][$__WEBVIEW2_ASYNC_ID] = $__g_iWebView2_AsyncNextId
		$__g_aWebView2_Async[$iSlot][$__WEBVIEW2_ASYNC_VIEW] = $iWebView
		$__g_aWebView2_Async[$iSlot][$__WEBVIEW2_ASYNC_DONE] = False
		$__g_aWebView2_Async[$iSlot][$__WEBVIEW2_ASYNC_ABANDONED] = False
		$__g_aWebView2_Async[$iSlot][$__WEBVIEW2_ASYNC_HRESULT] = 0
		$__g_aWebView2_Async[$iSlot][$__WEBVIEW2_ASYNC_JSON] = ""
		Local $oCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE]
		Local $iHRESULT = $oCore.ExecuteScript($sJavaScript, __WebView2_Callback_GetPointer($iCallback))
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
			__WebView2_Async_ClearSlot($iSlot)
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iHRESULT
			ExitLoop 1
		EndIf
		$iValue = $__g_iWebView2_AsyncNextId
	Until True
	If $iError Then __WebView2_Error("_WebView2_ExecuteScriptAsyncStart", $iError, "Unable to start asynchronous script.", $iExtended)
	Return SetError($iError, $iExtended, $iValue)
EndFunc   ;==>_WebView2_ExecuteScriptAsyncStart

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ExecuteScriptAsyncPoll
; Description ...: Checks one request and consumes its result when complete.
; Syntax ........: _WebView2_ExecuteScriptAsyncPoll($iRequest, ByRef $sJSON)
; Parameters ....: $iRequest - Request ID returned by the start call.
;                  $sJSON - Receives the raw JSON result when complete; cleared while pending or on failure.
; Return values .: 0 while pending, 1 on success, -1 with @error on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Call from the ordinary GUI loop. Each completed ID can be consumed only once.
; Related .......: _WebView2_ExecuteScriptAsyncStart, _WebView2_ExecuteScriptAsyncForget
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ExecuteScriptAsyncPoll($iRequest, ByRef $sJSON)
	Local $iValue = -1, $iError = 0, $iExtended = 0
	$sJSON = ""
	Do
		Local $iSlot = __WebView2_Async_FindSlot($iRequest)
		If $iSlot < 0 Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		If Not $__g_aWebView2_Async[$iSlot][$__WEBVIEW2_ASYNC_DONE] Then
			$iValue = 0
			ExitLoop 1
		EndIf
		Local $iHRESULT = $__g_aWebView2_Async[$iSlot][$__WEBVIEW2_ASYNC_HRESULT]
		If $iHRESULT <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iHRESULT
			__WebView2_Async_ClearSlot($iSlot)
			ExitLoop 1
		EndIf
		$sJSON = $__g_aWebView2_Async[$iSlot][$__WEBVIEW2_ASYNC_JSON]
		__WebView2_Async_ClearSlot($iSlot)
		$iValue = 1
	Until True
	If $iError Then __WebView2_Error("_WebView2_ExecuteScriptAsyncPoll", $iError, "Asynchronous script request failed or is invalid.", $iExtended)
	Return SetError($iError, $iExtended, $iValue)
EndFunc   ;==>_WebView2_ExecuteScriptAsyncPoll

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ExecuteScriptAsyncForget
; Description ...: Discards a result or abandons a pending request without freeing its native callback prematurely.
; Syntax ........: _WebView2_ExecuteScriptAsyncForget($iRequest)
; Parameters ....: $iRequest - Active request ID.
; Return values .: True on success; False with @error for an invalid ID.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Native ExecuteScript cannot be cancelled by this function.
; Related .......: _WebView2_ExecuteScriptAsyncStart, _WebView2_ExecuteScriptAsyncPoll
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ExecuteScriptAsyncForget($iRequest)
	Local $bValue = False, $iError = 0
	Do
		Local $iSlot = __WebView2_Async_FindSlot($iRequest)
		If $iSlot < 0 Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		If $__g_aWebView2_Async[$iSlot][$__WEBVIEW2_ASYNC_DONE] Then
			__WebView2_Async_ClearSlot($iSlot)
		Else
			$__g_aWebView2_Async[$iSlot][$__WEBVIEW2_ASYNC_ABANDONED] = True
		EndIf
		$bValue = True
	Until True
	If $iError Then __WebView2_Error("_WebView2_ExecuteScriptAsyncForget", $iError, "Invalid asynchronous script ID.", 0)
	Return SetError($iError, 0, $bValue)
EndFunc   ;==>_WebView2_ExecuteScriptAsyncForget

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Async_Completed_Invoke
; Description ...: Correlates a native completion with its dedicated callback object and request slot.
; Syntax ........: __WebView2_Async_Completed_Invoke($pSelf, $iHRESULT, $sJSON)
; Parameters ....: Native callback pointer, HRESULT and JSON result.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This callback does not call user code or start another WebView2 operation.
; Related .......: _WebView2_ExecuteScriptAsyncStart
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Async_Completed_Invoke($pSelf, $iHRESULT, $sJSON)
	For $i = 0 To $__WEBVIEW2_ASYNC_REQUEST_CAPACITY - 1
		If __WebView2_Callback_GetPointer($__WEBVIEW2_CB_ASYNC_BASE + $i) = $pSelf Then
			If $__g_aWebView2_Async[$i][$__WEBVIEW2_ASYNC_USED] Then
				If $__g_aWebView2_Async[$i][$__WEBVIEW2_ASYNC_ABANDONED] Then
					__WebView2_Async_ClearSlot($i)
				Else
					$__g_aWebView2_Async[$i][$__WEBVIEW2_ASYNC_HRESULT] = $iHRESULT
					$__g_aWebView2_Async[$i][$__WEBVIEW2_ASYNC_JSON] = $sJSON
					$__g_aWebView2_Async[$i][$__WEBVIEW2_ASYNC_DONE] = True
				EndIf
			EndIf
			ExitLoop
		EndIf
	Next
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_Async_Completed_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Async_FindSlot
; Description ...: Looks up an active public request ID.
; Syntax ........: __WebView2_Async_FindSlot($iRequest)
; Parameters ....: $iRequest - Positive request ID.
; Return values .: Slot index or -1.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Abandoned IDs cannot be polled again.
; Related .......: _WebView2_ExecuteScriptAsyncPoll
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Async_FindSlot($iRequest)
	Local $iSlot = -1
	If IsInt($iRequest) And $iRequest > 0 Then
		For $i = 0 To $__WEBVIEW2_ASYNC_REQUEST_CAPACITY - 1
			If $__g_aWebView2_Async[$i][$__WEBVIEW2_ASYNC_USED] And Not $__g_aWebView2_Async[$i][$__WEBVIEW2_ASYNC_ABANDONED] And $__g_aWebView2_Async[$i][$__WEBVIEW2_ASYNC_ID] = $iRequest Then
				$iSlot = $i
				ExitLoop
			EndIf
		Next
	EndIf
	Return $iSlot
EndFunc   ;==>__WebView2_Async_FindSlot

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Async_ClearSlot
; Description ...: Clears one result record after the native callback has completed.
; Syntax ........: __WebView2_Async_ClearSlot($iSlot)
; Parameters ....: $iSlot - Internal request slot.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Callback object storage is retained until global cleanup for safe reuse.
; Related .......: __WebView2_Async_Completed_Invoke
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Async_ClearSlot($iSlot)
	For $i = 0 To $__WEBVIEW2_ASYNC_FIELDS - 1
		$__g_aWebView2_Async[$iSlot][$i] = 0
	Next
	Return
EndFunc   ;==>__WebView2_Async_ClearSlot

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Async_InvalidateView
; Description ...: Abandons pending results owned by a view being destroyed.
; Syntax ........: __WebView2_Async_InvalidateView($iWebView)
; Parameters ....: $iWebView - View slot being destroyed.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Pending callback storage stays alive until its native completion or global cleanup.
; Related .......: _WebView2_Destroy
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Async_InvalidateView($iWebView)
	For $i = 0 To $__WEBVIEW2_ASYNC_REQUEST_CAPACITY - 1
		If $__g_aWebView2_Async[$i][$__WEBVIEW2_ASYNC_USED] And $__g_aWebView2_Async[$i][$__WEBVIEW2_ASYNC_VIEW] = $iWebView Then
			If $__g_aWebView2_Async[$i][$__WEBVIEW2_ASYNC_DONE] Then
				__WebView2_Async_ClearSlot($i)
			Else
				$__g_aWebView2_Async[$i][$__WEBVIEW2_ASYNC_ABANDONED] = True
			EndIf
		EndIf
	Next
	Return
EndFunc   ;==>__WebView2_Async_InvalidateView

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Async_Cleanup
; Description ...: Clears the request registry during global UDF cleanup.
; Syntax ........: __WebView2_Async_Cleanup()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Called after view disposal and before native callback-object disposal.
; Related .......: _WebView2_Cleanup
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Async_Cleanup()
	For $i = 0 To $__WEBVIEW2_ASYNC_REQUEST_CAPACITY - 1
		__WebView2_Async_ClearSlot($i)
	Next
	Return
EndFunc   ;==>__WebView2_Async_Cleanup
