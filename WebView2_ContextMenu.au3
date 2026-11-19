#include-once
#Tidy_ILC_Pos=44

Global Const $__WEBVIEW2_CONTEXT_MENU_COMMAND_KIND = 0

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_ContextMenu_Subscribe
; Description ...: Registers the optional native context-menu callback.
; Syntax ........: __WebView2_ContextMenu_Subscribe($iView, $fnCallback)
; Parameters ....: $iView - A valid WebView instance.
;                  $fnCallback - AutoIt callback reference.
; Return values .: True on success. False propagates the interface-query error or sets CALLBACK or HRESULT.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ContextMenu_Subscribe($iView, $fnCallback)
	If Not IsObj($__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_CORE]) Then
		Local $oCore = __WebView2_Frame_QueryInterface($__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_CORE_POINTER], $WEBVIEW2_IID_ICoreWebView2_11, $WEBVIEW2_DTAG_ICoreWebView2_11)
		If @error Then Return SetError(@error, @extended, False)
		If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_CONTEXT_MENU_REQUESTED) Then
			If Not __WebView2_Callback_Create($__WEBVIEW2_CB_CONTEXT_MENU_REQUESTED, __WebView2_ContextMenu_Invoke, "ptr;ptr;ptr") Then Return SetError($WEBVIEW2_ERR_CALLBACK, 0, False)
		EndIf
		Local $tToken = DllStructCreate("int64")
		Local $iResult = $oCore.add_ContextMenuRequested(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_CONTEXT_MENU_REQUESTED), $tToken)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then Return SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)
		$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_CORE] = $oCore
		$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_TOKEN] = DllStructGetData($tToken, 1)
	EndIf
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_CALLBACK] = $fnCallback
	Return SetError(0, 0, True)
EndFunc   ;==>__WebView2_ContextMenu_Subscribe

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_ContextMenu_Cleanup
; Description ...: Unsubscribes before the owning WebView closes.
; Syntax ........: __WebView2_ContextMenu_Cleanup($iView)
; Parameters ....: $iView - Internal WebView slot.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ContextMenu_Cleanup($iView)
	__WebView2_ContextMenu_ClearItem($iView)
	Local $oCore = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_CORE]
	If IsObj($oCore) Then $oCore.remove_ContextMenuRequested($__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_TOKEN])
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_CORE] = Null
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_TOKEN] = 0
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_CALLBACK] = Null
EndFunc   ;==>__WebView2_ContextMenu_Cleanup

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_ContextMenu_ClearItem
; Description ...: Detaches the previous custom command and discards its selection data.
; Syntax ........: __WebView2_ContextMenu_ClearItem($iView)
; Parameters ....: $iView - Internal WebView slot.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ContextMenu_ClearItem($iView)
	Local $oItem = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_ITEM]
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_ITEM_POINTER] = 0
	If IsObj($oItem) Then $oItem.remove_CustomItemSelected($__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_ITEM_TOKEN])
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_ITEM] = Null
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_ITEM_TOKEN] = 0
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_ITEM_CALLBACK] = Null
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_ITEM_CONTEXT] = Null
EndFunc   ;==>__WebView2_ContextMenu_ClearItem

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_ContextMenu_Invoke
; Description ...: Copies request data and applies the host decision.
; Syntax ........: __WebView2_ContextMenu_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: $pSelf - COM handler pointer.
;                  $pSender - Core WebView pointer.
;                  $pArgs - Borrowed event arguments.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......: An invalid return value leaves the native menu intact.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ContextMenu_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Local $iView = __WebView2_Instance_FindByCorePointer($pSender)
	If $iView < 0 Or Not $pArgs Then Return $WEBVIEW2_S_OK
	Local $fnCallback = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_CALLBACK]
	If Not IsFunc($fnCallback) Then Return $WEBVIEW2_S_OK
	__WebView2_ContextMenu_ClearItem($iView)
	Local $oArgs = __WebView2_Frame_QueryInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2ContextMenuRequestedEventArgs, $WEBVIEW2_DTAG_ICoreWebView2ContextMenuRequestedEventArgs)
	If @error Then Return $WEBVIEW2_S_OK
	Local $aContext = __WebView2_ContextMenu_Read($oArgs)
	If Not IsArray($aContext) Then Return $WEBVIEW2_S_OK
	Local $vDecision = Call($fnCallback, $iView, $aContext)
	If @error Or __WebView2_Instance_FindByCorePointer($pSender) <> $iView Then Return $WEBVIEW2_S_OK
	If IsBool($vDecision) And $vDecision = True Then
		$oArgs.put_Handled(1)
	ElseIf IsArray($vDecision) Then
		If UBound($vDecision, 0) <> 1 Or UBound($vDecision) <> 2 Then Return $WEBVIEW2_S_OK
		If Not IsString($vDecision[0]) Or Not IsFunc($vDecision[1]) Then Return $WEBVIEW2_S_OK
		Local $sCaption = $vDecision[0]
		If StringStripWS($sCaption, 8) = "" Or StringRegExp($sCaption, "[\x00-\x1f]") Then Return $WEBVIEW2_S_OK
		If Not __WebView2_ContextMenu_Append($iView, $oArgs, $sCaption, $vDecision[1], $aContext) Then
			__WebView2_Error("__WebView2_ContextMenu_Append", @error, "Could not append the native context menu command.", @extended)
		EndIf
	EndIf
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_ContextMenu_Invoke

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_ContextMenu_Read
; Description ...: Copies the native menu target into a plain array.
; Syntax ........: __WebView2_ContextMenu_Read($oArgs)
; Parameters ....: $oArgs - Native request wrapper.
; Return values .: A context array on success or Null if the required fields cannot be read.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ContextMenu_Read($oArgs)
	Local $tPoint = DllStructCreate("long X;long Y")
	Local $iResult = $oArgs.get_Location($tPoint)
	If @error Or $iResult <> $WEBVIEW2_S_OK Then Return Null
	Local $pTarget = 0
	$iResult = $oArgs.get_ContextMenuTarget($pTarget)
	If @error Or $iResult <> $WEBVIEW2_S_OK Or Not $pTarget Then Return Null
	Local $oTarget = ObjCreateInterface($pTarget, $WEBVIEW2_IID_ICoreWebView2ContextMenuTarget, $WEBVIEW2_DTAG_ICoreWebView2ContextMenuTarget)
	If Not IsObj($oTarget) Then
		__WebView2_Ext_Release($pTarget)
		Return Null
	EndIf
	Local $iKind = 0, $iMainFrame = 0, $iHasLink = 0, $iHasSelection = 0
	$iResult = $oTarget.get_Kind($iKind)
	If @error Or $iResult <> $WEBVIEW2_S_OK Then Return Null
	$iResult = $oTarget.get_IsRequestedForMainFrame($iMainFrame)
	If @error Or $iResult <> $WEBVIEW2_S_OK Then Return Null
	Local $aContext[$__WEBVIEW2_CONTEXT_MENU_FIELD_COUNT]
	$aContext[$WEBVIEW2_CONTEXT_MENU_KIND] = $iKind
	$aContext[$WEBVIEW2_CONTEXT_MENU_X] = DllStructGetData($tPoint, "X")
	$aContext[$WEBVIEW2_CONTEXT_MENU_Y] = DllStructGetData($tPoint, "Y")
	$aContext[$WEBVIEW2_CONTEXT_MENU_MAIN_FRAME] = $iMainFrame <> 0
	Local $pString = 0
	$iResult = $oTarget.get_PageUri($pString)
	If @error Or $iResult <> $WEBVIEW2_S_OK Then Return Null
	$aContext[$WEBVIEW2_CONTEXT_MENU_PAGE_URI] = __WebView2_CoTaskMemString_ReadAndFree($pString)
	$aContext[$WEBVIEW2_CONTEXT_MENU_FRAME_URI] = ""
	$aContext[$WEBVIEW2_CONTEXT_MENU_LINK_URI] = ""
	$aContext[$WEBVIEW2_CONTEXT_MENU_SELECTION_TEXT] = ""
	If Not $iMainFrame Then
		$pString = 0
		$iResult = $oTarget.get_FrameUri($pString)
		If Not @error And $iResult = $WEBVIEW2_S_OK Then $aContext[$WEBVIEW2_CONTEXT_MENU_FRAME_URI] = __WebView2_CoTaskMemString_ReadAndFree($pString)
	EndIf
	$iResult = $oTarget.get_HasLinkUri($iHasLink)
	If Not @error And $iResult = $WEBVIEW2_S_OK And $iHasLink Then
		$pString = 0
		$iResult = $oTarget.get_LinkUri($pString)
		If Not @error And $iResult = $WEBVIEW2_S_OK Then $aContext[$WEBVIEW2_CONTEXT_MENU_LINK_URI] = __WebView2_CoTaskMemString_ReadAndFree($pString)
	EndIf
	$iResult = $oTarget.get_HasSelection($iHasSelection)
	If Not @error And $iResult = $WEBVIEW2_S_OK And $iHasSelection Then
		$pString = 0
		$iResult = $oTarget.get_SelectionText($pString)
		If Not @error And $iResult = $WEBVIEW2_S_OK Then $aContext[$WEBVIEW2_CONTEXT_MENU_SELECTION_TEXT] = __WebView2_CoTaskMemString_ReadAndFree($pString)
	EndIf
	Return $aContext
EndFunc   ;==>__WebView2_ContextMenu_Read

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_ContextMenu_Append
; Description ...: Appends one native command to the current menu.
; Syntax ........: __WebView2_ContextMenu_Append($iView, $oArgs, $sCaption, $fnSelection, $aContext)
; Parameters ....: $iView - Internal WebView slot.
;                  $oArgs - Native request wrapper.
;                  $sCaption - Command caption.
;                  $fnSelection - Selection callback.
;                  $aContext - Copied request metadata.
; Return values .: True on success. False propagates interface-query errors or sets CALLBACK or HRESULT.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ContextMenu_Append($iView, $oArgs, $sCaption, $fnSelection, $aContext)
	Local $oEnv = __WebView2_Frame_QueryInterface($__g_pWebView2_Environment, $WEBVIEW2_IID_ICoreWebView2Environment9, $WEBVIEW2_DTAG_ICoreWebView2Environment9)
	If @error Then Return SetError(@error, @extended, False)
	If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_CONTEXT_MENU_ITEM_SELECTED) Then
		If Not __WebView2_Callback_Create($__WEBVIEW2_CB_CONTEXT_MENU_ITEM_SELECTED, __WebView2_ContextMenu_Selected, "ptr;ptr;ptr") Then Return SetError($WEBVIEW2_ERR_CALLBACK, 0, False)
	EndIf
	Local $pItems = 0, $pItem = 0, $iCount = 0
	Local $iResult = $oArgs.get_MenuItems($pItems)
	If @error Or $iResult <> $WEBVIEW2_S_OK Or Not $pItems Then Return SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)
	Local $oItems = ObjCreateInterface($pItems, $WEBVIEW2_IID_ICoreWebView2ContextMenuItemCollection, $WEBVIEW2_DTAG_ICoreWebView2ContextMenuItemCollection)
	If Not IsObj($oItems) Then
		__WebView2_Ext_Release($pItems)
		Return SetError($WEBVIEW2_ERR_HRESULT, 0, False)
	EndIf
	$iResult = $oItems.get_Count($iCount)
	If @error Or $iResult <> $WEBVIEW2_S_OK Then Return SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)
	$iResult = $oEnv.CreateContextMenuItem($sCaption, Ptr(0), $__WEBVIEW2_CONTEXT_MENU_COMMAND_KIND, $pItem)
	If @error Or $iResult <> $WEBVIEW2_S_OK Or Not $pItem Then Return SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)
	Local $oItem = ObjCreateInterface($pItem, $WEBVIEW2_IID_ICoreWebView2ContextMenuItem, $WEBVIEW2_DTAG_ICoreWebView2ContextMenuItem)
	If Not IsObj($oItem) Then
		__WebView2_Ext_Release($pItem)
		Return SetError($WEBVIEW2_ERR_HRESULT, 0, False)
	EndIf
	$iResult = $oItem.put_IsEnabled(1)
	If @error Or $iResult <> $WEBVIEW2_S_OK Then Return SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)
	Local $tToken = DllStructCreate("int64")
	$iResult = $oItem.add_CustomItemSelected(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_CONTEXT_MENU_ITEM_SELECTED), $tToken)
	If @error Or $iResult <> $WEBVIEW2_S_OK Then Return SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)
	Local $iToken = DllStructGetData($tToken, 1)
	$iResult = $oItems.InsertValueAtIndex($iCount, $pItem)
	If @error Or $iResult <> $WEBVIEW2_S_OK Then
		$oItem.remove_CustomItemSelected($iToken)
		Return SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)
	EndIf
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_ITEM] = $oItem
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_ITEM_POINTER] = $pItem
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_ITEM_TOKEN] = $iToken
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_ITEM_CALLBACK] = $fnSelection
	$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_ITEM_CONTEXT] = $aContext
	Return SetError(0, 0, True)
EndFunc   ;==>__WebView2_ContextMenu_Append

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WebView2_ContextMenu_Selected
; Description ...: Dispatches the selection with the original request data.
; Syntax ........: __WebView2_ContextMenu_Selected($pSelf, $pSender, $pArgs)
; Parameters ....: $pSelf - COM handler pointer.
;                  $pSender - Native custom item pointer.
;                  $pArgs - Unused native event arguments.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ContextMenu_Selected($pSelf, $pSender, $pArgs)
	#forceref $pSelf, $pArgs
	If Not $pSender Then Return $WEBVIEW2_S_OK
	For $iView = 0 To $WEBVIEW2_MAX_INSTANCES - 1
		If $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_ITEM_POINTER] <> $pSender Then ContinueLoop
		Local $fnSelection = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_ITEM_CALLBACK]
		Local $aContext = $__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_ITEM_CONTEXT]
		; Consume the selection before calling AutoIt. Release the COM item on the next request or teardown.
		$__g_aWebView2_Instances[$iView][$__WEBVIEW2_INSTANCE_MENU_ITEM_CALLBACK] = Null
		If IsFunc($fnSelection) Then Call($fnSelection, $iView, $aContext)
		ExitLoop
	Next
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_ContextMenu_Selected
