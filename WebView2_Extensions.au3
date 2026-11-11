#include-once
#Tidy_ILC_Pos=44

; Native extension management. The existing CDP helpers remain available separately.
; Interface identifiers and vtable slots are taken from Microsoft's WebView2.idl (SDK 1.0.2210.55).

Global $__g_bWebView2_NativeExtensionsRequested = False
Global $__g_aWebView2_ExtOptionsCallbacks[13]
Global $__g_tWebView2_ExtOptionsBaseVTable = Null
Global $__g_tWebView2_ExtOptions6VTable = Null
Global $__g_tWebView2_ExtOptionsBase = Null
Global $__g_tWebView2_ExtOptions6 = Null
Global $__g_iWebView2_ExtPending = 0       ; 0 idle, 1 waiting, 2 timed out
Global $__g_bWebView2_ExtDone = False
Global $__g_iWebView2_ExtHRESULT = 0
Global $__g_pWebView2_ExtResult = 0

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_NativeExtensions_EnableForEnvironment
; Description ...: Enables native profile extensions for the next environment created by _WebView2_Init().
; Syntax ........: _WebView2_NativeExtensions_EnableForEnvironment()
; Return values .: True before initialization; False with @error when an environment already exists.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Call before _WebView2_Init(). The option is process-local and reset by _WebView2_Cleanup().
; Related .......: _WebView2_NativeExtension_Add
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2environmentoptions6
; ===============================================================================================================================
Func _WebView2_NativeExtensions_EnableForEnvironment()
	If $__g_bWebView2_Initialized Then Return __WebView2_Fail($WEBVIEW2_ERR_BUSY, 0, "Set browser-extension options before initialization.", False)
	$__g_bWebView2_NativeExtensionsRequested = True
	Return True
EndFunc   ;==>_WebView2_NativeExtensions_EnableForEnvironment

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_OptionsQuery
; Description ...: Exposes only IUnknown, base environment options and environment options 6.
; ===============================================================================================================================
Func __WebView2_Ext_OptionsQuery($pSelf, $pIID, $pOutput)
	#forceref $pSelf
	If Not $pOutput Or Not $pIID Then Return $WEBVIEW2_E_POINTER
	Local $tOut = DllStructCreate("ptr", $pOutput)
	DllStructSetData($tOut, 1, 0)
	Local $tRequested = DllStructCreate("byte[16]", $pIID)
	Local $bRequested = DllStructGetData($tRequested, 1)
	For $i = 0 To 2
		Local $sIID = $WEBVIEW2_IID_IUnknown
		If $i = 1 Then $sIID = $WEBVIEW2_IID_ICoreWebView2EnvironmentOptions
		If $i = 2 Then $sIID = $WEBVIEW2_IID_ICoreWebView2EnvironmentOptions6
		Local $tKnown = DllStructCreate($tagGUID)
		Local $aGuid = DllCall("ole32.dll", "long", "IIDFromString", "wstr", $sIID, "ptr", DllStructGetPtr($tKnown))
		If @error Or $aGuid[0] <> 0 Then ContinueLoop
		Local $tBytes = DllStructCreate("byte[16]", DllStructGetPtr($tKnown))
		If $bRequested = DllStructGetData($tBytes, 1) Then
			DllStructSetData($tOut, 1, DllStructGetPtr($i = 2 ? $__g_tWebView2_ExtOptions6 : $__g_tWebView2_ExtOptionsBase))
			Return $WEBVIEW2_S_OK
		EndIf
	Next
	Return $WEBVIEW2_E_NOINTERFACE
EndFunc   ;==>__WebView2_Ext_OptionsQuery

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_OptionsRef
; Description ...: Keeps the UDF-owned environment-options object alive until the environment callback.
; ===============================================================================================================================
Func __WebView2_Ext_OptionsRef($pSelf)
	#forceref $pSelf
	Return 2
EndFunc   ;==>__WebView2_Ext_OptionsRef

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_OptionsUnref
; Description ...: Leaves lifetime management with the UDF.
; ===============================================================================================================================
Func __WebView2_Ext_OptionsUnref($pSelf)
	#forceref $pSelf
	Return 1
EndFunc   ;==>__WebView2_Ext_OptionsUnref

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_OptionsString
; Description ...: Allocates an output string with the COM task allocator.
; ===============================================================================================================================
Func __WebView2_Ext_OptionsString($sValue, $pOutput)
	If Not $pOutput Then Return $WEBVIEW2_E_POINTER
	Local $aMem = DllCall("ole32.dll", "ptr", "CoTaskMemAlloc", "ulong_ptr", (StringLen($sValue) + 1) * 2)
	If @error Or Not $aMem[0] Then Return 0x8007000E
	Local $tText = DllStructCreate("wchar[" & (StringLen($sValue) + 1) & "]", $aMem[0])
	DllStructSetData($tText, 1, $sValue)
	Local $tOut = DllStructCreate("ptr", $pOutput)
	DllStructSetData($tOut, 1, $aMem[0])
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_Ext_OptionsString

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_OptionsGetEmpty
; Description ...: Supplies default empty arguments and language.
; ===============================================================================================================================
Func __WebView2_Ext_OptionsGetEmpty($pSelf, $pOutput)
	#forceref $pSelf
	Return __WebView2_Ext_OptionsString("", $pOutput)
EndFunc   ;==>__WebView2_Ext_OptionsGetEmpty

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_OptionsGetTarget
; Description ...: Supplies the target Runtime version from the SDK introducing this API.
; ===============================================================================================================================
Func __WebView2_Ext_OptionsGetTarget($pSelf, $pOutput)
	#forceref $pSelf
	Return __WebView2_Ext_OptionsString("120.0.2210.55", $pOutput)
EndFunc   ;==>__WebView2_Ext_OptionsGetTarget

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_OptionsPutString
; Description ...: Accepts unused setters on the UDF-owned creation-only options object.
; ===============================================================================================================================
Func __WebView2_Ext_OptionsPutString($pSelf, $pValue)
	#forceref $pSelf, $pValue
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_Ext_OptionsPutString

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_OptionsGetFalse
; Description ...: Keeps single sign-on disabled by default.
; ===============================================================================================================================
Func __WebView2_Ext_OptionsGetFalse($pSelf, $pOutput)
	#forceref $pSelf
	If Not $pOutput Then Return $WEBVIEW2_E_POINTER
	DllStructSetData(DllStructCreate("int", $pOutput), 1, 0)
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_Ext_OptionsGetFalse

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_OptionsPutBool
; Description ...: Accepts unused Boolean setters on the creation-only options object.
; ===============================================================================================================================
Func __WebView2_Ext_OptionsPutBool($pSelf, $bValue)
	#forceref $pSelf, $bValue
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_Ext_OptionsPutBool

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_OptionsGetEnabled
; Description ...: Reports browser extensions enabled through ICoreWebView2EnvironmentOptions6.
; ===============================================================================================================================
Func __WebView2_Ext_OptionsGetEnabled($pSelf, $pOutput)
	#forceref $pSelf
	If Not $pOutput Then Return $WEBVIEW2_E_POINTER
	DllStructSetData(DllStructCreate("int", $pOutput), 1, 1)
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_Ext_OptionsGetEnabled

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_OptionsCreate
; Description ...: Creates separate COM vtables for base options and options 6.
; ===============================================================================================================================
Func __WebView2_Ext_OptionsCreate()
	Local $aFuncs[13] = [__WebView2_Ext_OptionsQuery, __WebView2_Ext_OptionsRef, __WebView2_Ext_OptionsUnref, _
			__WebView2_Ext_OptionsGetEmpty, __WebView2_Ext_OptionsPutString, __WebView2_Ext_OptionsGetTarget, _
			__WebView2_Ext_OptionsGetFalse, __WebView2_Ext_OptionsPutBool, __WebView2_Ext_OptionsGetEnabled, _
			__WebView2_Ext_OptionsGetEmpty, __WebView2_Ext_OptionsPutString, __WebView2_Ext_OptionsPutBool, __WebView2_Ext_OptionsGetEmpty]
	Local $aSignatures[13] = ["ptr;ptr;ptr", "ptr", "ptr", "ptr;ptr", "ptr;ptr", "ptr;ptr", _
			"ptr;ptr", "ptr;int", "ptr;ptr", "ptr;ptr", "ptr;ptr", "ptr;int", "ptr;ptr"]
	For $i = 0 To 12
		Local $sReturn = ($i = 1 Or $i = 2) ? "ulong" : "long"
		$__g_aWebView2_ExtOptionsCallbacks[$i] = DllCallbackRegister($aFuncs[$i], $sReturn, $aSignatures[$i])
		If @error Then
			__WebView2_Ext_OptionsDelete()
			Return SetError($WEBVIEW2_ERR_CALLBACK, $i, 0)
		EndIf
	Next
	$__g_tWebView2_ExtOptionsBaseVTable = DllStructCreate("ptr[11]")
	$__g_tWebView2_ExtOptions6VTable = DllStructCreate("ptr[5]")
	; IUnknown entries are shared by both interfaces.
	For $i = 0 To 2
		Local $pMethod = DllCallbackGetPtr($__g_aWebView2_ExtOptionsCallbacks[$i])
		DllStructSetData($__g_tWebView2_ExtOptionsBaseVTable, 1, $pMethod, $i + 1)
		DllStructSetData($__g_tWebView2_ExtOptions6VTable, 1, $pMethod, $i + 1)
	Next
	Local $aBase[8] = [3, 4, 9, 10, 5, 4, 6, 7]
	For $i = 0 To 7
		DllStructSetData($__g_tWebView2_ExtOptionsBaseVTable, 1, DllCallbackGetPtr($__g_aWebView2_ExtOptionsCallbacks[$aBase[$i]]), $i + 4)
	Next
	DllStructSetData($__g_tWebView2_ExtOptions6VTable, 1, DllCallbackGetPtr($__g_aWebView2_ExtOptionsCallbacks[8]), 4)
	DllStructSetData($__g_tWebView2_ExtOptions6VTable, 1, DllCallbackGetPtr($__g_aWebView2_ExtOptionsCallbacks[11]), 5)
	$__g_tWebView2_ExtOptionsBase = DllStructCreate("ptr")
	$__g_tWebView2_ExtOptions6 = DllStructCreate("ptr")
	DllStructSetData($__g_tWebView2_ExtOptionsBase, 1, DllStructGetPtr($__g_tWebView2_ExtOptionsBaseVTable))
	DllStructSetData($__g_tWebView2_ExtOptions6, 1, DllStructGetPtr($__g_tWebView2_ExtOptions6VTable))
	Return DllStructGetPtr($__g_tWebView2_ExtOptionsBase)
EndFunc   ;==>__WebView2_Ext_OptionsCreate

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_OptionsDelete
; Description ...: Frees the creation-only options vtables and callbacks.
; ===============================================================================================================================
Func __WebView2_Ext_OptionsDelete()
	$__g_tWebView2_ExtOptionsBase = Null
	$__g_tWebView2_ExtOptions6 = Null
	$__g_tWebView2_ExtOptionsBaseVTable = Null
	$__g_tWebView2_ExtOptions6VTable = Null
	For $i = 0 To UBound($__g_aWebView2_ExtOptionsCallbacks) - 1
		If $__g_aWebView2_ExtOptionsCallbacks[$i] Then DllCallbackFree($__g_aWebView2_ExtOptionsCallbacks[$i])
		$__g_aWebView2_ExtOptionsCallbacks[$i] = Null
	Next
EndFunc   ;==>__WebView2_Ext_OptionsDelete

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_Method
; Description ...: Gets a COM vtable method address using a verified SDK slot.
; ===============================================================================================================================
Func __WebView2_Ext_Method($pObject, $iSlot)
	If Not $pObject Then Return 0
	Local $tObject = DllStructCreate("ptr", $pObject)
	Local $pVTable = DllStructGetData($tObject, 1)
	If Not $pVTable Then Return 0
	Local $tVTable = DllStructCreate("ptr[" & ($iSlot + 1) & "]", $pVTable)
	Return DllStructGetData($tVTable, 1, $iSlot + 1)
EndFunc   ;==>__WebView2_Ext_Method

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_Release
; Description ...: Releases a COM reference obtained by QueryInterface or a native getter.
; ===============================================================================================================================
Func __WebView2_Ext_Release($pObject)
	If $pObject Then DllCallAddress("ulong", __WebView2_Ext_Method($pObject, 2), "ptr", $pObject)
EndFunc   ;==>__WebView2_Ext_Release

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_Query
; Description ...: Queries an interface without wrapping or changing its ownership.
; ===============================================================================================================================
Func __WebView2_Ext_Query($pObject, $sIID)
	Local $tIID = DllStructCreate($tagGUID)
	Local $aIID = DllCall("ole32.dll", "long", "IIDFromString", "wstr", $sIID, "ptr", DllStructGetPtr($tIID))
	If @error Or $aIID[0] <> 0 Then Return SetError($WEBVIEW2_ERR_DLLCALL, 0, 0)
	Local $aResult = DllCallAddress("long", __WebView2_Ext_Method($pObject, 0), "ptr", $pObject, "ptr", DllStructGetPtr($tIID), "ptr*", 0)
	If @error Then Return SetError($WEBVIEW2_ERR_DLLCALL, 0, 0)
	If $aResult[0] <> 0 Then Return SetError($WEBVIEW2_ERR_HRESULT, $aResult[0], 0)
	Return $aResult[3]
EndFunc   ;==>__WebView2_Ext_Query

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_Profile7
; Description ...: Obtains an owned ICoreWebView2Profile7 pointer for an instance.
; ===============================================================================================================================
Func __WebView2_Ext_Profile7($iWebView)
	If Not __WebView2_Instance_IsValid($iWebView) Then Return SetError($WEBVIEW2_ERR_INVALID_INSTANCE, 0, 0)
	Local $pCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE_POINTER]
	Local $pCore13 = __WebView2_Ext_Query($pCore, $WEBVIEW2_IID_ICoreWebView2_13)
	If @error Then Return SetError(@error, @extended, 0)
	Local $aProfile = DllCallAddress("long", __WebView2_Ext_Method($pCore13, 105), "ptr", $pCore13, "ptr*", 0)
	Local $iCallError = @error
	__WebView2_Ext_Release($pCore13)
	If $iCallError Or $aProfile[0] <> 0 Or Not $aProfile[2] Then Return SetError($WEBVIEW2_ERR_HRESULT, $aProfile[0], 0)
	Local $pProfile7 = __WebView2_Ext_Query($aProfile[2], $WEBVIEW2_IID_ICoreWebView2Profile7)
	Local $iError = @error, $iExtended = @extended
	__WebView2_Ext_Release($aProfile[2])
	Return SetError($iError, $iExtended, $pProfile7)
EndFunc   ;==>__WebView2_Ext_Profile7

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_CompleteWithPointer
; Description ...: Receives add/list completion and retains the returned COM pointer until read.
; ===============================================================================================================================
Func __WebView2_Ext_CompleteWithPointer($pSelf, $iHRESULT, $pResult)
	#forceref $pSelf
	If $__g_iWebView2_ExtPending = 0 Then Return $WEBVIEW2_S_OK
	$__g_iWebView2_ExtHRESULT = $iHRESULT
	If $__g_iWebView2_ExtPending = 1 And $pResult Then
		DllCallAddress("ulong", __WebView2_Ext_Method($pResult, 1), "ptr", $pResult)
		$__g_pWebView2_ExtResult = $pResult
	EndIf
	$__g_bWebView2_ExtDone = True
	If $__g_iWebView2_ExtPending = 2 Then $__g_iWebView2_ExtPending = 0
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_Ext_CompleteWithPointer

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_Complete
; Description ...: Receives enable/remove completion.
; ===============================================================================================================================
Func __WebView2_Ext_Complete($pSelf, $iHRESULT)
	#forceref $pSelf
	If $__g_iWebView2_ExtPending = 0 Then Return $WEBVIEW2_S_OK
	$__g_iWebView2_ExtHRESULT = $iHRESULT
	$__g_bWebView2_ExtDone = True
	If $__g_iWebView2_ExtPending = 2 Then $__g_iWebView2_ExtPending = 0
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_Ext_Complete

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_Begin
; Description ...: Reserves the single synchronous extension operation slot.
; ===============================================================================================================================
Func __WebView2_Ext_Begin()
	If $__g_iWebView2_ExtPending Then Return SetError($WEBVIEW2_ERR_BUSY, 0, False)
	$__g_iWebView2_ExtPending = 1
	$__g_bWebView2_ExtDone = False
	$__g_iWebView2_ExtHRESULT = 0
	$__g_pWebView2_ExtResult = 0
	Return True
EndFunc   ;==>__WebView2_Ext_Begin

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_Wait
; Description ...: Pumps messages until a native extension operation completes or times out.
; ===============================================================================================================================
Func __WebView2_Ext_Wait($iTimeoutMs)
	Local $bDone = __WebView2_WaitForFlag($__g_bWebView2_ExtDone, $iTimeoutMs)
	Local $iWaitError = @error, $iWaitExtended = @extended
	If Not $bDone Then
		$__g_iWebView2_ExtPending = 2
		Return SetError($iWaitError ? $iWaitError : $WEBVIEW2_ERR_TIMEOUT, $iWaitExtended, False)
	EndIf
	$__g_iWebView2_ExtPending = 0
	If $__g_iWebView2_ExtHRESULT <> 0 Then
		__WebView2_Ext_Release($__g_pWebView2_ExtResult)
		$__g_pWebView2_ExtResult = 0
		Return SetError($WEBVIEW2_ERR_HRESULT, $__g_iWebView2_ExtHRESULT, False)
	EndIf
	Return True
EndFunc   ;==>__WebView2_Ext_Wait

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_GetString
; Description ...: Reads and frees a COM-allocated extension property.
; ===============================================================================================================================
Func __WebView2_Ext_GetString($pExtension, $iSlot)
	Local $aResult = DllCallAddress("long", __WebView2_Ext_Method($pExtension, $iSlot), "ptr", $pExtension, "ptr*", 0)
	If @error Or $aResult[0] <> 0 Then Return SetError($WEBVIEW2_ERR_HRESULT, $aResult[0], "")
	Return __WebView2_CoTaskMemString_ReadAndFree($aResult[2])
EndFunc   ;==>__WebView2_Ext_GetString

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_FindById
; Description ...: Resolves an extension ID against the current profile snapshot.
; ===============================================================================================================================
Func __WebView2_Ext_FindById($pList, $sId)
	Local $aCount = DllCallAddress("long", __WebView2_Ext_Method($pList, 3), "ptr", $pList, "uint*", 0)
	If @error Or $aCount[0] <> 0 Then Return SetError($WEBVIEW2_ERR_HRESULT, $aCount[0], 0)
	For $i = 0 To $aCount[2] - 1
		Local $aItem = DllCallAddress("long", __WebView2_Ext_Method($pList, 4), "ptr", $pList, "uint", $i, "ptr*", 0)
		If @error Or $aItem[0] <> 0 Then ContinueLoop
		Local $sCurrentId = __WebView2_Ext_GetString($aItem[3], 3)
		If $sCurrentId = $sId Then Return $aItem[3] ; Caller owns the reference.
		__WebView2_Ext_Release($aItem[3])
	Next
	Return SetError($WEBVIEW2_ERR_NO_MATCH, 0, 0)
EndFunc   ;==>__WebView2_Ext_FindById

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_NativeExtension_Add
; Description ...: Installs an unpacked extension into the current WebView2 profile.
; Syntax ........: _WebView2_NativeExtension_Add($iWebView, $sFolder[, $iTimeoutMs = 30000])
; Return values .: Extension ID; empty string with @error on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The folder must contain manifest.json and remain unchanged; installation persists with a persistent profile.
; Related .......: _WebView2_NativeExtensions_EnableForEnvironment
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2profile7
; ===============================================================================================================================
Func _WebView2_NativeExtension_Add($iWebView, $sFolder, $iTimeoutMs = 30000)
	If Not IsString($sFolder) Or Not FileExists($sFolder & "\manifest.json") Then Return __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "An unpacked extension with manifest.json is required.", "")
	Local $pProfile = __WebView2_Ext_Profile7($iWebView)
	If @error Then Return __WebView2_Fail(@error, @extended, "Native extension profile is unavailable.", "")
	If Not __WebView2_Ext_Begin() Then
		__WebView2_Ext_Release($pProfile)
		Return __WebView2_Fail($WEBVIEW2_ERR_BUSY, 0, "An extension operation is pending.", "")
	EndIf
	Local $aCall = DllCallAddress("long", __WebView2_Ext_Method($pProfile, 22), "ptr", $pProfile, "wstr", $sFolder, "ptr", __WebView2_Callback_GetPointer($__WEBVIEW2_CB_EXTENSION_ADD))
	Local $iCallError = @error
	__WebView2_Ext_Release($pProfile)
	If $iCallError Or $aCall[0] <> 0 Then
		$__g_iWebView2_ExtPending = 0
		Return __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $aCall[0], "AddBrowserExtension failed.", "")
	EndIf
	Local $bDone = __WebView2_Ext_Wait($iTimeoutMs)
	If Not $bDone Then Return __WebView2_Fail(@error, @extended, "AddBrowserExtension did not complete.", "")
	Local $sId = __WebView2_Ext_GetString($__g_pWebView2_ExtResult, 3)
	Local $iError = @error, $iExtended = @extended
	__WebView2_Ext_Release($__g_pWebView2_ExtResult)
	$__g_pWebView2_ExtResult = 0
	If $iError Then Return __WebView2_Fail($iError, $iExtended, "Could not read extension ID.", "")
	Return $sId
EndFunc   ;==>_WebView2_NativeExtension_Add

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_NativeExtension_List
; Description ...: Returns a snapshot of extension ID, name and enabled state in a 2-D array.
; Syntax ........: _WebView2_NativeExtension_List($iWebView[, $iTimeoutMs = 30000])
; Return values .: Array [count][3] with ID, name, enabled; @error on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: An empty profile returns a zero-row array.
; Related .......: _WebView2_NativeExtension_Add
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2profile7
; ===============================================================================================================================
Func __WebView2_Ext_GetListPointer($iWebView, $iTimeoutMs)
	Local $pProfile = __WebView2_Ext_Profile7($iWebView)
	If @error Then Return SetError(@error, @extended, 0)
	If Not __WebView2_Ext_Begin() Then
		__WebView2_Ext_Release($pProfile)
		Return SetError($WEBVIEW2_ERR_BUSY, 0, 0)
	EndIf
	Local $aCall = DllCallAddress("long", __WebView2_Ext_Method($pProfile, 23), "ptr", $pProfile, "ptr", __WebView2_Callback_GetPointer($__WEBVIEW2_CB_EXTENSION_LIST))
	Local $iCallError = @error
	__WebView2_Ext_Release($pProfile)
	If $iCallError Or $aCall[0] <> 0 Then
		$__g_iWebView2_ExtPending = 0
		Return SetError($WEBVIEW2_ERR_HRESULT, $aCall[0], 0)
	EndIf
	Local $bDone = __WebView2_Ext_Wait($iTimeoutMs)
	If Not $bDone Then Return SetError(@error, @extended, 0)
	Local $pList = $__g_pWebView2_ExtResult
	$__g_pWebView2_ExtResult = 0
	If Not $pList Then Return SetError($WEBVIEW2_ERR_HRESULT, $WEBVIEW2_E_POINTER, 0)
	Return $pList
EndFunc   ;==>__WebView2_Ext_GetListPointer

Func _WebView2_NativeExtension_List($iWebView, $iTimeoutMs = 30000)
	Local $pList = __WebView2_Ext_GetListPointer($iWebView, $iTimeoutMs)
	If @error Then Return SetError(@error, @extended, 0)
	Local $aCount = DllCallAddress("long", __WebView2_Ext_Method($pList, 3), "ptr", $pList, "uint*", 0)
	If @error Or $aCount[0] <> 0 Then
		__WebView2_Ext_Release($pList)
		Return SetError($WEBVIEW2_ERR_HRESULT, $aCount[0], 0)
	EndIf
	Local $aExtensions[$aCount[2]][3]
	For $i = 0 To $aCount[2] - 1
		Local $aItem = DllCallAddress("long", __WebView2_Ext_Method($pList, 4), "ptr", $pList, "uint", $i, "ptr*", 0)
		If @error Or $aItem[0] <> 0 Then ContinueLoop
		$aExtensions[$i][0] = __WebView2_Ext_GetString($aItem[3], 3)
		$aExtensions[$i][1] = __WebView2_Ext_GetString($aItem[3], 4)
		Local $aEnabled = DllCallAddress("long", __WebView2_Ext_Method($aItem[3], 6), "ptr", $aItem[3], "int*", 0)
		$aExtensions[$i][2] = Not @error And $aEnabled[0] = 0 And $aEnabled[2] <> 0
		__WebView2_Ext_Release($aItem[3])
	Next
	__WebView2_Ext_Release($pList)
	Return $aExtensions
EndFunc   ;==>_WebView2_NativeExtension_List

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Ext_Change
; Description ...: Enables, disables or removes an extension found by its ID.
; ===============================================================================================================================
Func __WebView2_Ext_Change($iWebView, $sId, $bEnabled, $bRemove, $iTimeoutMs)
	If Not IsString($sId) Or $sId = "" Then Return SetError($WEBVIEW2_ERR_INVALID_PARAMETER, 0, False)
	Local $pList = __WebView2_Ext_GetListPointer($iWebView, $iTimeoutMs)
	If @error Then Return SetError(@error, @extended, False)
	Local $pExtension = __WebView2_Ext_FindById($pList, $sId)
	Local $iFindError = @error, $iFindExtended = @extended
	__WebView2_Ext_Release($pList)
	If $iFindError Then Return SetError($iFindError, $iFindExtended, False)
	If Not __WebView2_Ext_Begin() Then
		__WebView2_Ext_Release($pExtension)
		Return SetError($WEBVIEW2_ERR_BUSY, 0, False)
	EndIf
	Local $aCall
	If $bRemove Then
		$aCall = DllCallAddress("long", __WebView2_Ext_Method($pExtension, 5), "ptr", $pExtension, "ptr", __WebView2_Callback_GetPointer($__WEBVIEW2_CB_EXTENSION_REMOVE))
	Else
		$aCall = DllCallAddress("long", __WebView2_Ext_Method($pExtension, 7), "ptr", $pExtension, "int", $bEnabled ? 1 : 0, "ptr", __WebView2_Callback_GetPointer($__WEBVIEW2_CB_EXTENSION_ENABLE))
	EndIf
	Local $iCallError = @error
	__WebView2_Ext_Release($pExtension)
	If $iCallError Or $aCall[0] <> 0 Then
		$__g_iWebView2_ExtPending = 0
		Return SetError($WEBVIEW2_ERR_HRESULT, $aCall[0], False)
	EndIf
	Return __WebView2_Ext_Wait($iTimeoutMs)
EndFunc   ;==>__WebView2_Ext_Change

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_NativeExtension_SetEnabled
; Description ...: Enables or disables an installed extension in its profile.
; Syntax ........: _WebView2_NativeExtension_SetEnabled($iWebView, $sId, $bEnabled[, $iTimeoutMs = 30000])
; Return values .: True on success; False with @error on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The enabled state persists in the profile.
; Related .......: _WebView2_NativeExtension_List
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2browserextension
; ===============================================================================================================================
Func _WebView2_NativeExtension_SetEnabled($iWebView, $sId, $bEnabled, $iTimeoutMs = 30000)
	Return __WebView2_Ext_Change($iWebView, $sId, $bEnabled, False, $iTimeoutMs)
EndFunc   ;==>_WebView2_NativeExtension_SetEnabled

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_NativeExtension_Remove
; Description ...: Removes an installed extension from its profile.
; Syntax ........: _WebView2_NativeExtension_Remove($iWebView, $sId[, $iTimeoutMs = 30000])
; Return values .: True on success; False with @error on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Removal persists in the profile.
; Related .......: _WebView2_NativeExtension_List
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2browserextension
; ===============================================================================================================================
Func _WebView2_NativeExtension_Remove($iWebView, $sId, $iTimeoutMs = 30000)
	Return __WebView2_Ext_Change($iWebView, $sId, False, True, $iTimeoutMs)
EndFunc   ;==>_WebView2_NativeExtension_Remove
