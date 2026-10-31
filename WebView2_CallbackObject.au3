#include-once
#Tidy_ILC_Pos=44

#include "WebView2_Constants.au3"

; #INDEX# =======================================================================================================================
; Title .........: WebView2_CallbackObject.au3
; Description ...: Minimal native COM callback-object factory for the WebView2 UDF.
; Author(s) .....: mLipok
; Version .......: 0.5.0
; Remarks .......: Inspired by the AutoIt ObjectFromTag()/WebView2 callback work discussed by LarsJ and trancexx.
; ===============================================================================================================================

Global Enum _
		$__WEBVIEW2_CB_QI, _
		$__WEBVIEW2_CB_ADDREF, _
		$__WEBVIEW2_CB_RELEASE, _
		$__WEBVIEW2_CB_INVOKE, _
		$__WEBVIEW2_CB_VTABLE, _
		$__WEBVIEW2_CB_OBJECT, _
		$__WEBVIEW2_CB_POINTER, _
		$__WEBVIEW2_CB_FIELDS

Global Enum _
		$__WEBVIEW2_CB_ENVIRONMENT, _
		$__WEBVIEW2_CB_CONTROLLER, _
		$__WEBVIEW2_CB_NAVIGATION_STARTING, _
		$__WEBVIEW2_CB_NAVIGATION_COMPLETED, _
		$__WEBVIEW2_CB_DOCUMENT_TITLE_CHANGED, _
		$__WEBVIEW2_CB_WEB_MESSAGE_RECEIVED, _
		$__WEBVIEW2_CB_NEW_WINDOW_REQUESTED, _
		$__WEBVIEW2_CB_EXECUTE_SCRIPT, _
		$__WEBVIEW2_CB_DOCUMENT_PLAYING_AUDIO_CHANGED, _
		$__WEBVIEW2_CB_COUNT

Global $__g_aWebView2_Callbacks[$__WEBVIEW2_CB_COUNT][$__WEBVIEW2_CB_FIELDS]

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Callback_QueryInterface
; Description ...: Implements the IUnknown QueryInterface entry point for internal callback objects.
; Syntax ........: __WebView2_Callback_QueryInterface($pSelf, $pRIID, $pObject)
; Parameters ....: $pSelf - Callback COM object pointer.
;                  $pRIID - Requested interface identifier pointer.
;                  $pObject - Output interface pointer.
; Return values .: S_OK when an output pointer is supplied.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Callback object infrastructure.
; Related .......: __WebView2_Callback_Create
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Callback_QueryInterface($pSelf, $pRIID, $pObject)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Do
		#forceref $pRIID
		If Not $pObject Then
			$__WebView2ExitValue = $WEBVIEW2_E_POINTER
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $tObject = DllStructCreate("ptr", $pObject)
		DllStructSetData($tObject, 1, $pSelf)
		$__WebView2ExitValue = $WEBVIEW2_S_OK
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_Callback_QueryInterface

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Callback_AddRef
; Description ...: Implements the IUnknown AddRef entry point for callback objects retained by AutoIt.
; Syntax ........: __WebView2_Callback_AddRef($pSelf)
; Parameters ....: $pSelf - Callback COM object pointer.
; Return values .: 1.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Lifetime is controlled by the UDF.
; Related .......: __WebView2_Callback_Release
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Callback_AddRef($pSelf)
	#forceref $pSelf
	Return 1
EndFunc   ;==>__WebView2_Callback_AddRef

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Callback_Release
; Description ...: Implements the IUnknown Release entry point for callback objects retained by AutoIt.
; Syntax ........: __WebView2_Callback_Release($pSelf)
; Parameters ....: $pSelf - Callback COM object pointer.
; Return values .: 1.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Callback memory is released explicitly by cleanup.
; Related .......: __WebView2_Callback_AddRef
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Callback_Release($pSelf)
	#forceref $pSelf
	Return 1
EndFunc   ;==>__WebView2_Callback_Release

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Callback_Create
; Description ...: Builds a four-entry IUnknown + Invoke COM callback object.
; Syntax ........: __WebView2_Callback_Create($iIndex, $fnInvoke, $sInvokeSignature)
; Parameters ....: $iIndex - Internal callback slot.
;                  $fnInvoke - AutoIt function reference used as Invoke.
;                  $sInvokeSignature - DllCallbackRegister parameter signature for Invoke.
; Return values .: On Success - Pointer to the callback COM object.
;                  On Failure - 0 and @error set.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Native callback vtable creation.
; Related .......: __WebView2_Callback_DeleteAll
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Callback_Create($iIndex, $fnInvoke, $sInvokeSignature)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Do
		If $iIndex < 0 Or $iIndex >= $__WEBVIEW2_CB_COUNT Then
			$__WebView2ExitValue = SetError($WEBVIEW2_ERR_INVALID_PARAMETER, 0, 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not IsFunc($fnInvoke) Then
			$__WebView2ExitValue = SetError($WEBVIEW2_ERR_CALLBACK, 0, 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__g_aWebView2_Callbacks[$iIndex][$__WEBVIEW2_CB_QI] = DllCallbackRegister(__WebView2_Callback_QueryInterface, "long", "ptr;ptr;ptr")
		If @error Then
			$__WebView2ExitValue = SetError($WEBVIEW2_ERR_CALLBACK, 1, 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__g_aWebView2_Callbacks[$iIndex][$__WEBVIEW2_CB_ADDREF] = DllCallbackRegister(__WebView2_Callback_AddRef, "ulong", "ptr")
		If @error Then
			$__WebView2ExitValue = SetError($WEBVIEW2_ERR_CALLBACK, 2, 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__g_aWebView2_Callbacks[$iIndex][$__WEBVIEW2_CB_RELEASE] = DllCallbackRegister(__WebView2_Callback_Release, "ulong", "ptr")
		If @error Then
			$__WebView2ExitValue = SetError($WEBVIEW2_ERR_CALLBACK, 3, 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__g_aWebView2_Callbacks[$iIndex][$__WEBVIEW2_CB_INVOKE] = DllCallbackRegister($fnInvoke, "long", $sInvokeSignature)
		If @error Then
			$__WebView2ExitValue = SetError($WEBVIEW2_ERR_CALLBACK, 4, 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $tVTable = DllStructCreate("ptr;ptr;ptr;ptr")
		DllStructSetData($tVTable, 1, DllCallbackGetPtr($__g_aWebView2_Callbacks[$iIndex][$__WEBVIEW2_CB_QI]))
		DllStructSetData($tVTable, 2, DllCallbackGetPtr($__g_aWebView2_Callbacks[$iIndex][$__WEBVIEW2_CB_ADDREF]))
		DllStructSetData($tVTable, 3, DllCallbackGetPtr($__g_aWebView2_Callbacks[$iIndex][$__WEBVIEW2_CB_RELEASE]))
		DllStructSetData($tVTable, 4, DllCallbackGetPtr($__g_aWebView2_Callbacks[$iIndex][$__WEBVIEW2_CB_INVOKE]))

		Local $tObject = DllStructCreate("ptr")
		DllStructSetData($tObject, 1, DllStructGetPtr($tVTable))

		$__g_aWebView2_Callbacks[$iIndex][$__WEBVIEW2_CB_VTABLE] = $tVTable
		$__g_aWebView2_Callbacks[$iIndex][$__WEBVIEW2_CB_OBJECT] = $tObject
		$__g_aWebView2_Callbacks[$iIndex][$__WEBVIEW2_CB_POINTER] = DllStructGetPtr($tObject)

		$__WebView2ExitValue = $__g_aWebView2_Callbacks[$iIndex][$__WEBVIEW2_CB_POINTER]
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_Callback_Create

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Callback_GetPointer
; Description ...: Returns an internal callback object pointer.
; Syntax ........: __WebView2_Callback_GetPointer($iIndex)
; Parameters ....: $iIndex - Internal callback slot.
; Return values .: Callback object pointer or 0.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Internal callback pointer accessor.
; Related .......: __WebView2_Callback_Create
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Callback_GetPointer($iIndex)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Do
		If $iIndex < 0 Or $iIndex >= $__WEBVIEW2_CB_COUNT Then
			$__WebView2ExitValue = 0
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $__g_aWebView2_Callbacks[$iIndex][$__WEBVIEW2_CB_POINTER]
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_Callback_GetPointer

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Callback_DeleteAll
; Description ...: Releases DllCallback resources used by all internal WebView2 COM callbacks.
; Syntax ........: __WebView2_Callback_DeleteAll()
; Parameters ....: None.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Must be called after WebView2 objects are closed.
; Related .......: __WebView2_Callback_Create
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Callback_DeleteAll()
	For $i = 0 To $__WEBVIEW2_CB_COUNT - 1
		If $__g_aWebView2_Callbacks[$i][$__WEBVIEW2_CB_POINTER] Then
			DllCallbackFree($__g_aWebView2_Callbacks[$i][$__WEBVIEW2_CB_INVOKE])
			DllCallbackFree($__g_aWebView2_Callbacks[$i][$__WEBVIEW2_CB_RELEASE])
			DllCallbackFree($__g_aWebView2_Callbacks[$i][$__WEBVIEW2_CB_ADDREF])
			DllCallbackFree($__g_aWebView2_Callbacks[$i][$__WEBVIEW2_CB_QI])
		EndIf

		For $j = 0 To $__WEBVIEW2_CB_FIELDS - 1
			$__g_aWebView2_Callbacks[$i][$j] = Null
		Next
	Next
	Return
EndFunc   ;==>__WebView2_Callback_DeleteAll
