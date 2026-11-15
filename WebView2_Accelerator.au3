#include-once
#Tidy_ILC_Pos=44

; #INDEX# =======================================================================================================================
; Title .........: WebView2_Accelerator.au3
; Description ...: Native browser accelerator settings and key event support.
; Author(s) .....: mLipok
; Version .......: 0.6.0
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetBrowserAcceleratorKeysEnabled
; Description ...: Enables or disables WebView2 browser-specific keyboard shortcuts.
; Syntax ........: _WebView2_SetBrowserAcceleratorKeysEnabled($iWebView[, $bEnabled = True])
; Parameters ....: $iWebView - WebView instance ID.
;                  $bEnabled - True to enable browser shortcuts (default); False to disable them.
; Return values .: On Success - True.
;                  On Failure - False and sets @error to $WEBVIEW2_ERR_INVALID_INSTANCE or $WEBVIEW2_ERR_HRESULT.
;                  @extended contains the native HRESULT when available.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Text editing shortcuts remain available. A changed setting may require the next top-level navigation.
; Related .......: _WebView2_SetCallback, $WEBVIEW2_EVENT_ACCELERATOR_KEY_PRESSED
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2settings3
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_SetBrowserAcceleratorKeysEnabled($iWebView, $bEnabled = True)
	Local $bResult = False, $iError = 0, $iExtended = 0
	Local Const $sFuncName = "_WebView2_SetBrowserAcceleratorKeysEnabled"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$iError = $WEBVIEW2_ERR_INVALID_INSTANCE
			$sMessage = "Invalid WebView2 instance."
			ExitLoop 1
		EndIf
		Local $pSettings = 0
		Local $oCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE]
		Local $iResult = $oCore.get_Settings($pSettings)
		If @error Or $iResult <> $WEBVIEW2_S_OK Or Not $pSettings Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			$sMessage = "Unable to access WebView2 settings."
			ExitLoop 1
		EndIf
		Local $oSettings3 = __WebView2_Frame_QueryInterface($pSettings, $WEBVIEW2_IID_ICoreWebView2Settings3, $WEBVIEW2_DTAG_ICoreWebView2Settings3)
		Local $iQueryError = @error, $iQueryExtended = @extended
		__WebView2_Accelerator_Release($pSettings)
		If $iQueryError Or Not IsObj($oSettings3) Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iQueryExtended
			$sMessage = "ICoreWebView2Settings3 is unavailable."
			ExitLoop 1
		EndIf
		$iResult = $oSettings3.put_AreBrowserAcceleratorKeysEnabled($bEnabled ? 1 : 0)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			$sMessage = "Setting browser accelerator keys failed."
			ExitLoop 1
		EndIf
		$bResult = True
	Until True
	If $iError Then __WebView2_Error($sFuncName, $iError, $sMessage, $iExtended)
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_SetBrowserAcceleratorKeysEnabled

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Accelerator_SetCallback
; Description ...: Subscribes an instance to the native accelerator event.
; Syntax ........: __WebView2_Accelerator_SetCallback($iWebView, $fnCallback)
; Parameters ....: $iWebView - WebView instance ID.
;                  $fnCallback - AutoIt callback.
; Return values .: On Success - True; on failure - False with @error and native HRESULT in @extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Accelerator_SetCallback($iWebView, $fnCallback)
	Local $bResult = False, $iError = 0, $iExtended = 0
	Local Const $sFuncName = "__WebView2_Accelerator_SetCallback"
	Local $sMessage = ''
	Do
		If Not $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_TOKEN_ACCELERATOR] Then
			Local $oController = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CONTROLLER]
			Local $tToken = DllStructCreate("int64")
			Local $iResult = $oController.add_AcceleratorKeyPressed(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_ACCELERATOR_KEY_PRESSED), $tToken)
			If @error Or $iResult <> $WEBVIEW2_S_OK Then
				$iError = $WEBVIEW2_ERR_HRESULT
				$iExtended = $iResult
				$sMessage = "AcceleratorKeyPressed subscription failed."
				ExitLoop 1
			EndIf
			$__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_TOKEN_ACCELERATOR] = DllStructGetData($tToken, 1)
		EndIf
		$__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CB_ACCELERATOR] = $fnCallback
		$bResult = True
	Until True
	If $iError Then __WebView2_Error($sFuncName, $iError, $sMessage, $iExtended)
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>__WebView2_Accelerator_SetCallback

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Accelerator_Unsubscribe
; Description ...: Removes the accelerator event subscription before the controller is released.
; Syntax ........: __WebView2_Accelerator_Unsubscribe($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Accelerator_Unsubscribe($iWebView)
	Local $iToken = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_TOKEN_ACCELERATOR]
	If $iToken Then
		Local $oController = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CONTROLLER]
		If IsObj($oController) Then $oController.remove_AcceleratorKeyPressed($iToken)
		$__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_TOKEN_ACCELERATOR] = 0
	EndIf
	$__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CB_ACCELERATOR] = Null
EndFunc   ;==>__WebView2_Accelerator_Unsubscribe

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Accelerator_Invoke
; Description ...: Dispatches the native key event and applies the host's synchronous handled decision.
; Syntax ........: __WebView2_Accelerator_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: $pSelf - Native callback pointer.
;                  $pSender - Controller pointer.
;                  $pArgs - Native event arguments pointer.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......: User callback receives ($iWebView, $iKeyEventKind, $iVirtualKey, $iKeyEventLParam).
;                  Return True to prevent WebView2's default action. Do not block inside the callback.
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2acceleratorkeypressedeventargs
; Example .......: Yes
; ===============================================================================================================================
Func __WebView2_Accelerator_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Do
		Local $iWebView = -1
		For $i = 0 To $WEBVIEW2_MAX_INSTANCES - 1
			If $__g_aWebView2_Instances[$i][$__WEBVIEW2_INSTANCE_USED] And $__g_aWebView2_Instances[$i][$__WEBVIEW2_INSTANCE_CONTROLLER_POINTER] = $pSender Then
				$iWebView = $i
				ExitLoop
			EndIf
		Next
		If $iWebView < 0 Or Not $pArgs Then ExitLoop 1
		Local $fnCallback = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CB_ACCELERATOR]
		If Not IsFunc($fnCallback) Then ExitLoop 1
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2AcceleratorKeyPressedEventArgs, $WEBVIEW2_DTAG_ICoreWebView2AcceleratorKeyPressedEventArgs)
		If Not IsObj($oArgs) Then ExitLoop 1
		; The event argument is borrowed. Match the wrapper's eventual Release with a temporary AddRef.
		$oArgs.AddRef()
		Local $iKind = 0, $iKey = 0, $iLParam = 0
		Local $iResult = $oArgs.get_KeyEventKind($iKind)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then ExitLoop 1
		$iResult = $oArgs.get_VirtualKey($iKey)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then ExitLoop 1
		$iResult = $oArgs.get_KeyEventLParam($iLParam)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then ExitLoop 1
		Local $bHandled = Call($fnCallback, $iWebView, $iKind, $iKey, $iLParam)
		If Not @error And $bHandled = True Then $oArgs.put_Handled(1)
	Until True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_Accelerator_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Accelerator_Release
; Description ...: Releases an unwrapped COM interface pointer returned by get_Settings.
; Syntax ........: __WebView2_Accelerator_Release($pInterface)
; Parameters ....: $pInterface - Native COM interface pointer.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Accelerator_Release($pInterface)
	If Not $pInterface Then Return
	Local $tVTable = DllStructCreate("ptr", $pInterface)
	Local $tRelease = DllStructCreate("ptr[3]", DllStructGetData($tVTable, 1))
	DllCallAddress("ulong", DllStructGetData($tRelease, 1, 3), "ptr", $pInterface)
EndFunc   ;==>__WebView2_Accelerator_Release
