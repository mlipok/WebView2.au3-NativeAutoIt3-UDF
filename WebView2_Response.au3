#include-once
#Tidy_ILC_Pos=44

; #INDEX# =======================================================================================================================
; Title .........: WebView2_Response.au3
; Description ...: Native WebView2 resource response notifications.
; Author(s) .....: mLipok
; Version .......: 0.6.0
; ===============================================================================================================================

Global $__g_aWebView2_ResponseCore2[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_ResponseToken[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_ResponseCallback[$WEBVIEW2_MAX_INSTANCES]

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Response_SetCallback
; Description ...: Subscribes to WebResourceResponseReceived and stores the user callback.
; Syntax ........: __WebView2_Response_SetCallback($iWebView, $fnCallback)
; Parameters ....: $iWebView - WebView2 instance ID.
;                  $fnCallback - Response callback.
; Return values .: True on success, False with @error on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Register before navigation to include the document response.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Response_SetCallback($iWebView, $fnCallback)
	Local $iError = 0, $iExtended = 0
	Do
		If Not $__g_aWebView2_ResponseToken[$iWebView] Then
			If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_WEB_RESOURCE_RESPONSE) Then
				If Not __WebView2_Callback_Create($__WEBVIEW2_CB_WEB_RESOURCE_RESPONSE, __WebView2_Response_Invoke, "ptr;ptr;ptr") Then
					$iError = $WEBVIEW2_ERR_CALLBACK
					ExitLoop
				EndIf
			EndIf
			Local $pCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE_POINTER]
			Local $oCore2 = __WebView2_Frame_QueryInterface($pCore, $WEBVIEW2_IID_ICoreWebView2_2, $WEBVIEW2_DTAG_ICoreWebView2_2)
			$iError = @error
			$iExtended = @extended
			If $iError Then ExitLoop
			Local $tToken = DllStructCreate("int64")
			Local $iResult = $oCore2.add_WebResourceResponseReceived(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_WEB_RESOURCE_RESPONSE), $tToken)
			If @error Or $iResult <> $WEBVIEW2_S_OK Then
				$iError = $WEBVIEW2_ERR_HRESULT
				$iExtended = $iResult
				ExitLoop
			EndIf
			$__g_aWebView2_ResponseCore2[$iWebView] = $oCore2
			$__g_aWebView2_ResponseToken[$iWebView] = DllStructGetData($tToken, 1)
		EndIf
		$__g_aWebView2_ResponseCallback[$iWebView] = $fnCallback
	Until True
	Return SetError($iError, $iExtended, $iError = 0)
EndFunc   ;==>__WebView2_Response_SetCallback

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Response_Invoke
; Description ...: Reads request URI/method and response status/reason from a native event.
; Syntax ........: __WebView2_Response_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: $pSelf - Event handler COM pointer.
;                  $pSender - Core WebView2 COM pointer.
;                  $pArgs - Response event argument pointer.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The callback must not block navigation or perform synchronous browser calls.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Response_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Do
		Local $iView = __WebView2_Instance_FindByCorePointer($pSender)
		If $iView < 0 Or Not $pArgs Then ExitLoop
		Local $fnCallback = $__g_aWebView2_ResponseCallback[$iView]
		If Not IsFunc($fnCallback) Then ExitLoop
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2WebResourceResponseReceivedEventArgs, $WEBVIEW2_DTAG_ICoreWebView2WebResourceResponseReceivedEventArgs)
		If Not IsObj($oArgs) Then ExitLoop
		$oArgs.AddRef()
		Local $pRequest = 0, $pResponse = 0
		Local $iResult = $oArgs.get_Request($pRequest)
		If @error Or $iResult <> $WEBVIEW2_S_OK Or Not $pRequest Then ExitLoop
		$iResult = $oArgs.get_Response($pResponse)
		If @error Or $iResult <> $WEBVIEW2_S_OK Or Not $pResponse Then ExitLoop
		Local $oRequest = ObjCreateInterface($pRequest, $WEBVIEW2_IID_ICoreWebView2WebResourceRequest, $WEBVIEW2_DTAG_ICoreWebView2WebResourceRequest)
		Local $oResponse = ObjCreateInterface($pResponse, $WEBVIEW2_IID_ICoreWebView2WebResourceResponseView, $WEBVIEW2_DTAG_ICoreWebView2WebResourceResponseView)
		If Not IsObj($oRequest) Or Not IsObj($oResponse) Then ExitLoop
		$oRequest.AddRef()
		$oResponse.AddRef()
		Local $pURI = 0, $pMethod = 0, $pReason = 0, $iStatus = 0
		$iResult = $oRequest.get_Uri($pURI)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then ExitLoop
		Local $sURI = __WebView2_CoTaskMemString_ReadAndFree($pURI)
		$iResult = $oRequest.get_Method($pMethod)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then ExitLoop
		Local $sMethod = __WebView2_CoTaskMemString_ReadAndFree($pMethod)
		$iResult = $oResponse.get_StatusCode($iStatus)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then ExitLoop
		$iResult = $oResponse.get_ReasonPhrase($pReason)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then ExitLoop
		Local $sReason = __WebView2_CoTaskMemString_ReadAndFree($pReason)
		Call($fnCallback, $iView, $sURI, $sMethod, $iStatus, $sReason)
	Until True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_Response_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Response_Cleanup
; Description ...: Unsubscribes the native response event before destroying its instance.
; Syntax ........: __WebView2_Response_Cleanup($iWebView)
; Parameters ....: $iWebView - WebView2 instance ID.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_Cleanup
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Response_Cleanup($iWebView)
	If IsObj($__g_aWebView2_ResponseCore2[$iWebView]) And $__g_aWebView2_ResponseToken[$iWebView] Then $__g_aWebView2_ResponseCore2[$iWebView].remove_WebResourceResponseReceived($__g_aWebView2_ResponseToken[$iWebView])
	$__g_aWebView2_ResponseCore2[$iWebView] = Null
	$__g_aWebView2_ResponseToken[$iWebView] = 0
	$__g_aWebView2_ResponseCallback[$iWebView] = Null
	Return
EndFunc   ;==>__WebView2_Response_Cleanup
