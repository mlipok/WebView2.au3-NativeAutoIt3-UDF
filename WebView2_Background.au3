#include-once
#Tidy_ILC_Pos=44

; #INDEX# =======================================================================================================================
; Title .........: WebView2_Background.au3
; Description ...: Native WebView2 controller default background color.
; Author(s) .....: mLipok
; Version .......: 0.6.0
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetDefaultBackgroundColor
; Description ...: Sets the color rendered underneath web content in one WebView2 instance.
; Syntax ........: _WebView2_SetDefaultBackgroundColor($iWebView, $iRGB[, $iAlpha = 255])
; Parameters ....: $iWebView - WebView instance ID.
;                  $iRGB - RGB color in 0xRRGGBB format.
;                  $iAlpha - 255 for opaque (default), or 0 for fully transparent.
; Return values .: On Success - True.
;                  On Failure - False and sets @error to one of the following:
;                    $WEBVIEW2_ERR_INVALID_INSTANCE = Invalid WebView2 instance.
;                    $WEBVIEW2_ERR_INVALID_PARAMETER = Invalid RGB value or alpha.
;                    $WEBVIEW2_ERR_HRESULT = Controller2 is unavailable or the native call failed.
;                  @extended contains the native HRESULT when available.
; Author ........: mLipok
; Modified ......:
; Remarks .......: A page with an opaque CSS background hides this color. Setting it after controller creation may allow an initial white flash.
; Related .......: _WebView2_GetDefaultBackgroundColor
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2controller2
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_SetDefaultBackgroundColor($iWebView, $iRGB, $iAlpha = 255)
	Local $bResult = False, $iError = 0, $iExtended = 0
	Local Const $sFuncName = "_WebView2_SetDefaultBackgroundColor"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$iError = $WEBVIEW2_ERR_INVALID_INSTANCE
			$sMessage = "Invalid WebView2 instance."
			ExitLoop 1
		EndIf
		If Not IsInt($iRGB) Or $iRGB < 0 Or $iRGB > 0xFFFFFF Or Not IsInt($iAlpha) Or ($iAlpha <> 0 And $iAlpha <> 255) Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			$sMessage = "RGB must be 0x000000 through 0xFFFFFF; alpha must be 0 or 255."
			ExitLoop 1
		EndIf
		Local $pController = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CONTROLLER_POINTER]
		Local $oController2 = __WebView2_Frame_QueryInterface($pController, $WEBVIEW2_IID_ICoreWebView2Controller2, $WEBVIEW2_DTAG_ICoreWebView2Controller2)
		Local $iQueryError = @error, $iQueryExtended = @extended
		If $iQueryError Or Not IsObj($oController2) Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iQueryExtended
			$sMessage = "ICoreWebView2Controller2 is unavailable."
			ExitLoop 1
		EndIf
		Local $tColor = DllStructCreate("byte A;byte R;byte G;byte B")
		DllStructSetData($tColor, "A", $iAlpha)
		DllStructSetData($tColor, "R", BitAND(BitShift($iRGB, 16), 0xFF))
		DllStructSetData($tColor, "G", BitAND(BitShift($iRGB, 8), 0xFF))
		DllStructSetData($tColor, "B", BitAND($iRGB, 0xFF))
		Local $tPacked = DllStructCreate("uint", DllStructGetPtr($tColor))
		Local $iResult = $oController2.put_DefaultBackgroundColor(DllStructGetData($tPacked, 1))
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			$sMessage = "Setting the default background color failed."
			ExitLoop 1
		EndIf
		$bResult = True
	Until True
	If $iError Then __WebView2_Error($sFuncName, $iError, $sMessage, $iExtended)
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_SetDefaultBackgroundColor

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetDefaultBackgroundColor
; Description ...: Reads the native controller's current default background color.
; Syntax ........: _WebView2_GetDefaultBackgroundColor($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - RGB color in 0xRRGGBB format; @extended contains alpha (0 or 255).
;                  On Failure - -1 and sets @error to one of the following:
;                    $WEBVIEW2_ERR_INVALID_INSTANCE = Invalid WebView2 instance.
;                    $WEBVIEW2_ERR_HRESULT = Controller2 is unavailable or the native call failed.
;                  On failure, @extended contains the native HRESULT when available.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Call immediately after the setter to confirm that WebView2 accepted the requested value.
; Related .......: _WebView2_SetDefaultBackgroundColor
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2controller2
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetDefaultBackgroundColor($iWebView)
	Local $iRGB = -1, $iError = 0, $iExtended = 0
	Local Const $sFuncName = "_WebView2_GetDefaultBackgroundColor"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$iError = $WEBVIEW2_ERR_INVALID_INSTANCE
			$sMessage = "Invalid WebView2 instance."
			ExitLoop 1
		EndIf
		Local $pController = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CONTROLLER_POINTER]
		Local $oController2 = __WebView2_Frame_QueryInterface($pController, $WEBVIEW2_IID_ICoreWebView2Controller2, $WEBVIEW2_DTAG_ICoreWebView2Controller2)
		Local $iQueryError = @error, $iQueryExtended = @extended
		If $iQueryError Or Not IsObj($oController2) Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iQueryExtended
			$sMessage = "ICoreWebView2Controller2 is unavailable."
			ExitLoop 1
		EndIf
		Local $tColor = DllStructCreate("byte A;byte R;byte G;byte B")
		Local $iResult = $oController2.get_DefaultBackgroundColor($tColor)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			$sMessage = "Reading the default background color failed."
			ExitLoop 1
		EndIf
		$iRGB = DllStructGetData($tColor, "R") * 0x10000 + DllStructGetData($tColor, "G") * 0x100 + DllStructGetData($tColor, "B")
		$iExtended = DllStructGetData($tColor, "A")
	Until True
	If $iError Then __WebView2_Error($sFuncName, $iError, $sMessage, $iExtended)
	Return SetError($iError, $iExtended, $iRGB)
EndFunc   ;==>_WebView2_GetDefaultBackgroundColor
