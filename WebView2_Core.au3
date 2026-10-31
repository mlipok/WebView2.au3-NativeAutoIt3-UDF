#include-once
#Tidy_ILC_Pos=44

#include <WinAPI.au3>
#include <WinAPICom.au3>
#include <StructureConstants.au3>

#include "WebView2_Constants.au3"
#include "WebView2_Interfaces.au3"
#include "WebView2_CallbackObject.au3"

; #INDEX# =======================================================================================================================
; Title .........: WebView2_Core.au3
; Description ...: Public and internal implementation for WebView2.au3.
; Author(s) .....: mLipok
; Version .......: 0.5.0
; ===============================================================================================================================

Global Enum _
		$__WEBVIEW2_INSTANCE_USED, _
		$__WEBVIEW2_INSTANCE_PARENT, _
		$__WEBVIEW2_INSTANCE_CONTROLLER, _
		$__WEBVIEW2_INSTANCE_CORE, _
		$__WEBVIEW2_INSTANCE_CORE_POINTER, _
		$__WEBVIEW2_INSTANCE_LEFT, _
		$__WEBVIEW2_INSTANCE_TOP, _
		$__WEBVIEW2_INSTANCE_WIDTH, _
		$__WEBVIEW2_INSTANCE_HEIGHT, _
		$__WEBVIEW2_INSTANCE_CB_NAV_START, _
		$__WEBVIEW2_INSTANCE_CB_NAV_COMPLETE, _
		$__WEBVIEW2_INSTANCE_CB_TITLE, _
		$__WEBVIEW2_INSTANCE_CB_MESSAGE, _
		$__WEBVIEW2_INSTANCE_CB_NEW_WINDOW, _
		$__WEBVIEW2_INSTANCE_TOKEN_NAV_START, _
		$__WEBVIEW2_INSTANCE_TOKEN_NAV_COMPLETE, _
		$__WEBVIEW2_INSTANCE_TOKEN_TITLE, _
		$__WEBVIEW2_INSTANCE_TOKEN_MESSAGE, _
		$__WEBVIEW2_INSTANCE_TOKEN_NEW_WINDOW, _
		$__WEBVIEW2_INSTANCE_CORE8, _
		$__WEBVIEW2_INSTANCE_CB_AUDIO, _
		$__WEBVIEW2_INSTANCE_TOKEN_AUDIO, _
		$__WEBVIEW2_INSTANCE_FIELDS

Global $__g_aWebView2_Instances[$WEBVIEW2_MAX_INSTANCES][$__WEBVIEW2_INSTANCE_FIELDS]
Global $__g_bWebView2_Initialized = False
Global $__g_bWebView2_COMInitialized = False
Global $__g_hWebView2_Loader = -1
Global $__g_sWebView2_LoaderPath = ""
Global $__g_oWebView2_Environment = Null
Global $__g_bWebView2_EnvironmentDone = False
Global $__g_iWebView2_EnvironmentHRESULT = 0
Global $__g_iWebView2_PendingCreateSlot = -1
Global $__g_bWebView2_CreateDone = False
Global $__g_iWebView2_CreateHRESULT = 0
Global $__g_bWebView2_ScriptBusy = False
Global $__g_bWebView2_ScriptDone = False
Global $__g_iWebView2_ScriptHRESULT = 0
Global $__g_sWebView2_ScriptResult = ""
Global $__g_sWebView2_LastError = ""
Global $__g_iWebView2_LastError = $WEBVIEW2_ERR_NONE
Global $__g_iWebView2_LastExtended = 0
Global $__g_bWebView2_Trace = True
Global $__g_iWebView2_DebugLevel = $WEBVIEW2_DEBUG_FULL
Global $__g_fnWebView2_Sleep = Default
Global $__g_aWebView2_Tabs[$WEBVIEW2_MAX_INSTANCES]

; Win32 MSG structure used by the internal message pump.
; Defined locally because AutoIt 3.3.18.0 does not expose $tagMSG through the includes used by this UDF.
Global Const $__WEBVIEW2_TAG_MSG = "struct;hwnd hwnd;uint message;wparam wParam;lparam lParam;dword time;long X;long Y;dword lPrivate;endstruct"

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Init
; Description ...: Initializes STA COM, callback objects, WebView2Loader.dll and the shared WebView2 environment.
; Syntax ........: _WebView2_Init([$sLoaderPath = Default[, $sUserDataFolder = ""[, $sBrowserExecutableFolder = ""[, $iTimeoutMs = 30000]]]])
; Parameters ....: $sLoaderPath - Full loader path or directory containing architecture subfolders. Default searches common locations.
;                  $sUserDataFolder - Optional WebView2 user data folder. Empty uses the WebView2 default.
;                  $sBrowserExecutableFolder - Optional fixed-version WebView2 browser folder.
;                  $iTimeoutMs - Maximum initialization wait in milliseconds.
; Return values .: On Success - True.
;                  On Failure - False.
;                  @error $WEBVIEW2_ERR_USER_ABORT - User sleep callback cancelled the environment wait.
;                  @extended contains the callback error for USER_ABORT.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Uses native Win32 WebView2 API without a .NET/COM bridge.
; Related .......: _WebView2_Cleanup, _WebView2_Runtime_GetVersion
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/webview2-idl
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Init($sLoaderPath = Default, $sUserDataFolder = "", $sBrowserExecutableFolder = "", $iTimeoutMs = 30000)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_Init"
	Local $sMessage = ''
	Do
		If $__g_bWebView2_Initialized Then
			$__WebView2ExitValue = True
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		__WebView2_Error_Clear()

		Local $sResolvedLoader = __WebView2_Loader_Resolve($sLoaderPath)
		If @error Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_LOADER_NOT_FOUND, 0, "WebView2Loader.dll was not found.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__g_hWebView2_Loader = DllOpen($sResolvedLoader)
		If $__g_hWebView2_Loader = -1 Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_LOADER_OPEN, 0, "Unable to open WebView2Loader.dll: " & $sResolvedLoader, False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__g_sWebView2_LoaderPath = $sResolvedLoader

		; CoInitializeEx() returns both S_OK (0) and S_FALSE (1) for successful initialization.
		; S_FALSE means COM was already initialized on this thread in the same apartment model.
		Local $aCOMInit = DllCall("ole32.dll", "long", "CoInitializeEx", "ptr", 0, "dword", $COINIT_APARTMENTTHREADED)
		If @error Then
			Local $iCOMDllCallError = @error
			DllClose($__g_hWebView2_Loader)
			$__g_hWebView2_Loader = -1
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_DLLCALL, $iCOMDllCallError, "CoInitializeEx() could not be called.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $iCOMHRESULT = $aCOMInit[0]
		If __WebView2_HRESULT_Failed($iCOMHRESULT) Then
			DllClose($__g_hWebView2_Loader)
			$__g_hWebView2_Loader = -1
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iCOMHRESULT, "COM initialization failed. HRESULT=" & __WebView2_HRESULT_Format($iCOMHRESULT), False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		; Every successful CoInitializeEx() call, including S_FALSE, must be balanced by CoUninitialize().
		$__g_bWebView2_COMInitialized = True

		If Not __WebView2_Callbacks_Create() Then
			Local $iCallbackExtended = @extended
			_WebView2_Cleanup()
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_CALLBACK, $iCallbackExtended, "Unable to create WebView2 callback objects.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__g_bWebView2_EnvironmentDone = False
		$__g_iWebView2_EnvironmentHRESULT = 0

		Local $aResult = DllCall($__g_hWebView2_Loader, "long", "CreateCoreWebView2EnvironmentWithOptions", _
				"wstr", $sBrowserExecutableFolder, "wstr", $sUserDataFolder, "ptr", 0, _
				"ptr", __WebView2_Callback_GetPointer($__WEBVIEW2_CB_ENVIRONMENT))
		If @error Then
			Local $iDllCallError = @error
			_WebView2_Cleanup()
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_DLLCALL, $iDllCallError, "CreateCoreWebView2EnvironmentWithOptions() could not be called.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If $aResult[0] <> $WEBVIEW2_S_OK Then
			Local $iHRESULT = $aResult[0]
			_WebView2_Cleanup()
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iHRESULT, "CreateCoreWebView2EnvironmentWithOptions() returned an error.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $bEnvironmentWait = __WebView2_WaitForFlag($__g_bWebView2_EnvironmentDone, $iTimeoutMs)
		Local $iEnvironmentWaitError = @error
		Local $iEnvironmentWaitExtended = @extended
		If Not $bEnvironmentWait Then
			_WebView2_Cleanup()
			If $iEnvironmentWaitError = $WEBVIEW2_ERR_USER_ABORT Then
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_USER_ABORT, $iEnvironmentWaitExtended, "Environment creation wait was cancelled.", False)
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			EndIf
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_TIMEOUT, 0, "Timed out while creating the WebView2 environment.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		If $__g_iWebView2_EnvironmentHRESULT <> $WEBVIEW2_S_OK Or Not IsObj($__g_oWebView2_Environment) Then
			Local $iEnvironmentHRESULT = $__g_iWebView2_EnvironmentHRESULT
			_WebView2_Cleanup()
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iEnvironmentHRESULT, "WebView2 environment creation failed.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__g_bWebView2_Initialized = True
		$__WebView2ExitValue = True
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_Init

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Cleanup
; Description ...: Closes all WebView2 instances and releases UDF resources.
; Syntax ........: _WebView2_Cleanup()
; Parameters ....: None.
; Return values .: True.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Safe to call more than once.
; Related .......: _WebView2_Init, _WebView2_Destroy
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Cleanup()
	__WebView2_Trace("CLEANUP 01 START")

	For $i = 0 To $WEBVIEW2_MAX_INSTANCES - 1
		If $__g_aWebView2_Instances[$i][$__WEBVIEW2_INSTANCE_USED] Then __WebView2_Instance_Dispose($i)
	Next

	__WebView2_Trace("CLEANUP 02 Environment wrapper CLEAR START")
	$__g_oWebView2_Environment = Null
	__WebView2_Trace("CLEANUP 03 Environment wrapper CLEARED")

	$__g_bWebView2_Initialized = False
	$__g_bWebView2_EnvironmentDone = False
	$__g_iWebView2_PendingCreateSlot = -1
	$__g_bWebView2_ScriptBusy = False

	__WebView2_Trace("CLEANUP 04 Callback objects DELETE START")
	__WebView2_Callback_DeleteAll()
	__WebView2_Trace("CLEANUP 05 Callback objects DELETE OK")

	If $__g_hWebView2_Loader <> -1 Then
		__WebView2_Trace("CLEANUP 06 Loader CLOSE START")
		DllClose($__g_hWebView2_Loader)
		$__g_hWebView2_Loader = -1
		__WebView2_Trace("CLEANUP 07 Loader CLOSE OK")
	EndIf
	$__g_sWebView2_LoaderPath = ""

	If $__g_bWebView2_COMInitialized Then
		__WebView2_Trace("CLEANUP 08 CoUninitialize START")
		DllCall("ole32.dll", "none", "CoUninitialize")
		$__g_bWebView2_COMInitialized = False
		__WebView2_Trace("CLEANUP 09 CoUninitialize OK")
	EndIf

	__WebView2_Trace("CLEANUP 10 FINISHED")

	Return True
EndFunc   ;==>_WebView2_Cleanup

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Runtime_IsInstalled
; Description ...: Checks whether a compatible Evergreen WebView2 Runtime is available.
; Syntax ........: _WebView2_Runtime_IsInstalled([$sLoaderPath = Default])
; Parameters ....: $sLoaderPath - WebView2Loader.dll path or directory. Default searches common locations.
; Return values .: True when a runtime version can be queried, otherwise False.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The loader DLL itself is still required to perform this check.
; Related .......: _WebView2_Runtime_GetVersion
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/concepts/distribution
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Runtime_IsInstalled($sLoaderPath = Default)
	Local $sVersion = _WebView2_Runtime_GetVersion($sLoaderPath)
	Return ($sVersion <> "")
EndFunc   ;==>_WebView2_Runtime_IsInstalled

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Runtime_GetVersion
; Description ...: Returns the available Evergreen WebView2 Runtime version.
; Syntax ........: _WebView2_Runtime_GetVersion([$sLoaderPath = Default])
; Parameters ....: $sLoaderPath - WebView2Loader.dll path or directory. Default searches common locations.
; Return values .: On Success - Runtime version string.
;                  On Failure - Empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Uses GetAvailableCoreWebView2BrowserVersionString().
; Related .......: _WebView2_Runtime_IsInstalled, _WebView2_Init
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/webview2-idl
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Runtime_GetVersion($sLoaderPath = Default)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_Runtime_GetVersion"
	Local $sMessage = ''
	Do
		__WebView2_Error_Clear()

		Local $hLoader = $__g_hWebView2_Loader
		Local $bTemporary = False

		If $hLoader = -1 Then
			Local $sResolvedLoader = __WebView2_Loader_Resolve($sLoaderPath)
			If @error Then
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_LOADER_NOT_FOUND, 0, "WebView2Loader.dll was not found.", "")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			EndIf

			$hLoader = DllOpen($sResolvedLoader)
			If $hLoader = -1 Then
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_LOADER_OPEN, 0, "Unable to open WebView2Loader.dll.", "")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			EndIf
			$bTemporary = True
		EndIf

		Local $aResult = DllCall($hLoader, "long", "GetAvailableCoreWebView2BrowserVersionString", "ptr", 0, "ptr*", 0)
		Local $iDllError = @error

		If $bTemporary Then DllClose($hLoader)

		If $iDllError Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_DLLCALL, $iDllError, "GetAvailableCoreWebView2BrowserVersionString() could not be called.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If $aResult[0] <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_RUNTIME_NOT_FOUND, $aResult[0], "WebView2 Runtime was not found.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__WebView2ExitValue = __WebView2_CoTaskMemString_ReadAndFree($aResult[2])
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_Runtime_GetVersion

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Create
; Description ...: Creates a WebView2 controller and view inside a parent HWND.
; Syntax ........: _WebView2_Create($hWndParent[, $iLeft = 0[, $iTop = 0[, $iWidth = -1[, $iHeight = -1[, $iTimeoutMs = 30000]]]]])
; Parameters ....: $hWndParent - Parent window handle.
;                  $iLeft - Left coordinate inside the parent client area.
;                  $iTop - Top coordinate inside the parent client area.
;                  $iWidth - Width; -1 fills remaining parent client width.
;                  $iHeight - Height; -1 fills remaining parent client height.
;                  $iTimeoutMs - Maximum controller creation wait in milliseconds.
; Return values .: On Success - Numeric WebView instance ID.
;                  On Failure - -1.
;                  @error $WEBVIEW2_ERR_USER_ABORT - User sleep callback cancelled the controller wait.
;                  @extended contains the callback error for USER_ABORT.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Multiple sequentially-created instances share one WebView2 environment.
; Related .......: _WebView2_Destroy, _WebView2_SetBounds, _WebView2_ResizeToParent
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Create($hWndParent, $iLeft = 0, $iTop = 0, $iWidth = -1, $iHeight = -1, $iTimeoutMs = 30000)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_Create"
	Local $sMessage = ''
	Do
		If Not $__g_bWebView2_Initialized Or Not IsObj($__g_oWebView2_Environment) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_NOT_INITIALIZED, 0, "WebView2 is not initialized.", -1)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not IsHWnd($hWndParent) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Invalid parent HWND.", -1)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If $__g_iWebView2_PendingCreateSlot <> -1 Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_BUSY, 0, "Another WebView2 instance is being created.", -1)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $iSlot = __WebView2_Instance_Allocate()
		If $iSlot < 0 Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_NO_FREE_SLOT, 0, "No free WebView2 instance slots are available.", -1)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		If $iWidth < 0 Or $iHeight < 0 Then
			Local $tClient = _WinAPI_GetClientRect($hWndParent)
			If $iWidth < 0 Then $iWidth = DllStructGetData($tClient, "Right") - $iLeft
			If $iHeight < 0 Then $iHeight = DllStructGetData($tClient, "Bottom") - $iTop
		EndIf

		$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_PARENT] = $hWndParent
		$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_LEFT] = $iLeft
		$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOP] = $iTop
		$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_WIDTH] = $iWidth
		$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_HEIGHT] = $iHeight

		$__g_iWebView2_PendingCreateSlot = $iSlot
		$__g_bWebView2_CreateDone = False
		$__g_iWebView2_CreateHRESULT = 0

		__WebView2_Trace("CREATE 01 CreateCoreWebView2Controller START slot=" & $iSlot & " hwnd=" & $hWndParent)
		Local $iResult = $__g_oWebView2_Environment.CreateCoreWebView2Controller($hWndParent, __WebView2_Callback_GetPointer($__WEBVIEW2_CB_CONTROLLER))
		__WebView2_Trace("CREATE 02 CreateCoreWebView2Controller RETURN hr=" & __WebView2_HRESULT_Format($iResult) & " autoit_error=" & @error)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			Local $iHRESULT = $iResult
			$__g_iWebView2_PendingCreateSlot = -1
			__WebView2_Instance_Reset($iSlot)
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iHRESULT, "CreateCoreWebView2Controller() failed.", -1)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $bCreateWait = __WebView2_WaitForFlag($__g_bWebView2_CreateDone, $iTimeoutMs)
		Local $iCreateWaitError = @error
		Local $iCreateWaitExtended = @extended
		If Not $bCreateWait Then
			$__g_iWebView2_PendingCreateSlot = -1
			__WebView2_Instance_Dispose($iSlot)
			If $iCreateWaitError = $WEBVIEW2_ERR_USER_ABORT Then
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_USER_ABORT, $iCreateWaitExtended, "Controller creation wait was cancelled.", -1)
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			EndIf
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_TIMEOUT, 0, "Timed out while creating the WebView2 controller.", -1)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__g_iWebView2_PendingCreateSlot = -1
		If $__g_iWebView2_CreateHRESULT <> $WEBVIEW2_S_OK Or Not IsObj($__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CORE]) Then
			Local $iCreateHRESULT = $__g_iWebView2_CreateHRESULT
			__WebView2_Instance_Dispose($iSlot)
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iCreateHRESULT, "WebView2 controller creation failed.", -1)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__WebView2ExitValue = $iSlot
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_Create

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Destroy
; Description ...: Closes and releases one WebView2 instance.
; Syntax ........: _WebView2_Destroy($iWebView)
; Parameters ....: $iWebView - WebView instance ID returned by _WebView2_Create().
; Return values .: On Success - True.
;                  On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The shared WebView2 environment remains alive.
; Related .......: _WebView2_Create, _WebView2_Cleanup
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Destroy($iWebView)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_Destroy"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__g_aWebView2_Tabs[$iWebView] = False
		__WebView2_Instance_Dispose($iWebView)
		$__WebView2ExitValue = True
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_Destroy

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetBounds
; Description ...: Sets the WebView2 rectangle inside its parent window.
; Syntax ........: _WebView2_SetBounds($iWebView, $iLeft, $iTop, $iWidth, $iHeight)
; Parameters ....: $iWebView - WebView instance ID.
;                  $iLeft - Left coordinate.
;                  $iTop - Top coordinate.
;                  $iWidth - Width.
;                  $iHeight - Height.
; Return values .: On Success - True.
;                  On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Uses ICoreWebView2Controller::put_Bounds.
; Related .......: _WebView2_ResizeToParent
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_SetBounds($iWebView, $iLeft, $iTop, $iWidth, $iHeight)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_SetBounds"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $tRect = DllStructCreate($tagRECT)
		DllStructSetData($tRect, "Left", $iLeft)
		DllStructSetData($tRect, "Top", $iTop)
		DllStructSetData($tRect, "Right", $iLeft + $iWidth)
		DllStructSetData($tRect, "Bottom", $iTop + $iHeight)

		Local $oController = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CONTROLLER]
		Local $iResult = $oController.put_Bounds($tRect)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iResult, "put_Bounds() failed.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_LEFT] = $iLeft
		$__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_TOP] = $iTop
		$__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_WIDTH] = $iWidth
		$__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_HEIGHT] = $iHeight
		$__WebView2ExitValue = True
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_SetBounds

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ResizeToParent
; Description ...: Resizes a WebView2 instance to the current parent client area.
; Syntax ........: _WebView2_ResizeToParent($iWebView[, $iLeft = 0[, $iTop = 0]])
; Parameters ....: $iWebView - WebView instance ID.
;                  $iLeft - Optional left margin.
;                  $iTop - Optional top margin.
; Return values .: On Success - True.
;                  On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Intended for GUI resize handlers.
; Related .......: _WebView2_SetBounds
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ResizeToParent($iWebView, $iLeft = 0, $iTop = 0)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_ResizeToParent"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $hParent = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_PARENT]
		Local $tClient = _WinAPI_GetClientRect($hParent)
		Local $iWidth = DllStructGetData($tClient, "Right") - $iLeft
		Local $iHeight = DllStructGetData($tClient, "Bottom") - $iTop
		$__WebView2ExitValue = _WebView2_SetBounds($iWebView, $iLeft, $iTop, $iWidth, $iHeight)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_ResizeToParent

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetVisible
; Description ...: Shows or hides a WebView2 instance.
; Syntax ........: _WebView2_SetVisible($iWebView[, $bVisible = True])
; Parameters ....: $iWebView - WebView instance ID.
;                  $bVisible - True to show; False to hide.
; Return values .: On Success - True.
;                  On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Controller visibility wrapper.
; Related .......: _WebView2_Create
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_SetVisible($iWebView, $bVisible = True)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_SetVisible"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $oController = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CONTROLLER]
		Local $iResult = $oController.put_IsVisible($bVisible)
		Local $iCOMError = @error
		If $iCOMError Or $iResult <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iResult, "put_IsVisible() failed for instance " & $iWebView & ", visible=" & $bVisible & ", HRESULT=" & __WebView2_HRESULT_Format($iResult) & ", AutoIt error=" & $iCOMError & ".", False)
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
EndFunc   ;==>_WebView2_SetVisible

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetZoomFactor
; Description ...: Sets the WebView2 zoom factor.
; Syntax ........: _WebView2_SetZoomFactor($iWebView[, $fZoomFactor = 1.0])
; Parameters ....: $iWebView - WebView instance ID.
;                  $fZoomFactor - Zoom factor, where 1.0 means 100 percent.
; Return values .: On Success - True.
;                  On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Controller zoom wrapper.
; Related .......: _WebView2_Create
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_SetZoomFactor($iWebView, $fZoomFactor = 1.0)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_SetZoomFactor"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If $fZoomFactor <= 0 Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Zoom factor must be greater than zero.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $oController = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CONTROLLER]
		Local $iResult = $oController.put_ZoomFactor($fZoomFactor)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iResult, "put_ZoomFactor() failed.", False)
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
EndFunc   ;==>_WebView2_SetZoomFactor

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Navigate
; Description ...: Navigates to a URI.
; Syntax ........: _WebView2_Navigate($iWebView, $sURI)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sURI - URI to navigate to.
; Return values .: On Success - True.
;                  On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Direct ICoreWebView2::Navigate wrapper.
; Related .......: _WebView2_NavigateToString
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Navigate($iWebView, $sURI)
	Local $__WebView2DirectResult = __WebView2_CoreCall_String($iWebView, "Navigate", $sURI)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_Navigate

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_NavigateToString
; Description ...: Loads HTML content directly into the WebView.
; Syntax ........: _WebView2_NavigateToString($iWebView, $sHTML)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sHTML - HTML document string.
; Return values .: On Success - True.
;                  On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The resulting document uses about:blank as its origin.
; Related .......: _WebView2_Navigate
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_NavigateToString($iWebView, $sHTML)
	Local $__WebView2DirectResult = __WebView2_CoreCall_String($iWebView, "NavigateToString", $sHTML)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_NavigateToString

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetVirtualHostNameToFolderMapping
; Description ...: Serves a local folder from a virtual HTTP(S) host in one WebView2 instance.
; Syntax ........: _WebView2_SetVirtualHostNameToFolderMapping($iWebView, $sHostName, $sFolderPath[, $iAccessKind = $WEBVIEW2_HOST_RESOURCE_ACCESS_DENY])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sHostName - Host name without a scheme or path, such as appassets.example.
;                  $sFolderPath - Absolute path to an existing local folder.
;                  $iAccessKind - One of the following cross-origin access modes:
;                  |$WEBVIEW2_HOST_RESOURCE_ACCESS_DENY - Deny all cross-origin access (default).
;                  |$WEBVIEW2_HOST_RESOURCE_ACCESS_ALLOW - Allow cross-origin access.
;                  |$WEBVIEW2_HOST_RESOURCE_ACCESS_DENY_CORS - Allow ordinary cross-origin subresources but deny CORS requests.
; Return values .: On Success - True.
;                  On Failure - False and sets @error to $WEBVIEW2_ERR_INVALID_INSTANCE, $WEBVIEW2_ERR_INVALID_PARAMETER or $WEBVIEW2_ERR_HRESULT.
;                  @extended contains the native HRESULT for $WEBVIEW2_ERR_HRESULT.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Call before navigating to https://<host>/index.html. The mapping does not require an HTTP server.
; Related .......: _WebView2_Navigate
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_3#setvirtualhostnametofoldermapping
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_SetVirtualHostNameToFolderMapping($iWebView, $sHostName, $sFolderPath, $iAccessKind = $WEBVIEW2_HOST_RESOURCE_ACCESS_DENY)
	Local $__WebView2ExitValue = False
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_SetVirtualHostNameToFolderMapping"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not IsString($sHostName) Or Not StringRegExp($sHostName, "^[A-Za-z0-9][A-Za-z0-9.-]*$") Or StringInStr($sHostName, "..") Or _
				Not IsString($sFolderPath) Or Not FileExists($sFolderPath) Or Not StringInStr(FileGetAttrib($sFolderPath), "D") Or _
				Not IsInt($iAccessKind) Or $iAccessKind < $WEBVIEW2_HOST_RESOURCE_ACCESS_DENY Or $iAccessKind > $WEBVIEW2_HOST_RESOURCE_ACCESS_DENY_CORS Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Invalid host, folder or access kind.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $pCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE_POINTER]
		Local $tCoreVTable = DllStructCreate("ptr", $pCore)
		Local $tQueryInterface = DllStructCreate("ptr", DllStructGetData($tCoreVTable, 1))
		Local $tIID = DllStructCreate($tagGUID)
		Local $aIID = DllCall("ole32.dll", "long", "IIDFromString", "wstr", $WEBVIEW2_IID_ICoreWebView2_3, "ptr", DllStructGetPtr($tIID))
		If @error Or $aIID[0] <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $WEBVIEW2_E_NOINTERFACE, "Could not prepare ICoreWebView2_3 IID.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $aQuery = DllCallAddress("long", DllStructGetData($tQueryInterface, 1), "ptr", $pCore, "ptr", DllStructGetPtr($tIID), "ptr*", 0)
		If @error Or $aQuery[0] <> $WEBVIEW2_S_OK Or Not $aQuery[3] Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $WEBVIEW2_E_NOINTERFACE, "ICoreWebView2_3 is unavailable.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $oCore3 = ObjCreateInterface($aQuery[3], $WEBVIEW2_IID_ICoreWebView2_3, $WEBVIEW2_DTAG_ICoreWebView2_3)
		If Not IsObj($oCore3) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $WEBVIEW2_E_NOINTERFACE, "Could not wrap ICoreWebView2_3.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $iHRESULT = $oCore3.SetVirtualHostNameToFolderMapping($sHostName, $sFolderPath, $iAccessKind)
		Local $iCOMError = @error
		$oCore3 = Null
		If $iCOMError Or $iHRESULT <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iHRESULT, "SetVirtualHostNameToFolderMapping() failed.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = True
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_SetVirtualHostNameToFolderMapping

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Core_QueryAudioInterface
; Description ...: Obtains an ICoreWebView2_8 wrapper for media state.
; Syntax ........: __WebView2_Core_QueryAudioInterface($iWebView)
; Parameters ....: $iWebView - Valid WebView2 instance ID.
; Return values .: On Success - COM wrapper; On Failure - Null and @error.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The wrapper owns the QueryInterface reference and must be released by clearing it.
; Related .......: _WebView2_GetIsDocumentPlayingAudio
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_8
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Core_QueryAudioInterface($iWebView)
	Local $oResult = Null, $iError = 0, $iExtended = 0
	Do
		Local $pCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE_POINTER]
		Local $tCoreVTable = DllStructCreate("ptr", $pCore)
		Local $tQueryInterface = DllStructCreate("ptr", DllStructGetData($tCoreVTable, 1))
		Local $tIID = DllStructCreate($tagGUID)
		Local $aIID = DllCall("ole32.dll", "long", "IIDFromString", "wstr", $WEBVIEW2_IID_ICoreWebView2_8, "ptr", DllStructGetPtr($tIID))
		If @error Then
			$iError = $WEBVIEW2_ERR_DLLCALL
			ExitLoop 1
		EndIf
		If $aIID[0] <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $aIID[0]
			ExitLoop 1
		EndIf
		Local $aQuery = DllCallAddress("long", DllStructGetData($tQueryInterface, 1), "ptr", $pCore, "ptr", DllStructGetPtr($tIID), "ptr*", 0)
		If @error Then
			$iError = $WEBVIEW2_ERR_DLLCALL
			ExitLoop 1
		EndIf
		If $aQuery[0] <> $WEBVIEW2_S_OK Or Not $aQuery[3] Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $aQuery[0]
			ExitLoop 1
		EndIf
		$oResult = ObjCreateInterface($aQuery[3], $WEBVIEW2_IID_ICoreWebView2_8, $WEBVIEW2_DTAG_ICoreWebView2_8)
		If Not IsObj($oResult) Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $WEBVIEW2_E_NOINTERFACE
		EndIf
	Until True
	Return SetError($iError, $iExtended, $oResult)
EndFunc   ;==>__WebView2_Core_QueryAudioInterface

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetIsDocumentPlayingAudio
; Description ...: Reads the native WebView2 document-audio state.
; Syntax ........: _WebView2_GetIsDocumentPlayingAudio($iWebView)
; Parameters ....: $iWebView - WebView2 instance ID.
; Return values .: On Success - True when audio is playing, otherwise False; @error is zero in both cases.
;                  On Failure - False and @error is set; @extended contains a native HRESULT when available.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The value can be True even when the WebView is muted.
; Related .......: _WebView2_SetCallback
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2_8#get_isdocumentplayingaudio
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetIsDocumentPlayingAudio($iWebView)
	Local $bResult = False, $iError = 0, $iExtended = 0
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$iError = $WEBVIEW2_ERR_INVALID_INSTANCE
			ExitLoop 1
		EndIf
		Local $oCore8 = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE8]
		If Not IsObj($oCore8) Then
			$oCore8 = __WebView2_Core_QueryAudioInterface($iWebView)
			$iError = @error
			$iExtended = @extended
			If $iError Then ExitLoop 1
		EndIf
		Local $iPlaying = 0
		Local $iHRESULT = $oCore8.get_IsDocumentPlayingAudio($iPlaying)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iHRESULT
			ExitLoop 1
		EndIf
		$bResult = $iPlaying <> 0
	Until True
	If $iError Then __WebView2_Error("_WebView2_GetIsDocumentPlayingAudio", $iError, "Could not read audio state.", $iExtended)
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_GetIsDocumentPlayingAudio

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Reload
; Description ...: Reloads the current document.
; Syntax ........: _WebView2_Reload($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Navigation helper.
; Related .......: _WebView2_Stop
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_Reload($iWebView)
	Local $__WebView2DirectResult = __WebView2_CoreCall_NoArgs($iWebView, "Reload")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_Reload

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Stop
; Description ...: Stops the current navigation.
; Syntax ........: _WebView2_Stop($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Navigation helper.
; Related .......: _WebView2_Reload
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_Stop($iWebView)
	Local $__WebView2DirectResult = __WebView2_CoreCall_NoArgs($iWebView, "Stop")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_Stop

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GoBack
; Description ...: Navigates backward in history.
; Syntax ........: _WebView2_GoBack($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Check _WebView2_CanGoBack() when needed.
; Related .......: _WebView2_CanGoBack, _WebView2_GoForward
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_GoBack($iWebView)
	Local $__WebView2DirectResult = __WebView2_CoreCall_NoArgs($iWebView, "GoBack")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GoBack

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GoForward
; Description ...: Navigates forward in history.
; Syntax ........: _WebView2_GoForward($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Check _WebView2_CanGoForward() when needed.
; Related .......: _WebView2_CanGoForward, _WebView2_GoBack
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_GoForward($iWebView)
	Local $__WebView2DirectResult = __WebView2_CoreCall_NoArgs($iWebView, "GoForward")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_GoForward

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_CanGoBack
; Description ...: Returns whether backward history navigation is available.
; Syntax ........: _WebView2_CanGoBack($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: Boolean.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Reads ICoreWebView2::CanGoBack.
; Related .......: _WebView2_GoBack
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_CanGoBack($iWebView)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_CanGoBack"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $bValue = False
		Local $oCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE]
		Local $iResult = $oCore.get_CanGoBack($bValue)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iResult, "get_CanGoBack() failed.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $bValue
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_CanGoBack

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_CanGoForward
; Description ...: Returns whether forward history navigation is available.
; Syntax ........: _WebView2_CanGoForward($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: Boolean.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Reads ICoreWebView2::CanGoForward.
; Related .......: _WebView2_GoForward
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_CanGoForward($iWebView)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_CanGoForward"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $bValue = False
		Local $oCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE]
		Local $iResult = $oCore.get_CanGoForward($bValue)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iResult, "get_CanGoForward() failed.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $bValue
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_CanGoForward

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetSource
; Description ...: Returns the current top-level document URI.
; Syntax ........: _WebView2_GetSource($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - URI string; On Failure - empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Frees the COM-allocated string with CoTaskMemFree.
; Related .......: _WebView2_GetDocumentTitle
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetSource($iWebView)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_GetSource"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $pValue = 0
		Local $oCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE]
		Local $iResult = $oCore.get_Source($pValue)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iResult, "get_Source() failed.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = __WebView2_CoTaskMemString_ReadAndFree($pValue)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_GetSource

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetDocumentTitle
; Description ...: Returns the current top-level document title.
; Syntax ........: _WebView2_GetDocumentTitle($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - Document title; On Failure - empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Frees the COM-allocated string with CoTaskMemFree.
; Related .......: _WebView2_GetSource
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetDocumentTitle($iWebView)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_GetDocumentTitle"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $pValue = 0
		Local $oCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE]
		Local $iResult = $oCore.get_DocumentTitle($pValue)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iResult, "get_DocumentTitle() failed.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = __WebView2_CoTaskMemString_ReadAndFree($pValue)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_GetDocumentTitle

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ExecuteScript
; Description ...: Executes JavaScript and waits for the asynchronous WebView2 completion callback.
; Syntax ........: _WebView2_ExecuteScript($iWebView, $sJavaScript[, $iTimeoutMs = 30000])
; Parameters ....: $iWebView - WebView instance ID.
;                  $sJavaScript - JavaScript source.
;                  $iTimeoutMs - Maximum wait for completion in milliseconds.
; Return values .: On Success - JSON-encoded result returned by WebView2.
;                  On Failure - Empty string.
;                  @error $WEBVIEW2_ERR_USER_ABORT - User sleep callback cancelled the script wait.
;                  @extended contains the callback error for USER_ABORT.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: script executions are serialized across all instances.
; Related .......: _WebView2_PostWebMessageAsString, _WebView2_PostWebMessageAsJson
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2#executescript
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ExecuteScript($iWebView, $sJavaScript, $iTimeoutMs = 30000)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_ExecuteScript"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If $__g_bWebView2_ScriptBusy Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_BUSY, 0, "Another ExecuteScript request is still pending.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__g_bWebView2_ScriptBusy = True
		$__g_bWebView2_ScriptDone = False
		$__g_iWebView2_ScriptHRESULT = 0
		$__g_sWebView2_ScriptResult = ""

		Local $oCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE]
		Local $iResult = $oCore.ExecuteScript($sJavaScript, __WebView2_Callback_GetPointer($__WEBVIEW2_CB_EXECUTE_SCRIPT))
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$__g_bWebView2_ScriptBusy = False
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iResult, "ExecuteScript() could not be started.", "")
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
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_USER_ABORT, $iScriptWaitExtended, "Script wait was cancelled.", "")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			EndIf
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_TIMEOUT, 0, "ExecuteScript() timed out.", "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$__g_bWebView2_ScriptBusy = False
		If $__g_iWebView2_ScriptHRESULT <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $__g_iWebView2_ScriptHRESULT, "ExecuteScript() completed with an error.", "")
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
EndFunc   ;==>_WebView2_ExecuteScript

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_PostWebMessageAsString
; Description ...: Posts a string message from the native host to the top-level web document.
; Syntax ........: _WebView2_PostWebMessageAsString($iWebView, $sMessage)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sMessage - Message text.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: JavaScript receives this through window.chrome.webview message events.
; Related .......: _WebView2_PostWebMessageAsJson, _WebView2_SetCallback
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_PostWebMessageAsString($iWebView, $sMessage)
	Local $__WebView2DirectResult = __WebView2_CoreCall_String($iWebView, "PostWebMessageAsString", $sMessage)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_PostWebMessageAsString

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_PostWebMessageAsJson
; Description ...: Posts a JSON message from the native host to the top-level web document.
; Syntax ........: _WebView2_PostWebMessageAsJson($iWebView, $sJSON)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sJSON - Valid JSON text.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: WebView2 validates JSON syntax.
; Related .......: _WebView2_PostWebMessageAsString, _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_PostWebMessageAsJson($iWebView, $sJSON)
	Local $__WebView2DirectResult = __WebView2_CoreCall_String($iWebView, "PostWebMessageAsJson", $sJSON)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_PostWebMessageAsJson

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_OpenDevToolsWindow
; Description ...: Opens Edge DevTools for a WebView2 instance.
; Syntax ........: _WebView2_OpenDevToolsWindow($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Debugging helper.
; Related .......: _WebView2_ExecuteScript
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_OpenDevToolsWindow($iWebView)
	Local $__WebView2DirectResult = __WebView2_CoreCall_NoArgs($iWebView, "OpenDevToolsWindow")
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_OpenDevToolsWindow

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetCallback
; Description ...: Registers an AutoIt callback for one supported WebView2 event.
; Syntax ........: _WebView2_SetCallback($iWebView, $iEvent, $fnCallback)
; Parameters ....: $iWebView - WebView instance ID.
;                  $iEvent - One of the following $WEBVIEW2_EVENT_* constants:
;                  |NAVIGATION_STARTING      - Called before navigation; returning True cancels it.
;                  |NAVIGATION_COMPLETED     - Called after navigation completes.
;                  |DOCUMENT_TITLE_CHANGED   - Called when the page title changes.
;                  |WEB_MESSAGE_RECEIVED     - Called for a message posted by web content.
;                  |NEW_WINDOW_REQUESTED    - Called for target=_blank/window.open; returning True suppresses the popup.
;                  |DOCUMENT_PLAYING_AUDIO_CHANGED - Called when document audio starts or stops; receives ($iWebView, $bIsPlaying).
;                  $fnCallback - AutoIt function reference; pass without quotation marks.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: NewWindowRequested callback receives ($iWebView, $sURI, $bUserInitiated). Returning True marks
;                  the request handled. Queue tab creation outside the callback; the opener WindowProxy is not preserved.
; Related .......: _WebView2_Create, _WebView2_Tab_Create
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_SetCallback($iWebView, $iEvent, $fnCallback)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_SetCallback"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not IsFunc($fnCallback) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_CALLBACK, 0, "Callback must be an AutoIt function reference.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Switch $iEvent
			Case $WEBVIEW2_EVENT_NAVIGATION_STARTING
				$__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CB_NAV_START] = $fnCallback
			Case $WEBVIEW2_EVENT_NAVIGATION_COMPLETED
				$__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CB_NAV_COMPLETE] = $fnCallback
			Case $WEBVIEW2_EVENT_DOCUMENT_TITLE_CHANGED
				$__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CB_TITLE] = $fnCallback
			Case $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED
				$__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CB_MESSAGE] = $fnCallback
			Case $WEBVIEW2_EVENT_NEW_WINDOW_REQUESTED
				$__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CB_NEW_WINDOW] = $fnCallback
			Case $WEBVIEW2_EVENT_DOCUMENT_PLAYING_AUDIO_CHANGED
				If Not $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_TOKEN_AUDIO] Then
					Local $oCore8 = __WebView2_Core_QueryAudioInterface($iWebView)
					Local $iAudioQueryError = @error, $iAudioQueryExtended = @extended
					If $iAudioQueryError Then
						$__WebView2ExitError = $iAudioQueryError
						$__WebView2ExitExtended = $iAudioQueryExtended
						ExitLoop 1
					EndIf
					Local $tAudioToken = DllStructCreate("int64")
					Local $iAudioResult = $oCore8.add_IsDocumentPlayingAudioChanged(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_DOCUMENT_PLAYING_AUDIO_CHANGED), $tAudioToken)
					If @error Or $iAudioResult <> $WEBVIEW2_S_OK Then
						$__WebView2ExitError = $WEBVIEW2_ERR_HRESULT
						$__WebView2ExitExtended = $iAudioResult
						ExitLoop 1
					EndIf
					$__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE8] = $oCore8
					$__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_TOKEN_AUDIO] = DllStructGetData($tAudioToken, 1)
				EndIf
				$__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CB_AUDIO] = $fnCallback
			Case Else
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Unsupported WebView2 event constant.", False)
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
		EndSwitch

		$__WebView2ExitValue = True
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_SetCallback

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_IsReady
; Description ...: Checks whether a WebView2 instance is valid and ready for use.
; Syntax ........: _WebView2_IsReady($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: True when ready, otherwise False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Native equivalent of the common WebView2 manager IsReady helper.
; Related .......: _WebView2_Create, _WebView2_Destroy
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_IsReady($iWebView)
	Local $__WebView2DirectResult = __WebView2_Instance_IsValid($iWebView)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_IsReady

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetBrowserProcessId
; Description ...: Returns the browser process ID associated with the WebView2 instance.
; Syntax ........: _WebView2_GetBrowserProcessId($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - Browser process ID; On Failure - 0.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Uses ICoreWebView2::get_BrowserProcessId.
; Related .......: _WebView2_IsReady
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetBrowserProcessId($iWebView)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_GetBrowserProcessId"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $iPID = 0
		Local $oCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE]
		Local $iResult = $oCore.get_BrowserProcessId($iPID)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iResult, "get_BrowserProcessId() failed.", 0)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $iPID
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_GetBrowserProcessId

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ResetZoom
; Description ...: Resets zoom to 100 percent.
; Syntax ........: _WebView2_ResetZoom($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Convenience wrapper for _WebView2_SetZoomFactor(..., 1.0).
; Related .......: _WebView2_SetZoomFactor
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ResetZoom($iWebView)
	Local $__WebView2DirectResult = _WebView2_SetZoomFactor($iWebView, 1.0)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_ResetZoom

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Print
; Description ...: Opens the page print dialog using JavaScript window.print().
; Syntax ........: _WebView2_Print($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - True; On Failure - False and @error/@extended set.
; Author ........: mLipok
; Modified ......:
; Remarks .......: This mirrors the simple Print behavior exposed by NetWebView2Lib.
; Related .......: _WebView2_ExecuteScript
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Print($iWebView)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_Print"
	Local $sMessage = ''
	Do
		_WebView2_ExecuteScript($iWebView, "window.print(); true;")
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
EndFunc   ;==>_WebView2_Print

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetHtmlSource
; Description ...: Returns the current document HTML source.
; Syntax ........: _WebView2_GetHtmlSource($iWebView[, $iTimeoutMs = 30000])
; Parameters ....: $iWebView - WebView instance ID.
;                  $iTimeoutMs - Maximum script wait time in milliseconds.
; Return values .: On Success - HTML string; On Failure - empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Decodes the JSON string returned by ExecuteScript.
; Related .......: _WebView2_ExecuteScript, _WebView2_GetSelectedText
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetHtmlSource($iWebView, $iTimeoutMs = 30000)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_GetHtmlSource"
	Local $sMessage = ''
	Do
		Local $sResult = _WebView2_ExecuteScript($iWebView, "document.documentElement.outerHTML", $iTimeoutMs)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = __WebView2_JSONString_Decode($sResult)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_GetHtmlSource

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_GetSelectedText
; Description ...: Returns the text currently selected in the page.
; Syntax ........: _WebView2_GetSelectedText($iWebView[, $iTimeoutMs = 30000])
; Parameters ....: $iWebView - WebView instance ID.
;                  $iTimeoutMs - Maximum script wait time in milliseconds.
; Return values .: On Success - Selected text; On Failure - empty string.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Uses window.getSelection().toString().
; Related .......: _WebView2_GetHtmlSource
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_GetSelectedText($iWebView, $iTimeoutMs = 30000)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_GetSelectedText"
	Local $sMessage = ''
	Do
		Local $sResult = _WebView2_ExecuteScript($iWebView, "window.getSelection().toString()", $iTimeoutMs)
		If @error Then
			$__WebView2ExitValue = SetError(@error, @extended, "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = __WebView2_JSONString_Decode($sResult)
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>_WebView2_GetSelectedText

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_InjectCss
; Description ...: Injects or replaces a style block in the current document.
; Syntax ........: _WebView2_InjectCss($iWebView, $sCss)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sCss - CSS text.
; Return values .: On Success - True; On Failure - False and @error/@extended set.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Stores CSS in a style element with id __autoit_webview2_udf_css.
; Related .......: _WebView2_ClearInjectedCss
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_InjectCss($iWebView, $sCss)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_InjectCss"
	Local $sMessage = ''
	Do
		Local $sEncoded = __WebView2_JavaScript_StringLiteral($sCss)
		Local $sJS = "(()=>{let s=document.getElementById('__autoit_webview2_udf_css');if(!s){s=document.createElement('style');s.id='__autoit_webview2_udf_css';document.head.appendChild(s);}s.textContent=" & $sEncoded & ";return true;})()"
		_WebView2_ExecuteScript($iWebView, $sJS)
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
EndFunc   ;==>_WebView2_InjectCss

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_ClearInjectedCss
; Description ...: Removes CSS previously injected with _WebView2_InjectCss.
; Syntax ........: _WebView2_ClearInjectedCss($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - True; On Failure - False and @error/@extended set.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Safe when no injected style exists.
; Related .......: _WebView2_InjectCss
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_ClearInjectedCss($iWebView)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_ClearInjectedCss"
	Local $sMessage = ''
	Do
		_WebView2_ExecuteScript($iWebView, "(()=>{const s=document.getElementById('__autoit_webview2_udf_css');if(s)s.remove();return true;})()")
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
EndFunc   ;==>_WebView2_ClearInjectedCss

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetFocus
; Description ...: Moves keyboard focus into WebView2.
; Syntax ........: _WebView2_SetFocus($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - True; On Failure - False.
;                  Direct helper returns clear @error/@extended; inspect _WebView2_Error_GetCode/GetExtended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Uses COREWEBVIEW2_MOVE_FOCUS_REASON_PROGRAMMATIC (0).
; Related .......: _WebView2_Create
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_SetFocus($iWebView)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_SetFocus"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $oController = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CONTROLLER]
		Local $iResult = $oController.MoveFocus(0)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iResult, "MoveFocus() failed.", False)
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
EndFunc   ;==>_WebView2_SetFocus

; Settings wrappers inspired by the capabilities exposed by NetWebView2Lib.
; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetScriptEnabled
; Description ...: Enables or disables JavaScript execution.
; Syntax ........: _WebView2_SetScriptEnabled($iWebView[, $bEnabled = True])
; Parameters ....: $iWebView - WebView instance ID.
;                  $bEnabled - Whether to enable the setting. Default: True.
; Return values .: Boolean result from __WebView2_Setting_PutBool.
;                  Direct Return does not preserve that helper's @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_SetScriptEnabled($iWebView, $bEnabled = True)
	Local $__WebView2DirectResult = __WebView2_Setting_PutBool($iWebView, "put_IsScriptEnabled", $bEnabled)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_SetScriptEnabled

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetWebMessageEnabled
; Description ...: Enables or disables Web-message reception.
; Syntax ........: _WebView2_SetWebMessageEnabled($iWebView[, $bEnabled = True])
; Parameters ....: $iWebView - WebView instance ID.
;                  $bEnabled - Whether to enable the setting. Default: True.
; Return values .: Boolean result from __WebView2_Setting_PutBool.
;                  Direct Return does not preserve that helper's @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_SetWebMessageEnabled($iWebView, $bEnabled = True)
	Local $__WebView2DirectResult = __WebView2_Setting_PutBool($iWebView, "put_IsWebMessageEnabled", $bEnabled)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_SetWebMessageEnabled

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetDefaultScriptDialogsEnabled
; Description ...: Enables or disables default JavaScript dialogs.
; Syntax ........: _WebView2_SetDefaultScriptDialogsEnabled($iWebView[, $bEnabled = True])
; Parameters ....: $iWebView - WebView instance ID.
;                  $bEnabled - Whether to enable the setting. Default: True.
; Return values .: Boolean result from __WebView2_Setting_PutBool.
;                  Direct Return does not preserve that helper's @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_SetDefaultScriptDialogsEnabled($iWebView, $bEnabled = True)
	Local $__WebView2DirectResult = __WebView2_Setting_PutBool($iWebView, "put_AreDefaultScriptDialogsEnabled", $bEnabled)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_SetDefaultScriptDialogsEnabled

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetStatusBarEnabled
; Description ...: Enables or disables the status bar.
; Syntax ........: _WebView2_SetStatusBarEnabled($iWebView[, $bEnabled = True])
; Parameters ....: $iWebView - WebView instance ID.
;                  $bEnabled - Whether to enable the setting. Default: True.
; Return values .: Boolean result from __WebView2_Setting_PutBool.
;                  Direct Return does not preserve that helper's @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_SetStatusBarEnabled($iWebView, $bEnabled = True)
	Local $__WebView2DirectResult = __WebView2_Setting_PutBool($iWebView, "put_IsStatusBarEnabled", $bEnabled)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_SetStatusBarEnabled

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetDevToolsEnabled
; Description ...: Enables or disables developer tools.
; Syntax ........: _WebView2_SetDevToolsEnabled($iWebView[, $bEnabled = True])
; Parameters ....: $iWebView - WebView instance ID.
;                  $bEnabled - Whether to enable the setting. Default: True.
; Return values .: Boolean result from __WebView2_Setting_PutBool.
;                  Direct Return does not preserve that helper's @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_SetDevToolsEnabled($iWebView, $bEnabled = True)
	Local $__WebView2DirectResult = __WebView2_Setting_PutBool($iWebView, "put_AreDevToolsEnabled", $bEnabled)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_SetDevToolsEnabled

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetDefaultContextMenusEnabled
; Description ...: Enables or disables default WebView2 context menus.
; Syntax ........: _WebView2_SetDefaultContextMenusEnabled($iWebView[, $bEnabled = True])
; Parameters ....: $iWebView - WebView instance ID.
;                  $bEnabled - Whether to enable the setting. Default: True.
; Return values .: Boolean result from __WebView2_Setting_PutBool.
;                  Direct Return does not preserve that helper's @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_SetDefaultContextMenusEnabled($iWebView, $bEnabled = True)
	Local $__WebView2DirectResult = __WebView2_Setting_PutBool($iWebView, "put_AreDefaultContextMenusEnabled", $bEnabled)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_SetDefaultContextMenusEnabled

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetHostObjectsAllowed
; Description ...: Enables or disables host object access.
; Syntax ........: _WebView2_SetHostObjectsAllowed($iWebView[, $bEnabled = True])
; Parameters ....: $iWebView - WebView instance ID.
;                  $bEnabled - Whether to enable the setting. Default: True.
; Return values .: Boolean result from __WebView2_Setting_PutBool.
;                  Direct Return does not preserve that helper's @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_SetHostObjectsAllowed($iWebView, $bEnabled = True)
	Local $__WebView2DirectResult = __WebView2_Setting_PutBool($iWebView, "put_AreHostObjectsAllowed", $bEnabled)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_SetHostObjectsAllowed

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetZoomControlEnabled
; Description ...: Enables or disables zoom controls.
; Syntax ........: _WebView2_SetZoomControlEnabled($iWebView[, $bEnabled = True])
; Parameters ....: $iWebView - WebView instance ID.
;                  $bEnabled - Whether to enable the setting. Default: True.
; Return values .: Boolean result from __WebView2_Setting_PutBool.
;                  Direct Return does not preserve that helper's @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_SetZoomControlEnabled($iWebView, $bEnabled = True)
	Local $__WebView2DirectResult = __WebView2_Setting_PutBool($iWebView, "put_IsZoomControlEnabled", $bEnabled)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_SetZoomControlEnabled

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetBuiltInErrorPageEnabled
; Description ...: Enables or disables the built-in error page.
; Syntax ........: _WebView2_SetBuiltInErrorPageEnabled($iWebView[, $bEnabled = True])
; Parameters ....: $iWebView - WebView instance ID.
;                  $bEnabled - Whether to enable the setting. Default: True.
; Return values .: Boolean result from __WebView2_Setting_PutBool.
;                  Direct Return does not preserve that helper's @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_SetBuiltInErrorPageEnabled($iWebView, $bEnabled = True)
	Local $__WebView2DirectResult = __WebView2_Setting_PutBool($iWebView, "put_IsBuiltInErrorPageEnabled", $bEnabled)
	Local $__WebView2DirectError = @error, $__WebView2DirectExtended = @extended
	Return SetError($__WebView2DirectError, $__WebView2DirectExtended, $__WebView2DirectResult)
EndFunc   ;==>_WebView2_SetBuiltInErrorPageEnabled

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_LockWebView
; Description ...: Applies a conservative kiosk-style set of WebView2 settings.
; Syntax ........: _WebView2_LockWebView($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - True; On Failure - False and @error/@extended set.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Disables context menus, DevTools, script dialogs and user zoom controls. It does not disable JavaScript.
; Related .......: _WebView2_UnlockWebView
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_LockWebView($iWebView)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_LockWebView"
	Local $sMessage = ''
	Do
		If Not _WebView2_SetDefaultContextMenusEnabled($iWebView, False) Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not _WebView2_SetDevToolsEnabled($iWebView, False) Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not _WebView2_SetDefaultScriptDialogsEnabled($iWebView, False) Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not _WebView2_SetZoomControlEnabled($iWebView, False) Then
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
EndFunc   ;==>_WebView2_LockWebView

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_UnlockWebView
; Description ...: Re-enables settings changed by _WebView2_LockWebView.
; Syntax ........: _WebView2_UnlockWebView($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: On Success - True; On Failure - False and @error/@extended set.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Restores standard defaults for the settings controlled by _WebView2_LockWebView.
; Related .......: _WebView2_LockWebView
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_UnlockWebView($iWebView)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "_WebView2_UnlockWebView"
	Local $sMessage = ''
	Do
		If Not _WebView2_SetDefaultContextMenusEnabled($iWebView, True) Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not _WebView2_SetDevToolsEnabled($iWebView, True) Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not _WebView2_SetDefaultScriptDialogsEnabled($iWebView, True) Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not _WebView2_SetZoomControlEnabled($iWebView, True) Then
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
EndFunc   ;==>_WebView2_UnlockWebView

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Error_GetDescription
; Description ...: Returns the last UDF-level diagnostic text.
; Syntax ........: _WebView2_Error_GetDescription()
; Parameters ....: None.
; Return values .: Diagnostic string.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Complements @error and @extended.
; Related .......: _WebView2_Error_GetCode, _WebView2_Error_GetExtended
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_Error_GetDescription()
	Return $__g_sWebView2_LastError
EndFunc   ;==>_WebView2_Error_GetDescription

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Error_GetCode
; Description ...: Returns the last stored UDF error code.
; Syntax ........: _WebView2_Error_GetCode()
; Parameters ....: None.
; Return values .: $WEBVIEW2_ERR_* value.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Diagnostic helper.
; Related .......: _WebView2_Error_GetDescription, _WebView2_Error_GetExtended
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_Error_GetCode()
	Return $__g_iWebView2_LastError
EndFunc   ;==>_WebView2_Error_GetCode

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Error_GetExtended
; Description ...: Returns the last stored extended error value, usually an HRESULT.
; Syntax ........: _WebView2_Error_GetExtended()
; Parameters ....: None.
; Return values .: Extended error value.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Diagnostic helper.
; Related .......: _WebView2_Error_GetDescription, _WebView2_Error_GetCode
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_Error_GetExtended()
	Return $__g_iWebView2_LastExtended
EndFunc   ;==>_WebView2_Error_GetExtended

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Callbacks_Create
; Description ...: Creates callback objects used by the WebView2 host.
; Syntax ........: __WebView2_Callbacks_Create()
; Parameters ....: None.
; Return values .: True if every callback object was created; otherwise False.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Callbacks_Create()
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_Callbacks_Create"
	Local $sMessage = ''
	Do
		If Not __WebView2_Callback_Create($__WEBVIEW2_CB_ENVIRONMENT, __WebView2_EnvironmentCompleted_Invoke, "ptr;long;ptr") Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not __WebView2_Callback_Create($__WEBVIEW2_CB_CONTROLLER, __WebView2_ControllerCompleted_Invoke, "ptr;long;ptr") Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not __WebView2_Callback_Create($__WEBVIEW2_CB_NAVIGATION_STARTING, __WebView2_NavigationStarting_Invoke, "ptr;ptr;ptr") Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not __WebView2_Callback_Create($__WEBVIEW2_CB_NAVIGATION_COMPLETED, __WebView2_NavigationCompleted_Invoke, "ptr;ptr;ptr") Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not __WebView2_Callback_Create($__WEBVIEW2_CB_DOCUMENT_TITLE_CHANGED, __WebView2_DocumentTitleChanged_Invoke, "ptr;ptr;ptr") Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not __WebView2_Callback_Create($__WEBVIEW2_CB_WEB_MESSAGE_RECEIVED, __WebView2_WebMessageReceived_Invoke, "ptr;ptr;ptr") Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not __WebView2_Callback_Create($__WEBVIEW2_CB_NEW_WINDOW_REQUESTED, __WebView2_NewWindowRequested_Invoke, "ptr;ptr;ptr") Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not __WebView2_Callback_Create($__WEBVIEW2_CB_DOCUMENT_PLAYING_AUDIO_CHANGED, __WebView2_DocumentPlayingAudioChanged_Invoke, "ptr;ptr;ptr") Then
			$__WebView2ExitValue = False
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		If Not __WebView2_Callback_Create($__WEBVIEW2_CB_EXECUTE_SCRIPT, __WebView2_ExecuteScriptCompleted_Invoke, "ptr;long;wstr") Then
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
EndFunc   ;==>__WebView2_Callbacks_Create

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_EnvironmentCompleted_Invoke
; Description ...: Receives the environment creation callback.
; Syntax ........: __WebView2_EnvironmentCompleted_Invoke($pSelf, $iErrorCode, $pEnvironment)
; Parameters ....: $pSelf - Callback object's COM pointer.
;                  $iErrorCode - Completion HRESULT supplied by WebView2.
;                  $pEnvironment - Created environment COM pointer.
; Return values .: WebView2 success HRESULT after recording the callback result.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_EnvironmentCompleted_Invoke($pSelf, $iErrorCode, $pEnvironment)
	#forceref $pSelf
	$__g_iWebView2_EnvironmentHRESULT = $iErrorCode

	If $iErrorCode = $WEBVIEW2_S_OK And $pEnvironment Then
		$__g_oWebView2_Environment = ObjCreateInterface($pEnvironment, $WEBVIEW2_IID_ICoreWebView2Environment, $WEBVIEW2_DTAG_ICoreWebView2Environment)
		If IsObj($__g_oWebView2_Environment) Then
			; The callback argument is borrowed. Keep one COM reference for the shared environment lifetime.
			$__g_oWebView2_Environment.AddRef()
		Else
			$__g_iWebView2_EnvironmentHRESULT = $WEBVIEW2_E_NOINTERFACE
		EndIf
	EndIf

	$__g_bWebView2_EnvironmentDone = True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_EnvironmentCompleted_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_ControllerCompleted_Invoke
; Description ...: Receives the controller creation callback.
; Syntax ........: __WebView2_ControllerCompleted_Invoke($pSelf, $iErrorCode, $pController)
; Parameters ....: $pSelf - Callback object's COM pointer.
;                  $iErrorCode - Completion HRESULT supplied by WebView2.
;                  $pController - Created controller COM pointer.
; Return values .: WebView2 success HRESULT after recording the callback result.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ControllerCompleted_Invoke($pSelf, $iErrorCode, $pController)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_ControllerCompleted_Invoke"
	Local $sMessage = ''
	Do
		#forceref $pSelf
		Local $iSlot = $__g_iWebView2_PendingCreateSlot
		$__g_iWebView2_CreateHRESULT = $iErrorCode
		__WebView2_Trace("CREATE 03 Controller callback ENTER slot=" & $iSlot & " hr=" & __WebView2_HRESULT_Format($iErrorCode) & " ptr=" & $pController)

		If $iSlot < 0 Or $iSlot >= $WEBVIEW2_MAX_INSTANCES Then
			$__g_iWebView2_CreateHRESULT = $WEBVIEW2_E_POINTER
			$__g_bWebView2_CreateDone = True
			__WebView2_Trace("CREATE ERROR invalid pending slot")
			$__WebView2ExitValue = $WEBVIEW2_S_OK
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		If $iErrorCode = $WEBVIEW2_S_OK And $pController Then
			__WebView2_Trace("CREATE 04 Controller ObjCreateInterface START")
			Local $oController = ObjCreateInterface($pController, $WEBVIEW2_IID_ICoreWebView2Controller, $WEBVIEW2_DTAG_ICoreWebView2Controller)
			If Not IsObj($oController) Then
				$__g_iWebView2_CreateHRESULT = $WEBVIEW2_E_NOINTERFACE
				$__g_bWebView2_CreateDone = True
				__WebView2_Trace("CREATE ERROR Controller ObjCreateInterface failed")
				$__WebView2ExitValue = $WEBVIEW2_S_OK
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			EndIf
			__WebView2_Trace("CREATE 05 Controller ObjCreateInterface OK")

			$oController.AddRef()
			__WebView2_Trace("CREATE 06 Controller AddRef OK")
			$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CONTROLLER] = $oController

			Local $pCore = 0
			__WebView2_Trace("CREATE 07 get_CoreWebView2 START")
			Local $iResult = $oController.get_CoreWebView2($pCore)
			__WebView2_Trace("CREATE 08 get_CoreWebView2 RETURN hr=" & __WebView2_HRESULT_Format($iResult) & " ptr=" & $pCore & " autoit_error=" & @error)
			If @error Or $iResult <> $WEBVIEW2_S_OK Or Not $pCore Then
				$__g_iWebView2_CreateHRESULT = $iResult
				$__g_bWebView2_CreateDone = True
				$__WebView2ExitValue = $WEBVIEW2_S_OK
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			EndIf

			__WebView2_Trace("CREATE 09 Core ObjCreateInterface START")
			Local $oCore = ObjCreateInterface($pCore, $WEBVIEW2_IID_ICoreWebView2, $WEBVIEW2_DTAG_ICoreWebView2)
			If Not IsObj($oCore) Then
				$__g_iWebView2_CreateHRESULT = $WEBVIEW2_E_NOINTERFACE
				$__g_bWebView2_CreateDone = True
				__WebView2_Trace("CREATE ERROR Core ObjCreateInterface failed")
				$__WebView2ExitValue = $WEBVIEW2_S_OK
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			EndIf
			__WebView2_Trace("CREATE 10 Core ObjCreateInterface OK")

			; The callback-returned Core pointer is borrowed. Keep one COM reference for the instance lifetime.
			$oCore.AddRef()
			__WebView2_Trace("CREATE 11 Core AddRef OK")
			$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CORE] = $oCore
			$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CORE_POINTER] = $pCore

			__WebView2_Trace("CREATE 12 Events subscribe START")
			If Not __WebView2_Events_Subscribe($iSlot) Then
				$__g_iWebView2_CreateHRESULT = @extended
				$__g_bWebView2_CreateDone = True
				__WebView2_Trace("CREATE ERROR Events subscribe failed ext=" & @extended)
				$__WebView2ExitValue = $WEBVIEW2_S_OK
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			EndIf
			__WebView2_Trace("CREATE 13 Events subscribe OK")

			__WebView2_Trace("CREATE 14 put_Bounds START")
			_WebView2_SetBounds($iSlot, _
					$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_LEFT], _
					$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOP], _
					$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_WIDTH], _
					$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_HEIGHT])
			If @error Then
				$__g_iWebView2_CreateHRESULT = _WebView2_Error_GetExtended()
				__WebView2_Trace("CREATE ERROR put_Bounds failed ext=" & $__g_iWebView2_CreateHRESULT)
			Else
				__WebView2_Trace("CREATE 15 put_Bounds OK")
			EndIf
		EndIf

		$__g_bWebView2_CreateDone = True
		__WebView2_Trace("CREATE 16 Controller callback LEAVE hr=" & __WebView2_HRESULT_Format($__g_iWebView2_CreateHRESULT))
		$__WebView2ExitValue = $WEBVIEW2_S_OK
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_ControllerCompleted_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_NavigationStarting_Invoke
; Description ...: Receives the navigation-start callback.
; Syntax ........: __WebView2_NavigationStarting_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: $pSelf - Callback object's COM pointer.
;                  $pSender - Event sender COM pointer.
;                  $pArgs - Event argument COM pointer.
; Return values .: WebView2 success HRESULT after processing the event.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_NavigationStarting_Invoke($pSelf, $pSender, $pArgs)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_NavigationStarting_Invoke"
	Local $sMessage = ''
	Do
		#forceref $pSelf
		__WebView2_Trace("NAV_START 01 ENTER sender=" & $pSender & " args=" & $pArgs)
		Local $iSlot = __WebView2_Instance_FindByCorePointer($pSender)
		If $iSlot < 0 Or Not $pArgs Then
			__WebView2_Trace("NAV_START ERROR invalid slot/args slot=" & $iSlot)
			$__WebView2ExitValue = $WEBVIEW2_S_OK
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		__WebView2_Trace("NAV_START 02 ObjCreateInterface START")
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2NavigationStartingEventArgs, $WEBVIEW2_DTAG_ICoreWebView2NavigationStartingEventArgs)
		If Not IsObj($oArgs) Then
			__WebView2_Trace("NAV_START ERROR ObjCreateInterface failed")
			$__WebView2ExitValue = $WEBVIEW2_S_OK
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		__WebView2_Trace("NAV_START 03 ObjCreateInterface OK")

		; EventArgs pointers are borrowed for callback duration. Keep a temporary COM reference
		; so destruction of the local AutoIt wrapper cannot release WebView2's borrowed reference.
		$oArgs.AddRef()
		__WebView2_Trace("NAV_START 04 AddRef OK")

		Local $pURI = 0, $bUserInitiated = False, $bRedirected = False
		__WebView2_Trace("NAV_START 05 get_Uri START")
		$oArgs.get_Uri($pURI)
		__WebView2_Trace("NAV_START 06 get_Uri OK ptr=" & $pURI)
		$oArgs.get_IsUserInitiated($bUserInitiated)
		$oArgs.get_IsRedirected($bRedirected)
		Local $sURI = __WebView2_CoTaskMemString_ReadAndFree($pURI)

		Local $fnCallback = $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CB_NAV_START]
		If IsFunc($fnCallback) Then
			__WebView2_Trace("NAV_START 07 USER CALLBACK ENTER")
			Local $vCancel = Call($fnCallback, $iSlot, $sURI, $bUserInitiated, $bRedirected)
			Local $iCallbackError = @error
			__WebView2_Trace("NAV_START 08 USER CALLBACK LEAVE error=" & $iCallbackError & " cancel=" & $vCancel)
			If Not $iCallbackError And $vCancel Then $oArgs.put_Cancel(True)
		EndIf

		__WebView2_Trace("NAV_START 09 LEAVE")
		$__WebView2ExitValue = $WEBVIEW2_S_OK
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_NavigationStarting_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_NewWindowRequested_Invoke
; Description ...: Forwards a native new-window request to the optional host callback.
; Syntax ........: __WebView2_NewWindowRequested_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: $pSelf - Callback object's COM pointer.
;                  $pSender - Event sender COM pointer.
;                  $pArgs - Event argument COM pointer.
; Return values .: S_OK; the host callback return value controls the Handled flag.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Do not create a WebView2 controller inside this COM callback; queue host work instead.
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_NewWindowRequested_Invoke($pSelf, $pSender, $pArgs)
	Local Const $sFuncName = "__WebView2_NewWindowRequested_Invoke"
	Local $sMessage = ''
	Local $iResult = $WEBVIEW2_S_OK
	#forceref $pSelf, $sFuncName, $sMessage
	Do
		Local $iSlot = __WebView2_Instance_FindByCorePointer($pSender)
		If $iSlot < 0 Or Not $pArgs Then ExitLoop
		Local $fnCallback = $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CB_NEW_WINDOW]
		If Not IsFunc($fnCallback) Then ExitLoop
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2NewWindowRequestedEventArgs, $WEBVIEW2_DTAG_ICoreWebView2NewWindowRequestedEventArgs)
		If Not IsObj($oArgs) Then ExitLoop
		$oArgs.AddRef()
		Local $pURI = 0, $bUserInitiated = False
		Local $iHRESULT = $oArgs.get_Uri($pURI)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop
		Local $sURI = __WebView2_CoTaskMemString_ReadAndFree($pURI)
		$iHRESULT = $oArgs.get_IsUserInitiated($bUserInitiated)
		If @error Or $iHRESULT <> $WEBVIEW2_S_OK Then ExitLoop
		Local $vHandled = Call($fnCallback, $iSlot, $sURI, $bUserInitiated)
		Local $iCallbackError = @error
		If Not $iCallbackError And $vHandled Then $oArgs.put_Handled(True)
	Until True
	Return $iResult
EndFunc   ;==>__WebView2_NewWindowRequested_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_NavigationCompleted_Invoke
; Description ...: Receives the navigation-complete callback.
; Syntax ........: __WebView2_NavigationCompleted_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: $pSelf - Callback object's COM pointer.
;                  $pSender - Event sender COM pointer.
;                  $pArgs - Event argument COM pointer.
; Return values .: WebView2 success HRESULT after processing the event.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_NavigationCompleted_Invoke($pSelf, $pSender, $pArgs)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_NavigationCompleted_Invoke"
	Local $sMessage = ''
	Do
		#forceref $pSelf
		__WebView2_Trace("NAV_COMPLETE 01 ENTER sender=" & $pSender & " args=" & $pArgs)
		Local $iSlot = __WebView2_Instance_FindByCorePointer($pSender)
		If $iSlot < 0 Or Not $pArgs Then
			__WebView2_Trace("NAV_COMPLETE ERROR invalid slot/args slot=" & $iSlot)
			$__WebView2ExitValue = $WEBVIEW2_S_OK
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		__WebView2_Trace("NAV_COMPLETE 02 ObjCreateInterface START")
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2NavigationCompletedEventArgs, $WEBVIEW2_DTAG_ICoreWebView2NavigationCompletedEventArgs)
		If Not IsObj($oArgs) Then
			__WebView2_Trace("NAV_COMPLETE ERROR ObjCreateInterface failed")
			$__WebView2ExitValue = $WEBVIEW2_S_OK
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		__WebView2_Trace("NAV_COMPLETE 03 ObjCreateInterface OK")
		$oArgs.AddRef()
		__WebView2_Trace("NAV_COMPLETE 04 AddRef OK")

		Local $bSuccess = False, $iWebErrorStatus = 0, $iNavigationId = 0
		__WebView2_Trace("NAV_COMPLETE 05 get_IsSuccess START")
		$oArgs.get_IsSuccess($bSuccess)
		__WebView2_Trace("NAV_COMPLETE 06 get_IsSuccess OK value=" & $bSuccess)
		__WebView2_Trace("NAV_COMPLETE 07 get_WebErrorStatus START")
		$oArgs.get_WebErrorStatus($iWebErrorStatus)
		__WebView2_Trace("NAV_COMPLETE 08 get_WebErrorStatus OK value=" & $iWebErrorStatus)
		$oArgs.get_NavigationId($iNavigationId)

		Local $fnCallback = $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CB_NAV_COMPLETE]
		If IsFunc($fnCallback) Then
			__WebView2_Trace("NAV_COMPLETE 09 USER CALLBACK ENTER")
			Call($fnCallback, $iSlot, $bSuccess, $iWebErrorStatus, $iNavigationId)
			__WebView2_Trace("NAV_COMPLETE 10 USER CALLBACK LEAVE error=" & @error)
		EndIf
		__WebView2_Trace("NAV_COMPLETE 11 LEAVE")
		$__WebView2ExitValue = $WEBVIEW2_S_OK
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_NavigationCompleted_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_DocumentTitleChanged_Invoke
; Description ...: Receives the document-title callback.
; Syntax ........: __WebView2_DocumentTitleChanged_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: $pSelf - Callback object's COM pointer.
;                  $pSender - Event sender COM pointer.
;                  $pArgs - Event argument COM pointer.
; Return values .: WebView2 success HRESULT after processing the event.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_DocumentTitleChanged_Invoke($pSelf, $pSender, $pArgs)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_DocumentTitleChanged_Invoke"
	Local $sMessage = ''
	Do
		#forceref $pSelf, $pArgs
		Local $iSlot = __WebView2_Instance_FindByCorePointer($pSender)
		If $iSlot < 0 Then
			$__WebView2ExitValue = $WEBVIEW2_S_OK
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $pTitle = 0
		Local $oCore = $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CORE]
		$oCore.get_DocumentTitle($pTitle)
		Local $sTitle = __WebView2_CoTaskMemString_ReadAndFree($pTitle)

		Local $fnCallback = $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CB_TITLE]
		If IsFunc($fnCallback) Then Call($fnCallback, $iSlot, $sTitle)
		$__WebView2ExitValue = $WEBVIEW2_S_OK
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_DocumentTitleChanged_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_DocumentPlayingAudioChanged_Invoke
; Description ...: Dispatches the native audio-state event to an AutoIt callback.
; Syntax ........: __WebView2_DocumentPlayingAudioChanged_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: $pSelf - Callback COM pointer.
;                  $pSender - CoreWebView2 COM pointer.
;                  $pArgs - Unused event argument pointer.
; Return values .: S_OK.
; Author ........: mLipok
; Modified ......:
; Remarks .......: User callback receives ($iWebView, $bIsPlaying).
; Related .......: _WebView2_SetCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_DocumentPlayingAudioChanged_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf, $pArgs
	Local $iSlot = __WebView2_Instance_FindByCorePointer($pSender)
	If $iSlot >= 0 Then
		Local $bPlaying = _WebView2_GetIsDocumentPlayingAudio($iSlot)
		Local $iError = @error
		Local $fnCallback = $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CB_AUDIO]
		If Not $iError And IsFunc($fnCallback) Then Call($fnCallback, $iSlot, $bPlaying)
	EndIf
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_DocumentPlayingAudioChanged_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_WebMessageReceived_Invoke
; Description ...: Receives a web-message callback.
; Syntax ........: __WebView2_WebMessageReceived_Invoke($pSelf, $pSender, $pArgs)
; Parameters ....: $pSelf - Callback object's COM pointer.
;                  $pSender - Event sender COM pointer.
;                  $pArgs - Event argument COM pointer.
; Return values .: WebView2 success HRESULT after processing the event.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_WebMessageReceived_Invoke($pSelf, $pSender, $pArgs)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_WebMessageReceived_Invoke"
	Local $sDiagnosticMessage = ''
	Do
		#forceref $pSelf
		__WebView2_Trace("WEB_MESSAGE 01 ENTER sender=" & $pSender & " args=" & $pArgs)
		Local $iSlot = __WebView2_Instance_FindByCorePointer($pSender)
		If $iSlot < 0 Or Not $pArgs Then
			__WebView2_Trace("WEB_MESSAGE ERROR invalid slot/args slot=" & $iSlot)
			$__WebView2ExitValue = $WEBVIEW2_S_OK
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		__WebView2_Trace("WEB_MESSAGE 02 ObjCreateInterface START")
		Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2WebMessageReceivedEventArgs, $WEBVIEW2_DTAG_ICoreWebView2WebMessageReceivedEventArgs)
		If Not IsObj($oArgs) Then
			__WebView2_Trace("WEB_MESSAGE ERROR ObjCreateInterface failed")
			$__WebView2ExitValue = $WEBVIEW2_S_OK
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		__WebView2_Trace("WEB_MESSAGE 03 ObjCreateInterface OK")
		$oArgs.AddRef()
		__WebView2_Trace("WEB_MESSAGE 04 AddRef OK")

		Local $pSource = 0, $pMessage = 0, $bJSON = False
		$oArgs.get_Source($pSource)
		Local $sSource = __WebView2_CoTaskMemString_ReadAndFree($pSource)

		__WebView2_Trace("WEB_MESSAGE 05 TryGetWebMessageAsString START")
		Local $iResult = $oArgs.TryGetWebMessageAsString($pMessage)
		Local $iTryError = @error
		__WebView2_Trace("WEB_MESSAGE 06 TryGetWebMessageAsString RETURN hr=" & __WebView2_HRESULT_Format($iResult) & " autoit_error=" & $iTryError)
		Local $sMessage
		If Not $iTryError And $iResult = $WEBVIEW2_S_OK Then
			$sMessage = __WebView2_CoTaskMemString_ReadAndFree($pMessage)
		Else
			$pMessage = 0
			$oArgs.get_WebMessageAsJson($pMessage)
			$sMessage = __WebView2_CoTaskMemString_ReadAndFree($pMessage)
			$bJSON = True
		EndIf

		Local $fnCallback = $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CB_MESSAGE]
		If IsFunc($fnCallback) Then
			__WebView2_Trace("WEB_MESSAGE 07 USER CALLBACK ENTER")
			Call($fnCallback, $iSlot, $sMessage, $sSource, $bJSON)
			__WebView2_Trace("WEB_MESSAGE 08 USER CALLBACK LEAVE error=" & @error)
		EndIf
		__WebView2_Trace("WEB_MESSAGE 09 LEAVE")
		$__WebView2ExitValue = $WEBVIEW2_S_OK
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sDiagnosticMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_WebMessageReceived_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_ExecuteScriptCompleted_Invoke
; Description ...: Receives an asynchronous script result.
; Syntax ........: __WebView2_ExecuteScriptCompleted_Invoke($pSelf, $iErrorCode, $sResult)
; Parameters ....: $pSelf - Callback object's COM pointer.
;                  $iErrorCode - Completion HRESULT supplied by WebView2.
;                  $sResult - JavaScript or JSON result text.
; Return values .: WebView2 success HRESULT after recording the script result.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ExecuteScriptCompleted_Invoke($pSelf, $iErrorCode, $sResult)
	#forceref $pSelf
	$__g_iWebView2_ScriptHRESULT = $iErrorCode
	$__g_sWebView2_ScriptResult = $sResult
	$__g_bWebView2_ScriptDone = True
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_ExecuteScriptCompleted_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Events_Subscribe
; Description ...: Subscribes the WebView instance to native events.
; Syntax ........: __WebView2_Events_Subscribe($iSlot)
; Parameters ....: $iSlot - Internal WebView instance slot.
; Return values .: True if all event subscriptions succeed; otherwise False and sets @error.
;                  @error $WEBVIEW2_ERR_HRESULT - Native WebView2 method failed.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Events_Subscribe($iSlot)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_Events_Subscribe"
	Local $sMessage = ''
	Do
		Local $oCore = $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CORE]
		Local $tToken, $iResult

		$tToken = DllStructCreate("int64")
		$iResult = $oCore.add_NavigationStarting(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_NAVIGATION_STARTING), $tToken)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOKEN_NAV_START] = DllStructGetData($tToken, 1)

		$tToken = DllStructCreate("int64")
		$iResult = $oCore.add_NavigationCompleted(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_NAVIGATION_COMPLETED), $tToken)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			__WebView2_Events_Unsubscribe($iSlot)
			$__WebView2ExitValue = SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOKEN_NAV_COMPLETE] = DllStructGetData($tToken, 1)

		$tToken = DllStructCreate("int64")
		$iResult = $oCore.add_DocumentTitleChanged(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_DOCUMENT_TITLE_CHANGED), $tToken)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			__WebView2_Events_Unsubscribe($iSlot)
			$__WebView2ExitValue = SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOKEN_TITLE] = DllStructGetData($tToken, 1)

		$tToken = DllStructCreate("int64")
		$iResult = $oCore.add_WebMessageReceived(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_WEB_MESSAGE_RECEIVED), $tToken)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			__WebView2_Events_Unsubscribe($iSlot)
			$__WebView2ExitValue = SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOKEN_MESSAGE] = DllStructGetData($tToken, 1)

		$tToken = DllStructCreate("int64")
		$iResult = $oCore.add_NewWindowRequested(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_NEW_WINDOW_REQUESTED), $tToken)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			__WebView2_Events_Unsubscribe($iSlot)
			$__WebView2ExitValue = SetError($WEBVIEW2_ERR_HRESULT, $iResult, False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOKEN_NEW_WINDOW] = DllStructGetData($tToken, 1)

		$__WebView2ExitValue = True
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_Events_Subscribe

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Events_Unsubscribe
; Description ...: Removes native event subscriptions for the instance.
; Syntax ........: __WebView2_Events_Unsubscribe($iSlot)
; Parameters ....: $iSlot - Internal WebView instance slot.
; Return values .: No value.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Events_Unsubscribe($iSlot)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_Events_Unsubscribe"
	Local $sMessage = ''
	Do
		If $iSlot < 0 Or $iSlot >= $WEBVIEW2_MAX_INSTANCES Then
			$__WebView2ExitValue = 0
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $oCore = $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CORE]
		If Not IsObj($oCore) Then
			$__WebView2ExitValue = 0
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $iToken = $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOKEN_NAV_START]
		If $iToken Then
			$oCore.remove_NavigationStarting($iToken)
			$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOKEN_NAV_START] = 0
		EndIf

		$iToken = $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOKEN_NAV_COMPLETE]
		If $iToken Then
			$oCore.remove_NavigationCompleted($iToken)
			$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOKEN_NAV_COMPLETE] = 0
		EndIf

		$iToken = $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOKEN_TITLE]
		If $iToken Then
			$oCore.remove_DocumentTitleChanged($iToken)
			$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOKEN_TITLE] = 0
		EndIf

		$iToken = $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOKEN_MESSAGE]
		If $iToken Then
			$oCore.remove_WebMessageReceived($iToken)
			$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOKEN_MESSAGE] = 0
		EndIf

		$iToken = $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOKEN_NEW_WINDOW]
		If $iToken Then
			$oCore.remove_NewWindowRequested($iToken)
			$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOKEN_NEW_WINDOW] = 0
		EndIf

		$iToken = $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOKEN_AUDIO]
		If $iToken Then
			Local $oCore8 = $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CORE8]
			If IsObj($oCore8) Then $oCore8.remove_IsDocumentPlayingAudioChanged($iToken)
			$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_TOKEN_AUDIO] = 0
			$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CORE8] = Null
		EndIf
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_Events_Unsubscribe

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Instance_Dispose
; Description ...: Releases native objects for a WebView instance.
; Syntax ........: __WebView2_Instance_Dispose($iSlot)
; Parameters ....: $iSlot - Internal WebView instance slot.
; Return values .: No value.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Instance_Dispose($iSlot)
	If $iSlot < 0 Or $iSlot >= $WEBVIEW2_MAX_INSTANCES Then Return

	__WebView2_Trace("DISPOSE 01 START slot=" & $iSlot)

	__WebView2_Trace("DISPOSE 02 Events unsubscribe START slot=" & $iSlot)
	__WebView2_Events_Unsubscribe($iSlot)
	__WebView2_Trace("DISPOSE 03 Events unsubscribe OK slot=" & $iSlot)

	Local $oController = $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CONTROLLER]
	If IsObj($oController) Then
		__WebView2_Trace("DISPOSE 04 Controller.Close START slot=" & $iSlot)
		$oController.Close()
		__WebView2_Trace("DISPOSE 05 Controller.Close OK slot=" & $iSlot)
	EndIf

	; The persistent ObjCreateInterface() wrappers own the retained AddRef() references.
	; Clearing the wrapper lets AutoIt issue the matching Release() exactly once.
	__WebView2_Trace("DISPOSE 06 Core wrapper CLEAR START slot=" & $iSlot)
	$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CORE] = Null
	$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CORE_POINTER] = 0
	__WebView2_Trace("DISPOSE 07 Core wrapper CLEARED slot=" & $iSlot)

	__WebView2_Trace("DISPOSE 08 Controller wrapper CLEAR START slot=" & $iSlot)
	$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CONTROLLER] = Null
	$oController = Null
	__WebView2_Trace("DISPOSE 09 Controller wrapper CLEARED slot=" & $iSlot)

	__WebView2_Instance_Reset($iSlot)
	__WebView2_Trace("DISPOSE 10 FINISHED slot=" & $iSlot)
EndFunc   ;==>__WebView2_Instance_Dispose

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Instance_Allocate
; Description ...: Allocates an unused WebView instance slot.
; Syntax ........: __WebView2_Instance_Allocate()
; Parameters ....: None.
; Return values .: Available instance slot, or the helper's failure sentinel.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Instance_Allocate()
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_Instance_Allocate"
	Local $sMessage = ''
	Do
		For $i = 0 To $WEBVIEW2_MAX_INSTANCES - 1
			If Not $__g_aWebView2_Instances[$i][$__WEBVIEW2_INSTANCE_USED] Then
				$__g_aWebView2_Instances[$i][$__WEBVIEW2_INSTANCE_USED] = True
				$__WebView2ExitValue = $i
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 2
			EndIf
		Next
		$__WebView2ExitValue = -1
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_Instance_Allocate

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Instance_Reset
; Description ...: Clears the state of a WebView instance slot.
; Syntax ........: __WebView2_Instance_Reset($iSlot)
; Parameters ....: $iSlot - Internal WebView instance slot.
; Return values .: No value.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Instance_Reset($iSlot)
	If $iSlot < 0 Or $iSlot >= $WEBVIEW2_MAX_INSTANCES Then Return
	For $i = 0 To $__WEBVIEW2_INSTANCE_FIELDS - 1
		$__g_aWebView2_Instances[$iSlot][$i] = Null
	Next
	$__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_USED] = False
	$__g_aWebView2_Tabs[$iSlot] = False
EndFunc   ;==>__WebView2_Instance_Reset

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Instance_IsValid
; Description ...: Checks whether an instance slot is active.
; Syntax ........: __WebView2_Instance_IsValid($iSlot)
; Parameters ....: $iSlot - Internal WebView instance slot.
; Return values .: True for a valid instance; otherwise False.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Instance_IsValid($iSlot)
	Return IsInt($iSlot) And $iSlot >= 0 And $iSlot < $WEBVIEW2_MAX_INSTANCES And $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_USED] And IsObj($__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_CORE])
EndFunc   ;==>__WebView2_Instance_IsValid

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Instance_FindByCorePointer
; Description ...: Finds an instance slot by its core COM pointer.
; Syntax ........: __WebView2_Instance_FindByCorePointer($pCore)
; Parameters ....: $pCore - Core WebView2 COM pointer.
; Return values .: Matching slot, or the helper's not-found sentinel.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Instance_FindByCorePointer($pCore)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_Instance_FindByCorePointer"
	Local $sMessage = ''
	Do
		For $i = 0 To $WEBVIEW2_MAX_INSTANCES - 1
			If $__g_aWebView2_Instances[$i][$__WEBVIEW2_INSTANCE_USED] And $__g_aWebView2_Instances[$i][$__WEBVIEW2_INSTANCE_CORE_POINTER] = $pCore Then
				$__WebView2ExitValue = $i
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 2
			EndIf
		Next
		$__WebView2ExitValue = -1
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_Instance_FindByCorePointer

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Trace
; Description ...: Writes a diagnostic message when tracing is enabled.
; Syntax ........: __WebView2_Trace($sMessage)
; Parameters ....: $sMessage - Diagnostic text.
; Return values .: No value.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Trace($sMessage)
	If $__g_bWebView2_Trace Then __WebView2_ConsoleWrite($sMessage, $WEBVIEW2_DEBUG_FULL)
	Return
EndFunc   ;==>__WebView2_Trace

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_HRESULT_Failed
; Description ...: Checks whether an HRESULT indicates failure.
; Syntax ........: __WebView2_HRESULT_Failed($iHRESULT)
; Parameters ....: $iHRESULT - HRESULT to examine.
; Return values .: True for a failed HRESULT; otherwise False.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_HRESULT_Failed($iHRESULT)
	; DllCall(..., "long", ...) returns HRESULT as a signed 32-bit value. Negative values satisfy FAILED(hr).
	Return $iHRESULT < 0
EndFunc   ;==>__WebView2_HRESULT_Failed

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_HRESULT_Format
; Description ...: Formats an HRESULT as hexadecimal text.
; Syntax ........: __WebView2_HRESULT_Format($iHRESULT)
; Parameters ....: $iHRESULT - HRESULT to examine.
; Return values .: Eight-digit hexadecimal HRESULT prefixed with 0x.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_HRESULT_Format($iHRESULT)
	Return "0x" & Hex($iHRESULT, 8)
EndFunc   ;==>__WebView2_HRESULT_Format

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Loader_Resolve
; Description ...: Searches supported locations for the WebView2 loader DLL.
; Syntax ........: __WebView2_Loader_Resolve($sLoaderPath)
; Parameters ....: $sLoaderPath - Explicit loader DLL path or search directory; Default uses supported locations.
; Return values .: Resolved DLL path, or an empty string if no loader was found.
;                  @error $WEBVIEW2_ERR_LOADER_NOT_FOUND - No loader DLL was found at the checked paths.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Loader_Resolve($sLoaderPath)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_Loader_Resolve"
	Local $sMessage = ''
	Do
		Local $sArch = @AutoItX64 ? "x64" : "x86"
		Local $aCandidates[6]

		If $sLoaderPath <> Default And $sLoaderPath <> "" Then
			If StringRight(StringLower($sLoaderPath), 4) = ".dll" Then
				If FileExists($sLoaderPath) Then
					$__WebView2ExitValue = $sLoaderPath
					$__WebView2ExitError = @error
					$__WebView2ExitExtended = @extended
					ExitLoop 1
				EndIf
				$__WebView2ExitValue = SetError($WEBVIEW2_ERR_LOADER_NOT_FOUND, 0, "")
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
			EndIf

			$aCandidates[0] = $sLoaderPath & "\WebView2Loader.dll"
			$aCandidates[1] = $sLoaderPath & "\" & $sArch & "\WebView2Loader.dll"
			For $i = 0 To 1
				If FileExists($aCandidates[$i]) Then
					$__WebView2ExitValue = $aCandidates[$i]
					$__WebView2ExitError = @error
					$__WebView2ExitExtended = @extended
					ExitLoop 2
				EndIf
			Next
			$__WebView2ExitValue = SetError($WEBVIEW2_ERR_LOADER_NOT_FOUND, 0, "")
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		$aCandidates[0] = @ScriptDir & "\WebView2Loader.dll"
		$aCandidates[1] = @ScriptDir & "\bin\" & $sArch & "\WebView2Loader.dll"
		$aCandidates[2] = @ScriptDir & "\..\bin\" & $sArch & "\WebView2Loader.dll"
		$aCandidates[3] = @ScriptDir & "\WebView2Loader-" & $sArch & ".dll"
		$aCandidates[4] = @ScriptDir & "\..\WebView2Loader.dll"
		$aCandidates[5] = @ScriptDir & "\..\WebView2Loader-" & $sArch & ".dll"

		For $i = 0 To UBound($aCandidates) - 1
			If FileExists($aCandidates[$i]) Then
				$__WebView2ExitValue = $aCandidates[$i]
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 2
			EndIf
		Next

		$__WebView2ExitValue = SetError($WEBVIEW2_ERR_LOADER_NOT_FOUND, 0, "")
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_Loader_Resolve

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_WaitForFlag
; Description ...: Pumps Windows messages until a flag is set or the timeout expires.
; Syntax ........: __WebView2_WaitForFlag(ByRef $bFlag, $iTimeoutMs)
; Parameters ....: $bFlag - Flag updated by the asynchronous callback. Passed ByRef so callback updates are observed.
;                  $iTimeoutMs - Maximum wait in milliseconds.
; Return values .: True when the flag is set; False on timeout.
;                  On callback cancellation - False and sets @error $WEBVIEW2_ERR_USER_ABORT.
;                  @extended contains the callback error for USER_ABORT.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_WaitForFlag(ByRef $bFlag, $iTimeoutMs)
	Local $hTimer = TimerInit()
	Local $iErr = $WEBVIEW2_ERR_NONE
	Local $iExtended = 0
	While Not $bFlag
		__WebView2_PumpMessages()
		__WebView2_Sleep(1)
		$iErr = @error
		$iExtended = @extended
		If $iErr Or TimerDiff($hTimer) >= $iTimeoutMs Then ExitLoop
	WEnd
	Return SetError($iErr, $iExtended, $bFlag And Not $iErr)
EndFunc   ;==>__WebView2_WaitForFlag

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_PumpMessages
; Description ...: Dispatches pending Windows messages.
; Syntax ........: __WebView2_PumpMessages()
; Parameters ....: None.
; Return values .: No value.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_PumpMessages()
	Local Const $PM_REMOVE = 0x0001
	Local $tMsg = DllStructCreate($__WEBVIEW2_TAG_MSG)

	While True
		Local $aPeek = DllCall("user32.dll", "bool", "PeekMessageW", "struct*", $tMsg, "hwnd", 0, "uint", 0, "uint", 0, "uint", $PM_REMOVE)
		If @error Or Not $aPeek[0] Then ExitLoop
		DllCall("user32.dll", "bool", "TranslateMessage", "struct*", $tMsg)
		DllCall("user32.dll", "lresult", "DispatchMessageW", "struct*", $tMsg)
	WEnd
	Return
EndFunc   ;==>__WebView2_PumpMessages

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_CoTaskMemString_ReadAndFree
; Description ...: Reads a COM-allocated UTF-16 string and releases its memory.
; Syntax ........: __WebView2_CoTaskMemString_ReadAndFree($pString)
; Parameters ....: $pString - COM-allocated UTF-16 string pointer.
; Return values .: Decoded text, or an empty string when unavailable.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_CoTaskMemString_ReadAndFree($pString)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_CoTaskMemString_ReadAndFree"
	Local $sMessage = ''
	Do
		If Not $pString Then
			$__WebView2ExitValue = ""
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $aLength = DllCall("kernel32.dll", "int", "lstrlenW", "ptr", $pString)
		If @error Then
			DllCall("ole32.dll", "none", "CoTaskMemFree", "ptr", $pString)
			$__WebView2ExitValue = ""
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $tString = DllStructCreate("wchar[" & ($aLength[0] + 1) & "]", $pString)
		Local $sValue = DllStructGetData($tString, 1)
		DllCall("ole32.dll", "none", "CoTaskMemFree", "ptr", $pString)
		$__WebView2ExitValue = $sValue
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_CoTaskMemString_ReadAndFree

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_CoreCall_NoArgs
; Description ...: Calls a no-argument method on the WebView2 core.
; Syntax ........: __WebView2_CoreCall_NoArgs($iWebView, $sMethod)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sMethod - Native method name.
; Return values .: True if the selected native call succeeds; otherwise False.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_CoreCall_NoArgs($iWebView, $sMethod)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_CoreCall_NoArgs"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $oCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE]
		Local $iResult = 0

		Switch $sMethod
			Case "Reload"
				$iResult = $oCore.Reload()
			Case "Stop"
				$iResult = $oCore.Stop()
			Case "GoBack"
				$iResult = $oCore.GoBack()
			Case "GoForward"
				$iResult = $oCore.GoForward()
			Case "OpenDevToolsWindow"
				$iResult = $oCore.OpenDevToolsWindow()
			Case Else
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Unsupported internal no-argument method.", False)
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
		EndSwitch

		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iResult, $sMethod & "() failed.", False)
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
EndFunc   ;==>__WebView2_CoreCall_NoArgs

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_CoreCall_String
; Description ...: Calls a string-argument method on the WebView2 core.
; Syntax ........: __WebView2_CoreCall_String($iWebView, $sMethod, $sValue)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sMethod - Native method name.
;                  $sValue - Text or value to write.
; Return values .: True if the selected native call succeeds; otherwise False.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_CoreCall_String($iWebView, $sMethod, $sValue)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_CoreCall_String"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_INSTANCE, 0, "Invalid WebView2 instance.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf

		Local $oCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE]
		Local $iResult

		Switch $sMethod
			Case "Navigate"
				$iResult = $oCore.Navigate($sValue)
			Case "NavigateToString"
				$iResult = $oCore.NavigateToString($sValue)
			Case "PostWebMessageAsString"
				$iResult = $oCore.PostWebMessageAsString($sValue)
			Case "PostWebMessageAsJson"
				$iResult = $oCore.PostWebMessageAsJson($sValue)
			Case Else
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Unsupported internal string method.", False)
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
		EndSwitch

		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iResult, $sMethod & "() failed.", False)
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
EndFunc   ;==>__WebView2_CoreCall_String

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Settings_Get
; Description ...: Retrieves the settings interface for a WebView instance.
; Syntax ........: __WebView2_Settings_Get($iWebView)
; Parameters ....: $iWebView - WebView instance ID.
; Return values .: Settings COM interface, or a failure value.
;                  @error $WEBVIEW2_ERR_INVALID_INSTANCE - Invalid WebView instance.
;                  @error $WEBVIEW2_ERR_HRESULT - Native WebView2 method failed.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Settings_Get($iWebView)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_Settings_Get"
	Local $sMessage = ''
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$__WebView2ExitValue = SetError($WEBVIEW2_ERR_INVALID_INSTANCE, 0, Null)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $pSettings = 0
		Local $oCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE]
		Local $iResult = $oCore.get_Settings($pSettings)
		If @error Or $iResult <> $WEBVIEW2_S_OK Or Not $pSettings Then
			$__WebView2ExitValue = SetError($WEBVIEW2_ERR_HRESULT, $iResult, Null)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $oSettings = ObjCreateInterface($pSettings, $WEBVIEW2_IID_ICoreWebView2Settings, $WEBVIEW2_DTAG_ICoreWebView2Settings)
		If Not IsObj($oSettings) Then
			$__WebView2ExitValue = SetError($WEBVIEW2_ERR_HRESULT, $WEBVIEW2_E_NOINTERFACE, Null)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		$__WebView2ExitValue = $oSettings
		$__WebView2ExitError = @error
		$__WebView2ExitExtended = @extended
		ExitLoop 1
	Until True
	If $__WebView2ExitError And $__g_iWebView2_LastError <> $__WebView2ExitError Then __WebView2_Error($sFuncName, $__WebView2ExitError, $sMessage, $__WebView2ExitExtended)
	Return SetError($__WebView2ExitError, $__WebView2ExitExtended, $__WebView2ExitValue)
EndFunc   ;==>__WebView2_Settings_Get

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Setting_PutBool
; Description ...: Sets a Boolean WebView2 setting.
; Syntax ........: __WebView2_Setting_PutBool($iWebView, $sMethod, $bEnabled)
; Parameters ....: $iWebView - WebView instance ID.
;                  $sMethod - Native method name.
;                  $bEnabled - Whether to enable the setting.
; Return values .: True if the setting changes; otherwise False.
;                  Propagates the helper @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Setting_PutBool($iWebView, $sMethod, $bEnabled)
	Local $__WebView2ExitValue = 0
	Local $__WebView2ExitError = 0, $__WebView2ExitExtended = 0
	Local Const $sFuncName = "__WebView2_Setting_PutBool"
	Local $sMessage = ''
	Do
		Local $oSettings = __WebView2_Settings_Get($iWebView)
		If @error Or Not IsObj($oSettings) Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, @extended, "Unable to access ICoreWebView2Settings.", False)
			$__WebView2ExitError = @error
			$__WebView2ExitExtended = @extended
			ExitLoop 1
		EndIf
		Local $iResult
		Switch $sMethod
			Case "put_IsScriptEnabled"
				$iResult = $oSettings.put_IsScriptEnabled($bEnabled)
			Case "put_IsWebMessageEnabled"
				$iResult = $oSettings.put_IsWebMessageEnabled($bEnabled)
			Case "put_AreDefaultScriptDialogsEnabled"
				$iResult = $oSettings.put_AreDefaultScriptDialogsEnabled($bEnabled)
			Case "put_IsStatusBarEnabled"
				$iResult = $oSettings.put_IsStatusBarEnabled($bEnabled)
			Case "put_AreDevToolsEnabled"
				$iResult = $oSettings.put_AreDevToolsEnabled($bEnabled)
			Case "put_AreDefaultContextMenusEnabled"
				$iResult = $oSettings.put_AreDefaultContextMenusEnabled($bEnabled)
			Case "put_AreHostObjectsAllowed"
				$iResult = $oSettings.put_AreHostObjectsAllowed($bEnabled)
			Case "put_IsZoomControlEnabled"
				$iResult = $oSettings.put_IsZoomControlEnabled($bEnabled)
			Case "put_IsBuiltInErrorPageEnabled"
				$iResult = $oSettings.put_IsBuiltInErrorPageEnabled($bEnabled)
			Case Else
				$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_INVALID_PARAMETER, 0, "Unsupported WebView2 setting method.", False)
				$__WebView2ExitError = @error
				$__WebView2ExitExtended = @extended
				ExitLoop 1
		EndSwitch
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$__WebView2ExitValue = __WebView2_Fail($WEBVIEW2_ERR_HRESULT, $iResult, $sMethod & "() failed.", False)
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
EndFunc   ;==>__WebView2_Setting_PutBool

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_JSONString_Decode
; Description ...: Decodes a JSON string literal.
; Syntax ........: __WebView2_JSONString_Decode($sValue)
; Parameters ....: $sValue - JSON string literal, or an unquoted value passed through unchanged.
; Return values .: Decoded text with @error = 0 and @extended = 0.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Decodes escapes once, including Unicode UTF-16 code units and surrogate pairs.
;                  Unquoted values and unrecognized escape sequences are preserved.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_JSONString_Decode($sValue)
	Local $sResult = $sValue
	If StringLen($sValue) >= 2 And StringLeft($sValue, 1) = '"' And StringRight($sValue, 1) = '"' Then
		Local $sText = StringTrimLeft(StringTrimRight($sValue, 1), 1)
		Local $iStart = 1, $iSlash = 0, $iLength = StringLen($sText)
		$sResult = ''
		While $iStart <= $iLength
			$iSlash = StringInStr($sText, '\', 1, 1, $iStart)
			If Not $iSlash Then
				$sResult &= StringMid($sText, $iStart)
				ExitLoop
			EndIf
			$sResult &= StringMid($sText, $iStart, $iSlash - $iStart)
			Local $sEscape = StringMid($sText, $iSlash + 1, 1)
			$iStart = $iSlash + 2
			Switch $sEscape
				Case '"', '\', '/'
					$sResult &= $sEscape
				Case 'b'
					$sResult &= Chr(8)
				Case 'f'
					$sResult &= Chr(12)
				Case 'n'
					$sResult &= @LF
				Case 'r'
					$sResult &= @CR
				Case 't'
					$sResult &= @TAB
				Case 'u'
					Local $sHex = StringMid($sText, $iSlash + 2, 4)
					If StringRegExp($sHex, '^[0-9a-fA-F]{4}$') Then
						$sResult &= ChrW(Dec($sHex))
						$iStart += 4
					Else
						$sResult &= '\u'
					EndIf
				Case Else
					; Preserve unrecognized escapes, matching the original permissive input behavior.
					$sResult &= '\' & $sEscape
			EndSwitch
		WEnd
	EndIf
	Return SetError(0, 0, $sResult)
EndFunc   ;==>__WebView2_JSONString_Decode

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_JavaScript_StringLiteral
; Description ...: Escapes text as a JavaScript string literal.
; Syntax ........: __WebView2_JavaScript_StringLiteral($sValue)
; Parameters ....: $sValue - Text or value to write.
; Return values .: Quoted and escaped JavaScript text.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_JavaScript_StringLiteral($sValue)
	Local $s = StringReplace($sValue, '\', '\\')
	$s = StringReplace($s, '"', '\"')
	$s = StringReplace($s, @CRLF, '\n')
	$s = StringReplace($s, @CR, '\n')
	$s = StringReplace($s, @LF, '\n')
	$s = StringReplace($s, @TAB, '\t')
	Return '"' & $s & '"'
EndFunc   ;==>__WebView2_JavaScript_StringLiteral

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Error_Clear
; Description ...: Clears the stored WebView2 diagnostic state.
; Syntax ........: __WebView2_Error_Clear()
; Parameters ....: None.
; Return values .: No value; the stored diagnostic is reset.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Error_Clear()
	$__g_sWebView2_LastError = ""
	$__g_iWebView2_LastError = $WEBVIEW2_ERR_NONE
	$__g_iWebView2_LastExtended = 0
	Return
EndFunc   ;==>__WebView2_Error_Clear

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Fail
; Description ...: Stores a WebView2 diagnostic and returns a failure value.
; Syntax ........: __WebView2_Fail($iError, $iExtended, $sDescription, $vReturn)
; Parameters ....: $iError - WebView2 error code.
;                  $iExtended - Extended native error value.
;                  $sDescription - Stored diagnostic description.
;                  $vReturn - Value returned to the caller on failure.
; Return values .: The supplied failure value; sets the stored diagnostic and @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Fail($iError, $iExtended, $sDescription, $vReturn)
	$__g_iWebView2_LastError = $iError
	$__g_iWebView2_LastExtended = $iExtended
	$__g_sWebView2_LastError = $sDescription
	__WebView2_ConsoleWrite($sDescription, $WEBVIEW2_DEBUG_ERROR)
	Return SetError($iError, $iExtended, $vReturn)
EndFunc   ;==>__WebView2_Fail

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetDebugLevel
; Description ...: Sets the WebView2 console diagnostic level.
; Syntax ........: _WebView2_SetDebugLevel($iLevel)
; Parameters ....: $iLevel - One of $WEBVIEW2_DEBUG_NONE, ERROR, INFO or FULL.
; Return values .: On Success - True.
;                  On Failure - False and sets @error $WEBVIEW2_ERR_INVALID_PARAMETER.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Existing trace messages are emitted at FULL level.
; Related .......: __WebView2_ConsoleWrite
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_SetDebugLevel($iLevel)
	Local $iErr = $WEBVIEW2_ERR_NONE
	Local $bResult = True
	If Not IsInt($iLevel) Or $iLevel < $WEBVIEW2_DEBUG_NONE Or $iLevel > $WEBVIEW2_DEBUG_FULL Then
		$iErr = $WEBVIEW2_ERR_INVALID_PARAMETER
		$bResult = False
	Else
		$__g_iWebView2_DebugLevel = $iLevel
	EndIf
	If $iErr Then __WebView2_Error("_WebView2_SetDebugLevel", $iErr, String($iLevel))
	Return SetError($iErr, 0, $bResult)
EndFunc   ;==>_WebView2_SetDebugLevel

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_SetSleepCallback
; Description ...: Configures a user function called instead of Sleep() during WebView2 waits.
; Syntax ........: _WebView2_SetSleepCallback([$fnSleep = Default])
; Parameters ....: $fnSleep - Function accepting milliseconds, or Default to restore Sleep().
; Return values .: On Success - True.
;                  On Failure - False and sets @error $WEBVIEW2_ERR_INVALID_PARAMETER.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The callback can signal cancellation by setting @error.
; Related .......: __WebView2_Sleep
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_SetSleepCallback($fnSleep = Default)
	Local $iErr = $WEBVIEW2_ERR_NONE
	Local $bResult = True
	If $fnSleep = Default Or IsFunc($fnSleep) Then
		$__g_fnWebView2_Sleep = $fnSleep
	Else
		$iErr = $WEBVIEW2_ERR_INVALID_PARAMETER
		$bResult = False
		__WebView2_Error("_WebView2_SetSleepCallback", $iErr, "Callback must be an AutoIt function reference or Default.")
	EndIf
	Return SetError($iErr, 0, $bResult)
EndFunc   ;==>_WebView2_SetSleepCallback

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_ConsoleWrite
; Description ...: Writes a message when its level is enabled.
; Syntax ........: __WebView2_ConsoleWrite($sMessage[, $iLevel = $WEBVIEW2_DEBUG_INFO])
; Parameters ....: $sMessage - Message text.
;                  $iLevel - Minimum debug level for this message.
; Return values .: No value.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Debug levels are ordered NONE, ERROR, INFO, FULL.
; Related .......: _WebView2_SetDebugLevel
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_ConsoleWrite($sMessage, $iLevel = $WEBVIEW2_DEBUG_INFO)
	If $iLevel <= $__g_iWebView2_DebugLevel Then ConsoleWrite("[WebView2] " & $sMessage & @CRLF)
	Return
EndFunc   ;==>__WebView2_ConsoleWrite

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Error
; Description ...: Records an error and returns its code for SetError().
; Syntax ........: __WebView2_Error($sFuncName, $iErr[, $sParameters = ""[, $iExtended = 0]])
; Parameters ....: $sFuncName - Name of the reporting function.
;                  $iErr - WebView2 error code.
;                  $sParameters - Optional diagnostic details.
;                  $iExtended - Optional secondary error value.
; Return values .: Error code; does not itself set @error.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Use within a final Return SetError() statement.
; Related .......: __WebView2_Fail
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Error($sFuncName, $iErr, $sParameters = "", $iExtended = 0)
	$__g_iWebView2_LastError = $iErr
	$__g_iWebView2_LastExtended = $iExtended
	$__g_sWebView2_LastError = $sFuncName & ": " & $sParameters
	__WebView2_ConsoleWrite($__g_sWebView2_LastError & " (error=" & $iErr & ")", $WEBVIEW2_DEBUG_ERROR)
	Return $iErr
EndFunc   ;==>__WebView2_Error

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Sleep
; Description ...: Pauses a wait and maps a user callback error to UserAbort.
; Syntax ........: __WebView2_Sleep($iPause)
; Parameters ....: $iPause - Pause in milliseconds.
; Return values .: On Success - True.
;                  On Failure - False and sets @error $WEBVIEW2_ERR_USER_ABORT; @extended contains the callback error.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Calls Sleep() unless changed with _WebView2_SetSleepCallback().
; Related .......: _WebView2_SetSleepCallback
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Sleep($iPause)
	Local $iErr = $WEBVIEW2_ERR_NONE
	Local $iExtended = 0
	Local $bResult = True
	If $iPause < 1 Then $iPause = 1
	If $__g_fnWebView2_Sleep = Default Then
		Sleep($iPause)
	Else
		Call($__g_fnWebView2_Sleep, $iPause)
		$iExtended = @error
		If $iExtended Then
			$iErr = $WEBVIEW2_ERR_USER_ABORT
			$bResult = False
			__WebView2_Error("__WebView2_Sleep", $iErr, "User sleep callback returned @error=" & $iExtended)
			$__g_iWebView2_LastExtended = $iExtended
		EndIf
	EndIf
	Return SetError($iErr, $iExtended, $bResult)
EndFunc   ;==>__WebView2_Sleep

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Instance_List
; Description ...: Returns the IDs of all live WebView2 instances.
; Syntax ........: _WebView2_Instance_List()
; Parameters ....: None.
; Return values .: One-dimensional array with count at [0] and instance IDs at [1..count].
; Author ........: mLipok
; Modified ......:
; Remarks .......: The list includes instances that were not created as tabs.
; Related .......: _WebView2_Create, _WebView2_Tab_List
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_Instance_List()
	Local $aInstances[$WEBVIEW2_MAX_INSTANCES + 1]
	Local $iCount = 0
	For $iSlot = 0 To $WEBVIEW2_MAX_INSTANCES - 1
		If __WebView2_Instance_IsValid($iSlot) Then
			$iCount += 1
			$aInstances[$iCount] = $iSlot
		EndIf
	Next
	$aInstances[0] = $iCount
	ReDim $aInstances[$iCount + 1]
	Return $aInstances
EndFunc   ;==>_WebView2_Instance_List

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Tab_Create
; Description ...: Creates a WebView2 instance managed as a tab in a parent window.
; Syntax ........: _WebView2_Tab_Create($hWndParent[, $sURI = "about:blank"[, $iLeft = 0[, $iTop = 0[, $iWidth = -1[, $iHeight = -1[, $iTimeoutMs = 30000]]]]]])
; Parameters ....: $hWndParent - Parent window for the tab.
;                  $sURI - Initial URI; defaults to about:blank.
;                  $iLeft - Left offset inside the parent window.
;                  $iTop - Top offset inside the parent window.
;                  $iWidth - Tab width; -1 fills remaining parent width.
;                  $iHeight - Tab height; -1 fills remaining parent height.
;                  $iTimeoutMs - Maximum controller creation wait in milliseconds.
; Return values .: On Success - Tab ID, identical to its WebView2 instance ID.
;                  On Failure - -1 and sets @error to the underlying WebView2 code.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Tabs are separate WebView2 controllers sharing one environment.
; Related .......: _WebView2_Tab_Activate, _WebView2_Tab_Close, _WebView2_Tab_List
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_Tab_Create($hWndParent, $sURI = "about:blank", $iLeft = 0, $iTop = 0, $iWidth = -1, $iHeight = -1, $iTimeoutMs = 30000)
	Local $iErr = $WEBVIEW2_ERR_NONE
	Local $iExtended = 0
	Local $iTab = -1
	For $iAttempt = 1 To 3
		$iTab = _WebView2_Create($hWndParent, $iLeft, $iTop, $iWidth, $iHeight, $iTimeoutMs)
		$iErr = @error
		$iExtended = @extended
		If $iTab < 0 And Not $iErr Then $iErr = _WebView2_Error_GetCode()
		If $iTab >= 0 Or $iErr <> $WEBVIEW2_ERR_HRESULT Or $iExtended <> $WEBVIEW2_E_INVALID_WINDOW_HANDLE Or $iAttempt = 3 Then ExitLoop
		__WebView2_PumpMessages()
		__WebView2_Sleep(50)
		If @error Then
			$iErr = $WEBVIEW2_ERR_USER_ABORT
			$iExtended = @extended
			ExitLoop
		EndIf
	Next
	If Not $iErr Then
		$__g_aWebView2_Tabs[$iTab] = True
		Local $bNavigate = True
		If $sURI <> "about:blank" Then
			$bNavigate = _WebView2_Navigate($iTab, $sURI)
			$iErr = @error
			$iExtended = @extended
			If Not $bNavigate And Not $iErr Then $iErr = _WebView2_Error_GetCode()
		EndIf
		If Not $bNavigate Or $iErr Then
			_WebView2_Destroy($iTab)
			$iTab = -1
		Else
			_WebView2_Tab_Activate($iTab)
			$iErr = @error
			$iExtended = @extended
			If $iErr Then
				_WebView2_Destroy($iTab)
				$iTab = -1
			EndIf
		EndIf
	EndIf
	Return SetError($iErr, $iExtended, $iTab)
EndFunc   ;==>_WebView2_Tab_Create

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Tab_Activate
; Description ...: Shows one tab and hides other tabs in the same parent window.
; Syntax ........: _WebView2_Tab_Activate($iTab)
; Parameters ....: $iTab - Tab ID returned by _WebView2_Tab_Create().
; Return values .: On Success - True.
;                  On Failure - False and sets @error to a WebView2 error code.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Other parent windows and ordinary instances are unaffected.
; Related .......: _WebView2_Tab_Create, _WebView2_Tab_List
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_Tab_Activate($iTab)
	Local $iErr = $WEBVIEW2_ERR_NONE
	Local $iExtended = 0
	Local $bResult = False
	If Not __WebView2_Tab_IsValid($iTab) Then
		$iErr = __WebView2_Error("_WebView2_Tab_Activate", $WEBVIEW2_ERR_INVALID_INSTANCE, String($iTab))
	Else
		Local $hParent = $__g_aWebView2_Instances[$iTab][$__WEBVIEW2_INSTANCE_PARENT]
		$bResult = __WebView2_Tab_SetVisibleRetry($iTab, True)
		$iErr = @error
		$iExtended = @extended
		If Not $bResult And Not $iErr Then $iErr = _WebView2_Error_GetCode()
		If Not $iErr Then
			For $iSlot = 0 To $WEBVIEW2_MAX_INSTANCES - 1
				If $iSlot = $iTab Or Not $__g_aWebView2_Tabs[$iSlot] Then ContinueLoop
				If Not __WebView2_Instance_IsValid($iSlot) Then ContinueLoop
				If $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_PARENT] <> $hParent Then ContinueLoop
				Local $bHidden = __WebView2_Tab_SetVisibleRetry($iSlot, False)
				$iErr = @error
				$iExtended = @extended
				If Not $bHidden And Not $iErr Then $iErr = _WebView2_Error_GetCode()
				If $iErr Then
					$bResult = False
					ExitLoop
				EndIf
			Next
		EndIf
	EndIf
	Return SetError($iErr, $iExtended, $bResult)
EndFunc   ;==>_WebView2_Tab_Activate

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Tab_Close
; Description ...: Closes a managed tab and its WebView2 instance.
; Syntax ........: _WebView2_Tab_Close($iTab)
; Parameters ....: $iTab - Tab ID returned by _WebView2_Tab_Create().
; Return values .: On Success - True.
;                  On Failure - False and sets @error $WEBVIEW2_ERR_INVALID_INSTANCE.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Closing the active tab does not automatically activate another tab.
; Related .......: _WebView2_Tab_Create, _WebView2_Tab_Activate
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_Tab_Close($iTab)
	Local $iErr = $WEBVIEW2_ERR_NONE
	Local $iExtended = 0
	Local $bResult = False
	If Not __WebView2_Tab_IsValid($iTab) Then
		$iErr = __WebView2_Error("_WebView2_Tab_Close", $WEBVIEW2_ERR_INVALID_INSTANCE, String($iTab))
	Else
		$bResult = _WebView2_Destroy($iTab)
		$iErr = @error
		$iExtended = @extended
		If Not $bResult And Not $iErr Then $iErr = _WebView2_Error_GetCode()
	EndIf
	Return SetError($iErr, $iExtended, $bResult)
EndFunc   ;==>_WebView2_Tab_Close

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Tab_List
; Description ...: Returns managed tab IDs, optionally for one parent window.
; Syntax ........: _WebView2_Tab_List([$hWndParent = Default])
; Parameters ....: $hWndParent - Optional parent HWND; Default lists all parents.
; Return values .: One-dimensional array with count at [0] and tab IDs at [1..count].
; Author ........: mLipok
; Modified ......:
; Remarks .......: Each tab ID is also its WebView2 instance ID.
; Related .......: _WebView2_Instance_List, _WebView2_Tab_Create
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_Tab_List($hWndParent = Default)
	Local $aTabs[$WEBVIEW2_MAX_INSTANCES + 1]
	Local $iCount = 0
	For $iSlot = 0 To $WEBVIEW2_MAX_INSTANCES - 1
		If Not $__g_aWebView2_Tabs[$iSlot] Or Not __WebView2_Instance_IsValid($iSlot) Then ContinueLoop
		If $hWndParent <> Default And $__g_aWebView2_Instances[$iSlot][$__WEBVIEW2_INSTANCE_PARENT] <> $hWndParent Then ContinueLoop
		$iCount += 1
		$aTabs[$iCount] = $iSlot
	Next
	$aTabs[0] = $iCount
	ReDim $aTabs[$iCount + 1]
	Return $aTabs
EndFunc   ;==>_WebView2_Tab_List

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Tab_IsValid
; Description ...: Checks whether an ID refers to a live managed tab.
; Syntax ........: __WebView2_Tab_IsValid($iTab)
; Parameters ....: $iTab - Candidate tab ID.
; Return values .: True or False.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Guards the array index before reading the tab registry.
; Related .......: _WebView2_Tab_List
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Tab_IsValid($iTab)
	Local $bValid = False
	If IsInt($iTab) Then
		If $iTab >= 0 And $iTab < $WEBVIEW2_MAX_INSTANCES Then
			If $__g_aWebView2_Tabs[$iTab] Then $bValid = __WebView2_Instance_IsValid($iTab)
		EndIf
	EndIf
	Return $bValid
EndFunc   ;==>__WebView2_Tab_IsValid

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Tab_SetVisibleRetry
; Description ...: Retries transient native visibility errors during tab activation.
; Syntax ........: __WebView2_Tab_SetVisibleRetry($iTab, $bVisible)
; Parameters ....: $iTab - Live WebView2 tab ID.
;                  $bVisible - Requested visibility.
; Return values .: On Success - True.
;                  On Failure - False and propagates the final WebView2 @error/@extended.
; Author ........: mLipok
; Modified ......:
; Remarks .......: WebView2 may briefly reject visibility changes while a controller is settling.
; Related .......: _WebView2_Tab_Activate, _WebView2_SetVisible
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Tab_SetVisibleRetry($iTab, $bVisible)
	Local $bResult = False
	Local $iErr = $WEBVIEW2_ERR_NONE
	Local $iExtended = 0
	For $iAttempt = 1 To 5
		$bResult = _WebView2_SetVisible($iTab, $bVisible)
		$iErr = @error
		$iExtended = @extended
		If $bResult Or $iErr <> $WEBVIEW2_ERR_HRESULT Or $iExtended <> $WEBVIEW2_E_INVALID_STATE Or $iAttempt = 5 Then ExitLoop
		__WebView2_PumpMessages()
		__WebView2_Sleep(25)
		If @error Then
			$iErr = $WEBVIEW2_ERR_USER_ABORT
			$iExtended = @extended
			ExitLoop
		EndIf
	Next
	If $bResult Then __WebView2_Error_Clear()
	Return SetError($iErr, $iExtended, $bResult)
EndFunc   ;==>__WebView2_Tab_SetVisibleRetry

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_JavaScriptStringLiteral
; Description ...: Encodes text as a JavaScript string literal.
; Syntax ........: _WebView2_JavaScriptStringLiteral($sValue)
; Parameters ....: $sValue - Text to encode.
; Return values .: A quoted JavaScript string literal.
; Author ........:
; Modified ......:
; Remarks .......: Public wrapper for use by other UDFs.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_JavaScriptStringLiteral($sValue)
	Return __WebView2_JavaScript_StringLiteral($sValue)
EndFunc   ;==>_WebView2_JavaScriptStringLiteral

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_JSONStringDecode
; Description ...: Decodes a JSON string returned by script execution.
; Syntax ........: _WebView2_JSONStringDecode($sValue)
; Parameters ....: $sValue - JSON-encoded value.
; Return values .: Decoded string, with @error/@extended from the decoder.
; Author ........:
; Modified ......:
; Remarks .......: Public wrapper for use by other UDFs.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WebView2_JSONStringDecode($sValue)
	Local $sDecoded = __WebView2_JSONString_Decode($sValue)
	Return SetError(@error, @extended, $sDecoded)
EndFunc   ;==>_WebView2_JSONStringDecode
