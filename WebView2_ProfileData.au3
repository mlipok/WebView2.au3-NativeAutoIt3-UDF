#include-once
#Tidy_ILC_Pos=44

Global $__g_aWebView2_ProfileDataCallbacks[$WEBVIEW2_MAX_INSTANCES]

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ClearProfileBrowsingData
; Description ...: Starts an asynchronous clear of selected browsing data from the view's entire profile.
; Syntax ........: _WebView2_ClearProfileBrowsingData($iWebView, $iKinds, $fnCallback[, $vStart = Default[, $vEnd = Default]])
; Parameters ....: $iWebView - ID of a view using the target profile.
;                  $iKinds - Nonempty mask of $WEBVIEW2_BROWSING_DATA_* flags.
;                  $fnCallback - Completion function receiving ($iWebView, $iHRESULT).
;                  $vStart, $vEnd - Both Default for all time, or finite UTC Unix seconds in [start, end) order.
; Return values .: On Success - True when the Runtime accepts the request. Completion is reported through the callback.
;                  On Failure - False with @error set:
;                    INVALID_INSTANCE - Invalid view ID.
;                    INVALID_PARAMETER - Unsupported mask or invalid time bounds.
;                    CALLBACK - Invalid callback or callback allocation failed.
;                    BUSY - A clear is already pending for this view.
;                    DLLCALL or HRESULT - Profile interface lookup or native start failed. HRESULT uses @extended for the native code.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Requires ICoreWebView2Profile2. The clear affects origins and other views in the same profile.
;                  Closing the initiating view discards its callback; the Runtime may still clear data.
; Related .......: _WebView2_ClearBrowserData
; Link ..........: https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2profile2
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ClearProfileBrowsingData($iWebView, $iKinds, $fnCallback, $vStart = Default, $vEnd = Default)
	If Not __WebView2_Instance_IsValid($iWebView) Then Return SetError($WEBVIEW2_ERR_INVALID_INSTANCE, 0, False)
	If Not IsInt($iKinds) Or $iKinds < 1 Or $iKinds > 0xFFFF Then Return SetError($WEBVIEW2_ERR_INVALID_PARAMETER, 0, False)
	If Not IsFunc($fnCallback) Then Return SetError($WEBVIEW2_ERR_CALLBACK, 0, False)
	Local $bTimed = $vStart <> Default Or $vEnd <> Default
	If $bTimed Then
		If Not IsNumber($vStart) Or Not IsNumber($vEnd) Then Return SetError($WEBVIEW2_ERR_INVALID_PARAMETER, 0, False)
		If Not ($vStart < $vEnd And $vStart - $vStart = 0 And $vEnd - $vEnd = 0) Then Return SetError($WEBVIEW2_ERR_INVALID_PARAMETER, 0, False)
	EndIf
	If IsFunc($__g_aWebView2_ProfileDataCallbacks[$iWebView]) Then Return SetError($WEBVIEW2_ERR_BUSY, 0, False)
	Local $pProfile = __WebView2_Ext_Profile($iWebView, $WEBVIEW2_IID_ICoreWebView2Profile2)
	If @error Then Return SetError(@error, @extended, False)
	If Not $pProfile Then Return SetError($WEBVIEW2_ERR_HRESULT, 0, False)
	Local $oProfile = ObjCreateInterface($pProfile, $WEBVIEW2_IID_ICoreWebView2Profile2, $WEBVIEW2_DTAG_ICoreWebView2Profile2)
	If Not IsObj($oProfile) Then
		__WebView2_Ext_Release($pProfile)
		Return SetError($WEBVIEW2_ERR_HRESULT, 0, False)
	EndIf
	Local $iSlot = $__WEBVIEW2_CB_PROFILE_DATA_BASE + $iWebView
	Local $pHandler = __WebView2_Callback_GetPointer($iSlot)
	If Not $pHandler Then
		If Not __WebView2_Callback_Create($iSlot, __WebView2_ProfileData_Completed, "ptr;long") Then Return SetError($WEBVIEW2_ERR_CALLBACK, 0, False)
		$pHandler = __WebView2_Callback_GetPointer($iSlot)
	EndIf
	$__g_aWebView2_ProfileDataCallbacks[$iWebView] = $fnCallback
	Local $iResult, $iCallError
	If $bTimed Then
		$iResult = $oProfile.ClearBrowsingDataInTimeRange($iKinds, $vStart, $vEnd, $pHandler)
		$iCallError = @error
	Else
		$iResult = $oProfile.ClearBrowsingData($iKinds, $pHandler)
		$iCallError = @error
	EndIf
	If $iCallError Or $iResult <> $WEBVIEW2_S_OK Then
		$__g_aWebView2_ProfileDataCallbacks[$iWebView] = Null
		Return SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)
	EndIf
	Return SetError(0, 0, True)
EndFunc   ;==>_WebView2_ClearProfileBrowsingData

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_ProfileData_Completed
; Description ...: Delivers the native clear result to the initiating AutoIt callback.
; Syntax ........: __WebView2_ProfileData_Completed($pSelf, $iHRESULT)
; Parameters ....: $pSelf - Native handler pointer identifying the originating view.
;                  $iHRESULT - Result reported by WebView2.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The view can start another clear after this completion.
; Related .......: _WebView2_ClearProfileBrowsingData
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ProfileData_Completed($pSelf, $iHRESULT)
	For $iView = 0 To $WEBVIEW2_MAX_INSTANCES - 1
		If __WebView2_Callback_GetPointer($__WEBVIEW2_CB_PROFILE_DATA_BASE + $iView) <> $pSelf Then ContinueLoop
		Local $fnCallback = $__g_aWebView2_ProfileDataCallbacks[$iView]
		$__g_aWebView2_ProfileDataCallbacks[$iView] = Null
		If IsFunc($fnCallback) Then Call($fnCallback, $iView, $iHRESULT)
		ExitLoop
	Next
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_ProfileData_Completed
