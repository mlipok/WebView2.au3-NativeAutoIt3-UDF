#include-once
#Tidy_ILC_Pos=44
#include "WebView2_Core.au3"

; #INDEX# =======================================================================================================================
; Title .........: WebView2_PDF.au3
; Description ...: Native PDF toolbar visibility settings.
; Author(s) .....: mLipok
; Version .......: 0.6.0
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetHiddenPdfToolbarItems
; Description ...: Sets the native PDF toolbar items to hide.
; Syntax ........: _WebView2_SetHiddenPdfToolbarItems($iWebView[, $iItems = 0])
; Parameters ....: $iWebView - WebView instance ID.
;                  $iItems - Optional BitOR of $WEBVIEW2_PDF_TOOLBAR_ITEMS_*; default 0 restores all items.
; Return values .: On Success - True.
;                  On Failure - False and sets @error:
;                  $WEBVIEW2_ERR_INVALID_INSTANCE - Invalid WebView instance.
;                  $WEBVIEW2_ERR_INVALID_PARAMETER - Mask is not an integer from 0 through 0x1FFF.
;                  $WEBVIEW2_ERR_HRESULT or $WEBVIEW2_ERR_DLLCALL - Native access failed.
;                  @extended contains the underlying HRESULT when available.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Applies on the next navigation, across views sharing the environment/profile.
;                  Affects native PDF UI, not PDF.js. Hiding controls does not prevent saving or printing by other means.
;                  Individual controls depend on the installed Runtime. Check @error when the getter returns zero.
; Related .......: _WebView2_GetHiddenPdfToolbarItems, _WebView2_SetHiddenPdfToolbarItems
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2settings7
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_SetHiddenPdfToolbarItems($iWebView, $iItems = 0)
	Local $iError = 0, $iExtended = 0, $vResult = False
	Do
		If Not IsInt($iItems) Or $iItems < 0 Or $iItems > $WEBVIEW2_PDF_TOOLBAR_ITEMS_ALL Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop
		EndIf
		Local $oSettings = __WebView2_PDF_GetSettings($iWebView)
		$iError = @error
		$iExtended = @extended
		If $iError Then ExitLoop
		Local $iResult = $oSettings.put_HiddenPdfToolbarItems($iItems)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop
		EndIf
		$vResult = True
	Until True
	If $iError Then __WebView2_Error("_WebView2_SetHiddenPdfToolbarItems", $iError, "Native PDF toolbar settings failed.", $iExtended)
	Return SetError($iError, $iExtended, $vResult)
EndFunc   ;==>_WebView2_SetHiddenPdfToolbarItems

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetHiddenPdfToolbarItems
; Description ...: Reads the native PDF toolbar hidden-item bitmask.
; Syntax ........: _WebView2_GetHiddenPdfToolbarItems($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - Native hidden-item bitmask; zero means no items hidden.
;                  On Failure - 0 and sets @error:
;                  $WEBVIEW2_ERR_INVALID_INSTANCE - Invalid WebView instance.
;                  $WEBVIEW2_ERR_HRESULT or $WEBVIEW2_ERR_DLLCALL - Native access failed.
;                  @extended contains the underlying HRESULT when available.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Applies on the next navigation, across views sharing the environment/profile.
;                  Affects native PDF UI, not PDF.js. Hiding controls does not prevent saving or printing by other means.
;                  Individual controls depend on the installed Runtime. Check @error when the getter returns zero.
; Related .......: _WebView2_GetHiddenPdfToolbarItems, _WebView2_SetHiddenPdfToolbarItems
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2settings7
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetHiddenPdfToolbarItems($iWebView)
	Local $iError = 0, $iExtended = 0, $vResult = 0
	Do
		Local $oSettings = __WebView2_PDF_GetSettings($iWebView)
		$iError = @error
		$iExtended = @extended
		If $iError Then ExitLoop
		Local $iItems = 0
		Local $iResult = $oSettings.get_HiddenPdfToolbarItems($iItems)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop
		EndIf
		$vResult = $iItems
	Until True
	If $iError Then __WebView2_Error("_WebView2_GetHiddenPdfToolbarItems", $iError, "Native PDF toolbar settings failed.", $iExtended)
	Return SetError($iError, $iExtended, $vResult)
EndFunc   ;==>_WebView2_GetHiddenPdfToolbarItems

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_PDF_GetSettings
; Description ...: Queries Settings7 and releases the temporary base settings pointer.
; Syntax ........: __WebView2_PDF_GetSettings($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: Settings7 object, or Null with INVALID_INSTANCE/HRESULT/DLLCALL in @error.
;                  @extended contains the native HRESULT when available.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2settings7
; Example .......: Yes
; ===============================================================================================================================
Func __WebView2_PDF_GetSettings($iWebView)
	If Not __WebView2_Instance_IsValid($iWebView) Then Return SetError($WEBVIEW2_ERR_INVALID_INSTANCE, 0, Null)
	Local $pSettings = 0
	Local $oCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE]
	Local $iResult = $oCore.get_Settings($pSettings)
	If @error Or $iResult <> $WEBVIEW2_S_OK Or Not $pSettings Then Return SetError($WEBVIEW2_ERR_HRESULT, $iResult, Null)
	Local $oSettings = __WebView2_Frame_QueryInterface($pSettings, $WEBVIEW2_IID_ICoreWebView2Settings7, $WEBVIEW2_DTAG_ICoreWebView2Settings7)
	Local $iError = @error, $iExtended = @extended
	__WebView2_Accelerator_Release($pSettings)
	Return SetError($iError, $iExtended, $oSettings)
EndFunc   ;==>__WebView2_PDF_GetSettings
