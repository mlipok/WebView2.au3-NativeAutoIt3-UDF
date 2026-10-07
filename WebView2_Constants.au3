#include-once
#Tidy_ILC_Pos=44

; #INDEX# =======================================================================================================================
; Title .........: WebView2_Constants.au3
; Description ...: Public constants used by WebView2.au3.
; Author(s) .....: mLipok
; Version .......: 0.5.0
; ===============================================================================================================================

Global Const $WEBVIEW2_VERSION = "0.5.0"
Global Const $WEBVIEW2_NUGET_VERSION = "1.0.4191.47"
Global Const $WEBVIEW2_MAX_INSTANCES = 32

Global Const $WEBVIEW2_LOCATOR_BY_CSS_SELECTOR = "css selector"
Global Const $WEBVIEW2_LOCATOR_BY_XPATH = "xpath"
Global Const $WEBVIEW2_LOCATOR_BY_ID = "id"
Global Const $WEBVIEW2_LOCATOR_BY_NAME = "name"
Global Const $WEBVIEW2_LOCATOR_BY_TAG_NAME = "tag name"
Global Const $WEBVIEW2_LOCATOR_BY_LINK_TEXT = "link text"
Global Const $WEBVIEW2_LOCATOR_BY_PARTIAL_LINK_TEXT = "partial link text"

Global Enum _
		$WEBVIEW2_EVENT_NAVIGATION_STARTING = 1, _
		$WEBVIEW2_EVENT_NAVIGATION_COMPLETED, _
		$WEBVIEW2_EVENT_DOCUMENT_TITLE_CHANGED, _
		$WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED, _
		$WEBVIEW2_EVENT_NEW_WINDOW_REQUESTED

Global Enum _
		$WEBVIEW2_ERR_NONE = 0, _
		$WEBVIEW2_ERR_NOT_INITIALIZED, _
		$WEBVIEW2_ERR_LOADER_NOT_FOUND, _
		$WEBVIEW2_ERR_LOADER_OPEN, _
		$WEBVIEW2_ERR_DLLCALL, _
		$WEBVIEW2_ERR_HRESULT, _
		$WEBVIEW2_ERR_TIMEOUT, _
		$WEBVIEW2_ERR_INVALID_INSTANCE, _
		$WEBVIEW2_ERR_NO_FREE_SLOT, _
		$WEBVIEW2_ERR_CALLBACK, _
		$WEBVIEW2_ERR_BUSY, _
		$WEBVIEW2_ERR_INVALID_PARAMETER, _
		$WEBVIEW2_ERR_RUNTIME_NOT_FOUND, _
		$WEBVIEW2_ERR_NO_MATCH, _
		$WEBVIEW2_ERR_STALE_ELEMENT, _
		$WEBVIEW2_ERR_JAVASCRIPT, _
		$WEBVIEW2_ERR_USER_ABORT

Global Enum _
		$WEBVIEW2_DEBUG_NONE = 0, _
		$WEBVIEW2_DEBUG_ERROR, _
		$WEBVIEW2_DEBUG_INFO, _
		$WEBVIEW2_DEBUG_FULL

Global Const $WEBVIEW2_S_OK = 0
Global Const $WEBVIEW2_S_FALSE = 1
Global Const $WEBVIEW2_RPC_E_CHANGED_MODE = 0x80010106
Global Const $WEBVIEW2_E_NOINTERFACE = 0x80004002
Global Const $WEBVIEW2_E_POINTER = 0x80004003
Global Const $WEBVIEW2_E_INVALID_WINDOW_HANDLE = 0x80070578
Global Const $WEBVIEW2_E_INVALID_STATE = 0x8007139F
