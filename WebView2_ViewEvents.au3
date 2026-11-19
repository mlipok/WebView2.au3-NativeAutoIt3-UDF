#include-once
#Tidy_ILC_Pos=44

; Event IDs are consecutive from SOURCE_CHANGED to LOST_FOCUS.
Global Const $__WEBVIEW2_VIEW_EVENT_COUNT = $WEBVIEW2_EVENT_LOST_FOCUS - $WEBVIEW2_EVENT_SOURCE_CHANGED + 1
Global $__g_aWebView2_ViewEventCallbacks[$WEBVIEW2_MAX_INSTANCES][$__WEBVIEW2_VIEW_EVENT_COUNT]
Global $__g_aWebView2_ViewEventTokens[$WEBVIEW2_MAX_INSTANCES][$__WEBVIEW2_VIEW_EVENT_COUNT]

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_ViewEvents_Subscribe
; Description ...: Registers one optional native event for a view.
; Syntax ........: __WebView2_ViewEvents_Subscribe($iView, $iEvent, $fnCallback)
; Parameters ....: $iView - Valid instance slot.
;                  $iEvent - A native view-event constant.
;                  $fnCallback - AutoIt function reference.
; Return values .: True on success. False sets CALLBACK or HRESULT in @error.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Replacing a callback reuses the native subscription.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ViewEvents_Subscribe($iView, $iEvent, $fnCallback)
	Local $iIndex = $iEvent - $WEBVIEW2_EVENT_SOURCE_CHANGED
	If Not IsFunc($__g_aWebView2_ViewEventCallbacks[$iView][$iIndex]) Then
		Local $iCallbackSlot = $__WEBVIEW2_CB_SOURCE_CHANGED + $iIndex
		Local $fnNative = Null
		Switch $iEvent
			Case $WEBVIEW2_EVENT_SOURCE_CHANGED
				$fnNative = __WebView2_ViewEvents_SourceChanged
			Case $WEBVIEW2_EVENT_ZOOM_FACTOR_CHANGED
				$fnNative = __WebView2_ViewEvents_ZoomFactorChanged
			Case $WEBVIEW2_EVENT_GOT_FOCUS
				$fnNative = __WebView2_ViewEvents_GotFocus
			Case $WEBVIEW2_EVENT_LOST_FOCUS
				$fnNative = __WebView2_ViewEvents_LostFocus

		EndSwitch
		Local $pHandler = __WebView2_Callback_GetPointer($iCallbackSlot)
		If Not $pHandler Then
			If Not __WebView2_Callback_Create($iCallbackSlot, $fnNative, "ptr;ptr;ptr") Then Return SetError($WEBVIEW2_ERR_CALLBACK, 0, False)
			$pHandler = __WebView2_Callback_GetPointer($iCallbackSlot)
		EndIf
		Local $tToken = DllStructCreate("int64")
		Local $oCore = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_CORE]
		Local $oController = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_CONTROLLER]
		Local $iResult = 0
		Switch $iEvent
			Case $WEBVIEW2_EVENT_SOURCE_CHANGED
				$iResult = $oCore.add_SourceChanged($pHandler, $tToken)
				If @error Or $iResult <> $WEBVIEW2_S_OK Then Return SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)
			Case $WEBVIEW2_EVENT_ZOOM_FACTOR_CHANGED
				$iResult = $oController.add_ZoomFactorChanged($pHandler, $tToken)
				If @error Or $iResult <> $WEBVIEW2_S_OK Then Return SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)
			Case $WEBVIEW2_EVENT_GOT_FOCUS
				$iResult = $oController.add_GotFocus($pHandler, $tToken)
				If @error Or $iResult <> $WEBVIEW2_S_OK Then Return SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)
			Case $WEBVIEW2_EVENT_LOST_FOCUS
				$iResult = $oController.add_LostFocus($pHandler, $tToken)
				If @error Or $iResult <> $WEBVIEW2_S_OK Then Return SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)

		EndSwitch
		$__g_aWebView2_ViewEventTokens[$iView][$iIndex] = DllStructGetData($tToken, 1)
	EndIf
	$__g_aWebView2_ViewEventCallbacks[$iView][$iIndex] = $fnCallback
	Return SetError(0, 0, True)
EndFunc   ;==>__WebView2_ViewEvents_Subscribe

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_ViewEvents_Cleanup
; Description ...: Clears callbacks and removes native subscriptions before closing the view.
; Syntax ........: __WebView2_ViewEvents_Cleanup($iView)
; Parameters ....: $iView - Instance slot.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ViewEvents_Cleanup($iView)
	Local $oCore = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_CORE]
	Local $oController = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_CONTROLLER]
	For $iIndex = 0 To $__WEBVIEW2_VIEW_EVENT_COUNT - 1
		If Not IsFunc($__g_aWebView2_ViewEventCallbacks[$iView][$iIndex]) Then ContinueLoop
		Local $iToken = $__g_aWebView2_ViewEventTokens[$iView][$iIndex]
		$__g_aWebView2_ViewEventCallbacks[$iView][$iIndex] = Null
		$__g_aWebView2_ViewEventTokens[$iView][$iIndex] = 0
		Switch $WEBVIEW2_EVENT_SOURCE_CHANGED + $iIndex
			Case $WEBVIEW2_EVENT_SOURCE_CHANGED
				If IsObj($oCore) Then $oCore.remove_SourceChanged($iToken)
			Case $WEBVIEW2_EVENT_ZOOM_FACTOR_CHANGED
				If IsObj($oController) Then $oController.remove_ZoomFactorChanged($iToken)
			Case $WEBVIEW2_EVENT_GOT_FOCUS
				If IsObj($oController) Then $oController.remove_GotFocus($iToken)
			Case $WEBVIEW2_EVENT_LOST_FOCUS
				If IsObj($oController) Then $oController.remove_LostFocus($iToken)

		EndSwitch
	Next
EndFunc   ;==>__WebView2_ViewEvents_Cleanup

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_ViewEvents_SourceChanged
; Description ...: Copies the top-level URI and native document-change flag.
; Syntax ........: __WebView2_ViewEvents_SourceChanged($pSelf, $pSender, $pArgs)
; Parameters ....: $pSelf - Handler pointer.
;                  $pSender - Core WebView pointer.
;                  $pArgs - Borrowed event arguments.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ViewEvents_SourceChanged($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Local $iView = __WebView2_Instance_FindByCorePointer($pSender)
	If $iView < 0 Or Not $pArgs Then Return $WEBVIEW2_S_OK
	Local $fnCallback = $__g_aWebView2_ViewEventCallbacks[$iView][0]
	If Not IsFunc($fnCallback) Then Return $WEBVIEW2_S_OK
	Local $oArgs = __WebView2_Frame_QueryInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2SourceChangedEventArgs, $WEBVIEW2_DTAG_ICoreWebView2SourceChangedEventArgs)
	If @error Then Return $WEBVIEW2_S_OK
	Local $iNewDocument = 0
	Local $iResult = $oArgs.get_IsNewDocument($iNewDocument)
	If @error Or $iResult <> $WEBVIEW2_S_OK Then Return $WEBVIEW2_S_OK
	$oArgs = Null
	Local $oCore = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_CORE]
	Local $pURI = 0
	$iResult = $oCore.get_Source($pURI)
	If @error Or $iResult <> $WEBVIEW2_S_OK Then Return $WEBVIEW2_S_OK
	Local $sURI = __WebView2_CoTaskMemString_ReadAndFree($pURI)
	Call($fnCallback, $iView, $sURI, $iNewDocument <> 0)
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_ViewEvents_SourceChanged

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_ViewEvents_ZoomFactorChanged
; Description ...: Dispatches ZoomFactorChanged from the controller.
; Syntax ........: __WebView2_ViewEvents_ZoomFactorChanged($pSelf, $pSender, $pArgs)
; Parameters ....: $pSelf - Handler pointer.
;                  $pSender - Controller pointer.
;                  $pArgs - Unused event arguments.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ViewEvents_ZoomFactorChanged($pSelf, $pSender, $pArgs)
	#forceref $pSelf, $pArgs
	Return __WebView2_ViewEvents_Controller($pSender, $WEBVIEW2_EVENT_ZOOM_FACTOR_CHANGED)
EndFunc   ;==>__WebView2_ViewEvents_ZoomFactorChanged

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_ViewEvents_GotFocus
; Description ...: Dispatches GotFocus from the controller.
; Syntax ........: __WebView2_ViewEvents_GotFocus($pSelf, $pSender, $pArgs)
; Parameters ....: $pSelf - Handler pointer.
;                  $pSender - Controller pointer.
;                  $pArgs - Unused event arguments.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ViewEvents_GotFocus($pSelf, $pSender, $pArgs)
	#forceref $pSelf, $pArgs
	Return __WebView2_ViewEvents_Controller($pSender, $WEBVIEW2_EVENT_GOT_FOCUS)
EndFunc   ;==>__WebView2_ViewEvents_GotFocus

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_ViewEvents_LostFocus
; Description ...: Dispatches LostFocus from the controller.
; Syntax ........: __WebView2_ViewEvents_LostFocus($pSelf, $pSender, $pArgs)
; Parameters ....: $pSelf - Handler pointer.
;                  $pSender - Controller pointer.
;                  $pArgs - Unused event arguments.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ViewEvents_LostFocus($pSelf, $pSender, $pArgs)
	#forceref $pSelf, $pArgs
	Return __WebView2_ViewEvents_Controller($pSender, $WEBVIEW2_EVENT_LOST_FOCUS)
EndFunc   ;==>__WebView2_ViewEvents_LostFocus

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_ViewEvents_Controller
; Description ...: Resolves the controller owner and dispatches its native notification.
; Syntax ........: __WebView2_ViewEvents_Controller($pSender, $iEvent)
; Parameters ....: $pSender - Controller pointer.
;                  $iEvent - Controller event constant.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ViewEvents_Controller($pSender, $iEvent)
	If Not $pSender Then Return $WEBVIEW2_S_OK
	Local $iIndex = $iEvent - $WEBVIEW2_EVENT_SOURCE_CHANGED
	For $iView = 0 To $WEBVIEW2_MAX_INSTANCES - 1
		If Not $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_USED] Then ContinueLoop
		If $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_CONTROLLER_POINTER] <> $pSender Then ContinueLoop
		Local $fnCallback = $__g_aWebView2_ViewEventCallbacks[$iView][$iIndex]
		If Not IsFunc($fnCallback) Then ExitLoop
		If $iEvent = $WEBVIEW2_EVENT_ZOOM_FACTOR_CHANGED Then
			Local $oController = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_CONTROLLER]
			Local $fZoomFactor = 0.0
			Local $iResult = $oController.get_ZoomFactor($fZoomFactor)
			If @error Or $iResult <> $WEBVIEW2_S_OK Then ExitLoop
			Call($fnCallback, $iView, $fZoomFactor)
		Else
			Call($fnCallback, $iView)
		EndIf
		ExitLoop
	Next
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_ViewEvents_Controller
