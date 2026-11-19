#include-once
#Tidy_ILC_Pos=44

; Native WebView2 process diagnostics.

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetFailureReportFolderPath
; Description ...: Reads the Runtime's failure-report directory.
; Syntax ........: _WebView2_GetFailureReportFolderPath()
; Parameters ....: None.
; Return values .: On Success - Directory path.
;                  On Failure - Empty string. @error is NOT_INITIALIZED, DLLCALL or HRESULT.
;                  @extended contains the native HRESULT when available.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Requires ICoreWebView2Environment11. The path may contain older reports or no report for a given event.
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetFailureReportFolderPath()
	If Not $__g_pWebView2_Environment Then Return SetError($WEBVIEW2_ERR_NOT_INITIALIZED, 0, "")
	Local $oEnv = __WebView2_Frame_QueryInterface($__g_pWebView2_Environment, $WEBVIEW2_IID_ICoreWebView2Environment11, $WEBVIEW2_DTAG_ICoreWebView2Environment11)
	If @error Then Return SetError(@error, @extended, "")
	Local $pPath = 0
	Local $iResult = $oEnv.get_FailureReportFolderPath($pPath)
	If @error Or $iResult <> $WEBVIEW2_S_OK Then Return SetError($WEBVIEW2_ERR_HRESULT, $iResult, "")
	Local $sPath = __WebView2_CoTaskMemString_ReadAndFree($pPath)
	Return SetError(0, 0, $sPath)
EndFunc   ;==>_WebView2_GetFailureReportFolderPath

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_ProcessFailed_Subscribe
; Description ...: Registers an optional per-view native failure callback.
; Syntax ........: __WebView2_ProcessFailed_Subscribe($iView, $fnCallback)
; Parameters ....: $iView - Valid instance ID.
;                  $fnCallback - AutoIt function reference.
; Return values .: True on success. False sets CALLBACK or HRESULT in @error.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func __WebView2_ProcessFailed_Subscribe($iView, $fnCallback)
	If Not $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_PROCESS_FAILED_TOKEN] Then
		If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_PROCESS_FAILED) Then
			If Not __WebView2_Callback_Create($__WEBVIEW2_CB_PROCESS_FAILED, __WebView2_ProcessFailed_Invoke, "ptr;ptr;ptr") Then Return SetError($WEBVIEW2_ERR_CALLBACK, 0, False)
		EndIf
		Local $oCore = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_CORE]
		Local $tToken = DllStructCreate("int64")
		Local $iResult = $oCore.add_ProcessFailed(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_PROCESS_FAILED), $tToken)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then Return SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)
		$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_PROCESS_FAILED_TOKEN] = DllStructGetData($tToken, 1)
	EndIf
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_PROCESS_FAILED_CALLBACK] = $fnCallback
	Return SetError(0, 0, True)
EndFunc   ;==>__WebView2_ProcessFailed_Subscribe

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_ProcessFailed_Unsubscribe
; Description ...: Detaches the native failure callback before closing a view.
; Syntax ........: __WebView2_ProcessFailed_Unsubscribe($iView)
; Parameters ....: $iView - Instance slot.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func __WebView2_ProcessFailed_Unsubscribe($iView)
	Local $iToken = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_PROCESS_FAILED_TOKEN]
	Local $oCore = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_CORE]
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_PROCESS_FAILED_CALLBACK] = Null
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_PROCESS_FAILED_TOKEN] = 0
	If $iToken And IsObj($oCore) Then $oCore.remove_ProcessFailed($iToken)
EndFunc   ;==>__WebView2_ProcessFailed_Unsubscribe

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_ProcessFailed_Invoke
; Description ...: Copies native failure data and calls the application.
; Syntax ........: __WebView2_ProcessFailed_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: $pSelf - COM callback pointer.
;                  $pSender - Core WebView2 pointer.
;                  $pArgs - Borrowed event arguments pointer.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Missing optional fields are Null. Callback return values do not affect Runtime behavior.
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func __WebView2_ProcessFailed_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Local $iView = __WebView2_Instance_FindByCorePointer($pSender)
	If $iView < 0 Or Not $pArgs Then Return $WEBVIEW2_S_OK
	Local $fnCallback = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_PROCESS_FAILED_CALLBACK]
	If Not IsFunc($fnCallback) Then Return $WEBVIEW2_S_OK
	Local $oArgs = __WebView2_Frame_QueryInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2ProcessFailedEventArgs, $WEBVIEW2_DTAG_ICoreWebView2ProcessFailedEventArgs)
	If @error Then Return $WEBVIEW2_S_OK
	Local $iKind = 0
	Local $iResult = $oArgs.get_ProcessFailedKind($iKind)
	If @error Or $iResult <> $WEBVIEW2_S_OK Then Return $WEBVIEW2_S_OK
	Local $vReason = Null, $vExitCode = Null, $vDescription = Null
	Local $oDetails = __WebView2_Frame_QueryInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2ProcessFailedEventArgs2, $WEBVIEW2_DTAG_ICoreWebView2ProcessFailedEventArgs2)
	If IsObj($oDetails) Then
		Local $iReason = 0, $iExitCode = 0, $pDescription = 0
		$iResult = $oDetails.get_Reason($iReason)
		If Not @error And $iResult = $WEBVIEW2_S_OK Then $vReason = $iReason
		$iResult = $oDetails.get_ExitCode($iExitCode)
		If Not @error And $iResult = $WEBVIEW2_S_OK Then $vExitCode = $iExitCode
		$iResult = $oDetails.get_ProcessDescription($pDescription)
		If Not @error And $iResult = $WEBVIEW2_S_OK Then $vDescription = __WebView2_CoTaskMemString_ReadAndFree($pDescription)
	EndIf
	$oDetails = Null
	$oArgs = Null
	Call($fnCallback, $iView, $iKind, $vReason, $vExitCode, $vDescription)
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_ProcessFailed_Invoke
