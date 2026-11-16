#include-once
#Tidy_ILC_Pos=44

#include "WebView2_Constants.au3"

; #INDEX# =======================================================================================================================
; Title .........: WebView2_DPI.au3
; Description ...: Optional host-process DPI helpers for WebView2 applications.
; Author(s) .....: mLipok
; Version .......: 0.6.0
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_DPI_SetProcessPerMonitorV2
; Description ...: Opts the host process into Per Monitor v2 DPI awareness before creating any UI.
; Syntax ........: _WebView2_DPI_SetProcessPerMonitorV2()
; Parameters ....: None.
; Return values .: True on success or if the current thread already has this context; False with @error on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Prefer a manifest for production applications. @extended=1 means the current thread already had this context.
;                  A manifest or earlier API call with a different context makes SetProcessDpiAwarenessContext fail.
; Related .......: _WebView2_DPI_GetWindowDpi, _WebView2_Create
; Link ..........: https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-setprocessdpiawarenesscontext
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_DPI_SetProcessPerMonitorV2()
	Local $bResult = False, $iError = 0, $iExtended = 0
	Do
		Local $aContext = DllCall("user32.dll", "handle", "GetThreadDpiAwarenessContext")
		If Not @error And IsArray($aContext) And $aContext[0] Then
			Local $aEqual = DllCall("user32.dll", "bool", "AreDpiAwarenessContextsEqual", "handle", $aContext[0], "handle", Ptr(-4))
			If Not @error And $aEqual[0] Then
				$bResult = True
				$iExtended = 1
				ExitLoop 1
			EndIf
		EndIf
		Local $aSet = DllCall("user32.dll", "bool", "SetProcessDpiAwarenessContext", "handle", Ptr(-4))
		Local $iWin32Error = @extended
		If @error Or Not IsArray($aSet) Then
			$iError = $WEBVIEW2_ERR_DLLCALL
			ExitLoop 1
		EndIf
		If Not $aSet[0] Then
			$iError = $WEBVIEW2_ERR_DLLCALL
			$iExtended = $iWin32Error
			ExitLoop 1
		EndIf
		$bResult = True
	Until True
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_DPI_SetProcessPerMonitorV2

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_DPI_GetWindowDpi
; Description ...: Reads the DPI assigned to one host window by Windows.
; Syntax ........: _WebView2_DPI_GetWindowDpi($hWnd)
; Parameters ....: $hWnd - Existing host window handle.
; Return values .: DPI on success; 0 with @error on failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Use the host window DPI when laying out WebView2 bounds after WM_DPICHANGED.
; Related .......: _WebView2_DPI_SetProcessPerMonitorV2, _WebView2_SetBounds
; Link ..........: https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-getdpiforwindow
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_DPI_GetWindowDpi($hWnd)
	Local $iResult = 0, $iError = 0, $iExtended = 0
	Do
		If Not IsHWnd($hWnd) Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		Local $aDpi = DllCall("user32.dll", "uint", "GetDpiForWindow", "hwnd", $hWnd)
		If @error Or Not IsArray($aDpi) Then
			$iError = $WEBVIEW2_ERR_DLLCALL
			ExitLoop 1
		EndIf
		If $aDpi[0] = 0 Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		$iResult = $aDpi[0]
	Until True
	Return SetError($iError, $iExtended, $iResult)
EndFunc   ;==>_WebView2_DPI_GetWindowDpi
