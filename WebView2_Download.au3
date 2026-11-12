#include-once
#Tidy_ILC_Pos=44

; #INDEX# =======================================================================================================================
; Title .........: WebView2_Download.au3
; Description ...: Native WebView2 download policy, progress, state and cancellation.
; Author(s) .....: mLipok
; Version .......: 0.6.0
; ===============================================================================================================================

Global Const $__WEBVIEW2_DOWNLOAD_LIMIT = 64
Global Enum _
		$__WEBVIEW2_DOWNLOAD_ID, _
		$__WEBVIEW2_DOWNLOAD_VIEW, _
		$__WEBVIEW2_DOWNLOAD_PTR, _
		$__WEBVIEW2_DOWNLOAD_OBJECT, _
		$__WEBVIEW2_DOWNLOAD_PROGRESS_TOKEN, _
		$__WEBVIEW2_DOWNLOAD_STATE_TOKEN, _
		$__WEBVIEW2_DOWNLOAD_PENDING_ARGS, _
		$__WEBVIEW2_DOWNLOAD_PENDING_DEFERRAL, _
		$__WEBVIEW2_DOWNLOAD_FIELDS
Global $__g_aWebView2_Downloads[$__WEBVIEW2_DOWNLOAD_LIMIT][$__WEBVIEW2_DOWNLOAD_FIELDS]
Global $__g_iWebView2_NextDownloadId = 1
Global $__g_aWebView2_DownloadCore4[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_DownloadToken[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_DownloadStartCallback[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_DownloadProgressCallback[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_DownloadStateCallback[$WEBVIEW2_MAX_INSTANCES]

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Download_List
; Description ...: Lists tracked downloads for one WebView2 instance.
; Syntax ........: _WebView2_Download_List($iWebView)
; Parameters ....: $iWebView - WebView2 instance ID.
; Return values .: Array of download IDs; empty array when none. @error on invalid instance.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Completed downloads remain in the bounded registry until cleanup or replacement by a new download.
; Related .......: _WebView2_Download_GetInfo
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Download_List($iWebView)
	Local $aResult[0], $iError = 0
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$iError = $WEBVIEW2_ERR_INVALID_INSTANCE
			ExitLoop
		EndIf
		For $i = 0 To $__WEBVIEW2_DOWNLOAD_LIMIT - 1
			If $__g_aWebView2_Downloads[$i][$__WEBVIEW2_DOWNLOAD_ID] And $__g_aWebView2_Downloads[$i][$__WEBVIEW2_DOWNLOAD_VIEW] = $iWebView Then
				ReDim $aResult[UBound($aResult) + 1]
				$aResult[UBound($aResult) - 1] = $__g_aWebView2_Downloads[$i][$__WEBVIEW2_DOWNLOAD_ID]
			EndIf
		Next
	Until True
	Return SetError($iError, 0, $aResult)
EndFunc   ;==>_WebView2_Download_List

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Download_GetInfo
; Description ...: Reads current native download metadata.
; Syntax ........: _WebView2_Download_GetInfo($iDownload)
; Parameters ....: $iDownload - ID from a download callback or _WebView2_Download_List().
; Return values .: [URI, file path, MIME type, bytes received, total bytes, state, interrupt reason]; @error for stale ID.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Total bytes is -1 when unknown; state uses $WEBVIEW2_DOWNLOAD_STATE_* constants.
; Related .......: _WebView2_Download_List, _WebView2_Download_Cancel
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Download_GetInfo($iDownload)
	Local $aInfo[7], $iError = 0, $iExtended = 0
	Do
		Local $iSlot = __WebView2_Download_Find($iDownload)
		If $iSlot < 0 Then
			$iError = $WEBVIEW2_ERR_NO_MATCH
			ExitLoop
		EndIf
		Local $oOperation = $__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_OBJECT]
		Local $pString = 0, $iValue = 0
		Local $iResult = $oOperation.get_Uri($pString)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop
		EndIf
		$aInfo[0] = __WebView2_CoTaskMemString_ReadAndFree($pString)
		$pString = 0
		$iResult = $oOperation.get_ResultFilePath($pString)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop
		EndIf
		$aInfo[1] = __WebView2_CoTaskMemString_ReadAndFree($pString)
		$pString = 0
		$iResult = $oOperation.get_MimeType($pString)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop
		EndIf
		$aInfo[2] = __WebView2_CoTaskMemString_ReadAndFree($pString)
		$iResult = $oOperation.get_BytesReceived($iValue)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop
		EndIf
		$aInfo[3] = $iValue
		$iResult = $oOperation.get_TotalBytesToReceive($iValue)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop
		EndIf
		$aInfo[4] = $iValue
		$iResult = $oOperation.get_State($iValue)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop
		EndIf
		$aInfo[5] = $iValue
		$iResult = $oOperation.get_InterruptReason($iValue)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop
		EndIf
		$aInfo[6] = $iValue
		ExitLoop
	Until True
	Return SetError($iError, $iExtended, $aInfo)
EndFunc   ;==>_WebView2_Download_GetInfo

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Download_CanResume
; Description ...: Checks whether an interrupted download can be resumed.
; Syntax ........: _WebView2_Download_CanResume($iDownload)
; Parameters ....: $iDownload - Tracked download ID.
; Return values .: True or False; @error for stale ID or native failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: A paused download is reported as interrupted with the USER_PAUSED reason.
; Related .......: _WebView2_Download_Pause, _WebView2_Download_Resume
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2downloadoperation
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Download_CanResume($iDownload)
	Local $bResult = False, $iError = 0, $iExtended = 0
	Do
		Local $iSlot = __WebView2_Download_Find($iDownload)
		If $iSlot < 0 Then
			$iError = $WEBVIEW2_ERR_NO_MATCH
			ExitLoop
		EndIf
		Local $oOperation = $__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_OBJECT]
		Local $iResult = $oOperation.get_CanResume($bResult)
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
		EndIf
	Until True
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_Download_CanResume

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Download_Pause
; Description ...: Pauses an active native download.
; Syntax ........: _WebView2_Download_Pause($iDownload)
; Parameters ....: $iDownload - Tracked download ID.
; Return values .: True on success; False with @error on stale ID or native failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: WebView2 reports a pause as INTERRUPTED with reason USER_PAUSED.
; Related .......: _WebView2_Download_CanResume, _WebView2_Download_Resume
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2downloadoperation
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Download_Pause($iDownload)
	Local $bResult = False, $iError = 0, $iExtended = 0
	Do
		Local $iSlot = __WebView2_Download_Find($iDownload)
		If $iSlot < 0 Then
			$iError = $WEBVIEW2_ERR_NO_MATCH
			ExitLoop
		EndIf
		If IsObj($__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_PENDING_DEFERRAL]) Then
			$iError = $WEBVIEW2_ERR_BUSY
			ExitLoop
		EndIf
		Local $oOperation = $__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_OBJECT]
		Local $iResult = $oOperation.Pause()
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop
		EndIf
		$bResult = True
	Until True
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_Download_Pause

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Download_Resume
; Description ...: Resumes an interrupted download when WebView2 permits it.
; Syntax ........: _WebView2_Download_Resume($iDownload)
; Parameters ....: $iDownload - Tracked download ID.
; Return values .: True on success; False with @error when unavailable or on native failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Call _WebView2_Download_CanResume() to enable a host Resume button.
; Related .......: _WebView2_Download_CanResume, _WebView2_Download_Pause
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2downloadoperation
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Download_Resume($iDownload)
	Local $bResult = False, $iError = 0, $iExtended = 0
	Do
		Local $bCanResume = _WebView2_Download_CanResume($iDownload)
		$iError = @error
		$iExtended = @extended
		If $iError Then ExitLoop
		If Not $bCanResume Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $WEBVIEW2_E_INVALID_STATE
			ExitLoop
		EndIf
		Local $iSlot = __WebView2_Download_Find($iDownload)
		Local $oOperation = $__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_OBJECT]
		Local $iResult = $oOperation.Resume()
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop
		EndIf
		$bResult = True
	Until True
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_Download_Resume

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Download_Pending_List
; Description ...: Lists download IDs awaiting a deferred start decision.
; Syntax ........: _WebView2_Download_Pending_List($iWebView)
; Parameters ....: $iWebView - WebView2 instance ID.
; Return values .: Array of IDs; empty array when none, @error on invalid instance.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Decide outside the native callback; always complete or cancel promptly.
; Related .......: _WebView2_Download_Complete, _WebView2_Download_Cancel
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Download_Pending_List($iWebView)
	Local $aResult[0], $iError = 0
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$iError = $WEBVIEW2_ERR_INVALID_INSTANCE
			ExitLoop
		EndIf
		For $i = 0 To $__WEBVIEW2_DOWNLOAD_LIMIT - 1
			If $__g_aWebView2_Downloads[$i][$__WEBVIEW2_DOWNLOAD_ID] And $__g_aWebView2_Downloads[$i][$__WEBVIEW2_DOWNLOAD_VIEW] = $iWebView And _
					IsObj($__g_aWebView2_Downloads[$i][$__WEBVIEW2_DOWNLOAD_PENDING_DEFERRAL]) Then
				ReDim $aResult[UBound($aResult) + 1]
				$aResult[UBound($aResult) - 1] = $__g_aWebView2_Downloads[$i][$__WEBVIEW2_DOWNLOAD_ID]
			EndIf
		Next
	Until True
	Return SetError($iError, 0, $aResult)
EndFunc   ;==>_WebView2_Download_Pending_List

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Download_Complete
; Description ...: Allows a deferred download with the default or selected destination.
; Syntax ........: _WebView2_Download_Complete($iDownload[, $sPath = Default[, $bHideDefaultUI = False]])
; Parameters ....: $iDownload - Pending download ID.
;                  $sPath - Default to retain WebView2's path, or a new absolute file path.
;                  $bHideDefaultUI - True to hide the Runtime download UI.
; Return values .: True on success; False with @error on invalid ID/path or native failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: An invalid path leaves the request pending for retry. Cleanup cancels any remaining request.
; Related .......: _WebView2_Download_Pending_List, _WebView2_Download_Cancel
; Link ..........: https://learn.microsoft.com/microsoft-edge/webview2/reference/win32/icorewebview2downloadstartingeventargs
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Download_Complete($iDownload, $sPath = Default, $bHideDefaultUI = False)
	Local $bResult = False, $iError = 0, $iExtended = 0
	Do
		Local $iSlot = __WebView2_Download_Find($iDownload)
		If $iSlot < 0 Then
			$iError = $WEBVIEW2_ERR_NO_MATCH
			ExitLoop
		EndIf
		If Not IsObj($__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_PENDING_DEFERRAL]) Then
			$iError = $WEBVIEW2_ERR_NO_MATCH
			ExitLoop
		EndIf
		If Not IsBool($bHideDefaultUI) Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop
		EndIf
		$bResult = __WebView2_Download_Resolve($iSlot, False, $sPath, $bHideDefaultUI)
		$iError = @error
		$iExtended = @extended
	Until True
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_Download_Complete

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_Download_Cancel
; Description ...: Cancels an active native download.
; Syntax ........: _WebView2_Download_Cancel($iDownload)
; Parameters ....: $iDownload - ID from a download callback or _WebView2_Download_List().
; Return values .: True on success; False with @error on invalid ID or native failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Also cancels and completes a pending deferred start decision.
; Related .......: _WebView2_Download_GetInfo
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_Download_Cancel($iDownload)
	Local $bResult = False, $iError = 0, $iExtended = 0
	Do
		Local $iSlot = __WebView2_Download_Find($iDownload)
		If $iSlot < 0 Then
			$iError = $WEBVIEW2_ERR_NO_MATCH
			ExitLoop
		EndIf
		If IsObj($__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_PENDING_DEFERRAL]) Then
			$bResult = __WebView2_Download_Resolve($iSlot, True)
			$iError = @error
			$iExtended = @extended
			ExitLoop
		EndIf
		Local $oOperation = $__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_OBJECT]
		Local $iResult = $oOperation.Cancel()
		If @error Or $iResult <> $WEBVIEW2_S_OK Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
			ExitLoop
		EndIf
		$bResult = True
	Until True
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>_WebView2_Download_Cancel

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_Download_Resolve
; Description ...: Applies a deferred start decision and completes the native deferral.
; Syntax ........: __WebView2_Download_Resolve($iSlot, $bCancel[, $sPath = Default[, $bHideDefaultUI = False]])
; Parameters ....: $iSlot - Internal download slot.
;                  $bCancel - True to reject the request.
;                  $sPath - Default or an absolute new destination path.
;                  $bHideDefaultUI - Whether to hide WebView2's download UI.
; Return values .: True on success; False with @error on validation/native failure.
; Author ........: mLipok
; Modified ......:
; Remarks .......: A native failure cancels and completes the request to avoid leaving it suspended.
; Related .......: _WebView2_Download_Complete, _WebView2_Download_Cancel
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_Download_Resolve($iSlot, $bCancel, $sPath = Default, $bHideDefaultUI = False)
	Local $bResult = False, $iError = 0, $iExtended = 0
	Do
		Local $oArgs = $__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_PENDING_ARGS]
		Local $oDeferral = $__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_PENDING_DEFERRAL]
		If Not IsObj($oArgs) Or Not IsObj($oDeferral) Then
			$iError = $WEBVIEW2_ERR_NO_MATCH
			ExitLoop
		EndIf
		If Not $bCancel And $sPath <> Default Then
			If Not IsString($sPath) Or Not (StringRegExp($sPath, "^[A-Za-z]:\\") Or StringRegExp($sPath, "^\\\\[^\\]+\\[^\\]+\\")) Or FileExists($sPath) Then
				$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
				ExitLoop
			EndIf
		EndIf
		Local $iResult = $WEBVIEW2_S_OK
		If Not $bCancel And $sPath <> Default Then
			$iResult = $oArgs.put_ResultFilePath($sPath)
			If @error Or $iResult <> $WEBVIEW2_S_OK Then
				$iError = $WEBVIEW2_ERR_HRESULT
				$iExtended = $iResult
				$bCancel = True
			EndIf
		EndIf
		If Not $bCancel And $bHideDefaultUI Then
			$iResult = $oArgs.put_Handled(True)
			If @error Or $iResult <> $WEBVIEW2_S_OK Then
				$iError = $WEBVIEW2_ERR_HRESULT
				$iExtended = $iResult
				$bCancel = True
			EndIf
		EndIf
		If $bCancel Then
			$iResult = $oArgs.put_Cancel(True)
			If (@error Or $iResult <> $WEBVIEW2_S_OK) And Not $iError Then
				$iError = $WEBVIEW2_ERR_HRESULT
				$iExtended = $iResult
			EndIf
		EndIf
		$iResult = $oDeferral.Complete()
		If (@error Or $iResult <> $WEBVIEW2_S_OK) And Not $iError Then
			$iError = $WEBVIEW2_ERR_HRESULT
			$iExtended = $iResult
		EndIf
		$__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_PENDING_ARGS] = Null
		$__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_PENDING_DEFERRAL] = Null
		$bResult = ($iError = 0)
	Until True
	Return SetError($iError, $iExtended, $bResult)
EndFunc   ;==>__WebView2_Download_Resolve

; #INTERNAL_USE_ONLY# ===========================================================================================================
Func __WebView2_Download_Find($iDownload, $bPointer = False)
	For $i = 0 To $__WEBVIEW2_DOWNLOAD_LIMIT - 1
		If $__g_aWebView2_Downloads[$i][$__WEBVIEW2_DOWNLOAD_ID] Then
			If $bPointer And $__g_aWebView2_Downloads[$i][$__WEBVIEW2_DOWNLOAD_PTR] = $iDownload Then Return $i
			If Not $bPointer And $__g_aWebView2_Downloads[$i][$__WEBVIEW2_DOWNLOAD_ID] = $iDownload Then Return $i
		EndIf
	Next
	Return -1
EndFunc   ;==>__WebView2_Download_Find

; #INTERNAL_USE_ONLY# ===========================================================================================================
Func __WebView2_Download_SetCallback($iWebView, $iEvent, $fnCallback)
	Local $iError = 0, $iExtended = 0
	Do
		If Not $__g_aWebView2_DownloadToken[$iWebView] Then
			If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_DOWNLOAD_STARTING) Then
				If Not __WebView2_Callback_Create($__WEBVIEW2_CB_DOWNLOAD_STARTING, __WebView2_DownloadStarting_Invoke, "ptr;ptr;ptr") Then
					$iError = $WEBVIEW2_ERR_CALLBACK
					ExitLoop
				EndIf
			EndIf
			If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_DOWNLOAD_PROGRESS) Then
				If Not __WebView2_Callback_Create($__WEBVIEW2_CB_DOWNLOAD_PROGRESS, __WebView2_DownloadProgress_Invoke, "ptr;ptr;ptr") Then
					$iError = $WEBVIEW2_ERR_CALLBACK
					ExitLoop
				EndIf
			EndIf
			If Not __WebView2_Callback_GetPointer($__WEBVIEW2_CB_DOWNLOAD_STATE) Then
				If Not __WebView2_Callback_Create($__WEBVIEW2_CB_DOWNLOAD_STATE, __WebView2_DownloadState_Invoke, "ptr;ptr;ptr") Then
					$iError = $WEBVIEW2_ERR_CALLBACK
					ExitLoop
				EndIf
			EndIf
			Local $pCore = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CORE_POINTER]
			Local $oCore4 = __WebView2_Frame_QueryInterface($pCore, $WEBVIEW2_IID_ICoreWebView2_4, $WEBVIEW2_DTAG_ICoreWebView2_4)
			$iError = @error
			$iExtended = @extended
			If $iError Then ExitLoop
			Local $tToken = DllStructCreate("int64")
			Local $iResult = $oCore4.add_DownloadStarting(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_DOWNLOAD_STARTING), $tToken)
			If @error Or $iResult <> $WEBVIEW2_S_OK Then
				$iError = $WEBVIEW2_ERR_HRESULT
				$iExtended = $iResult
				ExitLoop
			EndIf
			$__g_aWebView2_DownloadCore4[$iWebView] = $oCore4
			$__g_aWebView2_DownloadToken[$iWebView] = DllStructGetData($tToken, 1)
		EndIf
		Switch $iEvent
			Case $WEBVIEW2_EVENT_DOWNLOAD_STARTING
				$__g_aWebView2_DownloadStartCallback[$iWebView] = $fnCallback
			Case $WEBVIEW2_EVENT_DOWNLOAD_PROGRESS
				$__g_aWebView2_DownloadProgressCallback[$iWebView] = $fnCallback
			Case $WEBVIEW2_EVENT_DOWNLOAD_STATE_CHANGED
				$__g_aWebView2_DownloadStateCallback[$iWebView] = $fnCallback
		EndSwitch
	Until True
	Return SetError($iError, $iExtended, $iError = 0)
EndFunc   ;==>__WebView2_Download_SetCallback

; #INTERNAL_USE_ONLY# ===========================================================================================================
Func __WebView2_DownloadStarting_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf
	Local $iView = __WebView2_Instance_FindByCorePointer($pSender)
	If $iView < 0 Or Not $pArgs Then Return $WEBVIEW2_S_OK
	Local $oArgs = ObjCreateInterface($pArgs, $WEBVIEW2_IID_ICoreWebView2DownloadStartingEventArgs, $WEBVIEW2_DTAG_ICoreWebView2DownloadStartingEventArgs)
	If Not IsObj($oArgs) Then Return $WEBVIEW2_S_OK
	$oArgs.AddRef()
	Local $pOperation = 0
	If $oArgs.get_DownloadOperation($pOperation) <> $WEBVIEW2_S_OK Or Not $pOperation Then Return $WEBVIEW2_S_OK
	Local $oOperation = ObjCreateInterface($pOperation, $WEBVIEW2_IID_ICoreWebView2DownloadOperation, $WEBVIEW2_DTAG_ICoreWebView2DownloadOperation)
	If Not IsObj($oOperation) Then Return $WEBVIEW2_S_OK
	$oOperation.AddRef()
	Local $iSlot = -1
	For $i = 0 To $__WEBVIEW2_DOWNLOAD_LIMIT - 1
		If Not $__g_aWebView2_Downloads[$i][$__WEBVIEW2_DOWNLOAD_ID] Then
			$iSlot = $i
			ExitLoop
		EndIf
	Next
	If $iSlot < 0 Then
		For $i = 0 To $__WEBVIEW2_DOWNLOAD_LIMIT - 1
			If IsObj($__g_aWebView2_Downloads[$i][$__WEBVIEW2_DOWNLOAD_PENDING_DEFERRAL]) Then ContinueLoop
			Local $iOldDownload = $__g_aWebView2_Downloads[$i][$__WEBVIEW2_DOWNLOAD_ID]
			Local $aOld = _WebView2_Download_GetInfo($iOldDownload)
			If @error Or $aOld[5] = $WEBVIEW2_DOWNLOAD_STATE_IN_PROGRESS Then ContinueLoop
			If $aOld[5] = $WEBVIEW2_DOWNLOAD_STATE_INTERRUPTED Then
				Local $bCanResume = _WebView2_Download_CanResume($iOldDownload)
				If @error Or $bCanResume Then ContinueLoop
			EndIf
			__WebView2_Download_Release($i)
			$iSlot = $i
			ExitLoop
		Next
	EndIf
	If $iSlot < 0 Then
		$oArgs.put_Cancel(True)
		Return $WEBVIEW2_S_OK
	EndIf
	Local $tProgress = DllStructCreate("int64"), $tState = DllStructCreate("int64")
	Local $iResult = $oOperation.add_BytesReceivedChanged(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_DOWNLOAD_PROGRESS), $tProgress)
	If @error Or $iResult <> $WEBVIEW2_S_OK Then
		$oArgs.put_Cancel(True)
		Return $WEBVIEW2_S_OK
	EndIf
	$iResult = $oOperation.add_StateChanged(__WebView2_Callback_GetPointer($__WEBVIEW2_CB_DOWNLOAD_STATE), $tState)
	If @error Or $iResult <> $WEBVIEW2_S_OK Then
		$oOperation.remove_BytesReceivedChanged(DllStructGetData($tProgress, 1))
		$oArgs.put_Cancel(True)
		Return $WEBVIEW2_S_OK
	EndIf
	Local $iDownload = $__g_iWebView2_NextDownloadId
	$__g_iWebView2_NextDownloadId += 1
	$__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_ID] = $iDownload
	$__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_VIEW] = $iView
	$__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_PTR] = $pOperation
	$__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_OBJECT] = $oOperation
	$__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_PROGRESS_TOKEN] = DllStructGetData($tProgress, 1)
	$__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_STATE_TOKEN] = DllStructGetData($tState, 1)
	Local $pString = 0, $sURI = "", $sPath = "", $sMime = ""
	If $oOperation.get_Uri($pString) = $WEBVIEW2_S_OK Then $sURI = __WebView2_CoTaskMemString_ReadAndFree($pString)
	$pString = 0
	If $oArgs.get_ResultFilePath($pString) = $WEBVIEW2_S_OK Then $sPath = __WebView2_CoTaskMemString_ReadAndFree($pString)
	$pString = 0
	If $oOperation.get_MimeType($pString) = $WEBVIEW2_S_OK Then $sMime = __WebView2_CoTaskMemString_ReadAndFree($pString)
	Local $fnCallback = $__g_aWebView2_DownloadStartCallback[$iView]
	If IsFunc($fnCallback) Then
		Local $vPolicy = $fnCallback($iView, $iDownload, $sURI, $sPath, $sMime)
		If IsArray($vPolicy) Then
			If UBound($vPolicy) <> 2 Then
				$oArgs.put_Cancel(True)
				Return $WEBVIEW2_S_OK
			EndIf
			Local $sTarget = $vPolicy[0]
			If IsString($sTarget) And (StringRegExp($sTarget, "^[A-Za-z]:\\") Or StringRegExp($sTarget, "^\\\\[^\\]+\\[^\\]+\\")) And Not FileExists($sTarget) Then
				$iResult = $oArgs.put_ResultFilePath($sTarget)
				If $iResult = $WEBVIEW2_S_OK Then
					$oArgs.put_Handled($vPolicy[1] ? True : False)
				Else
					$oArgs.put_Cancel(True)
				EndIf
			Else
				$oArgs.put_Cancel(True)
			EndIf
		ElseIf $vPolicy = $WEBVIEW2_DOWNLOAD_DEFER Then
			Local $pDeferral = 0
			$iResult = $oArgs.GetDeferral($pDeferral)
			If @error Or $iResult <> $WEBVIEW2_S_OK Or Not $pDeferral Then
				$oArgs.put_Cancel(True)
			Else
				Local $oDeferral = ObjCreateInterface($pDeferral, $WEBVIEW2_IID_ICoreWebView2Deferral, $WEBVIEW2_DTAG_ICoreWebView2Deferral)
				If IsObj($oDeferral) Then
					$__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_PENDING_ARGS] = $oArgs
					$__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_PENDING_DEFERRAL] = $oDeferral
				Else
					$oArgs.put_Cancel(True)
				EndIf
			EndIf
		ElseIf $vPolicy = $WEBVIEW2_DOWNLOAD_CANCEL Then
			$oArgs.put_Cancel(True)
		EndIf
	EndIf
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_DownloadStarting_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
Func __WebView2_DownloadProgress_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf, $pArgs
	Local $iSlot = __WebView2_Download_Find($pSender, True)
	If $iSlot < 0 Then Return $WEBVIEW2_S_OK
	Local $iView = $__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_VIEW]
	Local $fnCallback = $__g_aWebView2_DownloadProgressCallback[$iView]
	If IsFunc($fnCallback) Then
		Local $oOperation = $__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_OBJECT]
		Local $iBytes = 0, $iTotal = -1
		$oOperation.get_BytesReceived($iBytes)
		$oOperation.get_TotalBytesToReceive($iTotal)
		$fnCallback($iView, $__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_ID], $iBytes, $iTotal)
	EndIf
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_DownloadProgress_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
Func __WebView2_DownloadState_Invoke($pSelf, $pSender, $pArgs)
	#forceref $pSelf, $pArgs
	Local $iSlot = __WebView2_Download_Find($pSender, True)
	If $iSlot < 0 Then Return $WEBVIEW2_S_OK
	Local $iView = $__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_VIEW]
	Local $fnCallback = $__g_aWebView2_DownloadStateCallback[$iView]
	If IsFunc($fnCallback) Then
		Local $oOperation = $__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_OBJECT]
		Local $iState = 0, $iReason = 0
		$oOperation.get_State($iState)
		$oOperation.get_InterruptReason($iReason)
		$fnCallback($iView, $__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_ID], $iState, $iReason)
	EndIf
	Return $WEBVIEW2_S_OK
EndFunc   ;==>__WebView2_DownloadState_Invoke

; #INTERNAL_USE_ONLY# ===========================================================================================================
Func __WebView2_Download_Release($iSlot)
	If IsObj($__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_PENDING_DEFERRAL]) Then __WebView2_Download_Resolve($iSlot, True)
	Local $oOperation = $__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_OBJECT]
	If IsObj($oOperation) Then
		If $__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_PROGRESS_TOKEN] Then $oOperation.remove_BytesReceivedChanged($__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_PROGRESS_TOKEN])
		If $__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_STATE_TOKEN] Then $oOperation.remove_StateChanged($__g_aWebView2_Downloads[$iSlot][$__WEBVIEW2_DOWNLOAD_STATE_TOKEN])
	EndIf
	For $j = 0 To $__WEBVIEW2_DOWNLOAD_FIELDS - 1
		$__g_aWebView2_Downloads[$iSlot][$j] = Null
	Next
EndFunc   ;==>__WebView2_Download_Release

; #INTERNAL_USE_ONLY# ===========================================================================================================
Func __WebView2_Download_Cleanup($iView)
	For $i = 0 To $__WEBVIEW2_DOWNLOAD_LIMIT - 1
		If $__g_aWebView2_Downloads[$i][$__WEBVIEW2_DOWNLOAD_ID] And $__g_aWebView2_Downloads[$i][$__WEBVIEW2_DOWNLOAD_VIEW] = $iView Then __WebView2_Download_Release($i)
	Next
	If IsObj($__g_aWebView2_DownloadCore4[$iView]) And $__g_aWebView2_DownloadToken[$iView] Then $__g_aWebView2_DownloadCore4[$iView].remove_DownloadStarting($__g_aWebView2_DownloadToken[$iView])
	$__g_aWebView2_DownloadCore4[$iView] = Null
	$__g_aWebView2_DownloadToken[$iView] = 0
	$__g_aWebView2_DownloadStartCallback[$iView] = Null
	$__g_aWebView2_DownloadProgressCallback[$iView] = Null
	$__g_aWebView2_DownloadStateCallback[$iView] = Null
EndFunc   ;==>__WebView2_Download_Cleanup
