#include-once
#Tidy_ILC_Pos=44

; A pending native deferral keeps its event arguments alive until the host responds.
Global Const $__WEBVIEW2_MAX_PERMISSION_REQUESTS = 64
Global Enum _
		$__WEBVIEW2_PERMISSION_ID, _
		$__WEBVIEW2_PERMISSION_VIEW, _
		$__WEBVIEW2_PERMISSION_FRAME, _
		$__WEBVIEW2_PERMISSION_URI, _
		$__WEBVIEW2_PERMISSION_KIND, _
		$__WEBVIEW2_PERMISSION_USER, _
		$__WEBVIEW2_PERMISSION_ARGS, _
		$__WEBVIEW2_PERMISSION_ARGS_POINTER, _
		$__WEBVIEW2_PERMISSION_DEFERRAL, _
		$__WEBVIEW2_PERMISSION_STARTED, _
		$__WEBVIEW2_PERMISSION_FIELDS

Global $__g_aWebView2_Permissions[$__WEBVIEW2_MAX_PERMISSION_REQUESTS][$__WEBVIEW2_PERMISSION_FIELDS]
Global $__g_iWebView2_NextPermissionId = 1

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Permission_Find
; Description ...: Finds a pending permission request by its public ID.
; Syntax ........: __WebView2_Permission_Find($iRequest)
; Parameters ....: $iRequest - Pending request ID.
; Return values .: Registry slot, or -1 when the request is no longer pending.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_Permission_Request_List
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Permission_Find($iRequest)
	Local $iSlot = -1
	If IsInt($iRequest) And $iRequest > 0 Then
		For $i = 0 To $__WEBVIEW2_MAX_PERMISSION_REQUESTS - 1
			If $__g_aWebView2_Permissions[$i][$__WEBVIEW2_PERMISSION_ID] = $iRequest Then
				$iSlot = $i
				ExitLoop
			EndIf
		Next
	EndIf
	Return $iSlot
EndFunc   ;==>__WebView2_Permission_Find

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Permission_Defer
; Description ...: Retains one native permission event for a later host decision.
; Syntax ........: __WebView2_Permission_Defer($iView, $iFrame, $oArgs, $sURI, $iKind, $bUserInitiated)
; Parameters ....: $iView - Owning WebView2 instance ID.
;                  $iFrame - Tracked frame ID, or 0 for the top-level event.
;                  $oArgs - Permission event arguments with a retained COM reference.
;                  $sURI - Requesting origin.
;                  $iKind - Native permission kind.
;                  $bUserInitiated - Native user-gesture flag.
; Return values .: Positive request ID, or 0 when no slot or deferral is available.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The caller must return promptly from the native event handler.
; Related .......: _WebView2_Permission_Request_Respond
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2permissionrequestedeventargs
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Permission_Defer($iView, $iFrame, $oArgs, $pArgs, $sURI, $iKind, $bUserInitiated)
	Local $iRequest = 0
	Do
		Local $iSlot = -1
		For $i = 0 To $__WEBVIEW2_MAX_PERMISSION_REQUESTS - 1
			If Not $__g_aWebView2_Permissions[$i][$__WEBVIEW2_PERMISSION_ID] Then
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
		$iRequest = $__g_iWebView2_NextPermissionId
		$__g_iWebView2_NextPermissionId += 1
		$__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_ID] = $iRequest
		$__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_VIEW] = $iView
		$__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_FRAME] = $iFrame
		$__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_URI] = $sURI
		$__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_KIND] = $iKind
		$__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_USER] = $bUserInitiated
		$__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_ARGS] = $oArgs
		$__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_ARGS_POINTER] = $pArgs
		$__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_DEFERRAL] = $oDeferral
		$__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_STARTED] = TimerInit()
	Until True
	Return $iRequest
EndFunc   ;==>__WebView2_Permission_Defer

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Permission_Request_List
; Description ...: Lists pending permission request IDs for one view or all views.
; Syntax ........: _WebView2_Permission_Request_List([$iWebView = Default])
; Parameters ....: $iWebView - Optional WebView2 instance ID; Default includes all views.
; Return values .: Array with the count at index 0 and request IDs thereafter.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Poll this list from the host event loop, outside native callbacks.
; Related .......: _WebView2_Permission_Request_GetInfo, _WebView2_Permission_Request_Respond
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Permission_Request_List($iWebView = Default)
	Local $aResult[$__WEBVIEW2_MAX_PERMISSION_REQUESTS + 1], $iCount = 0
	For $i = 0 To $__WEBVIEW2_MAX_PERMISSION_REQUESTS - 1
		If Not $__g_aWebView2_Permissions[$i][$__WEBVIEW2_PERMISSION_ID] Then ContinueLoop
		If $iWebView <> Default And $__g_aWebView2_Permissions[$i][$__WEBVIEW2_PERMISSION_VIEW] <> $iWebView Then ContinueLoop
		$iCount += 1
		$aResult[$iCount] = $__g_aWebView2_Permissions[$i][$__WEBVIEW2_PERMISSION_ID]
	Next
	$aResult[0] = $iCount
	ReDim $aResult[$iCount + 1]
	Return $aResult
EndFunc   ;==>_WebView2_Permission_Request_List

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Permission_Request_GetInfo
; Description ...: Reads the origin and source of a pending permission request.
; Syntax ........: _WebView2_Permission_Request_GetInfo($iRequest)
; Parameters ....: $iRequest - ID returned by _WebView2_Permission_Request_List().
; Return values .: On Success - Array [view ID, frame ID or 0, origin, kind, user-initiated flag].
;                  On Failure - Empty array with @error = $WEBVIEW2_ERR_INVALID_PARAMETER.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Validate the exact origin and permission kind before granting access.
; Related .......: _WebView2_Permission_Request_List, _WebView2_Permission_Request_Respond
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Permission_Request_GetInfo($iRequest)
	Local $aInfo[0], $iError = 0
	Local $iSlot = __WebView2_Permission_Find($iRequest)
	If $iSlot < 0 Then
		$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
	Else
		ReDim $aInfo[5]
		$aInfo[0] = $__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_VIEW]
		$aInfo[1] = $__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_FRAME]
		$aInfo[2] = $__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_URI]
		$aInfo[3] = $__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_KIND]
		$aInfo[4] = $__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_USER]
	EndIf
	Return SetError($iError, 0, $aInfo)
EndFunc   ;==>_WebView2_Permission_Request_GetInfo

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Permission_Request_Respond
; Description ...: Applies a deferred permission decision and completes its native deferral.
; Syntax ........: _WebView2_Permission_Request_Respond($iRequest, $iState[, $bSaveInProfile = False])
; Parameters ....: $iRequest - Pending request ID.
;                  $iState - $WEBVIEW2_PERMISSION_STATE_ALLOW or $WEBVIEW2_PERMISSION_STATE_DENY.
;                  $bSaveInProfile - False prevents persistence when EventArgs3 is available.
; Return values .: On Success - True.
;                  On Failure - False with @error = $WEBVIEW2_ERR_INVALID_PARAMETER or $WEBVIEW2_ERR_HRESULT;
;                  @extended contains the native HRESULT when available.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Call outside a native callback. A failed native Complete invalidates the request ID.
; Related .......: _WebView2_Permission_Request_List, _WebView2_Permission_Request_Cancel
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2permissionrequestedeventargs
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Permission_Request_Respond($iRequest, $iState, $bSaveInProfile = False)
	Local $bResult = False, $iError = 0, $iExtended = 0
	Do
		Local $iSlot = __WebView2_Permission_Find($iRequest)
		If $iSlot < 0 Or Not IsInt($iState) Or ($iState <> $WEBVIEW2_PERMISSION_STATE_ALLOW And $iState <> $WEBVIEW2_PERMISSION_STATE_DENY) Or Not IsBool($bSaveInProfile) Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $oArgs = $__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_ARGS]
		Local $oDeferral = $__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_DEFERRAL]
		If Not $bSaveInProfile Then
			Local $oArgs3 = ObjCreateInterface($__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_ARGS_POINTER], $WEBVIEW2_IID_ICoreWebView2PermissionRequestedEventArgs3, $WEBVIEW2_DTAG_ICoreWebView2PermissionRequestedEventArgs3)
			If Not IsObj($oArgs3) Then
				$iError = $WEBVIEW2_ERR_HRESULT
				$iExtended = $WEBVIEW2_E_NOINTERFACE
				ExitLoop 1
			EndIf
			$oArgs3.AddRef()
			Local $iHRESULT = $oArgs3.put_SavesInProfile(False)
			If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
				$iError = $WEBVIEW2_ERR_HRESULT
				$iExtended = $iHRESULT
				ExitLoop 1
			EndIf
		EndIf
		$iHRESULT = $oArgs.put_State($iState)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iHRESULT
			ExitLoop 1
		EndIf
		__WebView2_Permission_Clear($iSlot)
		$iHRESULT = $oDeferral.Complete()
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iHRESULT
			ExitLoop 1
		EndIf
		$bResult = True
	Until True
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_Permission_Request_Respond

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Permission_Request_Cancel
; Description ...: Denies a pending permission request without profile persistence.
; Syntax ........: _WebView2_Permission_Request_Cancel($iRequest)
; Parameters ....: $iRequest - Pending request ID.
; Return values .: On Success - True.
;                  On Failure - False with @error = $WEBVIEW2_ERR_INVALID_PARAMETER.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Always completes the deferral, even when EventArgs3 is unavailable.
; Related .......: _WebView2_Permission_Request_Respond
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Permission_Request_Cancel($iRequest)
	Local $bResult = False, $iError = 0
	Local $iSlot = __WebView2_Permission_Find($iRequest)
	If $iSlot < 0 Then
		$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
	Else
		__WebView2_Permission_Abandon($iSlot)
		$bResult = True
	EndIf
	Return SetError($iError, 0, $bResult)
EndFunc   ;==>_WebView2_Permission_Request_Cancel

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Permission_Request_Expire
; Description ...: Denies permission requests older than the chosen timeout.
; Syntax ........: _WebView2_Permission_Request_Expire([$iTimeoutMs = 15000])
; Parameters ....: $iTimeoutMs - Maximum pending age in milliseconds; poll from the main loop.
; Return values .: On Success - Count of expired requests.
;                  On Failure - 0 with @error = $WEBVIEW2_ERR_INVALID_PARAMETER.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The UDF cannot run a timer while the host stops pumping its event loop.
; Related .......: _WebView2_Permission_Request_Cancel
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Permission_Request_Expire($iTimeoutMs = 15000)
	Local $iCount = 0, $iError = 0
	If Not IsInt($iTimeoutMs) Or $iTimeoutMs < 1 Then
		$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
	Else
		For $i = 0 To $__WEBVIEW2_MAX_PERMISSION_REQUESTS - 1
			If Not $__g_aWebView2_Permissions[$i][$__WEBVIEW2_PERMISSION_ID] Then ContinueLoop
			If TimerDiff($__g_aWebView2_Permissions[$i][$__WEBVIEW2_PERMISSION_STARTED]) < $iTimeoutMs Then ContinueLoop
			__WebView2_Permission_Abandon($i)
			$iCount += 1
		Next
	EndIf
	Return SetError($iError, 0, $iCount)
EndFunc   ;==>_WebView2_Permission_Request_Expire

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Permission_Clear
; Description ...: Releases one completed permission record.
; Syntax ........: __WebView2_Permission_Clear($iSlot)
; Parameters ....: $iSlot - Permission registry slot.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_Permission_Request_Respond
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Permission_Clear($iSlot)
	For $i = 0 To $__WEBVIEW2_PERMISSION_FIELDS - 1
		$__g_aWebView2_Permissions[$iSlot][$i] = Null
	Next
	Return
EndFunc   ;==>__WebView2_Permission_Clear

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Permission_CancelForView
; Description ...: Completes pending permissions before the owning view is destroyed.
; Syntax ........: __WebView2_Permission_CancelForView($iView)
; Parameters ....: $iView - Owning WebView2 instance ID.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_Destroy
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Permission_CancelForView($iView)
	For $i = 0 To $__WEBVIEW2_MAX_PERMISSION_REQUESTS - 1
		If Not $__g_aWebView2_Permissions[$i][$__WEBVIEW2_PERMISSION_ID] Then ContinueLoop
		If $__g_aWebView2_Permissions[$i][$__WEBVIEW2_PERMISSION_VIEW] <> $iView Then ContinueLoop
		__WebView2_Permission_Abandon($i)
	Next
	Return
EndFunc   ;==>__WebView2_Permission_CancelForView

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Permission_CancelForFrame
; Description ...: Completes pending permissions before their tracked frame is released.
; Syntax ........: __WebView2_Permission_CancelForFrame($iFrame)
; Parameters ....: $iFrame - Tracked frame ID.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: __WebView2_FrameDestroyed_Invoke
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Permission_CancelForFrame($iFrame)
	For $i = 0 To $__WEBVIEW2_MAX_PERMISSION_REQUESTS - 1
		If Not $__g_aWebView2_Permissions[$i][$__WEBVIEW2_PERMISSION_ID] Then ContinueLoop
		If $__g_aWebView2_Permissions[$i][$__WEBVIEW2_PERMISSION_FRAME] <> $iFrame Then ContinueLoop
		__WebView2_Permission_Abandon($i)
	Next
	Return
EndFunc   ;==>__WebView2_Permission_CancelForFrame

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Permission_Abandon
; Description ...: Denies a request being discarded during owner cleanup.
; Syntax ........: __WebView2_Permission_Abandon($iSlot)
; Parameters ....: $iSlot - Permission registry slot.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Always completes the native deferral, even if EventArgs3 is unavailable.
; Related .......: __WebView2_Permission_CancelForView
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Permission_Abandon($iSlot)
	Local $oArgs = $__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_ARGS]
	Local $oDeferral = $__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_DEFERRAL]
	If IsObj($oArgs) Then
		Local $oArgs3 = ObjCreateInterface($__g_aWebView2_Permissions[$iSlot][$__WEBVIEW2_PERMISSION_ARGS_POINTER], $WEBVIEW2_IID_ICoreWebView2PermissionRequestedEventArgs3, $WEBVIEW2_DTAG_ICoreWebView2PermissionRequestedEventArgs3)
		If IsObj($oArgs3) Then
			$oArgs3.AddRef()
			$oArgs3.put_SavesInProfile(False)
		EndIf
		$oArgs.put_State($WEBVIEW2_PERMISSION_STATE_DENY)
	EndIf
	__WebView2_Permission_Clear($iSlot)
	If IsObj($oDeferral) Then $oDeferral.Complete()
	Return
EndFunc   ;==>__WebView2_Permission_Abandon
