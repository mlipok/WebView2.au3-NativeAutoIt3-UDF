#include-once
#Tidy_ILC_Pos=44

; #INDEX# =======================================================================================================================
; Title .........: WebView2_DOM.au3
; Description ...: DOM automation helpers for WebView2.au3, inspired by useful au3WebDriver patterns but implemented natively via WebView2 ExecuteScript.
; Author(s) .....: mLipok
; Version .......: 0.5.0
; ===============================================================================================================================

#include "WebView2_Core.au3"
#include <StringConstants.au3>

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_FindElement
; Description ...: Finds the first DOM element matching a supported locator strategy and returns an opaque element token.
; Syntax ........: _WebView2_FindElement($iWebView, $sStrategy, $sSelector)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sStrategy - One of the following $WEBVIEW2_LOCATOR_* strategies:
;                  |CSS_SELECTOR      - Matches a CSS selector.
;                  |XPATH             - Matches an XPath expression.
;                  |ID                - Matches an element ID.
;                  |NAME              - Matches an element name.
;                  |TAG_NAME          - Matches an HTML tag name.
;                  |LINK_TEXT         - Matches complete link text.
;                  |PARTIAL_LINK_TEXT - Matches part of link text.
;                  $sSelector - Locator value.
; Return values .: On Success - Opaque element token; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Element tokens are valid only for the current document. Navigation makes previous tokens stale.
; Related .......: _WebView2_FindElements, _WebView2_ElementAction
; Link ..........: https://www.w3.org/TR/webdriver/#element-retrieval
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_FindElement($iWebView, $sStrategy, $sSelector)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_FindElement"
	Local $sMessage = ''
	Do
		If Not __WebView2_DOM_Locator_IsValid($sStrategy) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Unsupported DOM locator strategy.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $sScript = __WebView2_DOM_RegistryPrefix() & _
				"const strategy=" & __WebView2_JavaScript_StringLiteral(StringLower($sStrategy)) & ";" & _
				"const selector=" & __WebView2_JavaScript_StringLiteral($sSelector) & ";" & _
				"const el=__wv2.findOne(strategy,selector);" & _
				"return el?__wv2.store(el):null;})()"
		Local $vResult = __WebView2_DOM_Execute($iWebView, $sScript, "")
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If $vResult = "" Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_NO_MATCH, 0, "DOM element not found.", "")
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
EndFunc   ;==>_WebView2_FindElement

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_FindElements
; Description ...: Finds all DOM elements matching a supported locator strategy.
; Syntax ........: _WebView2_FindElements($iWebView, $sStrategy, $sSelector)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sStrategy - One of the following $WEBVIEW2_LOCATOR_* strategies:
;                  |CSS_SELECTOR      - Matches a CSS selector.
;                  |XPATH             - Matches an XPath expression.
;                  |ID                - Matches an element ID.
;                  |NAME              - Matches an element name.
;                  |TAG_NAME          - Matches an HTML tag name.
;                  |LINK_TEXT         - Matches complete link text.
;                  |PARTIAL_LINK_TEXT - Matches part of link text.
;                  $sSelector - Locator value.
; Return values .: On Success - One-dimensional array of opaque element tokens; On Failure - 0.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Element tokens are document-scoped and become stale after navigation.
; Related .......: _WebView2_FindElement, _WebView2_ElementAction
; Link ..........: https://www.w3.org/TR/webdriver/#element-retrieval
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_FindElements($iWebView, $sStrategy, $sSelector)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_FindElements"
	Local $sMessage = ''
	Do
		If Not __WebView2_DOM_Locator_IsValid($sStrategy) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Unsupported DOM locator strategy.", 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $sScript = __WebView2_DOM_RegistryPrefix() & _
				"const strategy=" & __WebView2_JavaScript_StringLiteral(StringLower($sStrategy)) & ";" & _
				"const selector=" & __WebView2_JavaScript_StringLiteral($sSelector) & ";" & _
				"return __wv2.findAll(strategy,selector).map(e=>__wv2.store(e)).join('\u001f');})()"
		Local $vResult = __WebView2_DOM_Execute($iWebView, $sScript, "")
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If $vResult = "" Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_NO_MATCH, 0, "DOM elements not found.", 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = StringSplit($vResult, Chr(31), $STR_NOCOUNT)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_FindElements

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetElementById
; Description ...: Finds the first element with the specified id attribute.
; Syntax ........: _WebView2_GetElementById($iWebView, $sId)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sId - Element id.
; Return values .: On Success - Opaque element token; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Convenience wrapper equivalent in purpose to au3WebDriver _WD_GetElementById.
; Related .......: _WebView2_FindElement, _WebView2_GetElementByName
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetElementById($iWebView, $sId)
	Local $__WebView2DirectResult = _WebView2_FindElement($iWebView, $WEBVIEW2_LOCATOR_BY_ID, $sId)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetElementById

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetElementByName
; Description ...: Finds the first element with the specified name attribute.
; Syntax ........: _WebView2_GetElementByName($iWebView, $sName)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sName - Element name.
; Return values .: On Success - Opaque element token; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Convenience wrapper equivalent in purpose to au3WebDriver _WD_GetElementByName.
; Related .......: _WebView2_FindElement, _WebView2_GetElementById
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetElementByName($iWebView, $sName)
	Local $__WebView2DirectResult = _WebView2_FindElement($iWebView, $WEBVIEW2_LOCATOR_BY_NAME, $sName)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetElementByName

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetElementByRegEx
; Description ...: Finds the first element whose specified attribute or property matches a JavaScript regular expression.
; Syntax ........: _WebView2_GetElementByRegEx($iWebView, $sAttribute, $sPattern[, $sFlags = ""])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sAttribute - Attribute or property name.
;                  $sPattern - JavaScript RegExp pattern.
;                  $sFlags - Optional JavaScript RegExp flags.
; Return values .: On Success - Opaque element token; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Searches the current top-level document.
; Related .......: _WebView2_FindElement
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_GetElementByRegEx($iWebView, $sAttribute, $sPattern, $sFlags = "")
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_GetElementByRegEx"
	Local $sMessage = ''
	Do
		Local $sScript = __WebView2_DOM_RegistryPrefix() & _
				"const a=" & __WebView2_JavaScript_StringLiteral($sAttribute) & ";" & _
				"const re=new RegExp(" & __WebView2_JavaScript_StringLiteral($sPattern) & "," & __WebView2_JavaScript_StringLiteral($sFlags) & ");" & _
				"for(const el of document.querySelectorAll('*')){const v=el.getAttribute(a)??el[a];if(v!=null&&re.test(String(v)))return __wv2.store(el);}" & _
				"return null;})()"
		Local $vResult = __WebView2_DOM_Execute($iWebView, $sScript, "")
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If $vResult = "" Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_NO_MATCH, 0, "DOM element not found by regular expression.", "")
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
EndFunc   ;==>_WebView2_GetElementByRegEx

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetElementFromPoint
; Description ...: Returns the DOM element located at viewport coordinates.
; Syntax ........: _WebView2_GetElementFromPoint($iWebView, $iX, $iY)
; Parameters ....: $iWebView - WebView instance ID.
;                  $iX - X coordinate relative to the WebView viewport.
;                  $iY - Y coordinate relative to the WebView viewport.
; Return values .: On Success - Opaque element token; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Coordinates follow document.elementFromPoint() semantics.
; Related .......: _WebView2_ElementAction
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_GetElementFromPoint($iWebView, $iX, $iY)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_GetElementFromPoint"
	Local $sMessage = ''
	Do
		Local $sScript = __WebView2_DOM_RegistryPrefix() & _
				"const el=document.elementFromPoint(" & Number($iX) & "," & Number($iY) & ");return el?__wv2.store(el):null;})()"
		Local $vResult = __WebView2_DOM_Execute($iWebView, $sScript, "")
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If $vResult = "" Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_NO_MATCH, 0, "No DOM element exists at the specified point.", "")
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
EndFunc   ;==>_WebView2_GetElementFromPoint

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ElementAction
; Description ...: Performs a common action on a previously located DOM element.
; Syntax ........: _WebView2_ElementAction($iWebView, $sElement, $sCommand[, $sOption = Default])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque element token from _WebView2_FindElement().
;                  $sCommand - One of the following actions:
;                  |ATTRIBUTE      - Reads an HTML attribute named by $sOption.
;                  |CLEAR          - Clears the element value or text.
;                  |CLICK          - Clicks the element.
;                  |CLICKBUBBLE    - Dispatches a bubbling click MouseEvent.
;                  |CSS            - Reads a computed CSS property named by $sOption.
;                  |DISPLAYED      - Tests whether the element is visible.
;                  |ENABLED        - Tests whether the element is enabled.
;                  |FOCUS          - Focuses the element.
;                  |HTML           - Returns outerHTML.
;                  |NAME           - Returns the lowercase tag name.
;                  |PROPERTY       - Reads a property named by $sOption.
;                  |RECT           - Returns the element rectangle.
;                  |SCROLLINTOVIEW - Scrolls the element into view.
;                  |SELECTED       - Tests whether the element is selected or checked.
;                  |TEXT           - Returns the element text.
;                  |VALUE          - Reads or sets the value according to $sOption.
;                  $sOption - Optional command value / attribute / property / CSS name.
; Return values .: Command-dependent result; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: VALUE with Default reads the current value; otherwise it sets value and dispatches input/change events.
; Related .......: _WebView2_FindElement, _WebView2_ElementActionEx, _WebView2_ElementStyle
; Link ..........: https://www.w3.org/TR/webdriver/#element-interaction
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ElementAction($iWebView, $sElement, $sCommand, $sOption = Default)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_ElementAction"
	Local $sMessage = ''
	Do
		Local $sToken = __WebView2_JavaScript_StringLiteral($sElement)
		Local $sCmd = StringUpper($sCommand)
		Local $sScript = __WebView2_DOM_RegistryPrefix() & "const el=__wv2.get(" & $sToken & ");if(!el)return '__WV2_ERROR__:STALE';"

		Switch $sCmd
			Case "ATTRIBUTE"
				If $sOption = Default Then
					$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "ATTRIBUTE requires an attribute name.", "")
					$__WebView2ExitError = @error
					$__WebView2ExitExtended = @extended
					ExitLoop 1
				EndIf
				$sScript &= "return el.getAttribute(" & __WebView2_JavaScript_StringLiteral($sOption) & ");})()"
			Case "CLEAR"
				$sScript &= "if('value' in el)el.value='';else el.textContent='';el.dispatchEvent(new Event('input',{bubbles:true}));el.dispatchEvent(new Event('change',{bubbles:true}));return true;})()"
			Case "CLICK"
				$sScript &= "el.click();return true;})()"
			Case "CLICKBUBBLE"
				$sScript &= "el.dispatchEvent(new MouseEvent('click',{bubbles:true,cancelable:true,view:window}));return true;})()"
			Case "CSS"
				If $sOption = Default Then
					$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "CSS requires a property name.", "")
					$__WebView2ExitError = @error
					$__WebView2ExitExtended = @extended
					ExitLoop 1
				EndIf
				$sScript &= "return getComputedStyle(el).getPropertyValue(" & __WebView2_JavaScript_StringLiteral($sOption) & ");})()"
			Case "DISPLAYED"
				$sScript &= "const s=getComputedStyle(el),r=el.getBoundingClientRect();return !!(s.display!=='none'&&s.visibility!=='hidden'&&s.opacity!=='0'&&r.width>0&&r.height>0);})()"
			Case "ENABLED"
				$sScript &= "return !el.disabled;})()"
			Case "FOCUS"
				$sScript &= "el.focus();return document.activeElement===el;})()"
			Case "HTML"
				$sScript &= "return el.outerHTML;})()"
			Case "NAME"
				$sScript &= "return el.tagName.toLowerCase();})()"
			Case "PROPERTY"
				If $sOption = Default Then
					$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "PROPERTY requires a property name.", "")
					$__WebView2ExitError = @error
					$__WebView2ExitExtended = @extended
					ExitLoop 1
				EndIf
				$sScript &= "const v=el[" & __WebView2_JavaScript_StringLiteral($sOption) & "];return v==null?null:String(v);})()"
			Case "RECT"
				$sScript &= "const r=el.getBoundingClientRect();return [r.x,r.y,r.width,r.height].join('\u001f');})()"
			Case "SCROLLINTOVIEW"
				$sScript &= "el.scrollIntoView({block:'center',inline:'nearest'});return true;})()"
			Case "SELECTED"
				$sScript &= "return !!(el.selected||el.checked);})()"
			Case "TEXT"
				$sScript &= "return el.innerText??el.textContent??'';})()"
			Case "VALUE"
				If $sOption = Default Then
					$sScript &= "return ('value' in el)?String(el.value):'';})()"
				Else
					$sScript &= "const value=" & __WebView2_JavaScript_StringLiteral(String($sOption)) & ";const proto=el instanceof HTMLInputElement?HTMLInputElement.prototype:el instanceof HTMLTextAreaElement?HTMLTextAreaElement.prototype:el instanceof HTMLSelectElement?HTMLSelectElement.prototype:null;const setter=proto&&Object.getOwnPropertyDescriptor(proto,'value')?.set;if(setter)setter.call(el,value);else if('value' in el)el.value=value;else el.textContent=value;el.dispatchEvent(new Event('input',{bubbles:true}));el.dispatchEvent(new Event('change',{bubbles:true}));return true;})()"
				EndIf
			Case Else
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Unsupported DOM element action: " & $sCommand, "")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
		EndSwitch

		Local $vResult = __WebView2_DOM_Execute($iWebView, $sScript, "")
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		If $sCmd = "RECT" Then
			Local $aValues = StringSplit(String($vResult), Chr(31), $STR_NOCOUNT)
			If UBound($aValues) <> 4 Then
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_JAVASCRIPT, 0, "Unexpected RECT result.", "")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			EndIf
			For $i = 0 To 3
				$aValues[$i] = Number($aValues[$i])
			Next
			$__WebView2ExitValue = $aValues
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
EndFunc   ;==>_WebView2_ElementAction

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ElementActionEx
; Description ...: Performs additional DOM mutations not covered by _WebView2_ElementAction().
; Syntax ........: _WebView2_ElementActionEx($iWebView, $sElement, $sCommand)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque element token.
;                  $sCommand - One of the following actions:
;                  |HIDE    - Hides the element.
;                  |SHOW    - Shows a previously hidden element.
;                  |REMOVE  - Removes the element from the document.
;                  |DISABLE - Disables the element.
;                  |ENABLE  - Enables the element.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: REMOVE makes the element token stale after successful execution.
; Related .......: _WebView2_ElementAction
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_ElementActionEx($iWebView, $sElement, $sCommand)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_ElementActionEx"
	Local $sMessage = ''
	Do
		Local $sScript = __WebView2_DOM_RegistryPrefix() & "const el=__wv2.get(" & __WebView2_JavaScript_StringLiteral($sElement) & ");if(!el)return '__WV2_ERROR__:STALE';"
		Switch StringUpper($sCommand)
			Case "HIDE"
				$sScript &= "el.dataset.__wv2Display=el.style.display;el.style.display='none';return true;})()"
			Case "SHOW"
				$sScript &= "el.style.display=el.dataset.__wv2Display??'';delete el.dataset.__wv2Display;return true;})()"
			Case "REMOVE"
				$sScript &= "el.remove();return true;})()"
			Case "DISABLE"
				$sScript &= "el.disabled=true;return true;})()"
			Case "ENABLE"
				$sScript &= "el.disabled=false;return true;})()"
			Case Else
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Unsupported extended DOM element action: " & $sCommand, False)
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
		EndSwitch
		$__WebView2ExitValue = __WebView2_DOM_Execute($iWebView, $sScript, False)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_ElementActionEx

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetElementValue
; Description ...: Sets an element value and dispatches input and change events.
; Syntax ........: _WebView2_SetElementValue($iWebView, $sElement, $sValue)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque element token.
;                  $sValue - New value.
; Return values .: On Success - True; On Failure - False and @error/@extended set.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Convenience equivalent in purpose to au3WebDriver _WD_SetElementValue.
; Related .......: _WebView2_ElementAction
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_SetElementValue($iWebView, $sElement, $sValue)
	Local $vResult = _WebView2_ElementAction($iWebView, $sElement, "VALUE", $sValue)
	Return SetError(@error, @extended, $vResult)
EndFunc   ;==>_WebView2_SetElementValue

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ElementStyle
; Description ...: Gets or sets one inline style property on a DOM element.
; Syntax ........: _WebView2_ElementStyle($iWebView, $sElement, $sProperty[, $sValue = Default])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque element token.
;                  $sProperty - CSS property name.
;                  $sValue - Default to read; otherwise new inline style value.
; Return values .: On Success - Current value or True; On Failure - Empty string / False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Set uses style.setProperty() so hyphenated CSS property names are supported.
; Related .......: _WebView2_ElementAction, _WebView2_HighlightElements
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ElementStyle($iWebView, $sElement, $sProperty, $sValue = Default)
	Local $sScript = __WebView2_DOM_RegistryPrefix() & "const el=__wv2.get(" & __WebView2_JavaScript_StringLiteral($sElement) & ");if(!el)return '__WV2_ERROR__:STALE';"
	If $sValue = Default Then
		$sScript &= "return el.style.getPropertyValue(" & __WebView2_JavaScript_StringLiteral($sProperty) & ")||getComputedStyle(el).getPropertyValue(" & __WebView2_JavaScript_StringLiteral($sProperty) & ");})()"
	Else
		$sScript &= "el.style.setProperty(" & __WebView2_JavaScript_StringLiteral($sProperty) & "," & __WebView2_JavaScript_StringLiteral(String($sValue)) & ");return true;})()"
	EndIf
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, $sScript, "")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_ElementStyle

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_DispatchEvent
; Description ...: Creates and dispatches a DOM Event on the specified element.
; Syntax ........: _WebView2_DispatchEvent($iWebView, $sElement, $sEvent[, $bBubbles = True[, $bCancelable = True]])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque element token.
;                  $sEvent - Event type such as input, change, click, blur, or focus.
;                  $bBubbles - Whether the event bubbles.
;                  $bCancelable - Whether the event is cancelable.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Similar in purpose to au3WebDriver _WD_DispatchEvent.
; Related .......: _WebView2_ElementAction
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_DispatchEvent($iWebView, $sElement, $sEvent, $bBubbles = True, $bCancelable = True)
	Local $sScript = __WebView2_DOM_RegistryPrefix() & _
			"const el=__wv2.get(" & __WebView2_JavaScript_StringLiteral($sElement) & ");if(!el)return '__WV2_ERROR__:STALE';" & _
			"el.dispatchEvent(new Event(" & __WebView2_JavaScript_StringLiteral($sEvent) & ",{bubbles:" & __WebView2_DOM_JSBool($bBubbles) & ",cancelable:" & __WebView2_DOM_JSBool($bCancelable) & "}));return true;})()"
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, $sScript, False)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_DispatchEvent

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ElementSelectAction
; Description ...: Performs common operations on a SELECT element.
; Syntax ........: _WebView2_ElementSelectAction($iWebView, $sElement, $sCommand[, $vOption = Default])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque SELECT element token.
;                  $sCommand - One of the following actions:
;                  |SELECTINDEX   - Selects an option by index.
;                  |SELECTVALUE   - Selects an option by value.
;                  |SELECTTEXT    - Selects an option by visible text.
;                  |SELECTALL     - Selects every option.
;                  |DESELECTALL   - Deselects every option.
;                  |SELECTEDINDEX - Returns the selected index.
;                  |OPTIONCOUNT   - Returns the option count.
;                  $vOption - Index/value/text used by selection commands.
; Return values .: Command-dependent result; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Selection commands dispatch input and change events.
; Related .......: _WebView2_FindElement
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ElementSelectAction($iWebView, $sElement, $sCommand, $vOption = Default)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_ElementSelectAction"
	Local $sMessage = ''
	Do
		Local $sScript = __WebView2_DOM_RegistryPrefix() & "const el=__wv2.get(" & __WebView2_JavaScript_StringLiteral($sElement) & ");if(!el)return '__WV2_ERROR__:STALE';if(el.tagName!=='SELECT')return '__WV2_ERROR__:NOTSELECT';"
		Local $sCmd = StringUpper($sCommand)
		Switch $sCmd
			Case "SELECTINDEX"
				If $vOption = Default Then
					$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "SELECTINDEX requires an index.", "")
					$__WebView2ExitError = @error
					$__WebView2ExitExtended = @extended
					ExitLoop 1
				EndIf
				$sScript &= "el.selectedIndex=" & Int($vOption) & ";el.dispatchEvent(new Event('input',{bubbles:true}));el.dispatchEvent(new Event('change',{bubbles:true}));return el.selectedIndex;})()"
			Case "SELECTVALUE"
				If $vOption = Default Then
					$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "SELECTVALUE requires a value.", "")
					$__WebView2ExitError = @error
					$__WebView2ExitExtended = @extended
					ExitLoop 1
				EndIf
				$sScript &= "el.value=" & __WebView2_JavaScript_StringLiteral(String($vOption)) & ";el.dispatchEvent(new Event('input',{bubbles:true}));el.dispatchEvent(new Event('change',{bubbles:true}));return el.selectedIndex;})()"
			Case "SELECTTEXT"
				If $vOption = Default Then
					$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "SELECTTEXT requires visible option text.", "")
					$__WebView2ExitError = @error
					$__WebView2ExitExtended = @extended
					ExitLoop 1
				EndIf
				$sScript &= "const o=Array.from(el.options).find(o=>o.text.trim()===" & __WebView2_JavaScript_StringLiteral(String($vOption)) & ");if(!o)return '__WV2_ERROR__:NOMATCH';o.selected=true;el.dispatchEvent(new Event('input',{bubbles:true}));el.dispatchEvent(new Event('change',{bubbles:true}));return o.index;})()"
			Case "SELECTALL"
				$sScript &= "for(const o of el.options)o.selected=true;el.dispatchEvent(new Event('input',{bubbles:true}));el.dispatchEvent(new Event('change',{bubbles:true}));return true;})()"
			Case "DESELECTALL"
				$sScript &= "for(const o of el.options)o.selected=false;el.dispatchEvent(new Event('input',{bubbles:true}));el.dispatchEvent(new Event('change',{bubbles:true}));return true;})()"
			Case "SELECTEDINDEX"
				$sScript &= "return el.selectedIndex;})()"
			Case "OPTIONCOUNT"
				$sScript &= "return el.options.length;})()"
			Case Else
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Unsupported SELECT action: " & $sCommand, "")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
		EndSwitch
		$__WebView2ExitValue = __WebView2_DOM_Execute($iWebView, $sScript, "")
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_ElementSelectAction

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ElementOptionSelect
; Description ...: Selects one option by visible text, value, or index.
; Syntax ........: _WebView2_ElementOptionSelect($iWebView, $sElement, $vValue[, $sMode = "TEXT"])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sElement - Opaque SELECT element token.
;                  $vValue - Text, value, or numeric index.
;                  $sMode - One of the following matching modes:
;                  |TEXT  - Match option text.
;                  |VALUE - Match option value.
;                  |INDEX - Match zero-based option index.
; Return values .: On Success - Selected index; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Convenience wrapper comparable in purpose to au3WebDriver _WD_ElementOptionSelect.
; Related .......: _WebView2_ElementSelectAction
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ElementOptionSelect($iWebView, $sElement, $vValue, $sMode = "TEXT")
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_ElementOptionSelect"
	Local $sMessage = ''
	Do
		Switch StringUpper($sMode)
			Case "TEXT"
				$__WebView2ExitValue = _WebView2_ElementSelectAction($iWebView, $sElement, "SELECTTEXT", $vValue)
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			Case "VALUE"
				$__WebView2ExitValue = _WebView2_ElementSelectAction($iWebView, $sElement, "SELECTVALUE", $vValue)
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			Case "INDEX"
				$__WebView2ExitValue = _WebView2_ElementSelectAction($iWebView, $sElement, "SELECTINDEX", $vValue)
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			Case Else
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Unsupported option selection mode.", "")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
		EndSwitch
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_ElementOptionSelect

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_LinkClickByText
; Description ...: Finds and clicks a link by its visible text.
; Syntax ........: _WebView2_LinkClickByText($iWebView, $sText[, $bPartial = False])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sText - Link text.
;                  $bPartial - True to use partial text matching.
; Return values .: On Success - True; On Failure - False and @error/@extended set.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Searches only the current top-level document.
; Related .......: _WebView2_FindElement, _WebView2_ElementAction
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_LinkClickByText($iWebView, $sText, $bPartial = False)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_LinkClickByText"
	Local $sMessage = ''
	Do
		Local $sStrategy = $bPartial ? $WEBVIEW2_LOCATOR_BY_PARTIAL_LINK_TEXT : $WEBVIEW2_LOCATOR_BY_LINK_TEXT
		Local $sElement = _WebView2_FindElement($iWebView, $sStrategy, $sText)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $vResult = _WebView2_ElementAction($iWebView, $sElement, "CLICK")
		$__WebView2ExitValue = SetError(@error, @extended, $vResult)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_LinkClickByText

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_HighlightElements
; Description ...: Highlights one or more located elements using an outline.
; Syntax ........: _WebView2_HighlightElements($iWebView, $vElements[, $sOutline = "3px solid red"])
; Parameters ....: $iWebView - WebView instance ID.
;                  $vElements - One element token or an array of tokens.
;                  $sOutline - CSS outline value.
; Return values .: On Success - Number of highlighted elements; On Failure - 0.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Does not alter page layout because outline does not consume space.
; Related .......: _WebView2_ElementStyle
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_HighlightElements($iWebView, $vElements, $sOutline = "3px solid red")
	Local $sTokens = ""
	If IsArray($vElements) Then
		For $i = 0 To UBound($vElements) - 1
			If $i > 0 Then $sTokens &= ","
			$sTokens &= __WebView2_JavaScript_StringLiteral($vElements[$i])
		Next
	Else
		$sTokens = __WebView2_JavaScript_StringLiteral($vElements)
	EndIf
	Local $sScript = __WebView2_DOM_RegistryPrefix() & _
			"const ids=[" & $sTokens & "];let n=0;for(const id of ids){const el=__wv2.get(id);if(el){el.style.outline=" & __WebView2_JavaScript_StringLiteral($sOutline) & ";el.style.outlineOffset='2px';n++;}}return n;})()"
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, $sScript, 0)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_HighlightElements

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetDevicePixelRatio
; Description ...: Returns window.devicePixelRatio for the current document.
; Syntax ........: _WebView2_GetDevicePixelRatio($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - Numeric device pixel ratio; On Failure - 0.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Equivalent in purpose to au3WebDriver _WD_GetDevicePixelRatio.
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetDevicePixelRatio($iWebView)
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, "window.devicePixelRatio", 0)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetDevicePixelRatio

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetFrameCount
; Description ...: Returns the number of frame/iframe elements in the current top-level document.
; Syntax ........: _WebView2_GetFrameCount($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - Frame count; On Failure - 0.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This does not switch JavaScript execution context into a frame.
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetFrameCount($iWebView)
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, "document.querySelectorAll('frame,iframe').length", 0)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GetFrameCount

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_IsFullScreen
; Description ...: Returns whether the document currently has a Fullscreen API element.
; Syntax ........: _WebView2_IsFullScreen($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - Boolean; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This reports DOM Fullscreen API state, not whether the native host window is maximized.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_IsFullScreen($iWebView)
	Local $__WebView2DirectResult = __WebView2_DOM_Execute($iWebView, "document.fullscreenElement!==null", False)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_IsFullScreen

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_LoadWait
; Description ...: Waits until document.readyState becomes complete.
; Syntax ........: _WebView2_LoadWait($iWebView[, $iTimeoutMs = 30000[, $iPollMs = 50]])
; Parameters ....: $iWebView - WebView instance ID.
;                  $iTimeoutMs - Maximum wait time.
;                  $iPollMs - Poll interval.
; Return values .: On Success - True; On Failure - False.
;                  @error $WEBVIEW2_ERR_USER_ABORT - User sleep callback cancelled the wait.
;                  @extended contains the callback error for USER_ABORT.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Pumps the native message queue while waiting.
; Related .......: _WebView2_WaitElement, _WebView2_WaitScript
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_LoadWait($iWebView, $iTimeoutMs = 30000, $iPollMs = 50)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_LoadWait"
	Local $sMessage = ''
	Do
		Local $hTimer = TimerInit()
		While TimerDiff($hTimer) < $iTimeoutMs
			Local $vReady = __WebView2_DOM_Execute($iWebView, "document.readyState", "")
			If @error Then
				$__WebView2ExitValue = SetError(@error, @extended, False)
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 2
			EndIf
			If $vReady = "complete" Then
				__WebView2_Error_Clear()
				$__WebView2ExitValue = True
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 2
			EndIf
			__WebView2_PumpMessages()
			__WebView2_Sleep($iPollMs < 1 ? 1 : $iPollMs)
			If @error Then
				$__WebView2ExitValue = SetError($WEBVIEW2_ERR_USER_ABORT, @extended, False)
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 2
			EndIf
		WEnd
		$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_TIMEOUT, 0, "Timed out waiting for document.readyState=complete.", False)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_LoadWait

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_WaitScript
; Description ...: Waits until a JavaScript expression evaluates to a truthy value.
; Syntax ........: _WebView2_WaitScript($iWebView, $sJavaScript[, $iTimeoutMs = 10000[, $iPollMs = 100]])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sJavaScript - JavaScript expression or IIFE expression.
;                  $iTimeoutMs - Maximum wait time.
;                  $iPollMs - Poll interval.
; Return values .: On Success - True; On Failure - False.
;                  @error $WEBVIEW2_ERR_USER_ABORT - User sleep callback cancelled the wait.
;                  @extended contains the callback error for USER_ABORT.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: For multi-statement logic pass an immediately invoked function expression.
; Related .......: _WebView2_LoadWait, _WebView2_WaitElement
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_WaitScript($iWebView, $sJavaScript, $iTimeoutMs = 10000, $iPollMs = 100)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_WaitScript"
	Local $sMessage = ''
	Do
		Local $hTimer = TimerInit()
		While TimerDiff($hTimer) < $iTimeoutMs
			Local $vResult = __WebView2_DOM_Execute($iWebView, "Boolean(" & $sJavaScript & ")", False)
			If @error Then
				$__WebView2ExitValue = SetError(@error, @extended, False)
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 2
			EndIf
			If $vResult Then
				__WebView2_Error_Clear()
				$__WebView2ExitValue = True
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 2
			EndIf
			__WebView2_PumpMessages()
			__WebView2_Sleep($iPollMs < 1 ? 1 : $iPollMs)
			If @error Then
				$__WebView2ExitValue = SetError($WEBVIEW2_ERR_USER_ABORT, @extended, False)
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 2
			EndIf
		WEnd
		$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_TIMEOUT, 0, "Timed out waiting for JavaScript expression.", False)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_WaitScript

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_WaitElement
; Description ...: Waits for an element to exist and optionally be visible and/or enabled.
; Syntax ........: _WebView2_WaitElement($iWebView, $sStrategy, $sSelector[, $iTimeoutMs = 10000[, $iPollMs = 100[, $bVisible = False[, $bEnabled = False]]]])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sStrategy - One of the $WEBVIEW2_LOCATOR_* strategies listed by _WebView2_FindElement().
;                  $sSelector - Locator value.
;                  $iTimeoutMs - Maximum wait time.
;                  $iPollMs - Poll interval.
;                  $bVisible - Require displayed element.
;                  $bEnabled - Require enabled element.
; Return values .: On Success - Opaque element token; On Failure - Empty string.
;                  @error $WEBVIEW2_ERR_USER_ABORT - User sleep callback cancelled the wait.
;                  @extended contains the callback error for USER_ABORT.
;                  @error $WEBVIEW2_ERR_TIMEOUT - No matching ready element within the wait limit.
;                  Errors other than $WEBVIEW2_ERR_NO_MATCH and $WEBVIEW2_ERR_STALE_ELEMENT
;                  from finding or testing an element are returned with original @error/@extended.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Similar in purpose to au3WebDriver _WD_WaitElement.
;                  Missing or stale elements are re-located on each poll without resetting the timeout.
; Related .......: _WebView2_FindElement, _WebView2_LoadWait, _WebView2_WaitScript
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_WaitElement($iWebView, $sStrategy, $sSelector, $iTimeoutMs = 10000, $iPollMs = 100, $bVisible = False, $bEnabled = False)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_WaitElement"
	Local $sMessage = ''
	Do
		Local $hTimer = TimerInit()
		While TimerDiff($hTimer) < $iTimeoutMs
			Local $sElement = _WebView2_FindElement($iWebView, $sStrategy, $sSelector)
			Local $iFindError = @error, $iFindExtended = @extended
			If $iFindError And $iFindError <> $WEBVIEW2_ERR_NO_MATCH And $iFindError <> $WEBVIEW2_ERR_STALE_ELEMENT Then
				$__WebView2ExitValue = SetError($iFindError, $iFindExtended, "")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 2
			EndIf
			If Not $iFindError And $sElement <> "" Then
				Local $bOK = True
				Local $iActionError = 0, $iActionExtended = 0
				If $bVisible Then
					$bOK = _WebView2_ElementAction($iWebView, $sElement, "DISPLAYED")
					$iActionError = @error
					$iActionExtended = @extended
					If $iActionError = $WEBVIEW2_ERR_STALE_ELEMENT Then
						; The page replaced the element; find a fresh token on the next poll.
						$bOK = False
					ElseIf $iActionError Then
						$__WebView2ExitValue = SetError($iActionError, $iActionExtended, "")
						$__WebView2ExitError = @error
						$__WebView2ExitExtended = @extended
						ExitLoop 2
					EndIf
				EndIf
				If $bOK And $bEnabled Then
					$bOK = _WebView2_ElementAction($iWebView, $sElement, "ENABLED")
					$iActionError = @error
					$iActionExtended = @extended
					If $iActionError = $WEBVIEW2_ERR_STALE_ELEMENT Then
						; The page replaced the element; find a fresh token on the next poll.
						$bOK = False
					ElseIf $iActionError Then
						$__WebView2ExitValue = SetError($iActionError, $iActionExtended, "")
						$__WebView2ExitError = @error
						$__WebView2ExitExtended = @extended
						ExitLoop 2
					EndIf
				EndIf
				If $bOK Then
					__WebView2_Error_Clear()
					$__WebView2ExitValue = $sElement
					$__WebView2ExitError = @error
					$__WebView2ExitExtended = @extended
					ExitLoop 2
				EndIf
			EndIf
			__WebView2_PumpMessages()
			__WebView2_Sleep($iPollMs < 1 ? 1 : $iPollMs)
			If @error Then
				$__WebView2ExitValue = SetError($WEBVIEW2_ERR_USER_ABORT, @extended, "")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 2
			EndIf
		WEnd
		$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_TIMEOUT, 0, "Timed out waiting for DOM element.", "")
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_WaitElement

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Storage
; Description ...: Provides access to localStorage and sessionStorage.
; Syntax ........: _WebView2_Storage($iWebView, $sStorage, $sCommand[, $sKey = Default[, $sValue = Default]])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sStorage - LOCAL or SESSION.
;                  $sCommand - One of the following storage actions:
;                  |GET    - Returns the value of $sKey.
;                  |SET    - Stores $sValue under $sKey.
;                  |REMOVE - Removes $sKey.
;                  |CLEAR  - Removes all entries.
;                  |LENGTH - Returns the number of entries.
;                  |KEY    - Returns the key at the requested index.
;                  $sKey - Storage key or numeric index for KEY.
;                  $sValue - Value for SET.
; Return values .: Command-dependent result; On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Equivalent in purpose to au3WebDriver _WD_Storage.
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Storage($iWebView, $sStorage, $sCommand, $sKey = Default, $sValue = Default)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_Storage"
	Local $sMessage = ''
	Do
		Local $sObject
		Switch StringUpper($sStorage)
			Case "LOCAL"
				$sObject = "localStorage"
			Case "SESSION"
				$sObject = "sessionStorage"
			Case Else
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Storage must be LOCAL or SESSION.", "")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
		EndSwitch

		Local $sScript
		Switch StringUpper($sCommand)
			Case "GET"
				If $sKey = Default Then
					$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "GET requires a key.", "")
					$__WebView2ExitError = @error
					$__WebView2ExitExtended = @extended
					ExitLoop 1
				EndIf
				$sScript = $sObject & ".getItem(" & __WebView2_JavaScript_StringLiteral(String($sKey)) & ")"
			Case "SET"
				If $sKey = Default Or $sValue = Default Then
					$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "SET requires key and value.", "")
					$__WebView2ExitError = @error
					$__WebView2ExitExtended = @extended
					ExitLoop 1
				EndIf
				$sScript = "(()=>{" & $sObject & ".setItem(" & __WebView2_JavaScript_StringLiteral(String($sKey)) & "," & __WebView2_JavaScript_StringLiteral(String($sValue)) & ");return true;})()"
			Case "REMOVE"
				If $sKey = Default Then
					$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "REMOVE requires a key.", "")
					$__WebView2ExitError = @error
					$__WebView2ExitExtended = @extended
					ExitLoop 1
				EndIf
				$sScript = "(()=>{" & $sObject & ".removeItem(" & __WebView2_JavaScript_StringLiteral(String($sKey)) & ");return true;})()"
			Case "CLEAR"
				$sScript = "(()=>{" & $sObject & ".clear();return true;})()"
			Case "LENGTH"
				$sScript = $sObject & ".length"
			Case "KEY"
				If $sKey = Default Then
					$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "KEY requires a numeric index.", "")
					$__WebView2ExitError = @error
					$__WebView2ExitExtended = @extended
					ExitLoop 1
				EndIf
				$sScript = $sObject & ".key(" & Int($sKey) & ")"
			Case Else
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Unsupported storage command.", "")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
		EndSwitch
		$__WebView2ExitValue = __WebView2_DOM_Execute($iWebView, $sScript, "")
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_Storage

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetTable
; Description ...: Returns a HTML TABLE as a two-dimensional AutoIt array of visible cell text.
; Syntax ........: _WebView2_GetTable($iWebView, $sElement[, $sChildSelector = Default])
; Parameters ....: $iWebView - WebView instance ID for current document.
;                  $sElement - Opaque TABLE element token.
;                  $sChildSelector - Optional CSS selector for rows relative to the TABLE.
; Return values .: On Success - Two-dimensional array; On Failure - 0.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Cell and row separators are internal control characters and are not intended for page data containing ASCII 29/30.
; Related .......: _WebView2_FindElement
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetTable($iWebView, $sElement, $sChildSelector = Default)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_GetTable"
	Local $sMessage = ''
	Do
		Local $sRows = "el.rows"
		If $sChildSelector <> Default And $sChildSelector <> '' Then $sRows = "el.querySelectorAll(" & __WebView2_JavaScript_StringLiteral($sChildSelector) & ")"
		Local $sScript = __WebView2_DOM_RegistryPrefix() & _
				"const el=__wv2.get(" & __WebView2_JavaScript_StringLiteral($sElement) & ");if(!el)return '__WV2_ERROR__:STALE';if(el.tagName!=='TABLE')return '__WV2_ERROR__:NOTTABLE';" & _
				"return Array.from(" & $sRows & ").map(r=>Array.from(r.cells).map(c=>(c.innerText??c.textContent??'').trim()).join('\u001e')).join('\u001d');})()"
		Local $vResult = __WebView2_DOM_Execute($iWebView, $sScript, "")
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $aRows = StringSplit(String($vResult), Chr(29), $STR_NOCOUNT)
		Local $iRows = UBound($aRows), $iCols = 0
		For $i = 0 To $iRows - 1
			Local $aCellsTmp = StringSplit($aRows[$i], Chr(30), $STR_NOCOUNT)
			If UBound($aCellsTmp) > $iCols Then $iCols = UBound($aCellsTmp)
		Next
		If $iRows = 0 Or $iCols = 0 Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_NO_MATCH, 0, "Table contains no cells.", 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $aTable[$iRows][$iCols]
		For $i = 0 To $iRows - 1
			Local $aCells = StringSplit($aRows[$i], Chr(30), $STR_NOCOUNT)
			For $j = 0 To UBound($aCells) - 1
				$aTable[$i][$j] = $aCells[$j]
			Next
		Next
		$__WebView2ExitValue = $aTable
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_GetTable

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_DOM_Execute
; Description ...: Executes JavaScript and decodes its DOM result.
; Syntax ........: __WebView2_DOM_Execute($iWebView, $sJavaScript, $vFailure)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sJavaScript - JavaScript source text.
;                  $vFailure - Value returned if script execution fails.
; Return values .: Decoded DOM result, or $vFailure on failure; underlying script errors are propagated on guarded paths.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_DOM_Execute($iWebView, $sJavaScript, $vFailure)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_DOM_Execute"
	Local $sMessage = ''
	Do
		Local $sResult = _WebView2_ExecuteScript($iWebView, $sJavaScript)
		Local $iError = @error, $iExtended = @extended
		If $iError Then
			$__WebView2ExitValue = SetError($iError, $iExtended, $vFailure)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $vResult = __WebView2_DOM_ResultDecode($sResult)
		If IsString($vResult) And StringLeft($vResult, 14) = "__WV2_ERROR__:" Then
			Switch $vResult
				Case "__WV2_ERROR__:STALE"
					$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_STALE_ELEMENT, 0, "DOM element token is stale or invalid.", $vFailure)
					$__WebView2ExitError = @error
					$__WebView2ExitExtended = @extended
					ExitLoop 1
				Case "__WV2_ERROR__:NOMATCH"
					$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_NO_MATCH, 0, "No matching DOM item was found.", $vFailure)
					$__WebView2ExitError = @error
					$__WebView2ExitExtended = @extended
					ExitLoop 1
				Case "__WV2_ERROR__:NOTSELECT", "__WV2_ERROR__:NOTTABLE"
					$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "DOM element has an incompatible element type.", $vFailure)
					$__WebView2ExitError = @error
					$__WebView2ExitExtended = @extended
					ExitLoop 1
				Case Else
					$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_JAVASCRIPT, 0, $vResult, $vFailure)
					$__WebView2ExitError = @error
					$__WebView2ExitExtended = @extended
					ExitLoop 1
			EndSwitch
		EndIf
		$__WebView2ExitValue = $vResult
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_DOM_Execute

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_DOM_ResultDecode
; Description ...: Converts a JSON scalar result to an AutoIt value.
; Syntax ........: __WebView2_DOM_ResultDecode($sResult)
; Parameters ....: $sResult - JavaScript or JSON result text.
; Return values .: Decoded AutoIt scalar or text.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_DOM_ResultDecode($sResult)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_DOM_ResultDecode"
	Local $sMessage = ''
	Do
		If $sResult = "null" Or $sResult = "undefined" Then
			$__WebView2ExitValue = ""
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If StringLen($sResult) >= 2 And StringLeft($sResult, 1) = '"' And StringRight($sResult, 1) = '"' Then
			$__WebView2ExitValue = __WebView2_JSONString_Decode($sResult)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Switch StringLower($sResult)
			Case "true"
				$__WebView2ExitValue = True
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			Case "false"
				$__WebView2ExitValue = False
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
		EndSwitch
		If StringRegExp($sResult, '^-?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?$') Then
			$__WebView2ExitValue = Number($sResult)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $sResult
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_DOM_ResultDecode

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_DOM_RegistryPrefix
; Description ...: Returns JavaScript that initializes the DOM token registry.
; Syntax ........: __WebView2_DOM_RegistryPrefix()
; Parameters ....: None.
; Return values .: JavaScript source text.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_DOM_RegistryPrefix()
	Return "(()=>{const __wv2=window.__autoitWebView2||(window.__autoitWebView2={nextId:1,elements:{}});" & _
			"if(!__wv2.store){__wv2.store=function(el){for(const k in this.elements){if(this.elements[k]===el)return k;}const id='wv2e-'+(this.nextId++);this.elements[id]=el;return id;};" & _
			"__wv2.get=function(id){const el=this.elements[id];return el&&el.isConnected?el:null;};" & _
			"__wv2.findOne=function(strategy,selector){switch(strategy){case 'css selector':return document.querySelector(selector);case 'xpath':return document.evaluate(selector,document,null,XPathResult.FIRST_ORDERED_NODE_TYPE,null).singleNodeValue;case 'id':return document.getElementById(selector);case 'name':return document.getElementsByName(selector)[0]||null;case 'tag name':return document.getElementsByTagName(selector)[0]||null;case 'link text':return Array.from(document.querySelectorAll('a')).find(a=>a.textContent.trim()===selector)||null;case 'partial link text':return Array.from(document.querySelectorAll('a')).find(a=>a.textContent.includes(selector))||null;default:throw new Error('Unsupported locator strategy: '+strategy);}};" & _
			"__wv2.findAll=function(strategy,selector){switch(strategy){case 'css selector':return Array.from(document.querySelectorAll(selector));case 'xpath':{const out=[];const r=document.evaluate(selector,document,null,XPathResult.ORDERED_NODE_ITERATOR_TYPE,null);let n;while(n=r.iterateNext())out.push(n);return out;}case 'id':{const e=document.getElementById(selector);return e?[e]:[];}case 'name':return Array.from(document.getElementsByName(selector));case 'tag name':return Array.from(document.getElementsByTagName(selector));case 'link text':return Array.from(document.querySelectorAll('a')).filter(a=>a.textContent.trim()===selector);case 'partial link text':return Array.from(document.querySelectorAll('a')).filter(a=>a.textContent.includes(selector));default:throw new Error('Unsupported locator strategy: '+strategy);}};}"
EndFunc   ;==>__WebView2_DOM_RegistryPrefix


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_DOM_Locator_IsValid
; Description ...: Checks whether a DOM locator strategy is supported.
; Syntax ........: __WebView2_DOM_Locator_IsValid($sStrategy)
; Parameters ....: $sStrategy - DOM locator strategy.
; Return values .: True for a supported strategy; otherwise False.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_DOM_Locator_IsValid($sStrategy)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_DOM_Locator_IsValid"
	Local $sMessage = ''
	Do
		Switch StringLower($sStrategy)
			Case $WEBVIEW2_LOCATOR_BY_CSS_SELECTOR, $WEBVIEW2_LOCATOR_BY_XPATH, $WEBVIEW2_LOCATOR_BY_ID, $WEBVIEW2_LOCATOR_BY_NAME, _
					$WEBVIEW2_LOCATOR_BY_TAG_NAME, $WEBVIEW2_LOCATOR_BY_LINK_TEXT, $WEBVIEW2_LOCATOR_BY_PARTIAL_LINK_TEXT
				$__WebView2ExitValue = True
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
		EndSwitch
		$__WebView2ExitValue = False
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_DOM_Locator_IsValid

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_DOM_JSBool
; Description ...: Converts an AutoIt Boolean to JavaScript text.
; Syntax ........: __WebView2_DOM_JSBool($bValue)
; Parameters ....: $bValue - Boolean value to convert.
; Return values .: The JavaScript literal true or false.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_DOM_JSBool($bValue)
	Return $bValue ? "true" : "false"
EndFunc   ;==>__WebView2_DOM_JSBool
