#include-once
#Tidy_ILC_Pos=44

; #INDEX# =======================================================================================================================
; Title .........: WebView2_ScriptDialog.au3
; Description ...: Native JavaScript dialog callbacks and deferred responses for WebView2.au3.
; Author(s) .....: mLipok
; Version .......: 0.6.0
; ===============================================================================================================================

Global Const $__WEBVIEW2_MAX_SCRIPT_DIALOGS = 32
Global Enum _
		$__WEBVIEW2_DIALOG_ID, _
		$__WEBVIEW2_DIALOG_VIEW, _
		$__WEBVIEW2_DIALOG_URI, _
		$__WEBVIEW2_DIALOG_KIND, _
		$__WEBVIEW2_DIALOG_MESSAGE, _
		$__WEBVIEW2_DIALOG_DEFAULT_TEXT, _
		$__WEBVIEW2_DIALOG_ARGS, _
		$__WEBVIEW2_DIALOG_DEFERRAL, _
		$__WEBVIEW2_DIALOG_STARTED, _
		$__WEBVIEW2_DIALOG_FIELDS

Global $__g_aWebView2_ScriptDialogs[$__WEBVIEW2_MAX_SCRIPT_DIALOGS][$__WEBVIEW2_DIALOG_FIELDS]
Global $__g_iWebView2_NextScriptDialogId = 1

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_ScriptDialog_Find
; Description ...: Finds a pending script dialog by public ID.
; Syntax ........: __WebView2_ScriptDialog_Find($iRequest)
; Parameters ....: $iRequest - Pending request ID.
; Return values .: Registry slot, or -1 when no request matches.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_ScriptDialog_Request_List
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ScriptDialog_Find($iRequest)
	Local $iSlot = -1
	If IsInt($iRequest) And $iRequest > 0 Then
		For $i = 0 To $__WEBVIEW2_MAX_SCRIPT_DIALOGS - 1
			If $__g_aWebView2_ScriptDialogs[$i][$__WEBVIEW2_DIALOG_ID] = $iRequest Then
				$iSlot = $i
				ExitLoop
			EndIf
		Next
	EndIf
	Return $iSlot
EndFunc   ;==>__WebView2_ScriptDialog_Find

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_ScriptDialog_Defer
; Description ...: Retains a native dialog until the AutoIt event loop answers it.
; Syntax ........: __WebView2_ScriptDialog_Defer($iView, $oArgs, $sURI, $iKind, $sMessage, $sDefaultText)
; Parameters ....: $iView - Owning WebView2 instance.
;                  $oArgs - Retained native event arguments.
;                  $sURI - Requesting page URI.
;                  $iKind - Script dialog kind.
;                  $sMessage - Message shown by the page.
;                  $sDefaultText - Prompt default text.
; Return values .: Positive request ID, or 0 when the registry or deferral is unavailable.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The native callback must return promptly after this call.
; Related .......: _WebView2_ScriptDialog_Request_Respond
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2scriptdialogopeningeventargs
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ScriptDialog_Defer($iView, $oArgs, $sURI, $iKind, $sMessage, $sDefaultText)
	Local $iRequest = 0
	Do
		Local $iSlot = -1
		For $i = 0 To $__WEBVIEW2_MAX_SCRIPT_DIALOGS - 1
			If Not $__g_aWebView2_ScriptDialogs[$i][$__WEBVIEW2_DIALOG_ID] Then
				$iSlot = $i
				ExitLoop
			EndIf
		Next
		If $iSlot < 0 Then ExitLoop 1
		Local $pDeferral = 0
		Local $iHRESULT = $oArgs.GetDeferral($pDeferral)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Or Not $pDeferral Then ExitLoop 1
		Local $oDeferral = ObjCreateInterface($pDeferral, $WEBVIEW2_IID_ICoreWebView2Deferral, $WEBVIEW2_DTAG_ICoreWebView2Deferral)
		If Not IsObj($oDeferral) Then ExitLoop 1
		$iRequest = $__g_iWebView2_NextScriptDialogId
		$__g_iWebView2_NextScriptDialogId += 1
		$__g_aWebView2_ScriptDialogs[$iSlot][$__WEBVIEW2_DIALOG_ID] = $iRequest
		$__g_aWebView2_ScriptDialogs[$iSlot][$__WEBVIEW2_DIALOG_VIEW] = $iView
		$__g_aWebView2_ScriptDialogs[$iSlot][$__WEBVIEW2_DIALOG_URI] = $sURI
		$__g_aWebView2_ScriptDialogs[$iSlot][$__WEBVIEW2_DIALOG_KIND] = $iKind
		$__g_aWebView2_ScriptDialogs[$iSlot][$__WEBVIEW2_DIALOG_MESSAGE] = $sMessage
		$__g_aWebView2_ScriptDialogs[$iSlot][$__WEBVIEW2_DIALOG_DEFAULT_TEXT] = $sDefaultText
		$__g_aWebView2_ScriptDialogs[$iSlot][$__WEBVIEW2_DIALOG_ARGS] = $oArgs
		$__g_aWebView2_ScriptDialogs[$iSlot][$__WEBVIEW2_DIALOG_DEFERRAL] = $oDeferral
		$__g_aWebView2_ScriptDialogs[$iSlot][$__WEBVIEW2_DIALOG_STARTED] = TimerInit()
	Until True
	Return $iRequest
EndFunc   ;==>__WebView2_ScriptDialog_Defer

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_ScriptDialog_Finish
; Description ...: Applies the answer and always completes the native deferral.
; Syntax ........: __WebView2_ScriptDialog_Finish($iSlot, $bAccept, $sResultText)
; Parameters ....: $iSlot - Pending registry slot.
;                  $bAccept - True accepts; False cancels.
;                  $sResultText - Optional prompt result or Default.
; Return values .: True on success; False with @error = $WEBVIEW2_ERR_HRESULT and native HRESULT in @extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: An alert closes when its deferral completes; Accept applies to the other dialog kinds.
; Related .......: _WebView2_ScriptDialog_Request_Respond
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ScriptDialog_Finish($iSlot, $bAccept, $sResultText)
	Local $iError = 0, $iExtended = 0, $iHRESULT = 0
	Local $oArgs = $__g_aWebView2_ScriptDialogs[$iSlot][$__WEBVIEW2_DIALOG_ARGS]
	Local $oDeferral = $__g_aWebView2_ScriptDialogs[$iSlot][$__WEBVIEW2_DIALOG_DEFERRAL]
	Local $iKind = $__g_aWebView2_ScriptDialogs[$iSlot][$__WEBVIEW2_DIALOG_KIND]
	If $bAccept Then
		If $iKind = $WEBVIEW2_SCRIPT_DIALOG_KIND_PROMPT And $sResultText <> Default Then
			$iHRESULT = $oArgs.put_ResultText($sResultText)
			If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
				$iError = $WEBVIEW2_ERR_HRESULT
				$iExtended = $iHRESULT
			EndIf
		EndIf
		If Not $iError And $iKind <> $WEBVIEW2_SCRIPT_DIALOG_KIND_ALERT Then
			$iHRESULT = $oArgs.Accept()
			If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
				$iError = $WEBVIEW2_ERR_HRESULT
				$iExtended = $iHRESULT
			EndIf
		EndIf
	EndIf
	For $i = 0 To $__WEBVIEW2_DIALOG_FIELDS - 1
		$__g_aWebView2_ScriptDialogs[$iSlot][$i] = Null
	Next
	$iHRESULT = $oDeferral.Complete()
	If (Not $iError) And (@error Or $iHRESULT <> $WEBVIEW2_S_OK) Then
		$iError = $WEBVIEW2_ERR_HRESULT
		$iExtended = $iHRESULT
	EndIf
	Return SetError($iError, $iExtended, $iError = 0)
EndFunc   ;==>__WebView2_ScriptDialog_Finish

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ScriptDialog_Request_List
; Description ...: Lists pending JavaScript dialog request IDs.
; Syntax ........: _WebView2_ScriptDialog_Request_List([$iWebView = Default])
; Parameters ....: $iWebView - Optional WebView2 instance ID; Default includes all instances.
; Return values .: Array with count at index 0 and request IDs thereafter.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Poll outside the native callback.
; Related .......: _WebView2_ScriptDialog_Request_GetInfo, _WebView2_ScriptDialog_Request_Respond
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ScriptDialog_Request_List($iWebView = Default)
	Local $aResult[$__WEBVIEW2_MAX_SCRIPT_DIALOGS + 1], $iCount = 0
	For $i = 0 To $__WEBVIEW2_MAX_SCRIPT_DIALOGS - 1
		If Not $__g_aWebView2_ScriptDialogs[$i][$__WEBVIEW2_DIALOG_ID] Then ContinueLoop
		If $iWebView <> Default And $__g_aWebView2_ScriptDialogs[$i][$__WEBVIEW2_DIALOG_VIEW] <> $iWebView Then ContinueLoop
		$iCount += 1
		$aResult[$iCount] = $__g_aWebView2_ScriptDialogs[$i][$__WEBVIEW2_DIALOG_ID]
	Next
	$aResult[0] = $iCount
	ReDim $aResult[$iCount + 1]
	Return $aResult
EndFunc   ;==>_WebView2_ScriptDialog_Request_List

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ScriptDialog_Request_GetInfo
; Description ...: Reads the origin and content of a pending JavaScript dialog.
; Syntax ........: _WebView2_ScriptDialog_Request_GetInfo($iRequest)
; Parameters ....: $iRequest - Pending request ID.
; Return values .: On Success - Array [view ID, URI, kind, message, prompt default text].
;                  On Failure - Empty array and @error = $WEBVIEW2_ERR_INVALID_PARAMETER.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Validate the URI before accepting a dialog from untrusted content.
; Related .......: _WebView2_ScriptDialog_Request_List
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ScriptDialog_Request_GetInfo($iRequest)
	Local $aInfo[0], $iError = 0
	Local $iSlot = __WebView2_ScriptDialog_Find($iRequest)
	If $iSlot < 0 Then
		$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
	Else
		ReDim $aInfo[5]
		$aInfo[0] = $__g_aWebView2_ScriptDialogs[$iSlot][$__WEBVIEW2_DIALOG_VIEW]
		$aInfo[1] = $__g_aWebView2_ScriptDialogs[$iSlot][$__WEBVIEW2_DIALOG_URI]
		$aInfo[2] = $__g_aWebView2_ScriptDialogs[$iSlot][$__WEBVIEW2_DIALOG_KIND]
		$aInfo[3] = $__g_aWebView2_ScriptDialogs[$iSlot][$__WEBVIEW2_DIALOG_MESSAGE]
		$aInfo[4] = $__g_aWebView2_ScriptDialogs[$iSlot][$__WEBVIEW2_DIALOG_DEFAULT_TEXT]
	EndIf
	Return SetError($iError, 0, $aInfo)
EndFunc   ;==>_WebView2_ScriptDialog_Request_GetInfo

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ScriptDialog_Request_Respond
; Description ...: Answers a pending JavaScript dialog and completes its deferral.
; Syntax ........: _WebView2_ScriptDialog_Request_Respond($iRequest, $iDecision[, $sResultText = Default])
; Parameters ....: $iRequest - Pending request ID.
;                  $iDecision - $WEBVIEW2_SCRIPT_DIALOG_ACCEPT or $WEBVIEW2_SCRIPT_DIALOG_CANCEL.
;                  $sResultText - Optional result for a prompt; Default keeps the page's default text.
; Return values .: On Success - True.
;                  On Failure - False with @error = $WEBVIEW2_ERR_INVALID_PARAMETER or $WEBVIEW2_ERR_HRESULT.
;                  @extended contains the native HRESULT when available.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Even a native failure invalidates the request ID and completes its deferral.
; Related .......: _WebView2_ScriptDialog_Request_List, _WebView2_ScriptDialog_Request_Cancel
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ScriptDialog_Request_Respond($iRequest, $iDecision, $sResultText = Default)
	Local $bResult = False, $iError = 0, $iExtended = 0
	Local $iSlot = __WebView2_ScriptDialog_Find($iRequest)
	If $iSlot < 0 Or Not IsInt($iDecision) Or ($iDecision <> $WEBVIEW2_SCRIPT_DIALOG_ACCEPT And $iDecision <> $WEBVIEW2_SCRIPT_DIALOG_CANCEL) Or ($sResultText <> Default And Not IsString($sResultText)) Then
		$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
	Else
		$bResult = __WebView2_ScriptDialog_Finish($iSlot, $iDecision = $WEBVIEW2_SCRIPT_DIALOG_ACCEPT, $sResultText)
		$iError = @error
		$iExtended = @extended
	EndIf
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_ScriptDialog_Request_Respond

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ScriptDialog_Request_Cancel
; Description ...: Dismisses a pending dialog without accepting it.
; Syntax ........: _WebView2_ScriptDialog_Request_Cancel($iRequest)
; Parameters ....: $iRequest - Pending request ID.
; Return values .: Propagates the result, @error and @extended of _WebView2_ScriptDialog_Request_Respond().
; Author ........: mLipok
; Modified ......:
; Remarks .......: An alert has no meaningful cancel choice; completion closes it.
; Related .......: _WebView2_ScriptDialog_Request_Respond
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ScriptDialog_Request_Cancel($iRequest)
	Local $bResult = _WebView2_ScriptDialog_Request_Respond($iRequest, $WEBVIEW2_SCRIPT_DIALOG_CANCEL)
	Local $iError = @error, $iExtended = @extended
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_ScriptDialog_Request_Cancel

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ScriptDialog_Request_Expire
; Description ...: Dismisses dialogs older than the specified timeout.
; Syntax ........: _WebView2_ScriptDialog_Request_Expire([$iTimeoutMs = 15000])
; Parameters ....: $iTimeoutMs - Maximum pending age in milliseconds; poll from the host loop.
; Return values .: On Success - Count of expired dialogs.
;                  On Failure - 0 with @error = $WEBVIEW2_ERR_INVALID_PARAMETER.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Timeouts require a running event loop; this function does not schedule a timer.
; Related .......: _WebView2_ScriptDialog_Request_Cancel
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ScriptDialog_Request_Expire($iTimeoutMs = 15000)
	Local $iCount = 0, $iError = 0
	If Not IsInt($iTimeoutMs) Or $iTimeoutMs < 1 Then
		$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
	Else
		For $i = 0 To $__WEBVIEW2_MAX_SCRIPT_DIALOGS - 1
			If Not $__g_aWebView2_ScriptDialogs[$i][$__WEBVIEW2_DIALOG_ID] Then ContinueLoop
			If TimerDiff($__g_aWebView2_ScriptDialogs[$i][$__WEBVIEW2_DIALOG_STARTED]) < $iTimeoutMs Then ContinueLoop
			__WebView2_ScriptDialog_Finish($i, False, Default)
			$iCount += 1
		Next
	EndIf
	Return SetError($iError, 0, $iCount)
EndFunc   ;==>_WebView2_ScriptDialog_Request_Expire

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_ScriptDialog_CancelForView
; Description ...: Completes all pending dialogs before their WebView2 instance is destroyed.
; Syntax ........: __WebView2_ScriptDialog_CancelForView($iWebView)
; Parameters ....: $iWebView - Owning instance ID.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_Destroy
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ScriptDialog_CancelForView($iWebView)
	For $i = 0 To $__WEBVIEW2_MAX_SCRIPT_DIALOGS - 1
		If Not $__g_aWebView2_ScriptDialogs[$i][$__WEBVIEW2_DIALOG_ID] Then ContinueLoop
		If $__g_aWebView2_ScriptDialogs[$i][$__WEBVIEW2_DIALOG_VIEW] <> $iWebView Then ContinueLoop
		__WebView2_ScriptDialog_Finish($i, False, Default)
	Next
	Return
EndFunc   ;==>__WebView2_ScriptDialog_CancelForView

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_ScriptDialog_Invoke
; Description ...: Receives native JavaScript dialogs and calls the host's short policy callback.
; Syntax ........: __WebView2_ScriptDialog_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: $pSelf - Callback COM pointer.
;                  $pSender - Core WebView2 pointer.
;                  $pArgs - Script dialog event arguments pointer.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......: No modal UI or synchronous WebView2 helper is called inside this handler.
; Related .......: _WebView2_SetCallback, _WebView2_ScriptDialog_Request_Respond
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ScriptDialog_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Do
		Local $iView = __WebView2_Instance_FindByCorePointer($pSender)
		If $iView < 0 Or Not $pArgs Then ExitLoop 1
		Local $fnCallback = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_CB_SCRIPT_DIALOG]
		If Not IsFunc($fnCallback) Then ExitLoop 1
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2ScriptDialogOpeningEventArgs, $WEBVIEW2_DTAG_ICoreWebView2ScriptDialogOpeningEventArgs)
		If Not IsObj($oArgs) Then ExitLoop 1
		$oArgs.AddRef()
		Local $pURI = 0, $pMessage = 0, $pDefaultText = 0, $iKind = 0
		Local $iHRESULT = $oArgs.get_Uri($pURI)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		Local $sURI = __WebView2_CoTaskMemString_ReadAndFree($pURI)
		$iHRESULT = $oArgs.get_Kind($iKind)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		$iHRESULT = $oArgs.get_Message($pMessage)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		Local $sMessage = __WebView2_CoTaskMemString_ReadAndFree($pMessage)
		$iHRESULT = $oArgs.get_DefaultText($pDefaultText)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
		Local $sDefaultText = __WebView2_CoTaskMemString_ReadAndFree($pDefaultText)
		Local $vDecision = Call($fnCallback, $iView, $sURI, $iKind, $sMessage, $sDefaultText)
		If @error Or __WebView2_Instance_FindByCorePointer($pSender) <> $iView Then ExitLoop 1
		If IsInt($vDecision) And $vDecision = $WEBVIEW2_SCRIPT_DIALOG_DEFER Then
			__WebView2_ScriptDialog_Defer($iView, $oArgs, $sURI, $iKind, $sMessage, $sDefaultText)
			ExitLoop 1
		EndIf
		Local $iDecision = $vDecision, $sResultText = Default
		If IsArray($vDecision) Then
			If UBound($vDecision) <> 2 Then ExitLoop 1
			$iDecision = $vDecision[0]
			$sResultText = $vDecision[1]
		EndIf
		If Not IsInt($iDecision) Or ($iDecision <> $WEBVIEW2_SCRIPT_DIALOG_ACCEPT And $iDecision <> $WEBVIEW2_SCRIPT_DIALOG_CANCEL) Then ExitLoop 1
		If $iDecision = $WEBVIEW2_SCRIPT_DIALOG_ACCEPT Then
			If $iKind = $WEBVIEW2_SCRIPT_DIALOG_KIND_PROMPT And $sResultText <> Default Then
				If Not IsString($sResultText) Then ExitLoop 1
				$iHRESULT = $oArgs.put_ResultText($sResultText)
				If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop 1
			EndIf
			If $iKind <> $WEBVIEW2_SCRIPT_DIALOG_KIND_ALERT Then $oArgs.Accept()
		EndIf
	Until True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_ScriptDialog_Invoke
