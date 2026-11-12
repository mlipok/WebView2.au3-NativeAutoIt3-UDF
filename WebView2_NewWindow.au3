#include-once
#Tidy_ILC_Pos=44

; Deferred NewWindowRequested handoff. A request must be completed or cancelled.
Global Enum _
		$__WEBVIEW2_NEW_WINDOW_ID, _
		$__WEBVIEW2_NEW_WINDOW_SOURCE, _
		$__WEBVIEW2_NEW_WINDOW_ARGS, _
		$__WEBVIEW2_NEW_WINDOW_DEFERRAL, _
		$__WEBVIEW2_NEW_WINDOW_URI, _
		$__WEBVIEW2_NEW_WINDOW_USER, _
		$__WEBVIEW2_NEW_WINDOW_FIELDS
Global $__g_aWebView2_NewWindows[$WEBVIEW2_MAX_INSTANCES][$__WEBVIEW2_NEW_WINDOW_FIELDS]
Global $__g_iWebView2_NextNewWindowId = 1

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_NewWindow_Find
; Description ...: Finds a live deferred request by its public ID.
; ===============================================================================================================================
Func __WebView2_NewWindow_Find($iRequest)
	Local $iResult = -1
	For $i = 0 To $WEBVIEW2_MAX_INSTANCES - 1
		If $__g_aWebView2_NewWindows[$i][$__WEBVIEW2_NEW_WINDOW_ID] = $iRequest And $iRequest > 0 Then
			$iResult = $i
			ExitLoop
		EndIf
	Next
	Return $iResult
EndFunc   ;==>__WebView2_NewWindow_Find

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_NewWindow_Defer
; Description ...: Retains the event arguments and a native deferral for later handoff.
; ===============================================================================================================================
Func __WebView2_NewWindow_Defer($iSource, $oArgs, $sURI, $bUserInitiated)
	Local $bResult = False
	Do
		Local $iSlot = -1
		For $i = 0 To $WEBVIEW2_MAX_INSTANCES - 1
			If Not $__g_aWebView2_NewWindows[$i][$__WEBVIEW2_NEW_WINDOW_ID] Then
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
		$__g_aWebView2_NewWindows[$iSlot][$__WEBVIEW2_NEW_WINDOW_ID] = $__g_iWebView2_NextNewWindowId
		$__g_aWebView2_NewWindows[$iSlot][$__WEBVIEW2_NEW_WINDOW_SOURCE] = $iSource
		$__g_aWebView2_NewWindows[$iSlot][$__WEBVIEW2_NEW_WINDOW_ARGS] = $oArgs
		$__g_aWebView2_NewWindows[$iSlot][$__WEBVIEW2_NEW_WINDOW_DEFERRAL] = $oDeferral
		$__g_aWebView2_NewWindows[$iSlot][$__WEBVIEW2_NEW_WINDOW_URI] = $sURI
		$__g_aWebView2_NewWindows[$iSlot][$__WEBVIEW2_NEW_WINDOW_USER] = $bUserInitiated
		$__g_iWebView2_NextNewWindowId += 1
		$bResult = True
	Until True
	Return $bResult
EndFunc   ;==>__WebView2_NewWindow_Defer

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_NewWindow_Request_List
; Description ...: Lists pending native new-window request IDs.
; Syntax ........: _WebView2_NewWindow_Request_List([$iSource = Default])
; Parameters ....: $iSource - Optional originating WebView2 instance ID.
; Return values .: One-dimensional array: element 0 is the count; following elements are request IDs.
; Author ........: mLipok
; Modified ......:
; Remarks .......: A deferred request remains pending until Complete, Cancel or source cleanup.
; Related .......: _WebView2_NewWindow_Request_GetInfo, _WebView2_NewWindow_Complete
; ===============================================================================================================================
Func _WebView2_NewWindow_Request_List($iSource = Default)
	Local $aResult[$WEBVIEW2_MAX_INSTANCES + 1], $iCount = 0
	For $i = 0 To $WEBVIEW2_MAX_INSTANCES - 1
		If Not $__g_aWebView2_NewWindows[$i][$__WEBVIEW2_NEW_WINDOW_ID] Then ContinueLoop
		If $iSource <> Default And $__g_aWebView2_NewWindows[$i][$__WEBVIEW2_NEW_WINDOW_SOURCE] <> $iSource Then ContinueLoop
		$iCount += 1
		$aResult[$iCount] = $__g_aWebView2_NewWindows[$i][$__WEBVIEW2_NEW_WINDOW_ID]
	Next
	$aResult[0] = $iCount
	ReDim $aResult[$iCount + 1]
	Return $aResult
EndFunc   ;==>_WebView2_NewWindow_Request_List

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_NewWindow_Request_GetInfo
; Description ...: Reads the origin, target URI and user-gesture flag of a pending request.
; Syntax ........: _WebView2_NewWindow_Request_GetInfo($iRequest)
; Parameters ....: $iRequest - ID returned by _WebView2_NewWindow_Request_List().
; Return values .: Array [$iSource, $sURI, $bUserInitiated]; empty array with @error on failure.
; Author ........: mLipok
; Modified ......:
; ===============================================================================================================================
Func _WebView2_NewWindow_Request_GetInfo($iRequest)
	Local $aResult[0], $iError = 0
	Local $iSlot = __WebView2_NewWindow_Find($iRequest)
	If $iSlot < 0 Then
		$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
	Else
		ReDim $aResult[3]
		$aResult[0] = $__g_aWebView2_NewWindows[$iSlot][$__WEBVIEW2_NEW_WINDOW_SOURCE]
		$aResult[1] = $__g_aWebView2_NewWindows[$iSlot][$__WEBVIEW2_NEW_WINDOW_URI]
		$aResult[2] = $__g_aWebView2_NewWindows[$iSlot][$__WEBVIEW2_NEW_WINDOW_USER]
	EndIf
	Return SetError($iError, 0, $aResult)
EndFunc   ;==>_WebView2_NewWindow_Request_GetInfo

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_NewWindow_Complete
; Description ...: Supplies an untouched controller to the opener and completes its deferral.
; Syntax ........: _WebView2_NewWindow_Complete($iRequest, $iNewWebView)
; Parameters ....: $iRequest - Pending request ID.
;                  $iNewWebView - Fresh instance created in the same WebView2 environment.
; Return values .: True on success; False with @error and native HRESULT in @extended on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Create the target after the event callback returns. Do not navigate it before this call.
; Related .......: _WebView2_NewWindow_Request_List, _WebView2_NewWindow_Cancel
; ===============================================================================================================================
Func _WebView2_NewWindow_Complete($iRequest, $iNewWebView)
	Local $bResult = False, $iError = 0, $iExtended = 0
	Do
		Local $iSlot = __WebView2_NewWindow_Find($iRequest)
		If $iSlot < 0 Or Not __WebView2_Instance_IsValid($iNewWebView) Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		If $iNewWebView = $__g_aWebView2_NewWindows[$iSlot][$__WEBVIEW2_NEW_WINDOW_SOURCE] Or _
				Not $__g_aWebView2_Instances[$iNewWebView][$__WEBVIEW2_INSTANCE_NEW_WINDOW_FRESH] Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $oArgs = $__g_aWebView2_NewWindows[$iSlot][$__WEBVIEW2_NEW_WINDOW_ARGS]
		Local $oDeferral = $__g_aWebView2_NewWindows[$iSlot][$__WEBVIEW2_NEW_WINDOW_DEFERRAL]
		Local $iHRESULT = $oArgs.put_NewWindow($__g_aWebView2_Instances[$iNewWebView][$__WEBVIEW2_INSTANCE_CORE_POINTER])
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iHRESULT
			ExitLoop 1
		EndIf
		$__g_aWebView2_Instances[$iNewWebView][$__WEBVIEW2_INSTANCE_NEW_WINDOW_FRESH] = False
		$iHRESULT = $oDeferral.Complete()
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iHRESULT
		EndIf
		__WebView2_NewWindow_Clear($iSlot)
		$bResult = ($iError = 0)
	Until True
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_NewWindow_Complete

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_NewWindow_Cancel
; Description ...: Blocks a deferred popup and completes its deferral.
; Syntax ........: _WebView2_NewWindow_Cancel($iRequest)
; Parameters ....: $iRequest - Pending request ID.
; Return values .: True on success; False with @error on failure.
; Author ........: mLipok
; Modified ......:
; ===============================================================================================================================
Func _WebView2_NewWindow_Cancel($iRequest)
	Local $bResult = False, $iError = 0, $iExtended = 0
	Do
		Local $iSlot = __WebView2_NewWindow_Find($iRequest)
		If $iSlot < 0 Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $oArgs = $__g_aWebView2_NewWindows[$iSlot][$__WEBVIEW2_NEW_WINDOW_ARGS]
		Local $oDeferral = $__g_aWebView2_NewWindows[$iSlot][$__WEBVIEW2_NEW_WINDOW_DEFERRAL]
		Local $iHRESULT = $oArgs.put_Handled(True)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iHRESULT
		EndIf
		$iHRESULT = $oDeferral.Complete()
		If (@error Or $iHRESULT <> $WEBVIEW2_S_OK) And Not $iError Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iHRESULT
		EndIf
		__WebView2_NewWindow_Clear($iSlot)
		$bResult = ($iError = 0)
	Until True
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_NewWindow_Cancel

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_NewWindow_Clear
; Description ...: Releases one completed or cancelled pending request.
; ===============================================================================================================================
Func __WebView2_NewWindow_Clear($iSlot)
	For $i = 0 To $__WEBVIEW2_NEW_WINDOW_FIELDS - 1
		$__g_aWebView2_NewWindows[$iSlot][$i] = Null
	Next
	Return
EndFunc   ;==>__WebView2_NewWindow_Clear

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_NewWindow_CancelForSource
; Description ...: Completes pending requests before their source controller is destroyed.
; ===============================================================================================================================
Func __WebView2_NewWindow_CancelForSource($iSource)
	For $i = 0 To $WEBVIEW2_MAX_INSTANCES - 1
		If $__g_aWebView2_NewWindows[$i][$__WEBVIEW2_NEW_WINDOW_ID] And _
				$__g_aWebView2_NewWindows[$i][$__WEBVIEW2_NEW_WINDOW_SOURCE] = $iSource Then _
				_WebView2_NewWindow_Cancel($__g_aWebView2_NewWindows[$i][$__WEBVIEW2_NEW_WINDOW_ID])
	Next
	Return
EndFunc   ;==>__WebView2_NewWindow_CancelForSource
