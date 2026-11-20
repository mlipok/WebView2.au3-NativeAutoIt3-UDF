#include-once
#Tidy_ILC_Pos=44

Global $__g_iWebView2_NavigationMetadataView = -1
Global $__g_oWebView2_NavigationMetadataArgs = Null
Global $__g_pWebView2_NavigationMetadataArgs = 0

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetNavigationStartingMetadata
; Description ...: Copies metadata from the currently executing navigation-start callback.
; Syntax ........: _WebView2_GetNavigationStartingMetadata($iWebView)
; Parameters ....: $iWebView - Instance ID passed to the top-level or frame navigation callback.
; Return values .: On Success - Array [navigationId, navigationKind, headers]. Each unavailable field is Null.
;                  Headers is a two-column array [name, value] with one row per native entry.
;                  On Failure - Null with @error $WEBVIEW2_ERR_INVALID_INSTANCE for an invalid instance, or
;                    $WEBVIEW2_ERR_NO_MATCH outside its active navigation-start callback.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Copied values may be retained after the callback returns. Headers are read-only.
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2navigationstartingeventargs
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetNavigationStartingMetadata($iWebView)
	If Not __WebView2_Instance_IsValid($iWebView) Then Return SetError($WEBVIEW2_ERR_INVALID_INSTANCE, 0, Null)
	If $iWebView <> $__g_iWebView2_NavigationMetadataView Or Not IsObj($__g_oWebView2_NavigationMetadataArgs) Then Return SetError($WEBVIEW2_ERR_NO_MATCH, 0, Null)
	Local $oArgs = $__g_oWebView2_NavigationMetadataArgs
	Local $pArgs = $__g_pWebView2_NavigationMetadataArgs
	Local $aMetadata[3] = [Null, Null, Null]
	Local $iNavigationID = 0
	Local $iResult = $oArgs.get_NavigationId($iNavigationID)
	If Not @error And $iResult = $WEBVIEW2_S_OK Then $aMetadata[$WEBVIEW2_NAVIGATION_METADATA_ID] = $iNavigationID
	Local $oArgs3 = __WebView2_Frame_QueryInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2NavigationStartingEventArgs3, $WEBVIEW2_DTAG_ICoreWebView2NavigationStartingEventArgs3)
	If IsObj($oArgs3) Then
		Local $iKind = 0
		$iResult = $oArgs3.get_NavigationKind($iKind)
		If Not @error And $iResult = $WEBVIEW2_S_OK Then $aMetadata[$WEBVIEW2_NAVIGATION_METADATA_KIND] = $iKind
	EndIf
	$aMetadata[$WEBVIEW2_NAVIGATION_METADATA_HEADERS] = __WebView2_NavigationMetadata_ReadHeaders($oArgs)
	Return SetError(0, 0, $aMetadata)
EndFunc   ;==>_WebView2_GetNavigationStartingMetadata

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_NavigationMetadata_Dispatch
; Description ...: Supplies the borrowed event context while the existing callback executes.
; Syntax ........: __WebView2_NavigationMetadata_Dispatch($fnCallback, $iView, $iFrame, $oArgs, $pArgs, $sURI, $bUserInitiated, $bRedirected)
; Parameters ....: $fnCallback - Registered AutoIt callback.
;                  $iView - Instance ID.
;                  $iFrame - Frame ID, or -1 for the top-level callback.
;                  $oArgs, $pArgs - Held wrapper and borrowed native event arguments pointer.
;                  $sURI, $bUserInitiated, $bRedirected - Existing callback arguments.
; Return values .: Callback value, @error and @extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: A nested navigation callback restores the preceding context on return.
; Related .......: _WebView2_GetNavigationStartingMetadata
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_NavigationMetadata_Dispatch($fnCallback, $iView, $iFrame, $oArgs, $pArgs, $sURI, $bUserInitiated, $bRedirected)
	Local $iPreviousView = $__g_iWebView2_NavigationMetadataView
	Local $oPreviousArgs = $__g_oWebView2_NavigationMetadataArgs
	Local $pPreviousArgs = $__g_pWebView2_NavigationMetadataArgs
	$__g_iWebView2_NavigationMetadataView = $iView
	$__g_oWebView2_NavigationMetadataArgs = $oArgs
	$__g_pWebView2_NavigationMetadataArgs = $pArgs
	Local $vCancel, $iCallbackError, $iCallbackExtended
	If $iFrame = -1 Then
		$vCancel = Call($fnCallback, $iView, $sURI, $bUserInitiated, $bRedirected)
		$iCallbackError = @error
		$iCallbackExtended = @extended
	Else
		$vCancel = Call($fnCallback, $iView, $iFrame, $sURI, $bUserInitiated, $bRedirected)
		$iCallbackError = @error
		$iCallbackExtended = @extended
	EndIf
	$__g_iWebView2_NavigationMetadataView = $iPreviousView
	$__g_oWebView2_NavigationMetadataArgs = $oPreviousArgs
	$__g_pWebView2_NavigationMetadataArgs = $pPreviousArgs
	Return SetError($iCallbackError, $iCallbackExtended, $vCancel)
EndFunc   ;==>__WebView2_NavigationMetadata_Dispatch

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_NavigationMetadata_ReadHeaders
; Description ...: Copies request headers from the native read-only collection.
; Syntax ........: __WebView2_NavigationMetadata_ReadHeaders($oArgs)
; Parameters ....: $oArgs - Navigation-start event wrapper.
; Return values .: A two-column array, or Null if the collection cannot be read.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Preserves native iteration order and duplicate names.
; Related .......: _WebView2_GetNavigationStartingMetadata
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_NavigationMetadata_ReadHeaders($oArgs)
	Local $pHeaders = 0
	Local $iResult = $oArgs.get_RequestHeaders($pHeaders)
	If @error Or $iResult <> $WEBVIEW2_S_OK Or Not $pHeaders Then Return Null
	Local $oHeaders = ObjCreateInterface($pHeaders, $WEBVIEW2_IID_ICoreWebView2HttpRequestHeaders, $WEBVIEW2_DTAG_ICoreWebView2HttpRequestHeaders)
	If Not IsObj($oHeaders) Then
		__WebView2_Ext_Release($pHeaders)
		Return Null
	EndIf
	Local $pIterator = 0
	$iResult = $oHeaders.GetIterator($pIterator)
	If @error Or $iResult <> $WEBVIEW2_S_OK Or Not $pIterator Then Return Null
	Local $oIterator = ObjCreateInterface($pIterator, $WEBVIEW2_IID_ICoreWebView2HttpHeadersCollectionIterator, $WEBVIEW2_DTAG_ICoreWebView2HttpHeadersCollectionIterator)
	If Not IsObj($oIterator) Then
		__WebView2_Ext_Release($pIterator)
		Return Null
	EndIf
	Local $iHasCurrent = 0
	$iResult = $oIterator.get_HasCurrentHeader($iHasCurrent)
	If @error Or $iResult <> $WEBVIEW2_S_OK Then Return Null
	Local $iCount = 0, $aHeaders[8][2]
	While $iHasCurrent
		Local $pName = 0, $pValue = 0
		$iResult = $oIterator.GetCurrentHeader($pName, $pValue)
		Local $iReadError = @error
		Local $sName = __WebView2_CoTaskMemString_ReadAndFree($pName)
		Local $sValue = __WebView2_CoTaskMemString_ReadAndFree($pValue)
		If $iReadError Or $iResult <> $WEBVIEW2_S_OK Then Return Null
		If $iCount = UBound($aHeaders) Then ReDim $aHeaders[$iCount * 2][2]
		$aHeaders[$iCount][0] = $sName
		$aHeaders[$iCount][1] = $sValue
		$iCount += 1
		$iResult = $oIterator.MoveNext($iHasCurrent)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then Return Null
	WEnd
	ReDim $aHeaders[$iCount][2]
	Return $aHeaders
EndFunc   ;==>__WebView2_NavigationMetadata_ReadHeaders
