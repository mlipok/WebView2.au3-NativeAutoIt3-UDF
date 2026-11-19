#include-once
#Tidy_ILC_Pos=44
; #INDEX# =======================================================================================================================
; Title .........: WebView2_Authentication.au3
; Description ...: Opt-in native HTTP authentication and bounded deferred decisions.
; Author(s) .....: mLipok
; Version .......: 0.6.0
; ===============================================================================================================================
Global Const $__WEBVIEW2_AUTH_CAPACITY = 32
Global Enum $__WEBVIEW2_AUTH_ID, $__WEBVIEW2_AUTH_VIEW, $__WEBVIEW2_AUTH_URI, $__WEBVIEW2_AUTH_CHALLENGE, $__WEBVIEW2_AUTH_ARGS, $__WEBVIEW2_AUTH_DEFERRAL, $__WEBVIEW2_AUTH_STARTED, $__WEBVIEW2_AUTH_FIELDS
Global $__g_aWebView2_Auth[$__WEBVIEW2_AUTH_CAPACITY][$__WEBVIEW2_AUTH_FIELDS]
Global $__g_iWebView2_NextAuthId = 1

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_Authentication_Find
; Description ...: Finds a live request by its monotonically increasing ID.
; Syntax ........: __WebView2_Authentication_Find($iRequest)
; Parameters ....: See signature.
; Return values .: Registry index, or -1.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func __WebView2_Authentication_Find($iRequest)
	If Not IsInt($iRequest) Or $iRequest < 1 Then Return -1
	For $i = 0 To $__WEBVIEW2_AUTH_CAPACITY - 1
		If $__g_aWebView2_Auth[$i][$__WEBVIEW2_AUTH_ID] = $iRequest Then Return $i
	Next
	Return -1
EndFunc   ;==>__WebView2_Authentication_Find

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_Authentication_CredentialsValid
; Description ...: Validates strings before passing them through UTF-16 COM setters.
; Syntax ........: __WebView2_Authentication_CredentialsValid($sUser, $sPassword)
; Parameters ....: See signature.
; Return values .: True if both inputs are bounded strings without embedded NUL.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func __WebView2_Authentication_CredentialsValid($sUser, $sPassword)
	If Not IsString($sUser) Or Not IsString($sPassword) Then Return False
	If $sUser = "" And $sPassword = "" Then Return False
	If StringLen($sUser) > 4096 Or StringLen($sPassword) > 4096 Then Return False
	If StringInStr($sUser, Chr(0)) Or StringInStr($sPassword, Chr(0)) Then Return False
	Return True
EndFunc   ;==>__WebView2_Authentication_CredentialsValid

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_Authentication_Finish
; Description ...: Applies credentials or cancellation, removes the ID, and completes its deferral.
; Syntax ........: __WebView2_Authentication_Finish($iSlot, $bCancel, $sUser, $sPassword)
; Parameters ....: See signature.
; Return values .: True on success; False with HRESULT error and @extended native HRESULT.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func __WebView2_Authentication_Finish($iSlot, $bCancel, $sUser, $sPassword)
	Local $oArgs = $__g_aWebView2_Auth[$iSlot][$__WEBVIEW2_AUTH_ARGS]
	Local $oDeferral = $__g_aWebView2_Auth[$iSlot][$__WEBVIEW2_AUTH_DEFERRAL]
	; Remove before native calls: completion can re-enter or invalidate the owner.
	For $i = 0 To $__WEBVIEW2_AUTH_FIELDS - 1
		$__g_aWebView2_Auth[$iSlot][$i] = Null
	Next
	Local $iError = 0, $iExtended = 0, $iHRESULT = 0
	If Not $bCancel Then
		Local $pResponse = 0
		$iHRESULT = $oArgs.get_Response($pResponse)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Or Not $pResponse Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iHRESULT
		Else
			Local $oResponse = ObjCreateInterface($pResponse, $WEBVIEW2_IID_ICoreWebView2BasicAuthenticationResponse, $WEBVIEW2_DTAG_ICoreWebView2BasicAuthenticationResponse)
			If Not IsObj($oResponse) Then
				__WebView2_Accelerator_Release($pResponse)
				$iError = $WEBVIEW2_ERR_HRESULT
				$iExtended = $WEBVIEW2_E_NOINTERFACE
			Else
				$iHRESULT = $oResponse.put_UserName($sUser)
				If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
					$iError = $WEBVIEW2_ERR_HRESULT
					$iExtended = $iHRESULT
				Else
					$iHRESULT = $oResponse.put_Password($sPassword)
					If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
						$iError = $WEBVIEW2_ERR_HRESULT
						$iExtended = $iHRESULT
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
	$iHRESULT = $oArgs.put_Cancel(($bCancel Or $iError) ? 1 : 0)
	If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
		If Not $iError Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iHRESULT
		EndIf
	EndIf
	$iHRESULT = $oDeferral.Complete()
	If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
		If Not $iError Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iHRESULT
		EndIf
	EndIf
	Return SetError($iError, $iExtended, $iError = 0)
EndFunc   ;==>__WebView2_Authentication_Finish

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Authentication_Request_Respond
; Description ...: Answers a pending native HTTP authentication request.
; Syntax ........: _WebView2_Authentication_Request_Respond($iRequest[, $sUser = ""[, $sPassword = ""[, $bCancel = False]]])
; Parameters ....: $iRequest - Pending ID.
;                  $sUser, $sPassword - Optional strings, each at most 4096 characters without NUL; both empty is invalid. Default empty.
;                  $bCancel - Optional Boolean; True cancels and ignores credential parameters. Default False.
; Return values .: True means the native decision completed, not that the server accepted credentials.
;                  False sets @error: INVALID_PARAMETER for invalid inputs, NO_MATCH for an expired/answered ID,
;                  HRESULT for native failure (@extended is the native HRESULT).
; Author ........: mLipok
; Modified ......:
; Remarks .......: The ID is consumed on native completion, including a native failure. The AutoIt registry does not store credentials; the Runtime may cache them.
;                  Host applications must validate URI/challenge and use HTTPS outside loopback demos.
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Authentication_Request_Respond($iRequest, $sUser = "", $sPassword = "", $bCancel = False)
	If Not IsBool($bCancel) Then Return SetError($WEBVIEW2_ERR_INVALID_PARAMETER, 0, False)
	If Not $bCancel And Not __WebView2_Authentication_CredentialsValid($sUser, $sPassword) Then Return SetError($WEBVIEW2_ERR_INVALID_PARAMETER, 0, False)
	Local $iSlot = __WebView2_Authentication_Find($iRequest)
	If $iSlot < 0 Then Return SetError($WEBVIEW2_ERR_NO_MATCH, 0, False)
	Local $bResult = __WebView2_Authentication_Finish($iSlot, $bCancel, $sUser, $sPassword)
	Return SetError(@error, @extended, $bResult)
EndFunc   ;==>_WebView2_Authentication_Request_Respond

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Authentication_Request_List
; Description ...: Lists pending authentication requests without credential data.
; Syntax ........: _WebView2_Authentication_Request_List([$iWebView = -1])
; Parameters ....: $iWebView - Optional owner ID; -1 (default) lists all owners.
; Return values .: 2D array: [0][0] count; rows 1..count contain ID, view, URI, challenge.
;                  On failure returns 0 with INVALID_PARAMETER or INVALID_INSTANCE in @error.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Requests vanish on response, expiration, new top-level navigation or owner cleanup.
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Authentication_Request_List($iWebView = -1)
	If Not IsInt($iWebView) Then Return SetError($WEBVIEW2_ERR_INVALID_PARAMETER, 0, 0)
	If $iWebView <> -1 And Not __WebView2_Instance_IsValid($iWebView) Then Return SetError($WEBVIEW2_ERR_INVALID_INSTANCE, 0, 0)
	Local $aResult[$__WEBVIEW2_AUTH_CAPACITY + 1][4], $iCount = 0
	For $i = 0 To $__WEBVIEW2_AUTH_CAPACITY - 1
		If Not $__g_aWebView2_Auth[$i][$__WEBVIEW2_AUTH_ID] Then ContinueLoop
		If $iWebView <> -1 And $__g_aWebView2_Auth[$i][$__WEBVIEW2_AUTH_VIEW] <> $iWebView Then ContinueLoop
		$iCount += 1
		For $j = 0 To 3
			$aResult[$iCount][$j] = $__g_aWebView2_Auth[$i][$j]
		Next
	Next
	$aResult[0][0] = $iCount
	ReDim $aResult[$iCount + 1][4]
	Return SetError(0, 0, $aResult)
EndFunc   ;==>_WebView2_Authentication_Request_List

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Authentication_Request_Expire
; Description ...: Cancels overdue authentication requests when called by the host event loop.
; Syntax ........: _WebView2_Authentication_Request_Expire([$iTimeoutMs = 30000])
; Parameters ....: $iTimeoutMs - Optional positive integer age in milliseconds; default 30000.
; Return values .: Number of consumed expired requests. INVALID_PARAMETER sets @error for invalid timeout;
;                  HRESULT reports the first native completion failure in @extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: No background timer is installed. Poll this function to enforce your timeout policy.
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Authentication_Request_Expire($iTimeoutMs = 30000)
	If Not IsInt($iTimeoutMs) Or $iTimeoutMs < 1 Then Return SetError($WEBVIEW2_ERR_INVALID_PARAMETER, 0, 0)
	Local $iCount = 0, $iError = 0, $iExtended = 0
	For $i = 0 To $__WEBVIEW2_AUTH_CAPACITY - 1
		If Not $__g_aWebView2_Auth[$i][$__WEBVIEW2_AUTH_ID] Then ContinueLoop
		If TimerDiff($__g_aWebView2_Auth[$i][$__WEBVIEW2_AUTH_STARTED]) < $iTimeoutMs Then ContinueLoop
		$iCount += 1
		__WebView2_Authentication_Finish($i, True, "", "")
		If @error And Not $iError Then
			$iError = @error
			$iExtended = @extended
		EndIf
	Next
	Return SetError($iError, $iExtended, $iCount)
EndFunc   ;==>_WebView2_Authentication_Request_Expire

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_Authentication_CancelForView
; Description ...: Cancels pending requests owned by one view.
; Syntax ........: __WebView2_Authentication_CancelForView($iView)
; Parameters ....: See signature.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func __WebView2_Authentication_CancelForView($iView)
	For $i = 0 To $__WEBVIEW2_AUTH_CAPACITY - 1
		If $__g_aWebView2_Auth[$i][$__WEBVIEW2_AUTH_ID] And $__g_aWebView2_Auth[$i][$__WEBVIEW2_AUTH_VIEW] = $iView Then __WebView2_Authentication_Finish($i, True, "", "")
	Next
EndFunc   ;==>__WebView2_Authentication_CancelForView

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_Authentication_Cleanup
; Description ...: Cancels requests and detaches the optional native subscription.
; Syntax ........: __WebView2_Authentication_Cleanup($iView)
; Parameters ....: See signature.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func __WebView2_Authentication_Cleanup($iView)
	Local $oCore = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_AUTH_CORE]
	Local $iToken = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_AUTH_TOKEN]
	If IsObj($oCore) And $iToken Then $oCore.remove_BasicAuthenticationRequested($iToken)
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_AUTH_TOKEN] = 0
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_AUTH_CALLBACK] = Null
	__WebView2_Authentication_CancelForView($iView)
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_AUTH_CORE] = Null
EndFunc   ;==>__WebView2_Authentication_Cleanup

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_Authentication_Subscribe
; Description ...: Lazily subscribes a view to ICoreWebView2_10 authentication events.
; Syntax ........: __WebView2_Authentication_Subscribe($iView, $fnCallback)
; Parameters ....: See signature.
; Return values .: True or False; propagates query error/HRESULT or callback creation failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func __WebView2_Authentication_Subscribe($iView, $fnCallback)
	If Not $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_AUTH_TOKEN] Then
		Local $oCore = __WebView2_Frame_QueryInterface($__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_CORE_POINTER], $WEBVIEW2_IID_ICoreWebView2_10, $WEBVIEW2_DTAG_ICoreWebView2_10)
		If @error Then Return SetError(@error, @extended, False)
		If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_BASIC_AUTHENTICATION_REQUESTED) Then
			If Not __WebView2_Callback_Create($__WEBVIEW2_CB_BASIC_AUTHENTICATION_REQUESTED, __WebView2_Authentication_Invoke, "ptr;ptr;ptr") Then Return SetError($WEBVIEW2_ERR_CALLBACK, 0, False)
		EndIf
		Local $tToken = DllStructCreate("int64")
		Local $iHRESULT = $oCore.add_BasicAuthenticationRequested(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_BASIC_AUTHENTICATION_REQUESTED), $tToken)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then Return SetError($WEBVIEW2_ERR_HRESULT, $iHRESULT, False)
		$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_AUTH_CORE] = $oCore
		$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_AUTH_TOKEN] = DllStructGetData($tToken, 1)
	EndIf
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_AUTH_CALLBACK] = $fnCallback
	Return SetError(0, 0, True)
EndFunc   ;==>__WebView2_Authentication_Subscribe

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_Authentication_Invoke
; Description ...: Retains event arguments before invoking the host decision callback.
; Syntax ........: __WebView2_Authentication_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: See signature.
; Return values .: S_OK; invalid host decisions or unavailable registry/deferral are cancelled.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Credentials never enter the registry or logs; retain only the native arguments until completion.
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_10
; Example .......: Yes
; ===============================================================================================================================
Func __WebView2_Authentication_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Local $iView = __WebView2_Instance_FindByCorePointer($pSender)
	If $iView < 0 Or Not $pArgs Then Return $WEBVIEW2_S_OK
	Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2BasicAuthenticationRequestedEventArgs, $WEBVIEW2_DTAG_ICoreWebView2BasicAuthenticationRequestedEventArgs)
	If Not IsObj($oArgs) Then Return $WEBVIEW2_S_OK
	$oArgs.AddRef()
	Local $iSlot = -1
	For $i = 0 To $__WEBVIEW2_AUTH_CAPACITY - 1
		If Not $__g_aWebView2_Auth[$i][$__WEBVIEW2_AUTH_ID] Then
			$iSlot = $i
			ExitLoop
		EndIf
	Next
	Local $pURI = 0, $pChallenge = 0, $pDeferral = 0, $iHRESULT = 0
	Do
		If $iSlot < 0 Then ExitLoop
		$iHRESULT = $oArgs.get_Uri($pURI)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop
		Local $sURI = __WebView2_CoTaskMemString_ReadAndFree($pURI)
		$iHRESULT = $oArgs.get_Challenge($pChallenge)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop
		Local $sChallenge = __WebView2_CoTaskMemString_ReadAndFree($pChallenge)
		$iHRESULT = $oArgs.GetDeferral($pDeferral)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Or Not $pDeferral Then ExitLoop
		Local $oDeferral = ObjCreateInterface($pDeferral, $WEBVIEW2_IID_ICoreWebView2Deferral, $WEBVIEW2_DTAG_ICoreWebView2Deferral)
		If Not IsObj($oDeferral) Then
			; Complete and release the acquired pointer even if wrapping failed.
			Local $tV = DllStructCreate("ptr", $pDeferral)
			Local $tMethods = DllStructCreate("ptr[4]", DllStructGetData($tV, 1))
			$oArgs.put_Cancel(1)
			DllCallAddress("long", DllStructGetData($tMethods, 1, 4), "ptr", $pDeferral)
			__WebView2_Accelerator_Release($pDeferral)
			Return $WEBVIEW2_S_OK
		EndIf
		Local $iRequest = $__g_iWebView2_NextAuthId
		$__g_iWebView2_NextAuthId += 1
		$__g_aWebView2_Auth[$iSlot][$__WEBVIEW2_AUTH_ID] = $iRequest
		$__g_aWebView2_Auth[$iSlot][$__WEBVIEW2_AUTH_VIEW] = $iView
		$__g_aWebView2_Auth[$iSlot][$__WEBVIEW2_AUTH_URI] = $sURI
		$__g_aWebView2_Auth[$iSlot][$__WEBVIEW2_AUTH_CHALLENGE] = $sChallenge
		$__g_aWebView2_Auth[$iSlot][$__WEBVIEW2_AUTH_ARGS] = $oArgs
		$__g_aWebView2_Auth[$iSlot][$__WEBVIEW2_AUTH_DEFERRAL] = $oDeferral
		$__g_aWebView2_Auth[$iSlot][$__WEBVIEW2_AUTH_STARTED] = TimerInit()
		Local $fnCallback = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_AUTH_CALLBACK]
		Local $vDecision = Call($fnCallback, $iView, $iRequest, $sURI, $sChallenge)
		Local $iCallError = @error
		; Owner destruction or a response from the callback may already have consumed the ID.
		If __WebView2_Authentication_Find($iRequest) < 0 Then Return $WEBVIEW2_S_OK
		If Not $iCallError Then
			If IsInt($vDecision) And $vDecision = $WEBVIEW2_AUTH_DEFER Then Return $WEBVIEW2_S_OK
			If IsArray($vDecision) Then
				If UBound($vDecision, 0) = 1 And UBound($vDecision) = 2 Then
					If __WebView2_Authentication_CredentialsValid($vDecision[0], $vDecision[1]) Then
						__WebView2_Authentication_Finish($iSlot, False, $vDecision[0], $vDecision[1])
						Return $WEBVIEW2_S_OK
					EndIf
				EndIf
			EndIf
		EndIf
		__WebView2_Authentication_Finish($iSlot, True, "", "")
		Return $WEBVIEW2_S_OK
	Until True
	$oArgs.put_Cancel(1)
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_Authentication_Invoke

