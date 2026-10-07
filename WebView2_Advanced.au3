#include-once
#Tidy_ILC_Pos=44

#include "WebView2_Core.au3"
#include "WebView2_DOM.au3"
#include <FileConstants.au3>
#include <StringConstants.au3>

; #INDEX# =======================================================================================================================
; Title .........: WebView2_Advanced.au3
; Description ...: Advanced WebView2 helpers implemented with the native DevTools Protocol entry point exposed by ICoreWebView2.
; Author(s) .....: mLipok
; Version .......: 0.5.0
; Remarks .......: Provides CDP, cookies, screenshot/PDF, frames, ad blocking, extensions and initialization-script helpers.
; ===============================================================================================================================

Global $__g_aWebView2_AdBlockEnabled[$WEBVIEW2_MAX_INSTANCES]
Global Const $__WEBVIEW2_ADBLOCK_MAX_RULES = 64
Global $__g_aWebView2_AdBlockRules[$WEBVIEW2_MAX_INSTANCES][$__WEBVIEW2_ADBLOCK_MAX_RULES]
Global $__g_aWebView2_AdBlockRuleCount[$WEBVIEW2_MAX_INSTANCES]

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_CallDevToolsProtocolMethod
; Description ...: Calls a Chrome DevTools Protocol method through native ICoreWebView2 and waits for its completion callback.
; Syntax ........: _WebView2_CallDevToolsProtocolMethod($iWebView, $sMethodName[, $sParametersJson = "{}"[, $iTimeoutMs = 30000]])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sMethodName - CDP method in Domain.method form.
;                  $sParametersJson - JSON object containing CDP parameters.
;                  $iTimeoutMs - Maximum wait for completion.
; Return values .: On Success - Raw JSON result returned by CDP; On Failure - Empty string.
;                  @error $WEBVIEW2_ERR_USER_ABORT - User sleep callback cancelled the CDP wait.
;                  @extended contains the callback error for USER_ABORT.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: CDP calls share the same serialized async completion infrastructure as ExecuteScript.
; Related .......: _WebView2_CapturePreview, _WebView2_ExportToPdf
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2#calldevtoolsprotocolmethod
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_CallDevToolsProtocolMethod($iWebView, $sMethodName, $sParametersJson = "{}", $iTimeoutMs = 30000)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_CallDevToolsProtocolMethod"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If $sMethodName = "" Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "CDP method name cannot be empty.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If $__g_bWebView2_ScriptBusy Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_BUSY, 0, "Another asynchronous WebView2 string-result request is pending.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__g_bWebView2_ScriptBusy = True
		$__g_bWebView2_ScriptDone = False
		$__g_iWebView2_ScriptHRESULT = 0
		$__g_sWebView2_ScriptResult = ""

		Local $oCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE]
		Local $iResult = $oCore.CallDevToolsProtocolMethod($sMethodName, $sParametersJson, __WebView2_Callback_GetPointer($__WEBVIEW2_CB_EXECUTE_SCRIPT))
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$__g_bWebView2_ScriptBusy = False
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iResult, "CallDevToolsProtocolMethod() could not be started.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $bScriptWait = __WebView2_WaitForFlag($__g_bWebView2_ScriptDone, $iTimeoutMs)
		Local $iScriptWaitError = @error
		Local $iScriptWaitExtended = @extended
		If Not $bScriptWait Then
			$__g_bWebView2_ScriptBusy = False
			If $iScriptWaitError = $WEBVIEW2_ERR_USER_ABORT Then
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_USER_ABORT, $iScriptWaitExtended, "CDP wait was cancelled.", "")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			EndIf
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_TIMEOUT, 0, "CallDevToolsProtocolMethod() timed out.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__g_bWebView2_ScriptBusy = False
		If $__g_iWebView2_ScriptHRESULT <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $__g_iWebView2_ScriptHRESULT, "CDP call completed with an error.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $__g_sWebView2_ScriptResult
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_CallDevToolsProtocolMethod

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_AddInitializationScript
; Description ...: Registers JavaScript that runs for every new top-level document.
; Syntax ........: _WebView2_AddInitializationScript($iWebView, $sJavaScript[, $iTimeoutMs = 30000])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sJavaScript - Script source.
;                  $iTimeoutMs - Maximum wait for script ID.
; Return values .: On Success - Script ID; On Failure - Empty string.
;                  @error $WEBVIEW2_ERR_USER_ABORT - User sleep callback cancelled the registration wait.
;                  @extended contains the callback error for USER_ABORT.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Uses the native AddScriptToExecuteOnDocumentCreated API.
; Related .......: _WebView2_RemoveInitializationScript
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2#addscripttoexecuteondocumentcreated
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_AddInitializationScript($iWebView, $sJavaScript, $iTimeoutMs = 30000)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_AddInitializationScript"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If $__g_bWebView2_ScriptBusy Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_BUSY, 0, "Another asynchronous WebView2 string-result request is pending.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__g_bWebView2_ScriptBusy = True
		$__g_bWebView2_ScriptDone = False
		$__g_iWebView2_ScriptHRESULT = 0
		$__g_sWebView2_ScriptResult = ""

		Local $oCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE]
		Local $iResult = $oCore.AddScriptToExecuteOnDocumentCreated($sJavaScript, __WebView2_Callback_GetPointer($__WEBVIEW2_CB_EXECUTE_SCRIPT))
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$__g_bWebView2_ScriptBusy = False
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iResult, "AddScriptToExecuteOnDocumentCreated() could not be started.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $bScriptWait = __WebView2_WaitForFlag($__g_bWebView2_ScriptDone, $iTimeoutMs)
		Local $iScriptWaitError = @error
		Local $iScriptWaitExtended = @extended
		If Not $bScriptWait Then
			$__g_bWebView2_ScriptBusy = False
			If $iScriptWaitError = $WEBVIEW2_ERR_USER_ABORT Then
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_USER_ABORT, $iScriptWaitExtended, "Initialization script wait was cancelled.", "")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			EndIf
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_TIMEOUT, 0, "AddScriptToExecuteOnDocumentCreated() timed out.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__g_bWebView2_ScriptBusy = False
		If $__g_iWebView2_ScriptHRESULT <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $__g_iWebView2_ScriptHRESULT, "Initialization script registration failed.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $__g_sWebView2_ScriptResult
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_AddInitializationScript

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_RemoveInitializationScript
; Description ...: Removes a script registered by _WebView2_AddInitializationScript.
; Syntax ........: _WebView2_RemoveInitializationScript($iWebView, $sScriptId)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sScriptId - Script identifier returned by _WebView2_AddInitializationScript.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_AddInitializationScript
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_RemoveInitializationScript($iWebView, $sScriptId)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_RemoveInitializationScript"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $oCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE]
		Local $iResult = $oCore.RemoveScriptToExecuteOnDocumentCreated($sScriptId)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iResult, "RemoveScriptToExecuteOnDocumentCreated() failed.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = True
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_RemoveInitializationScript

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_CapturePreviewAsBase64
; Description ...: Captures the visible WebView viewport using CDP and returns Base64 image data.
; Syntax ........: _WebView2_CapturePreviewAsBase64($iWebView[, $sFormat = "png"[, $iQuality = 90]])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sFormat - One of the following image formats:
;                  |PNG  - Lossless PNG image.
;                  |JPEG - JPEG image.
;                  |WEBP - WebP image.
;                  $iQuality - JPEG/WebP quality from 0 to 100.
; Return values .: On Success - Base64 image payload; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Captures the current viewport. Use CDP parameters directly for more advanced capture scenarios.
; Related .......: _WebView2_CapturePreview
; Link ..........: https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-captureScreenshot
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_CapturePreviewAsBase64($iWebView, $sFormat = "png", $iQuality = 90)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_CapturePreviewAsBase64"
	Local $sMessage = ''
	Do
		$sFormat = StringLower($sFormat)
		If $sFormat <> "png" And $sFormat <> "jpeg" And $sFormat <> "webp" Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Capture format must be png, jpeg, or webp.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $sParams = '{"format":' & __WebView2_JavaScript_StringLiteral($sFormat)
		If $sFormat <> "png" Then $sParams &= ',"quality":' & Int($iQuality)
		$sParams &= '}'
		Local $sResult = _WebView2_CallDevToolsProtocolMethod($iWebView, "Page.captureScreenshot", $sParams)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = __WebView2_JSON_GetStringProperty($sResult, "data")
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_CapturePreviewAsBase64

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_CapturePreviewBinary
; Description ...: Captures the visible WebView viewport and returns decoded image bytes as AutoIt Binary.
; Syntax ........: _WebView2_CapturePreviewBinary($iWebView[, $sFormat = "png"[, $iQuality = 90]])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sFormat - One of the following image formats:
;                  |PNG  - Lossless PNG image.
;                  |JPEG - JPEG image.
;                  |WEBP - WebP image.
;                  $iQuality - JPEG/WebP quality from 0 to 100.
; Return values .: On Success - Binary image payload; On Failure - Empty Binary.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_CapturePreviewAsBase64, _WebView2_CapturePreview
; Link ..........: https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-captureScreenshot
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_CapturePreviewBinary($iWebView, $sFormat = "png", $iQuality = 90)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_CapturePreviewBinary"
	Local $sMessage = ''
	Do
		Local $sBase64 = _WebView2_CapturePreviewAsBase64($iWebView, $sFormat, $iQuality)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, Binary(""))
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $bData = __WebView2_Base64_DecodeBinary($sBase64)
		If @error Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_JAVASCRIPT, @extended, "Unable to decode image Base64 payload.", Binary(""))
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $bData
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_CapturePreviewBinary

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_CapturePreview
; Description ...: Captures the current WebView viewport to an image file.
; Syntax ........: _WebView2_CapturePreview($iWebView, $sFilePath[, $sFormat = "png"[, $iQuality = 90]])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sFilePath - Output file path.
;                  $sFormat - One of the following image formats:
;                  |PNG  - Lossless PNG image.
;                  |JPEG - JPEG image.
;                  |WEBP - WebP image.
;                  $iQuality - JPEG/WebP quality from 0 to 100.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Implemented through Page.captureScreenshot.
; Related .......: _WebView2_CapturePreviewAsBase64
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_CapturePreview($iWebView, $sFilePath, $sFormat = "png", $iQuality = 90)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_CapturePreview"
	Local $sMessage = ''
	Do
		Local $bData = _WebView2_CapturePreviewBinary($iWebView, $sFormat, $iQuality)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = __WebView2_Binary_WriteFile($bData, $sFilePath)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_CapturePreview

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_PrintToPdfStream
; Description ...: Renders the current page as PDF and returns the PDF payload as Base64.
; Syntax ........: _WebView2_PrintToPdfStream($iWebView[, $sParametersJson = "{}"])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sParametersJson - Parameters accepted by CDP Page.printToPDF.
; Return values .: On Success - Base64 PDF payload; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_ExportToPdf
; Link ..........: https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-printToPDF
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_PrintToPdfStream($iWebView, $sParametersJson = "{}")
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_PrintToPdfStream"
	Local $sMessage = ''
	Do
		Local $sResult = _WebView2_CallDevToolsProtocolMethod($iWebView, "Page.printToPDF", $sParametersJson)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = __WebView2_JSON_GetStringProperty($sResult, "data")
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_PrintToPdfStream

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ExportToPdfBinary
; Description ...: Renders the current page as PDF and returns decoded PDF bytes as AutoIt Binary.
; Syntax ........: _WebView2_ExportToPdfBinary($iWebView[, $sParametersJson = "{}"])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sParametersJson - Parameters accepted by CDP Page.printToPDF.
; Return values .: On Success - Binary PDF payload; On Failure - Empty Binary.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Page.printToPDF returns Base64; this helper decodes it before returning.
; Related .......: _WebView2_ExportToPdfFile, _WebView2_PrintToPdfStream
; Link ..........: https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-printToPDF
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ExportToPdfBinary($iWebView, $sParametersJson = "{}")
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_ExportToPdfBinary"
	Local $sMessage = ''
	Do
		Local $sBase64 = _WebView2_PrintToPdfStream($iWebView, $sParametersJson)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, Binary(""))
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $bData = __WebView2_Base64_DecodeBinary($sBase64)
		If @error Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_JAVASCRIPT, @extended, "Unable to decode PDF Base64 payload.", Binary(""))
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $bData
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_ExportToPdfBinary

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ExportToPdfFile
; Description ...: Renders the current page as PDF and writes the exact binary payload to a file.
; Syntax ........: _WebView2_ExportToPdfFile($iWebView, $sFilePath[, $sParametersJson = "{}"])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sFilePath - Destination PDF path.
;                  $sParametersJson - Parameters accepted by CDP Page.printToPDF.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This is the file equivalent of _WebView2_ExportToPdfBinary().
; Related .......: _WebView2_ExportToPdfBinary, _WebView2_ExportToPdf
; Link ..........: https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-printToPDF
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ExportToPdfFile($iWebView, $sFilePath, $sParametersJson = "{}")
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_ExportToPdfFile"
	Local $sMessage = ''
	Do
		Local $bData = _WebView2_ExportToPdfBinary($iWebView, $sParametersJson)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = __WebView2_Binary_WriteFile($bData, $sFilePath)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_ExportToPdfFile

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ExportToPdf
; Description ...: Renders the current page as a PDF file.
; Syntax ........: _WebView2_ExportToPdf($iWebView, $sFilePath[, $sParametersJson = "{}"])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sFilePath - Destination PDF path.
;                  $sParametersJson - Parameters accepted by Page.printToPDF.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Uses CDP so it does not depend on newer ICoreWebView2 print interface revisions.
; Related .......: _WebView2_PrintToPdfStream
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ExportToPdf($iWebView, $sFilePath, $sParametersJson = "{}")
	Local $__WebView2DirectResult = _WebView2_ExportToPdfFile($iWebView, $sFilePath, $sParametersJson)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_ExportToPdf

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ExportStyledPageToPdfBinary
; Description ...: Prints the current page with temporary CSS and an optional HTML header.
; Syntax ........: _WebView2_ExportStyledPageToPdfBinary($iWebView[, $sCss = ""[, $sHeaderHtml = ""[, $sParametersJson = "{}"]]])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sCss - CSS applied temporarily before printing. Default: empty.
;                  $sHeaderHtml - Optional HTML inserted before the document body content. Default: empty.
;                  $sParametersJson - CDP Page.printToPDF options. Default: "{}".
; Return values .: On Success - PDF binary.
;                  On Failure - empty binary; preserves @error/@extended from a failed script or PDF export when nonzero.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Temporary elements are removed after printing, including when PDF export fails.
; Related .......: _WebView2_ExportToPdfBinary, _WebView2_ExecuteScript
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_ExportStyledPageToPdfBinary($iWebView, $sCss = "", $sHeaderHtml = "", $sParametersJson = "{}")
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_ExportStyledPageToPdfBinary"
	Local $sMessage = ''
	Do
		Local $sCssLiteral = __WebView2_JavaScript_StringLiteral($sCss)
		Local $sHeaderLiteral = __WebView2_JavaScript_StringLiteral($sHeaderHtml)
		Local $sScript = "(()=>{const css=document.createElement('style');css.id='__autoit_webview2_pdf_css';css.textContent=" & $sCssLiteral & ";document.head.appendChild(css);" & _
				"const header=document.createElement('div');header.id='__autoit_webview2_pdf_header';header.style.cssText='border-style:solid;border-width:1.5px;padding:2px';header.innerHTML=" & $sHeaderLiteral & ";" & _
				"if(header.innerHTML)document.body.insertBefore(header,document.body.firstChild);return true;})()"
		_WebView2_ExecuteScript($iWebView, $sScript)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, Binary(""))
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $bPdf = _WebView2_ExportToPdfBinary($iWebView, $sParametersJson)
		Local $iPrintError = @error, $iPrintExtended = @extended
		_WebView2_ExecuteScript($iWebView, "(()=>{document.getElementById('__autoit_webview2_pdf_header')?.remove();document.getElementById('__autoit_webview2_pdf_css')?.remove();return true;})()")
		If $iPrintError Then
			$__WebView2ExitValue = SetError($iPrintError, $iPrintExtended, Binary(""))
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, Binary(""))
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $bPdf
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_ExportStyledPageToPdfBinary

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_CaptureSnapshot
; Description ...: Captures a CDP page snapshot, normally MHTML.
; Syntax ........: _WebView2_CaptureSnapshot($iWebView[, $sParametersJson = '{"format":"mhtml"}'[, $sFilePath = ""]])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sParametersJson - Page.captureSnapshot parameters.
;                  $sFilePath - Optional text file path for the returned snapshot.
; Return values .: On Success - Snapshot data string; On Failure - Empty string.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_CallDevToolsProtocolMethod
; Link ..........: https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-captureSnapshot
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_CaptureSnapshot($iWebView, $sParametersJson = '{"format":"mhtml"}', $sFilePath = "")
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_CaptureSnapshot"
	Local $sMessage = ''
	Do
		Local $sResult = _WebView2_CallDevToolsProtocolMethod($iWebView, "Page.captureSnapshot", $sParametersJson)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $sData = __WebView2_JSON_GetStringProperty($sResult, "data")
		If $sFilePath <> "" Then
			Local $bData = StringToBinary($sData, $SB_UTF8)
			If Not __WebView2_Binary_WriteFile($bData, $sFilePath) Then
				$__WebView2ExitValue = SetError(@error, @extended, "")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			EndIf
		EndIf
		$__WebView2ExitValue = $sData
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_CaptureSnapshot

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ExportToMhtmlBinary
; Description ...: Captures the current page as MHTML and returns UTF-8 encoded MHTML bytes as AutoIt Binary.
; Syntax ........: _WebView2_ExportToMhtmlBinary($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - Binary MHTML payload; On Failure - Empty Binary and @error/@extended set.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Uses CDP Page.captureSnapshot with format=mhtml. Returned Binary is UTF-8 encoded MHTML data.
; Related .......: _WebView2_ExportToMhtmlFile, _WebView2_CaptureSnapshot
; Link ..........: https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-captureSnapshot
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ExportToMhtmlBinary($iWebView)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_ExportToMhtmlBinary"
	Local $sMessage = ''
	Do
		Local $sData = _WebView2_CaptureSnapshot($iWebView, '{"format":"mhtml"}')
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, Binary(""))
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = StringToBinary($sData, $SB_UTF8)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_ExportToMhtmlBinary

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ExportToMhtmlFile
; Description ...: Captures the current page as MHTML and writes the exact UTF-8 binary payload to a file.
; Syntax ........: _WebView2_ExportToMhtmlFile($iWebView, $sFilePath)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sFilePath - Destination MHTML path.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This is the file equivalent of _WebView2_ExportToMhtmlBinary().
; Related .......: _WebView2_ExportToMhtmlBinary, _WebView2_CaptureSnapshot
; Link ..........: https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-captureSnapshot
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ExportToMhtmlFile($iWebView, $sFilePath)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_ExportToMhtmlFile"
	Local $sMessage = ''
	Do
		Local $bData = _WebView2_ExportToMhtmlBinary($iWebView)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = __WebView2_Binary_WriteFile($bData, $sFilePath)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_ExportToMhtmlFile

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetCookies
; Description ...: Returns browser cookies as the raw CDP JSON result.
; Syntax ........: _WebView2_GetCookies($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - JSON containing cookies; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Uses Network.getAllCookies for broad compatibility with current WebView2 runtimes.
; Related .......: _WebView2_AddCookie, _WebView2_DeleteCookie, _WebView2_DeleteAllCookies
; Link ..........: https://chromedevtools.github.io/devtools-protocol/tot/Network/
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetCookies($iWebView)
	Local $__WebView2DirectResult = _WebView2_CallDevToolsProtocolMethod($iWebView, "Network.getAllCookies", "{}")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetCookies

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_AddCookie
; Description ...: Adds or updates a cookie through CDP.
; Syntax ........: _WebView2_AddCookie($iWebView, $sName, $sValue, $sDomain[, $sPath = "/"])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sName - Cookie name.
;                  $sValue - Cookie value.
;                  $sDomain - Cookie domain.
;                  $sPath - Cookie path.
; Return values .: On Success - Raw CDP JSON; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_GetCookies
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_AddCookie($iWebView, $sName, $sValue, $sDomain, $sPath = "/")
	Local $sParams = '{"name":' & __WebView2_JavaScript_StringLiteral($sName) & ',"value":' & __WebView2_JavaScript_StringLiteral($sValue) & _
			',"domain":' & __WebView2_JavaScript_StringLiteral($sDomain) & ',"path":' & __WebView2_JavaScript_StringLiteral($sPath) & '}'
	Local $__WebView2DirectResult = _WebView2_CallDevToolsProtocolMethod($iWebView, "Network.setCookie", $sParams)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_AddCookie

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_DeleteCookie
; Description ...: Deletes a cookie through CDP.
; Syntax ........: _WebView2_DeleteCookie($iWebView, $sName, $sDomain[, $sPath = "/"])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sName - Cookie name.
;                  $sDomain - Cookie domain.
;                  $sPath - Cookie path.
; Return values .: On Success - Raw CDP JSON; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_AddCookie, _WebView2_DeleteAllCookies
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_DeleteCookie($iWebView, $sName, $sDomain, $sPath = "/")
	Local $sParams = '{"name":' & __WebView2_JavaScript_StringLiteral($sName) & ',"domain":' & __WebView2_JavaScript_StringLiteral($sDomain) & _
			',"path":' & __WebView2_JavaScript_StringLiteral($sPath) & '}'
	Local $__WebView2DirectResult = _WebView2_CallDevToolsProtocolMethod($iWebView, "Network.deleteCookies", $sParams)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_DeleteCookie

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_DeleteAllCookies
; Description ...: Deletes all browser cookies visible to the current WebView2 profile through CDP.
; Syntax ........: _WebView2_DeleteAllCookies($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - Raw CDP JSON; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_GetCookies
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_DeleteAllCookies($iWebView)
	Local $__WebView2DirectResult = _WebView2_CallDevToolsProtocolMethod($iWebView, "Network.clearBrowserCookies", "{}")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_DeleteAllCookies

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ClearCache
; Description ...: Clears Chromium network cache and top-level web storage.
; Syntax ........: _WebView2_ClearCache($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - True; On Failure - False.
; Author ........: mLipok
; Modified ......:
; Remarks .......: localStorage/sessionStorage are cleared for the currently loaded origin.
; Related .......: _WebView2_ClearBrowserData
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ClearCache($iWebView)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_ClearCache"
	Local $sMessage = ''
	Do
		_WebView2_CallDevToolsProtocolMethod($iWebView, "Network.clearBrowserCache", "{}")
		If @error Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		_WebView2_ExecuteScript($iWebView, "(()=>{try{localStorage.clear();sessionStorage.clear();}catch(e){}return true;})()")
		If @error Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = True
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_ClearCache

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ClearBrowserData
; Description ...: Clears cookies, cache and top-level local/session storage.
; Syntax ........: _WebView2_ClearBrowserData($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This portable implementation intentionally avoids version-specific profile interfaces.
; Related .......: _WebView2_ClearCache, _WebView2_DeleteAllCookies
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ClearBrowserData($iWebView)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_ClearBrowserData"
	Local $sMessage = ''
	Do
		_WebView2_DeleteAllCookies($iWebView)
		If @error Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = _WebView2_ClearCache($iWebView)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_ClearBrowserData

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetUserAgent
; Description ...: Overrides the browser User-Agent for subsequent requests through CDP.
; Syntax ........: _WebView2_SetUserAgent($iWebView, $sUserAgent)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sUserAgent - User-Agent string.
; Return values .: On Success - True; On Failure - False.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_SetUserAgent($iWebView, $sUserAgent)
	Local $sResult = _WebView2_CallDevToolsProtocolMethod($iWebView, "Network.setUserAgentOverride", '{"userAgent":' & __WebView2_JavaScript_StringLiteral($sUserAgent) & '}')
	Return Not @error And $sResult <> ""
EndFunc   ;==>_WebView2_SetUserAgent

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetAdBlock
; Description ...: Enables or disables the UDF URL-pattern ad blocker.
; Syntax ........: _WebView2_SetAdBlock($iWebView[, $bActive = True])
; Parameters ....: $iWebView - WebView instance ID.
;                  $bActive - True to block configured patterns.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Uses Network.setBlockedURLs. Rules are URL patterns, not cosmetic DOM filters.
; Related .......: _WebView2_AddBlockRule, _WebView2_ClearBlockRules
; Link ..........: https://chromedevtools.github.io/devtools-protocol/tot/Network/#method-setBlockedURLs
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_SetAdBlock($iWebView, $bActive = True)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_SetAdBlock"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__g_aWebView2_AdBlockEnabled[$iWebView] = $bActive
		If $bActive Then
			_WebView2_CallDevToolsProtocolMethod($iWebView, "Network.enable", "{}")
			If @error Then
				$__WebView2ExitValue = False
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			EndIf
		EndIf
		$__WebView2ExitValue = __WebView2_AdBlock_Apply($iWebView)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_SetAdBlock

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_AddBlockRule
; Description ...: Adds a URL pattern to the per-instance ad block list.
; Syntax ........: _WebView2_AddBlockRule($iWebView, $sPattern)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sPattern - CDP blocked URL pattern or a domain name.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Plain domain names are converted to *://*.domain/* patterns.
; Related .......: _WebView2_SetAdBlock
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_AddBlockRule($iWebView, $sPattern)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_AddBlockRule"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If $sPattern = "" Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Block rule cannot be empty.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $iCount = $__g_aWebView2_AdBlockRuleCount[$iWebView]
		If $iCount >= UBound($__g_aWebView2_AdBlockRules, 2) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Maximum number of block rules reached.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If StringInStr($sPattern, "://") = 0 And StringInStr($sPattern, "*") = 0 Then $sPattern = "*://*." & $sPattern & "/*"
		$__g_aWebView2_AdBlockRules[$iWebView][$iCount] = $sPattern
		$__g_aWebView2_AdBlockRuleCount[$iWebView] = $iCount + 1
		If $__g_aWebView2_AdBlockEnabled[$iWebView] Then
			$__WebView2ExitValue = __WebView2_AdBlock_Apply($iWebView)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = True
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_AddBlockRule

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ClearBlockRules
; Description ...: Clears all URL block patterns for one WebView instance.
; Syntax ........: _WebView2_ClearBlockRules($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_AddBlockRule
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ClearBlockRules($iWebView)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_ClearBlockRules"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		For $i = 0 To UBound($__g_aWebView2_AdBlockRules, 2) - 1
			$__g_aWebView2_AdBlockRules[$iWebView][$i] = ""
		Next
		$__g_aWebView2_AdBlockRuleCount[$iWebView] = 0
		$__WebView2ExitValue = __WebView2_AdBlock_Apply($iWebView)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_ClearBlockRules

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetFrameTree
; Description ...: Returns the raw CDP frame tree JSON for the current page.
; Syntax ........: _WebView2_GetFrameTree($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - JSON frame tree; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Unlike DOM frame enumeration this also describes cross-origin frames.
; Related .......: _WebView2_GetFrameUrls, _WebView2_GetFrameNames
; Link ..........: https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-getFrameTree
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetFrameTree($iWebView)
	Local $__WebView2DirectResult = _WebView2_CallDevToolsProtocolMethod($iWebView, "Page.getFrameTree", "{}")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetFrameTree

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetFrameUrls
; Description ...: Returns a pipe-separated list of iframe/frame source URLs from the top-level DOM.
; Syntax ........: _WebView2_GetFrameUrls($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - Pipe-separated URLs; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_GetFrameUrl, _WebView2_GetFrameTree
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetFrameUrls($iWebView)
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, "Array.from(document.querySelectorAll('iframe,frame')).map(f=>f.src||'').join('|')", "")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetFrameUrls

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetFrameNames
; Description ...: Returns a pipe-separated list of iframe/frame names.
; Syntax ........: _WebView2_GetFrameNames($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - Pipe-separated names; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_GetFrameName
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetFrameNames($iWebView)
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, "Array.from(document.querySelectorAll('iframe,frame')).map(f=>f.name||f.id||'').join('|')", "")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetFrameNames

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetFrameUrl
; Description ...: Returns the URL of a frame element by zero-based index.
; Syntax ........: _WebView2_GetFrameUrl($iWebView, $iIndex)
; Parameters ....: $iWebView - WebView instance ID.
;                  $iIndex - Zero-based frame index.
; Return values .: On Success - URL; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_GetFrameUrls
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetFrameUrl($iWebView, $iIndex)
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, "(()=>{const a=document.querySelectorAll('iframe,frame');return a[" & Int($iIndex) & "]?(a[" & Int($iIndex) & "].src||''):null;})()", "")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetFrameUrl

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetFrameName
; Description ...: Returns the name or id of a frame element by zero-based index.
; Syntax ........: _WebView2_GetFrameName($iWebView, $iIndex)
; Parameters ....: $iWebView - WebView instance ID.
;                  $iIndex - Zero-based frame index.
; Return values .: On Success - Name/id; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_GetFrameNames
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetFrameName($iWebView, $iIndex)
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, "(()=>{const a=document.querySelectorAll('iframe,frame');return a[" & Int($iIndex) & "]?(a[" & Int($iIndex) & "].name||a[" & Int($iIndex) & "].id||''):null;})()", "")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetFrameName

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetFrameHtmlSource
; Description ...: Returns frame HTML by zero-based index when same-origin DOM access is permitted.
; Syntax ........: _WebView2_GetFrameHtmlSource($iWebView, $iIndex)
; Parameters ....: $iWebView - WebView instance ID.
;                  $iIndex - Zero-based frame index.
; Return values .: On Success - HTML; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Cross-origin frame DOM access is blocked by the browser security model; use _WebView2_GetFrameTree for metadata.
; Related .......: _WebView2_GetFrameTree
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetFrameHtmlSource($iWebView, $iIndex)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_GetFrameHtmlSource"
	Local $sMessage = ''
	Do
		Local $sScript = "(()=>{const f=document.querySelectorAll('iframe,frame')[" & Int($iIndex) & "];if(!f)return '__WV2_ERROR__:NOMATCH';try{return f.contentDocument&&f.contentDocument.documentElement?f.contentDocument.documentElement.outerHTML:'__WV2_ERROR__:CROSSORIGIN';}catch(e){return '__WV2_ERROR__:CROSSORIGIN';}})()"
		Local $vResult = __WebView2_DOM_Execute($iWebView, $sScript, "")
		If $vResult = "__WV2_ERROR__:CROSSORIGIN" Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_JAVASCRIPT, 0, "Cross-origin frame HTML cannot be read through the DOM helper.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $vResult
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_GetFrameHtmlSource

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_AddExtension
; Description ...: Attempts to load an unpacked Chromium extension through the experimental CDP Extensions domain.
; Syntax ........: _WebView2_AddExtension($iWebView, $sExtensionPath)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sExtensionPath - Absolute folder containing an unpacked extension.
; Return values .: On Success - Extension ID when returned; otherwise raw JSON result. On Failure - Empty string.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Runtime-dependent. Chromium can require extension debugging support for Extensions.loadUnpacked.
; Related .......: _WebView2_RemoveExtension, _WebView2_GetExtensions
; Link ..........: https://chromedevtools.github.io/devtools-protocol/tot/Extensions/
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_AddExtension($iWebView, $sExtensionPath)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_AddExtension"
	Local $sMessage = ''
	Do
		Local $sResult = _WebView2_CallDevToolsProtocolMethod($iWebView, "Extensions.loadUnpacked", '{"path":' & __WebView2_JavaScript_StringLiteral($sExtensionPath) & '}')
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $sId = __WebView2_JSON_GetStringProperty($sResult, "id")
		$__WebView2ExitValue = $sId <> "" ? $sId : $sResult
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_AddExtension

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_RemoveExtension
; Description ...: Attempts to uninstall an unpacked extension through CDP.
; Syntax ........: _WebView2_RemoveExtension($iWebView, $sExtensionId)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sExtensionId - Chromium extension ID.
; Return values .: On Success - Raw CDP JSON; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Runtime-dependent experimental CDP functionality.
; Related .......: _WebView2_AddExtension
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_RemoveExtension($iWebView, $sExtensionId)
	Local $__WebView2DirectResult = _WebView2_CallDevToolsProtocolMethod($iWebView, "Extensions.uninstall", '{"id":' & __WebView2_JavaScript_StringLiteral($sExtensionId) & '}')
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_RemoveExtension

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetExtensions
; Description ...: Returns extension metadata through the experimental CDP Extensions domain.
; Syntax ........: _WebView2_GetExtensions($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - Raw JSON; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Runtime-dependent experimental CDP functionality.
; Related .......: _WebView2_AddExtension, _WebView2_RemoveExtension
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetExtensions($iWebView)
	Local $__WebView2DirectResult = _WebView2_CallDevToolsProtocolMethod($iWebView, "Extensions.getExtensions", "{}")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetExtensions

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_EncodeURI
; Description ...: Encodes text using JavaScript encodeURIComponent semantics.
; Syntax ........: _WebView2_EncodeURI($iWebView, $sValue)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sValue - Input string.
; Return values .: Encoded string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_DecodeURI
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_EncodeURI($iWebView, $sValue)
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, "encodeURIComponent(" & __WebView2_JavaScript_StringLiteral($sValue) & ")", "")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_EncodeURI

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_DecodeURI
; Description ...: Decodes text using JavaScript decodeURIComponent semantics.
; Syntax ........: _WebView2_DecodeURI($iWebView, $sValue)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sValue - Encoded string.
; Return values .: Decoded string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_EncodeURI
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_DecodeURI($iWebView, $sValue)
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, "decodeURIComponent(" & __WebView2_JavaScript_StringLiteral($sValue) & ")", "")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_DecodeURI

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_EncodeBase64
; Description ...: Encodes UTF-8 text as Base64 using the document JavaScript runtime.
; Syntax ........: _WebView2_EncodeBase64($iWebView, $sValue)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sValue - Input string.
; Return values .: Base64 string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_DecodeBase64
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_EncodeBase64($iWebView, $sValue)
	Local $sScript = "btoa(String.fromCharCode(...new TextEncoder().encode(" & __WebView2_JavaScript_StringLiteral($sValue) & ")))"
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, $sScript, "")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_EncodeBase64

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_DecodeBase64
; Description ...: Decodes Base64 UTF-8 text using the document JavaScript runtime.
; Syntax ........: _WebView2_DecodeBase64($iWebView, $sBase64)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sBase64 - Base64 text.
; Return values .: Decoded text.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_EncodeBase64
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_DecodeBase64($iWebView, $sBase64)
	Local $sScript = "new TextDecoder().decode(Uint8Array.from(atob(" & __WebView2_JavaScript_StringLiteral($sBase64) & "),c=>c.charCodeAt(0)))"
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, $sScript, "")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_DecodeBase64

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_AdBlock_Apply
; Description ...: Applies the current URL-blocking rules through CDP.
; Syntax ........: __WebView2_AdBlock_Apply($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: True if CDP accepted the current rule set; otherwise False.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_AdBlock_Apply($iWebView)
	Local $sJson = '{"urls":['
	If $__g_aWebView2_AdBlockEnabled[$iWebView] Then
		For $i = 0 To $__g_aWebView2_AdBlockRuleCount[$iWebView] - 1
			If $i > 0 Then $sJson &= ","
			$sJson &= __WebView2_JavaScript_StringLiteral($__g_aWebView2_AdBlockRules[$iWebView][$i])
		Next
	EndIf
	$sJson &= "]}"
	Local $sResult = _WebView2_CallDevToolsProtocolMethod($iWebView, "Network.setBlockedURLs", $sJson)
	Return Not @error And $sResult <> ""
EndFunc   ;==>__WebView2_AdBlock_Apply

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_JSON_GetStringProperty
; Description ...: Extracts a string property from a JSON object.
; Syntax ........: __WebView2_JSON_GetStringProperty($sJson, $sProperty)
; Parameters ....: $sJson - JSON object text.
;                  $sProperty - JSON string property name.
; Return values .: On Success - Decoded property text, including an empty string.
;                  On Failure - Empty string and @error = 1 when the property or closing quote is absent.
;                  Propagates @error/@extended from StringRegExp or __WebView2_JSONString_Decode.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Uses a nonrecursive quote scan so large Base64 and escaped MHTML values are supported.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_JSON_GetStringProperty($sJson, $sProperty)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_JSON_GetStringProperty"
	Local $sMessage = ''
	Do
		; Match only the property prefix; scan quotes without a recursive regex over the value.
		Local $sPattern = '"' & StringRegExpReplace($sProperty, '([\\.^$|?*+(){}\[\]])', '\\$1') & '"\s*:\s*"'
		Local $aMatch = StringRegExp($sJson, $sPattern, 2)
		Local $iMatchError = @error, $iStart = @extended
		If $iMatchError Or UBound($aMatch) = 0 Then
			$__WebView2ExitValue = ""
			$__WebView2ExitError = $iMatchError
			$__WebView2ExitExtended = $iStart
			ExitLoop
		EndIf
		Local $iQuote = StringInStr($sJson, '"', 1, 1, $iStart)
		While $iQuote
			Local $iSlash = $iQuote - 1, $iSlashCount = 0
			While $iSlash >= $iStart And StringMid($sJson, $iSlash, 1) = '\'
				$iSlashCount += 1
				$iSlash -= 1
			WEnd
			If Mod($iSlashCount, 2) = 0 Then ExitLoop
			$iQuote = StringInStr($sJson, '"', 1, 1, $iQuote + 1)
		WEnd
		If Not $iQuote Then
			$__WebView2ExitValue = ""
			$__WebView2ExitError = 1
			$__WebView2ExitExtended = 0
			ExitLoop
		EndIf
		$__WebView2ExitValue = __WebView2_JSONString_Decode('"' & StringMid($sJson, $iStart, $iQuote - $iStart) & '"')
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_JSON_GetStringProperty

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Base64_DecodeBinary
; Description ...: Decodes Base64 text to binary data.
; Syntax ........: __WebView2_Base64_DecodeBinary($sBase64)
; Parameters ....: $sBase64 - Base64-encoded data.
; Return values .: Decoded binary data, or empty binary on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Base64_DecodeBinary($sBase64)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_Base64_DecodeBinary"
	Local $sMessage = ''
	Do
		Local $iSize = 0
		Local $aSize = DllCall("Crypt32.dll", "bool", "CryptStringToBinaryW", "wstr", $sBase64, "dword", 0, "dword", 1, "ptr", 0, "dword*", 0, "ptr", 0, "ptr", 0)
		If @error Or Not $aSize[0] Then
			$__WebView2ExitValue = SetError(1, @error, Binary(""))
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$iSize = $aSize[5]
		Local $tBuffer = DllStructCreate("byte[" & $iSize & "]")
		Local $aData = DllCall("Crypt32.dll", "bool", "CryptStringToBinaryW", "wstr", $sBase64, "dword", 0, "dword", 1, "ptr", DllStructGetPtr($tBuffer), "dword*", $iSize, "ptr", 0, "ptr", 0)
		If @error Or Not $aData[0] Then
			$__WebView2ExitValue = SetError(2, @error, Binary(""))
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = DllStructGetData($tBuffer, 1)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_Base64_DecodeBinary

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Binary_WriteFile
; Description ...: Writes binary data to a file.
; Syntax ........: __WebView2_Binary_WriteFile($bData, $sFilePath)
; Parameters ....: $bData - Binary data to write.
;                  $sFilePath - Destination file path.
; Return values .: True on success; otherwise False.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Binary_WriteFile($bData, $sFilePath)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_Binary_WriteFile"
	Local $sMessage = ''
	Do
		Local $hFile = FileOpen($sFilePath, BitOR($FO_OVERWRITE, $FO_BINARY))
		If $hFile = -1 Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Unable to create output file: " & $sFilePath, False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $iWritten = FileWrite($hFile, $bData)
		FileClose($hFile)
		If $iWritten = 0 And BinaryLen($bData) > 0 Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Unable to write output file: " & $sFilePath, False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = True
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_Binary_WriteFile

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Base64_WriteFile
; Description ...: Decodes Base64 text and writes it to a file.
; Syntax ........: __WebView2_Base64_WriteFile($sBase64, $sFilePath)
; Parameters ....: $sBase64 - Base64-encoded data.
;                  $sFilePath - Destination file path.
; Return values .: True on success; otherwise False.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Base64_WriteFile($sBase64, $sFilePath)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_Base64_WriteFile"
	Local $sMessage = ''
	Do
		Local $bData = __WebView2_Base64_DecodeBinary($sBase64)
		If @error Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_JAVASCRIPT, @extended, "Unable to decode Base64 payload.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = __WebView2_Binary_WriteFile($bData, $sFilePath)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_Base64_WriteFile
