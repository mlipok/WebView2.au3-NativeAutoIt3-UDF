#include-once
#Tidy_ILC_Pos=44

; #INDEX# =======================================================================================================================
; Title .........: WebView2_EventQueue.au3
; Description ...: Opt-in bounded delivery of copied WebView2 notification data from the AutoIt GUI loop.
; Author(s) .....: mLipok
; Version .......: 0.6.0
; ===============================================================================================================================

Global Const $__WEBVIEW2_EVENT_QUEUE_MAX = 64
Global Enum _
		$__WEBVIEW2_QUEUE_KIND, _
		$__WEBVIEW2_QUEUE_VALUE1, _
		$__WEBVIEW2_QUEUE_VALUE2, _
		$__WEBVIEW2_QUEUE_VALUE3, _
		$__WEBVIEW2_QUEUE_FIELDS
Global $__g_aWebView2_EventQueue[$WEBVIEW2_MAX_INSTANCES][$__WEBVIEW2_EVENT_QUEUE_MAX][$__WEBVIEW2_QUEUE_FIELDS]
Global $__g_aWebView2_EventQueueEnabled[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_EventQueueCapacity[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_EventQueueHead[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_EventQueueCount[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_EventQueueDropped[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_EventQueueDispatching[$WEBVIEW2_MAX_INSTANCES]
Global $__g_aWebView2_EventQueueGeneration[$WEBVIEW2_MAX_INSTANCES]

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_EventQueue_Enable
; Description ...: Selects queued delivery for three observational callback types on one view.
; Syntax ........: _WebView2_EventQueue_Enable($iWebView[, $iCapacity = 32])
; Parameters ....: $iWebView - Active WebView2 instance ID.
;                  $iCapacity - Maximum pending notifications, from 1 through 64.
; Return values .: True on success; False with @error on invalid view or capacity.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Register callbacks before navigation; dispatch from the ordinary GUI loop. Other events remain direct.
; Related .......: _WebView2_EventQueue_Dispatch, _WebView2_EventQueue_GetStats
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_EventQueue_Enable($iWebView, $iCapacity = 32)
	Local $bValue = False, $iError = 0
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$iError = $WEBVIEW2_ERR_INVALID_INSTANCE
			ExitLoop 1
		EndIf
		If Not IsInt($iCapacity) Or $iCapacity < 1 Or $iCapacity > $__WEBVIEW2_EVENT_QUEUE_MAX Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		__WebView2_EventQueue_Reset($iWebView)
		$__g_aWebView2_EventQueueCapacity[$iWebView] = $iCapacity
		$__g_aWebView2_EventQueueEnabled[$iWebView] = True
		$bValue = True
	Until True
	If $iError Then __WebView2_Error("_WebView2_EventQueue_Enable", $iError, "Unable to enable the notification queue.", 0)
	Return SetError($iError, 0, $bValue)
EndFunc   ;==>_WebView2_EventQueue_Enable

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_EventQueue_Disable
; Description ...: Discards pending notifications and restores direct delivery for one view.
; Syntax ........: _WebView2_EventQueue_Disable($iWebView)
; Parameters ....: $iWebView - Active WebView2 instance ID.
; Return values .: True on success; False with @error for an invalid view.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Does not unregister callbacks.
; Related .......: _WebView2_EventQueue_Enable
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_EventQueue_Disable($iWebView)
	Local $bValue = False, $iError = 0
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$iError = $WEBVIEW2_ERR_INVALID_INSTANCE
			ExitLoop 1
		EndIf
		__WebView2_EventQueue_Reset($iWebView)
		$bValue = True
	Until True
	If $iError Then __WebView2_Error("_WebView2_EventQueue_Disable", $iError, "Invalid WebView2 instance.", 0)
	Return SetError($iError, 0, $bValue)
EndFunc   ;==>_WebView2_EventQueue_Disable

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_EventQueue_Dispatch
; Description ...: Calls registered host callbacks for a bounded number of queued notifications.
; Syntax ........: _WebView2_EventQueue_Dispatch($iWebView[, $iMaximum = 32])
; Parameters ....: $iWebView - Active WebView2 instance ID.
;                  $iMaximum - Maximum notifications processed on this call, from 1 through 64.
; Return values .: Number dispatched; -1 with @error on invalid input or recursive dispatch.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Call in the application GUI loop. A host callback may enqueue later notifications.
; Related .......: _WebView2_EventQueue_Enable, _WebView2_EventQueue_GetStats
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_EventQueue_Dispatch($iWebView, $iMaximum = 32)
	Local $iValue = -1, $iError = 0
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$iError = $WEBVIEW2_ERR_INVALID_INSTANCE
			ExitLoop 1
		EndIf
		If Not IsInt($iMaximum) Or $iMaximum < 1 Or $iMaximum > $__WEBVIEW2_EVENT_QUEUE_MAX Or Not $__g_aWebView2_EventQueueEnabled[$iWebView] Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		If $__g_aWebView2_EventQueueDispatching[$iWebView] Then
			$iError = $WEBVIEW2_ERR_BUSY
			ExitLoop 1
		EndIf
		Local $iGeneration = $__g_aWebView2_EventQueueGeneration[$iWebView]
		$__g_aWebView2_EventQueueDispatching[$iWebView] = True
		$iValue = 0
		While $iValue < $iMaximum And $__g_aWebView2_EventQueueCount[$iWebView] > 0
			Local $iHead = $__g_aWebView2_EventQueueHead[$iWebView]
			Local $iKind = $__g_aWebView2_EventQueue[$iWebView][$iHead][$__WEBVIEW2_QUEUE_KIND]
			Local $v1 = $__g_aWebView2_EventQueue[$iWebView][$iHead][$__WEBVIEW2_QUEUE_VALUE1]
			Local $v2 = $__g_aWebView2_EventQueue[$iWebView][$iHead][$__WEBVIEW2_QUEUE_VALUE2]
			Local $v3 = $__g_aWebView2_EventQueue[$iWebView][$iHead][$__WEBVIEW2_QUEUE_VALUE3]
			For $iField = 0 To $__WEBVIEW2_QUEUE_FIELDS - 1
				$__g_aWebView2_EventQueue[$iWebView][$iHead][$iField] = 0
			Next
			$__g_aWebView2_EventQueueHead[$iWebView] = Mod($iHead + 1, $__g_aWebView2_EventQueueCapacity[$iWebView])
			$__g_aWebView2_EventQueueCount[$iWebView] -= 1
			Local $fnCallback = Null
			Switch $iKind
				Case $WEBVIEW2_EVENT_NAVIGATION_COMPLETED
					$fnCallback = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CB_NAV_COMPLETE]
					If IsFunc($fnCallback) Then Call($fnCallback, $iWebView, $v1, $v2, $v3)
				Case $WEBVIEW2_EVENT_DOCUMENT_TITLE_CHANGED
					$fnCallback = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CB_TITLE]
					If IsFunc($fnCallback) Then Call($fnCallback, $iWebView, $v1)
				Case $WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED
					$fnCallback = $__g_aWebView2_Instances[$iWebView][$__WEBVIEW2_INSTANCE_CB_MESSAGE]
					If IsFunc($fnCallback) Then Call($fnCallback, $iWebView, $v1, $v2, $v3)
			EndSwitch
			$iValue += 1
			If $__g_aWebView2_EventQueueGeneration[$iWebView] <> $iGeneration Then ExitLoop
		WEnd
		If $__g_aWebView2_EventQueueGeneration[$iWebView] = $iGeneration Then $__g_aWebView2_EventQueueDispatching[$iWebView] = False
	Until True
	If $iError Then __WebView2_Error("_WebView2_EventQueue_Dispatch", $iError, "Unable to dispatch the notification queue.", 0)
	Return SetError($iError, 0, $iValue)
EndFunc   ;==>_WebView2_EventQueue_Dispatch

; #FUNCTION# ====================================================================================================================
; Name ..........: _WebView2_EventQueue_GetStats
; Description ...: Reads current queue depth, dropped count and configured capacity.
; Syntax ........: _WebView2_EventQueue_GetStats($iWebView)
; Parameters ....: $iWebView - Active WebView2 instance ID.
; Return values .: Array [queued, dropped, capacity]; empty array with @error for an invalid or disabled view.
; Author ........: mLipok
; Modified ......:
; Remarks .......: The dropped counter advances for each newest notification rejected on overflow.
; Related .......: _WebView2_EventQueue_Dispatch
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _WebView2_EventQueue_GetStats($iWebView)
	Local $aStats[3], $iError = 0
	Do
		If Not __WebView2_Instance_IsValid($iWebView) Then
			$iError = $WEBVIEW2_ERR_INVALID_INSTANCE
			ExitLoop 1
		EndIf
		If Not $__g_aWebView2_EventQueueEnabled[$iWebView] Then
			$iError = $WEBVIEW2_ERR_INVALID_PARAMETER
			ExitLoop 1
		EndIf
		$aStats[0] = $__g_aWebView2_EventQueueCount[$iWebView]
		$aStats[1] = $__g_aWebView2_EventQueueDropped[$iWebView]
		$aStats[2] = $__g_aWebView2_EventQueueCapacity[$iWebView]
	Until True
	If $iError Then __WebView2_Error("_WebView2_EventQueue_GetStats", $iError, "Queue is unavailable.", 0)
	Return SetError($iError, 0, $aStats)
EndFunc   ;==>_WebView2_EventQueue_GetStats

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_EventQueue_IsEnabled
; Description ...: Checks whether a valid view selected queued notification delivery.
; Syntax ........: __WebView2_EventQueue_IsEnabled($iWebView)
; Parameters ....: $iWebView - Internal view slot.
; Return values .: Boolean.
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: __WebView2_EventQueue_Push
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_EventQueue_IsEnabled($iWebView)
	Return $iWebView >= 0 And $iWebView < $WEBVIEW2_MAX_INSTANCES And $__g_aWebView2_EventQueueEnabled[$iWebView]
EndFunc   ;==>__WebView2_EventQueue_IsEnabled

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_EventQueue_Push
; Description ...: Copies primitive event values into a per-view ring buffer.
; Syntax ........: __WebView2_EventQueue_Push($iWebView, $iKind[, $v1 = 0[, $v2 = 0[, $v3 = 0]]])
; Parameters ....: View slot, event type and up to three copied values.
; Return values .: True if enqueued; False if full or disabled.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Rejects the newest notification on overflow and increments the drop counter.
; Related .......: _WebView2_EventQueue_Dispatch
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_EventQueue_Push($iWebView, $iKind, $v1 = 0, $v2 = 0, $v3 = 0)
	Local $bValue = False
	Do
		If Not __WebView2_EventQueue_IsEnabled($iWebView) Then ExitLoop 1
		If $__g_aWebView2_EventQueueCount[$iWebView] >= $__g_aWebView2_EventQueueCapacity[$iWebView] Then
			$__g_aWebView2_EventQueueDropped[$iWebView] += 1
			ExitLoop 1
		EndIf
		Local $iTail = Mod($__g_aWebView2_EventQueueHead[$iWebView] + $__g_aWebView2_EventQueueCount[$iWebView], $__g_aWebView2_EventQueueCapacity[$iWebView])
		$__g_aWebView2_EventQueue[$iWebView][$iTail][$__WEBVIEW2_QUEUE_KIND] = $iKind
		$__g_aWebView2_EventQueue[$iWebView][$iTail][$__WEBVIEW2_QUEUE_VALUE1] = $v1
		$__g_aWebView2_EventQueue[$iWebView][$iTail][$__WEBVIEW2_QUEUE_VALUE2] = $v2
		$__g_aWebView2_EventQueue[$iWebView][$iTail][$__WEBVIEW2_QUEUE_VALUE3] = $v3
		$__g_aWebView2_EventQueueCount[$iWebView] += 1
		$bValue = True
	Until True
	Return $bValue
EndFunc   ;==>__WebView2_EventQueue_Push

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WebView2_EventQueue_Reset
; Description ...: Invalidates all queued records when a view is destroyed or delivery mode changes.
; Syntax ........: __WebView2_EventQueue_Reset($iWebView)
; Parameters ....: $iWebView - Internal view slot.
; Return values .: None.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Generation protects dispatch if a callback destroys/recreates its view.
; Related .......: _WebView2_EventQueue_Disable
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WebView2_EventQueue_Reset($iWebView)
	For $iRow = 0 To $__WEBVIEW2_EVENT_QUEUE_MAX - 1
		For $iField = 0 To $__WEBVIEW2_QUEUE_FIELDS - 1
			$__g_aWebView2_EventQueue[$iWebView][$iRow][$iField] = 0
		Next
	Next
	$__g_aWebView2_EventQueueEnabled[$iWebView] = False
	$__g_aWebView2_EventQueueCapacity[$iWebView] = 0
	$__g_aWebView2_EventQueueHead[$iWebView] = 0
	$__g_aWebView2_EventQueueCount[$iWebView] = 0
	$__g_aWebView2_EventQueueDropped[$iWebView] = 0
	$__g_aWebView2_EventQueueDispatching[$iWebView] = False
	$__g_aWebView2_EventQueueGeneration[$iWebView] += 1
	Return
EndFunc   ;==>__WebView2_EventQueue_Reset
