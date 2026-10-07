#include-once
#Tidy_ILC_Pos=44

#include "WebView2_DOM.au3"

; #INDEX# =======================================================================================================================
; Title .........: WebView2_IECompat.au3
; Description ...: WebView2 helpers covering useful IE.au3-style DOM operations without exposing legacy Internet Explorer COM objects.
; Author(s) .....: mLipok
; Version .......: 0.5.0
; Remarks .......: These are WebView2-native helpers, not drop-in _IE* compatibility aliases.
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetBodyHTML
; Description ...: Returns the HTML inside the document body.
; Syntax ........: _WebView2_GetBodyHTML($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: Body HTML text, or an empty string when unavailable.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_GetBodyHTML($iWebView)
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, "document.body?document.body.innerHTML:''", "")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetBodyHTML

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetBodyText
; Description ...: Returns the visible text of the document body.
; Syntax ........: _WebView2_GetBodyText($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: Body text, or an empty string when unavailable.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_GetBodyText($iWebView)
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, "document.body?(document.body.innerText||document.body.textContent||''):''", "")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetBodyText

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetBodyHTML
; Description ...: Replaces the HTML inside the document body.
; Syntax ........: _WebView2_SetBodyHTML($iWebView, $sHTML)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sHTML - HTML source to insert or display.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_SetBodyHTML($iWebView, $sHTML)
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, "(()=>{if(!document.body)return false;document.body.innerHTML=" & __WebView2_JavaScript_StringLiteral($sHTML) & ";return true;})()", False)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_SetBodyHTML

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_DocReadHTML
; Description ...: Returns the full document HTML source.
; Syntax ........: _WebView2_DocReadHTML($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: HTML source, or an empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_GetHtmlSource
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_DocReadHTML($iWebView)
	Local $__WebView2DirectResult = _WebView2_GetHtmlSource($iWebView)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_DocReadHTML

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_DocWriteHTML
; Description ...: Navigates to a document created from the supplied HTML.
; Syntax ........: _WebView2_DocWriteHTML($iWebView, $sHTML)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sHTML - HTML source to insert or display.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_NavigateToString
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_DocWriteHTML($iWebView, $sHTML)
	Local $__WebView2DirectResult = _WebView2_NavigateToString($iWebView, $sHTML)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_DocWriteHTML

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_InsertHTML
; Description ...: Inserts HTML next to the element identified by a DOM token.
; Syntax ........: _WebView2_InsertHTML($iWebView, $sElement, $sWhere, $sHTML)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque DOM element token.
;                  $sWhere - Insertion point relative to the element (aliases accepted):
;                  |BEFOREBEGIN - Before the element.
;                  |AFTERBEGIN  - At the start of its content.
;                  |BEFOREEND   - At the end of its content.
;                  |AFTEREND    - After the element.
;                  $sHTML - HTML source to insert or display.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_InsertHTML($iWebView, $sElement, $sWhere, $sHTML)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_InsertHTML"
	Local $sMessage = ''
	Do
		Local $sPosition = __WebView2_IE_InsertPosition($sWhere)
		If @error Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $sScript = __WebView2_DOM_RegistryPrefix() & "const el=__wv2.get(" & __WebView2_JavaScript_StringLiteral($sElement) & ");if(!el)return '__WV2_ERROR__:STALE';el.insertAdjacentHTML(" & __WebView2_JavaScript_StringLiteral($sPosition) & "," & __WebView2_JavaScript_StringLiteral($sHTML) & ");return true;})()"
		$__WebView2ExitValue = __WebView2_DOM_Execute($iWebView, $sScript, False)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_InsertHTML

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_InsertText
; Description ...: Inserts text next to the element identified by a DOM token.
; Syntax ........: _WebView2_InsertText($iWebView, $sElement, $sWhere, $sText)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque DOM element token.
;                  $sWhere - Insertion point relative to the element (aliases accepted):
;                  |BEFOREBEGIN - Before the element.
;                  |AFTERBEGIN  - At the start of its content.
;                  |BEFOREEND   - At the end of its content.
;                  |AFTEREND    - After the element.
;                  $sText - Plain text to insert.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_InsertText($iWebView, $sElement, $sWhere, $sText)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_InsertText"
	Local $sMessage = ''
	Do
		Local $sPosition = __WebView2_IE_InsertPosition($sWhere)
		If @error Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $sScript = __WebView2_DOM_RegistryPrefix() & "const el=__wv2.get(" & __WebView2_JavaScript_StringLiteral($sElement) & ");if(!el)return '__WV2_ERROR__:STALE';el.insertAdjacentText(" & __WebView2_JavaScript_StringLiteral($sPosition) & "," & __WebView2_JavaScript_StringLiteral($sText) & ");return true;})()"
		$__WebView2ExitValue = __WebView2_DOM_Execute($iWebView, $sScript, False)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_InsertText

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetElementsByTagName
; Description ...: Returns DOM tokens for elements with the given tag name.
; Syntax ........: _WebView2_GetElementsByTagName($iWebView, $sTagName)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sTagName - HTML tag name.
; Return values .: Array of DOM tokens or one token; 0/empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_GetElementsByTagName($iWebView, $sTagName)
	Local $__WebView2DirectResult = _WebView2_FindElements($iWebView, $WEBVIEW2_LOCATOR_BY_TAG_NAME, $sTagName)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetElementsByTagName

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetAllElements
; Description ...: Returns DOM tokens for all document elements.
; Syntax ........: _WebView2_GetAllElements($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: Array of DOM tokens or one token; 0/empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_GetAllElements($iWebView)
	Local $__WebView2DirectResult = _WebView2_FindElements($iWebView, $WEBVIEW2_LOCATOR_BY_CSS_SELECTOR, "*")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetAllElements

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetLinks
; Description ...: Returns DOM tokens for document links.
; Syntax ........: _WebView2_GetLinks($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: Array of DOM tokens or one token; 0/empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_GetLinks($iWebView)
	Local $__WebView2DirectResult = _WebView2_FindElements($iWebView, $WEBVIEW2_LOCATOR_BY_TAG_NAME, "a")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetLinks

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetImages
; Description ...: Returns DOM tokens for document images.
; Syntax ........: _WebView2_GetImages($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: Array of DOM tokens or one token; 0/empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_GetImages($iWebView)
	Local $__WebView2DirectResult = _WebView2_FindElements($iWebView, $WEBVIEW2_LOCATOR_BY_TAG_NAME, "img")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetImages

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetForms
; Description ...: Returns DOM tokens for document forms.
; Syntax ........: _WebView2_GetForms($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: Array of DOM tokens or one token; 0/empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_GetForms($iWebView)
	Local $__WebView2DirectResult = _WebView2_FindElements($iWebView, $WEBVIEW2_LOCATOR_BY_TAG_NAME, "form")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetForms

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetTables
; Description ...: Returns DOM tokens for document tables.
; Syntax ........: _WebView2_GetTables($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: Array of DOM tokens or one token; 0/empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_GetTables($iWebView)
	Local $__WebView2DirectResult = _WebView2_FindElements($iWebView, $WEBVIEW2_LOCATOR_BY_TAG_NAME, "table")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetTables

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetFrames
; Description ...: Returns DOM tokens for frames and iframes.
; Syntax ........: _WebView2_GetFrames($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: Array of DOM tokens or one token; 0/empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_GetFrames($iWebView)
	Local $__WebView2DirectResult = _WebView2_FindElements($iWebView, $WEBVIEW2_LOCATOR_BY_CSS_SELECTOR, "iframe,frame")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetFrames

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetFormByName
; Description ...: Finds a form by its name or ID and returns its DOM token.
; Syntax ........: _WebView2_GetFormByName($iWebView, $sName)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sName - Element name or ID.
; Return values .: Opaque DOM token, or an empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_GetFormByName($iWebView, $sName)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_GetFormByName"
	Local $sMessage = ''
	Do
		Local $sScript = __WebView2_DOM_RegistryPrefix() & "const n=" & __WebView2_JavaScript_StringLiteral($sName) & ";const el=Array.from(document.forms).find(f=>f.name===n||f.id===n);return el?__wv2.store(el):null;})()"
		Local $sToken = __WebView2_DOM_Execute($iWebView, $sScript, "")
		If $sToken = "" Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_NO_MATCH, 0, "Form not found.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $sToken
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_GetFormByName

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_FormGetElements
; Description ...: Returns DOM tokens for controls belonging to a form.
; Syntax ........: _WebView2_FormGetElements($iWebView, $sForm)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sForm - Opaque form token.
; Return values .: Array of DOM tokens or one token; 0/empty string on failure.
;                  Also propagates @error/@extended from a called helper on the guarded path.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_FormGetElements($iWebView, $sForm)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_FormGetElements"
	Local $sMessage = ''
	Do
		Local $sScript = __WebView2_DOM_RegistryPrefix() & "const f=__wv2.get(" & __WebView2_JavaScript_StringLiteral($sForm) & ");if(!f)return '__WV2_ERROR__:STALE';return Array.from(f.elements||[]).map(e=>__wv2.store(e)).join('\\u001f');})()"
		Local $sResult = __WebView2_DOM_Execute($iWebView, $sScript, "")
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If $sResult = "" Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_NO_MATCH, 0, "Form contains no elements.", 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = StringSplit($sResult, Chr(31), 2)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_FormGetElements

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_FormReset
; Description ...: Resets a form to its initial control values.
; Syntax ........: _WebView2_FormReset($iWebView, $sForm)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sForm - Opaque form token.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_FormReset($iWebView, $sForm)
	Local $sScript = __WebView2_DOM_RegistryPrefix() & "const f=__wv2.get(" & __WebView2_JavaScript_StringLiteral($sForm) & ");if(!f)return '__WV2_ERROR__:STALE';f.reset();return true;})()"
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, $sScript, False)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_FormReset

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_FormSubmit
; Description ...: Submits a form, optionally using requestSubmit().
; Syntax ........: _WebView2_FormSubmit($iWebView, $sForm[, $bRequestSubmit = True])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sForm - Opaque form token.
;                  $bRequestSubmit - Whether to use requestSubmit() when available. Default: True.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_FormSubmit($iWebView, $sForm, $bRequestSubmit = True)
	Local $sMethod = $bRequestSubmit ? "if(f.requestSubmit)f.requestSubmit();else f.submit();" : "f.submit();"
	Local $sScript = __WebView2_DOM_RegistryPrefix() & "const f=__wv2.get(" & __WebView2_JavaScript_StringLiteral($sForm) & ");if(!f)return '__WV2_ERROR__:STALE';" & $sMethod & "return true;})()"
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, $sScript, False)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_FormSubmit

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_FormElementGetValue
; Description ...: Returns the current value of a form control.
; Syntax ........: _WebView2_FormElementGetValue($iWebView, $sElement)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque DOM element token.
; Return values .: Current control value, or an empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_FormElementGetValue($iWebView, $sElement)
	Local $__WebView2DirectResult = _WebView2_ElementAction($iWebView, $sElement, "VALUE")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_FormElementGetValue

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_FormElementSetValue
; Description ...: Sets the current value of a form control.
; Syntax ........: _WebView2_FormElementSetValue($iWebView, $sElement, $sValue)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque DOM element token.
;                  $sValue - Text or value to write.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_FormElementSetValue($iWebView, $sElement, $sValue)
	Local $__WebView2DirectResult = _WebView2_SetElementValue($iWebView, $sElement, $sValue)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_FormElementSetValue

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_FormElementCheckBoxSelect
; Description ...: Changes the checked state of a checkbox.
; Syntax ........: _WebView2_FormElementCheckBoxSelect($iWebView, $sElement[, $bSelect = True[, $bFireChange = True]])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque DOM element token.
;                  $bSelect - Desired checked state. Default: True.
;                  $bFireChange - Whether to dispatch a change event. Default: True.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_FormElementCheckBoxSelect($iWebView, $sElement, $bSelect = True, $bFireChange = True)
	Local $__WebView2DirectResult = __WebView2_IE_SetChecked($iWebView, $sElement, $bSelect, $bFireChange, "checkbox")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_FormElementCheckBoxSelect

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_FormElementRadioSelect
; Description ...: Changes the checked state of a radio button.
; Syntax ........: _WebView2_FormElementRadioSelect($iWebView, $sElement[, $bSelect = True[, $bFireChange = True]])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque DOM element token.
;                  $bSelect - Desired checked state. Default: True.
;                  $bFireChange - Whether to dispatch a change event. Default: True.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_FormElementRadioSelect($iWebView, $sElement, $bSelect = True, $bFireChange = True)
	Local $__WebView2DirectResult = __WebView2_IE_SetChecked($iWebView, $sElement, $bSelect, $bFireChange, "radio")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_FormElementRadioSelect

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_LinkClickByIndex
; Description ...: Clicks a document link selected by zero-based index.
; Syntax ........: _WebView2_LinkClickByIndex($iWebView, $iIndex)
; Parameters ....: $iWebView - WebView instance ID.
;                  $iIndex - Zero-based link index.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_LinkClickByIndex($iWebView, $iIndex)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_LinkClickByIndex"
	Local $sMessage = ''
	Do
		Local $aLinks = _WebView2_GetLinks($iWebView)
		If @error Or Not IsArray($aLinks) Or $iIndex < 0 Or $iIndex >= UBound($aLinks) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_NO_MATCH, 0, "Link index does not exist.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = _WebView2_ElementAction($iWebView, $aLinks[$iIndex], "CLICK")
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_LinkClickByIndex

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ImageClick
; Description ...: Clicks the first image matching a search string.
; Syntax ........: _WebView2_ImageClick($iWebView, $sSearch[, $sMode = "src"])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sSearch - Text to find in the image property.
;                  $sMode - Image attribute to search; default is SRC:
;                  |SRC  - Match the image source URL.
;                  |ALT  - Match alternative text.
;                  |NAME - Match the image name.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_ImageClick($iWebView, $sSearch, $sMode = "src")
	Local $sScript = __WebView2_DOM_RegistryPrefix() & "const q=" & __WebView2_JavaScript_StringLiteral($sSearch) & ";const m=" & __WebView2_JavaScript_StringLiteral(StringLower($sMode)) & ";const el=Array.from(document.images).find(i=>String(m==='alt'?i.alt:m==='name'?i.name:i.src).includes(q));if(!el)return '__WV2_ERROR__:NOMATCH';el.click();return true;})()"
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, $sScript, False)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_ImageClick

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetFrameByName
; Description ...: Finds a frame by name or ID and returns its DOM token.
; Syntax ........: _WebView2_GetFrameByName($iWebView, $sName)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sName - Element name or ID.
; Return values .: Opaque DOM token, or an empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_GetFrameByName($iWebView, $sName)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_GetFrameByName"
	Local $sMessage = ''
	Do
		Local $sScript = __WebView2_DOM_RegistryPrefix() & "const n=" & __WebView2_JavaScript_StringLiteral($sName) & ";const el=Array.from(document.querySelectorAll('iframe,frame')).find(f=>f.name===n||f.id===n);return el?__wv2.store(el):null;})()"
		Local $sToken = __WebView2_DOM_Execute($iWebView, $sScript, "")
		If $sToken = "" Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_NO_MATCH, 0, "Frame not found.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $sToken
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_GetFrameByName

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_IsFrameSet
; Description ...: Reports whether the document contains a frameset.
; Syntax ........: _WebView2_IsFrameSet($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: True if a frameset exists; otherwise False.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_IsFrameSet($iWebView)
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, "document.querySelector('frameset')!==null", False)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_IsFrameSet

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetProperty
; Description ...: Reads a property from an element identified by a DOM token.
; Syntax ........: _WebView2_GetProperty($iWebView, $sElement, $sProperty)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque DOM element token.
;                  $sProperty - DOM property name.
; Return values .: DOM property value, or an empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_GetProperty($iWebView, $sElement, $sProperty)
	Local $sScript = __WebView2_DOM_RegistryPrefix() & "const el=__wv2.get(" & __WebView2_JavaScript_StringLiteral($sElement) & ");if(!el)return '__WV2_ERROR__:STALE';const p=" & __WebView2_JavaScript_StringLiteral($sProperty) & ";const v=el[p];return v==null?null:(typeof v==='object'?String(v):v);})()"
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, $sScript, "")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetProperty

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetProperty
; Description ...: Sets a property on an element identified by a DOM token.
; Syntax ........: _WebView2_SetProperty($iWebView, $sElement, $sProperty, $vValue)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque DOM element token.
;                  $sProperty - DOM property name.
;                  $vValue - Value to write or option to select.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_SetProperty($iWebView, $sElement, $sProperty, $vValue)
	Local $sValue = IsBool($vValue) ? ($vValue ? "true" : "false") : __WebView2_JavaScript_StringLiteral(String($vValue))
	Local $sScript = __WebView2_DOM_RegistryPrefix() & "const el=__wv2.get(" & __WebView2_JavaScript_StringLiteral($sElement) & ");if(!el)return '__WV2_ERROR__:STALE';el[" & __WebView2_JavaScript_StringLiteral($sProperty) & "]=" & $sValue & ";return true;})()"
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, $sScript, False)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_SetProperty

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_AddEventScript
; Description ...: Registers JavaScript for a document event.
; Syntax ........: _WebView2_AddEventScript($iWebView, $sEvent, $sJavaScript)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sEvent - DOM event name.
;                  $sJavaScript - JavaScript source text.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_AddEventScript($iWebView, $sEvent, $sJavaScript)
	Local $sScript = "document.addEventListener(" & __WebView2_JavaScript_StringLiteral($sEvent) & ",function(event){" & $sJavaScript & "});true"
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, $sScript, False)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_AddEventScript

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_IE_SetChecked
; Description ...: Sets an element's checked state and optionally fires change.
; Syntax ........: __WebView2_IE_SetChecked($iWebView, $sElement, $bSelect, $bFireChange, $sType)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque DOM element token.
;                  $bSelect - Desired checked state.
;                  $bFireChange - Whether to dispatch a change event.
;                  $sType - Expected HTML input type.
; Return values .: True if the element was changed; otherwise False.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_IE_SetChecked($iWebView, $sElement, $bSelect, $bFireChange, $sType)
	Local $sScript = __WebView2_DOM_RegistryPrefix() & "const el=__wv2.get(" & __WebView2_JavaScript_StringLiteral($sElement) & ");if(!el)return '__WV2_ERROR__:STALE';if(String(el.type).toLowerCase()!==" & __WebView2_JavaScript_StringLiteral($sType) & ")return '__WV2_ERROR__:TYPE';el.checked=" & ($bSelect ? "true" : "false") & ";" & ($bFireChange ? "el.dispatchEvent(new Event('change',{bubbles:true}));" : "") & "return true;})()"
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, $sScript, False)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>__WebView2_IE_SetChecked

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_IE_InsertPosition
; Description ...: Normalizes an insertion position name.
; Syntax ........: __WebView2_IE_InsertPosition($sWhere)
; Parameters ....: $sWhere - Insertion point relative to the element; beforebegin, afterbegin, beforeend or afterend (aliases accepted).
; Return values .: Normalized insertion position, or an empty string with @error on invalid input.
;                  @error $WEBVIEW2_ERR_INVALID_PARAMETER - Invalid parameter or incompatible element type.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_IE_InsertPosition($sWhere)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_IE_InsertPosition"
	Local $sMessage = ''
	Do
		Switch StringLower($sWhere)
			Case "beforebegin", "before"
				$__WebView2ExitValue = "beforebegin"
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			Case "afterbegin", "start"
				$__WebView2ExitValue = "afterbegin"
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			Case "beforeend", "end"
				$__WebView2ExitValue = "beforeend"
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			Case "afterend", "after"
				$__WebView2ExitValue = "afterend"
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
		EndSwitch
		$__WebView2ExitValue = SetError($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "")
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_IE_InsertPosition

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Action
; Description ...: Performs a common IE.au3-style action on a DOM element token.
; Syntax ........: _WebView2_Action($iWebView, $sElement, $sAction)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Element token returned by a DOM helper.
;                  $sAction - One of the following actions:
;                  |CLICK          - Clicks the element.
;                  |FOCUS          - Focuses the element.
;                  |SCROLLINTOVIEW - Scrolls the element into view.
;                  |SUBMIT         - Submits the related form.
;                  |SELECT         - Selects the element.
;                  |UNSELECT       - Deselects the element.
; Return values .: On Success - Action-specific result; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Provides a migration-friendly equivalent of the most useful _IEAction operations.
; Related .......: _WebView2_ElementAction, _WebView2_DispatchEvent
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Action($iWebView, $sElement, $sAction)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_Action"
	Local $sMessage = ''
	Do
		Switch StringLower($sAction)
			Case "click"
				$__WebView2ExitValue = _WebView2_ElementAction($iWebView, $sElement, "CLICK")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			Case "focus"
				$__WebView2ExitValue = _WebView2_ElementAction($iWebView, $sElement, "FOCUS")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			Case "scrollintoview"
				$__WebView2ExitValue = _WebView2_ElementAction($iWebView, $sElement, "SCROLLINTOVIEW")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			Case "submit"
				Local $sScript = __WebView2_DOM_RegistryPrefix() & "const el=__wv2.get(" & __WebView2_JavaScript_StringLiteral($sElement) & ");if(!el)return '__WV2_ERROR__:STALE';const f=el.tagName==='FORM'?el:el.form;if(!f)return '__WV2_ERROR__:TYPE';if(f.requestSubmit)f.requestSubmit();else f.submit();return true;})()"
				$__WebView2ExitValue = __WebView2_DOM_Execute($iWebView, $sScript, False)
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			Case "select"
				$__WebView2ExitValue = _WebView2_SetProperty($iWebView, $sElement, "selected", True)
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			Case "unselect"
				$__WebView2ExitValue = _WebView2_SetProperty($iWebView, $sElement, "selected", False)
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
		EndSwitch
		$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Unsupported action: " & $sAction, False)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_Action

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_BodyReadHTML
; Description ...: IE.au3-style alias for reading document.body.innerHTML.
; Syntax ........: _WebView2_BodyReadHTML($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: HTML string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_GetBodyHTML
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_BodyReadHTML($iWebView)
	Local $__WebView2DirectResult = _WebView2_GetBodyHTML($iWebView)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_BodyReadHTML

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_BodyReadText
; Description ...: Returns the visible text of the document body.
; Syntax ........: _WebView2_BodyReadText($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: Document text, or an empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_GetBodyText
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_BodyReadText($iWebView)
	Local $__WebView2DirectResult = _WebView2_GetBodyText($iWebView)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_BodyReadText

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_BodyWriteHTML
; Description ...: Replaces the HTML inside the document body.
; Syntax ........: _WebView2_BodyWriteHTML($iWebView, $sHTML)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sHTML - HTML source to insert or display.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetBodyHTML
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_BodyWriteHTML($iWebView, $sHTML)
	Local $__WebView2DirectResult = _WebView2_SetBodyHTML($iWebView, $sHTML)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_BodyWriteHTML

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_FormGetCollection
; Description ...: Returns form tokens or one form token by index.
; Syntax ........: _WebView2_FormGetCollection($iWebView[, $iIndex = Default])
; Parameters ....: $iWebView - WebView instance ID.
;                  $iIndex - Zero-based item index. Omit to return the entire collection.
; Return values .: Array of form tokens, one token, or 0/empty string on failure.
;                  Also propagates @error/@extended from a called helper on the guarded path.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_FormGetCollection($iWebView, $iIndex = Default)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_FormGetCollection"
	Local $sMessage = ''
	Do
		Local $aForms = _WebView2_GetForms($iWebView)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If $iIndex = Default Then
			$__WebView2ExitValue = $aForms
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not IsArray($aForms) Or $iIndex < 0 Or $iIndex >= UBound($aForms) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_NO_MATCH, 0, "Form index does not exist.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $aForms[$iIndex]
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_FormGetCollection

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_FormElementGetCollection
; Description ...: Returns control tokens from a form or one token by index.
; Syntax ........: _WebView2_FormElementGetCollection($iWebView, $sForm[, $iIndex = Default])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sForm - Opaque form token.
;                  $iIndex - Zero-based item index. Omit to return the entire collection.
; Return values .: Array of control tokens, one token, or 0/empty string on failure.
;                  Also propagates @error/@extended from a called helper on the guarded path.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_FormElementGetCollection($iWebView, $sForm, $iIndex = Default)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_FormElementGetCollection"
	Local $sMessage = ''
	Do
		Local $aElements = _WebView2_FormGetElements($iWebView, $sForm)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If $iIndex = Default Then
			$__WebView2ExitValue = $aElements
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not IsArray($aElements) Or $iIndex < 0 Or $iIndex >= UBound($aElements) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_NO_MATCH, 0, "Form element index does not exist.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $aElements[$iIndex]
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_FormElementGetCollection

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_FormElementGetByName
; Description ...: Finds a form control by name or ID.
; Syntax ........: _WebView2_FormElementGetByName($iWebView, $sForm, $sName)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sForm - Opaque form token.
;                  $sName - Element name or ID.
; Return values .: Opaque DOM token, or an empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_FormElementGetByName($iWebView, $sForm, $sName)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_FormElementGetByName"
	Local $sMessage = ''
	Do
		Local $sScript = __WebView2_DOM_RegistryPrefix() & "const f=__wv2.get(" & __WebView2_JavaScript_StringLiteral($sForm) & ");if(!f)return '__WV2_ERROR__:STALE';const n=" & __WebView2_JavaScript_StringLiteral($sName) & ";const el=Array.from(f.elements||[]).find(e=>e.name===n||e.id===n);return el?__wv2.store(el):null;})()"
		Local $sToken = __WebView2_DOM_Execute($iWebView, $sScript, "")
		If $sToken = "" Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_NO_MATCH, 0, "Form element not found.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $sToken
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_FormElementGetByName

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_FormElementOptionSelect
; Description ...: Selects an option in a form control.
; Syntax ........: _WebView2_FormElementOptionSelect($iWebView, $sElement, $vValue[, $sMode = "TEXT"])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque DOM element token.
;                  $vValue - Option text, value or zero-based index, according to $sMode.
;                  $sMode - Matching mode; default is TEXT:
;                  |TEXT  - Match option text.
;                  |VALUE - Match option value.
;                  |INDEX - Match zero-based option index.
; Return values .: Selected option index, or an empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_FormElementOptionSelect($iWebView, $sElement, $vValue, $sMode = "TEXT")
	Local $__WebView2DirectResult = _WebView2_ElementOptionSelect($iWebView, $sElement, $vValue, $sMode)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_FormElementOptionSelect

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_LinkGetCollection
; Description ...: Returns link tokens or one link token by index.
; Syntax ........: _WebView2_LinkGetCollection($iWebView[, $iIndex = Default])
; Parameters ....: $iWebView - WebView instance ID.
;                  $iIndex - Zero-based item index. Omit to return the entire collection.
; Return values .: Array of DOM tokens or one token; 0/empty string on failure.
;                  Also propagates @error/@extended from a called helper on the guarded path.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_LinkGetCollection($iWebView, $iIndex = Default)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_LinkGetCollection"
	Local $sMessage = ''
	Do
		Local $aItems = _WebView2_GetLinks($iWebView)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = __WebView2_IE_CollectionItem($aItems, $iIndex, "Link")
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_LinkGetCollection

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ImgGetCollection
; Description ...: Returns image tokens or one image token by index.
; Syntax ........: _WebView2_ImgGetCollection($iWebView[, $iIndex = Default])
; Parameters ....: $iWebView - WebView instance ID.
;                  $iIndex - Zero-based item index. Omit to return the entire collection.
; Return values .: Array of DOM tokens or one token; 0/empty string on failure.
;                  Also propagates @error/@extended from a called helper on the guarded path.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_ImgGetCollection($iWebView, $iIndex = Default)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_ImgGetCollection"
	Local $sMessage = ''
	Do
		Local $aItems = _WebView2_GetImages($iWebView)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = __WebView2_IE_CollectionItem($aItems, $iIndex, "Image")
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_ImgGetCollection

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_TableGetCollection
; Description ...: Returns table tokens or one table token by index.
; Syntax ........: _WebView2_TableGetCollection($iWebView[, $iIndex = Default])
; Parameters ....: $iWebView - WebView instance ID.
;                  $iIndex - Zero-based item index. Omit to return the entire collection.
; Return values .: Array of DOM tokens or one token; 0/empty string on failure.
;                  Also propagates @error/@extended from a called helper on the guarded path.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_TableGetCollection($iWebView, $iIndex = Default)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_TableGetCollection"
	Local $sMessage = ''
	Do
		Local $aItems = _WebView2_GetTables($iWebView)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = __WebView2_IE_CollectionItem($aItems, $iIndex, "Table")
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_TableGetCollection

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_FrameGetCollection
; Description ...: Returns frame tokens or one frame token by index.
; Syntax ........: _WebView2_FrameGetCollection($iWebView[, $iIndex = Default])
; Parameters ....: $iWebView - WebView instance ID.
;                  $iIndex - Zero-based item index. Omit to return the entire collection.
; Return values .: Array of DOM tokens or one token; 0/empty string on failure.
;                  Also propagates @error/@extended from a called helper on the guarded path.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_FrameGetCollection($iWebView, $iIndex = Default)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_FrameGetCollection"
	Local $sMessage = ''
	Do
		Local $aItems = _WebView2_GetFrames($iWebView)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = __WebView2_IE_CollectionItem($aItems, $iIndex, "Frame")
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_FrameGetCollection

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_FrameGetByName
; Description ...: Finds a frame by name or ID.
; Syntax ........: _WebView2_FrameGetByName($iWebView, $sName)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sName - Element name or ID.
; Return values .: Opaque DOM token, or an empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_GetFrameByName
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_FrameGetByName($iWebView, $sName)
	Local $__WebView2DirectResult = _WebView2_GetFrameByName($iWebView, $sName)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_FrameGetByName

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_TagNameGetCollection
; Description ...: Returns tokens for a tag or one token by index.
; Syntax ........: _WebView2_TagNameGetCollection($iWebView, $sTagName[, $iIndex = Default])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sTagName - HTML tag name.
;                  $iIndex - Zero-based item index. Omit to return the entire collection.
; Return values .: Array of DOM tokens or one token; 0/empty string on failure.
;                  Also propagates @error/@extended from a called helper on the guarded path.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_TagNameGetCollection($iWebView, $sTagName, $iIndex = Default)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_TagNameGetCollection"
	Local $sMessage = ''
	Do
		Local $aItems = _WebView2_GetElementsByTagName($iWebView, $sTagName)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = __WebView2_IE_CollectionItem($aItems, $iIndex, "Tag")
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_TagNameGetCollection

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_TagNameAllGetCollection
; Description ...: Returns all element tokens or one token by index.
; Syntax ........: _WebView2_TagNameAllGetCollection($iWebView[, $iIndex = Default])
; Parameters ....: $iWebView - WebView instance ID.
;                  $iIndex - Zero-based item index. Omit to return the entire collection.
; Return values .: Array of DOM tokens or one token; 0/empty string on failure.
;                  Also propagates @error/@extended from a called helper on the guarded path.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_TagNameAllGetCollection($iWebView, $iIndex = Default)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_TagNameAllGetCollection"
	Local $sMessage = ''
	Do
		Local $aItems = _WebView2_GetAllElements($iWebView)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = __WebView2_IE_CollectionItem($aItems, $iIndex, "Element")
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_TagNameAllGetCollection

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_TableWriteToArray
; Description ...: Converts the cells of a DOM table to a two-dimensional array.
; Syntax ........: _WebView2_TableWriteToArray($iWebView, $sTable)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sTable - Opaque table token.
; Return values .: Two-dimensional table array, or 0 on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_GetTable
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_TableWriteToArray($iWebView, $sTable)
	Local $__WebView2DirectResult = _WebView2_GetTable($iWebView, $sTable)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_TableWriteToArray

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_PropertyGet
; Description ...: Reads a property from a DOM element.
; Syntax ........: _WebView2_PropertyGet($iWebView, $sElement, $sProperty)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque DOM element token.
;                  $sProperty - DOM property name.
; Return values .: DOM property value, or an empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_GetProperty
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_PropertyGet($iWebView, $sElement, $sProperty)
	Local $__WebView2DirectResult = _WebView2_GetProperty($iWebView, $sElement, $sProperty)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_PropertyGet

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_PropertySet
; Description ...: Sets a property on a DOM element.
; Syntax ........: _WebView2_PropertySet($iWebView, $sElement, $sProperty, $vValue)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque DOM element token.
;                  $sProperty - DOM property name.
;                  $vValue - Value to write or option to select.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_SetProperty
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_PropertySet($iWebView, $sElement, $sProperty, $vValue)
	Local $__WebView2DirectResult = _WebView2_SetProperty($iWebView, $sElement, $sProperty, $vValue)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_PropertySet

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_HeadInsertHTML
; Description ...: Appends HTML to the document head.
; Syntax ........: _WebView2_HeadInsertHTML($iWebView, $sHTML)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sHTML - HTML source to insert or display.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_HeadInsertHTML($iWebView, $sHTML)
	Local $sScript = "(()=>{if(!document.head)return false;document.head.insertAdjacentHTML('beforeend'," & __WebView2_JavaScript_StringLiteral($sHTML) & ");return true;})()"
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, $sScript, False)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_HeadInsertHTML

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_HeadInsertScript
; Description ...: Appends a script element to the document head.
; Syntax ........: _WebView2_HeadInsertScript($iWebView, $sJavaScript)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sJavaScript - JavaScript source text.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_HeadInsertScript($iWebView, $sJavaScript)
	Local $sScript = "(()=>{if(!document.head)return false;const s=document.createElement('script');s.text=" & __WebView2_JavaScript_StringLiteral($sJavaScript) & ";document.head.appendChild(s);return true;})()"
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, $sScript, False)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_HeadInsertScript

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_HeadInsertEventScript
; Description ...: Registers JavaScript for a document event.
; Syntax ........: _WebView2_HeadInsertEventScript($iWebView, $sEvent, $sJavaScript)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sEvent - DOM event name.
;                  $sJavaScript - JavaScript source text.
; Return values .: True on success; False on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WebView2_AddEventScript
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_HeadInsertEventScript($iWebView, $sEvent, $sJavaScript)
	Local $__WebView2DirectResult = _WebView2_AddEventScript($iWebView, $sEvent, $sJavaScript)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_HeadInsertEventScript

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_IE_CollectionItem
; Description ...: Returns a collection or its zero-based indexed token.
; Syntax ........: __WebView2_IE_CollectionItem($aItems, $iIndex, $sKind)
; Parameters ....: $aItems - Array of opaque DOM tokens.
;                  $iIndex - Zero-based item index. Pass Default to return the entire collection.
;                  $sKind - Collection kind used in diagnostics.
; Return values .: Array when $iIndex is Default; otherwise the indexed token or an empty string on failure.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_IE_CollectionItem($aItems, $iIndex, $sKind)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_IE_CollectionItem"
	Local $sMessage = ''
	Do
		If $iIndex = Default Then
			$__WebView2ExitValue = $aItems
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not IsArray($aItems) Or $iIndex < 0 Or $iIndex >= UBound($aItems) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_NO_MATCH, 0, $sKind & " index does not exist.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $aItems[$iIndex]
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_IE_CollectionItem
