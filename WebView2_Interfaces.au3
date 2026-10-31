#include-once
#Tidy_ILC_Pos=44

; #INDEX# =======================================================================================================================
; Title .........: WebView2_Interfaces.au3
; Description ...: COM interface definitions used by the first public WebView2.au3 API surface.
; Author(s) .....: mLipok
; Version .......: 0.5.0
; Remarks .......: Only parameter types required by the implemented UDF surface are intentionally defined.
; ===============================================================================================================================

Global Const $WEBVIEW2_IID_ICoreWebView2Environment = "{B96D755E-0319-4E92-A296-23436F46A1FC}"
Global Const $WEBVIEW2_IID_ICoreWebView2Controller = "{4D00C0D1-9434-4EB6-8078-8697A560334F}"
Global Const $WEBVIEW2_IID_ICoreWebView2 = "{76ECEACB-0462-4D94-AC83-423A6793775E}"
Global Const $WEBVIEW2_IID_ICoreWebView2_3 = "{A0D6DF20-3B92-416D-AA0C-437A9C727857}"
Global Const $WEBVIEW2_IID_ICoreWebView2_8 = "{E9632730-6E1E-43AB-B7B8-7B2C9E62E094}"
Global Const $WEBVIEW2_IID_ICoreWebView2Settings = "{E562E4F0-D7FA-43AC-8D71-C05150499F00}"
Global Const $WEBVIEW2_IID_ICoreWebView2NavigationStartingEventArgs = "{5B495469-E119-438A-9B18-7604F25F2E49}"
Global Const $WEBVIEW2_IID_ICoreWebView2NavigationCompletedEventArgs = "{30D68B7D-20D9-4752-A9CA-EC8448FBB5C1}"
Global Const $WEBVIEW2_IID_ICoreWebView2WebMessageReceivedEventArgs = "{0F99A40C-E962-4207-9E92-E3D542EFF849}"
Global Const $WEBVIEW2_IID_ICoreWebView2NewWindowRequestedEventArgs = "{34ACB11C-FC37-4418-9132-F9C21D1EAFB9}"

Global Const $WEBVIEW2_IID_ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler = "{4E8A3389-C9D8-4BD2-B6B5-124FEE6CC14D}"
Global Const $WEBVIEW2_IID_ICoreWebView2CreateCoreWebView2ControllerCompletedHandler = "{6C4819F3-C9B7-4260-8127-C9F5BDE7F68C}"
Global Const $WEBVIEW2_IID_ICoreWebView2NavigationStartingEventHandler = "{9ADBE429-F36D-432B-9DDC-F8881FBD76E3}"
Global Const $WEBVIEW2_IID_ICoreWebView2NavigationCompletedEventHandler = "{D33A35BF-1C49-4F98-93AB-006E0533FE1C}"
Global Const $WEBVIEW2_IID_ICoreWebView2DocumentTitleChangedEventHandler = "{F5F2B923-953E-4042-9F95-F3A118E1AFD4}"
Global Const $WEBVIEW2_IID_ICoreWebView2IsDocumentPlayingAudioChangedEventHandler = "{5DEF109A-2F4B-49FA-B7F6-11C39E513328}"
Global Const $WEBVIEW2_IID_ICoreWebView2WebMessageReceivedEventHandler = "{57213F19-00E6-49FA-8E07-898EA01ECBD2}"
Global Const $WEBVIEW2_IID_ICoreWebView2NewWindowRequestedEventHandler = "{D4C185FE-C81C-4989-97AF-2D3FA7AB5651}"
Global Const $WEBVIEW2_IID_ICoreWebView2ExecuteScriptCompletedHandler = "{49511172-CC67-4BCA-9923-137112F4C4CC}"

Global Const $WEBVIEW2_DTAG_ICoreWebView2Environment = _
		"CreateCoreWebView2Controller hresult(hwnd;ptr);" & _
		"CreateWebResourceResponse hresult();" & _
		"get_BrowserVersionString hresult(ptr*);" & _
		"add_NewBrowserVersionAvailable hresult();" & _
		"remove_NewBrowserVersionAvailable hresult();"

Global Const $WEBVIEW2_DTAG_ICoreWebView2Controller = _
		"get_IsVisible hresult(bool*);" & _
		"put_IsVisible hresult(bool);" & _
		"get_Bounds hresult();" & _
		(@AutoItX64 ? "put_Bounds hresult(struct*);" : "put_Bounds hresult(struct);") & _
		"get_ZoomFactor hresult(double*);" & _
		"put_ZoomFactor hresult(double);" & _
		"add_ZoomFactorChanged hresult();" & _
		"remove_ZoomFactorChanged hresult();" & _
		"SetBoundsAndZoomFactor hresult();" & _
		"MoveFocus hresult(int);" & _
		"add_MoveFocusRequested hresult();" & _
		"remove_MoveFocusRequested hresult();" & _
		"add_GotFocus hresult();" & _
		"remove_GotFocus hresult();" & _
		"add_LostFocus hresult();" & _
		"remove_LostFocus hresult();" & _
		"add_AcceleratorKeyPressed hresult();" & _
		"remove_AcceleratorKeyPressed hresult();" & _
		"get_ParentWindow hresult(hwnd*);" & _
		"put_ParentWindow hresult(hwnd);" & _
		"NotifyParentWindowPositionChanged hresult();" & _
		"Close hresult();" & _
		"get_CoreWebView2 hresult(ptr*);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2 = _
		"get_Settings hresult(ptr*);" & _
		"get_Source hresult(ptr*);" & _
		"Navigate hresult(wstr);" & _
		"NavigateToString hresult(wstr);" & _
		"add_NavigationStarting hresult(ptr;struct*);" & _
		"remove_NavigationStarting hresult(int64);" & _
		"add_ContentLoading hresult();" & _
		"remove_ContentLoading hresult();" & _
		"add_SourceChanged hresult();" & _
		"remove_SourceChanged hresult();" & _
		"add_HistoryChanged hresult();" & _
		"remove_HistoryChanged hresult();" & _
		"add_NavigationCompleted hresult(ptr;struct*);" & _
		"remove_NavigationCompleted hresult(int64);" & _
		"add_FrameNavigationStarting hresult();" & _
		"remove_FrameNavigationStarting hresult();" & _
		"add_FrameNavigationCompleted hresult();" & _
		"remove_FrameNavigationCompleted hresult();" & _
		"add_ScriptDialogOpening hresult();" & _
		"remove_ScriptDialogOpening hresult();" & _
		"add_PermissionRequested hresult();" & _
		"remove_PermissionRequested hresult();" & _
		"add_ProcessFailed hresult();" & _
		"remove_ProcessFailed hresult();" & _
		"AddScriptToExecuteOnDocumentCreated hresult(wstr;ptr);" & _
		"RemoveScriptToExecuteOnDocumentCreated hresult(wstr);" & _
		"ExecuteScript hresult(wstr;ptr);" & _
		"CapturePreview hresult();" & _
		"Reload hresult();" & _
		"PostWebMessageAsJson hresult(wstr);" & _
		"PostWebMessageAsString hresult(wstr);" & _
		"add_WebMessageReceived hresult(ptr;struct*);" & _
		"remove_WebMessageReceived hresult(int64);" & _
		"CallDevToolsProtocolMethod hresult(wstr;wstr;ptr);" & _
		"get_BrowserProcessId hresult(uint*);" & _
		"get_CanGoBack hresult(bool*);" & _
		"get_CanGoForward hresult(bool*);" & _
		"GoBack hresult();" & _
		"GoForward hresult();" & _
		"GetDevToolsProtocolEventReceiver hresult();" & _
		"Stop hresult();" & _
		"add_NewWindowRequested hresult(ptr;struct*);" & _
		"remove_NewWindowRequested hresult(int64);" & _
		"add_DocumentTitleChanged hresult(ptr;struct*);" & _
		"remove_DocumentTitleChanged hresult(int64);" & _
		"get_DocumentTitle hresult(ptr*);" & _
		"AddHostObjectToScript hresult();" & _
		"RemoveHostObjectFromScript hresult();" & _
		"OpenDevToolsWindow hresult();" & _
		"add_ContainsFullScreenElementChanged hresult();" & _
		"remove_ContainsFullScreenElementChanged hresult();" & _
		"get_ContainsFullScreenElement hresult(bool*);" & _
		"add_WebResourceRequested hresult();" & _
		"remove_WebResourceRequested hresult();" & _
		"AddWebResourceRequestedFilter hresult();" & _
		"RemoveWebResourceRequestedFilter hresult();" & _
		"add_WindowCloseRequested hresult();" & _
		"remove_WindowCloseRequested hresult();"

; The inherited entries must remain in exact WebView2.idl vtable order.
Global Const $WEBVIEW2_DTAG_ICoreWebView2_3 = $WEBVIEW2_DTAG_ICoreWebView2 & _
		"add_WebResourceResponseReceived hresult();" & _
		"remove_WebResourceResponseReceived hresult();" & _
		"NavigateWithWebResourceRequest hresult();" & _
		"add_DOMContentLoaded hresult();" & _
		"remove_DOMContentLoaded hresult();" & _
		"get_CookieManager hresult();" & _
		"get_Environment hresult();" & _
		"TrySuspend hresult();" & _
		"Resume hresult();" & _
		"get_IsSuspended hresult();" & _
		"SetVirtualHostNameToFolderMapping hresult(wstr;wstr;int);" & _
		"ClearVirtualHostNameToFolderMapping hresult(wstr);"

; ICoreWebView2_4 through _8 append methods in their exact WebView2.idl order.
Global Const $WEBVIEW2_DTAG_ICoreWebView2_8 = $WEBVIEW2_DTAG_ICoreWebView2_3 & _
		"add_FrameCreated hresult();" & _
		"remove_FrameCreated hresult();" & _
		"add_DownloadStarting hresult();" & _
		"remove_DownloadStarting hresult();" & _
		"add_ClientCertificateRequested hresult();" & _
		"remove_ClientCertificateRequested hresult();" & _
		"OpenTaskManagerWindow hresult();" & _
		"PrintToPdf hresult();" & _
		"add_IsMutedChanged hresult();" & _
		"remove_IsMutedChanged hresult();" & _
		"get_IsMuted hresult();" & _
		"put_IsMuted hresult();" & _
		"add_IsDocumentPlayingAudioChanged hresult(ptr;struct*);" & _
		"remove_IsDocumentPlayingAudioChanged hresult(int64);" & _
		"get_IsDocumentPlayingAudio hresult(bool*);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2Settings = _
		"get_IsScriptEnabled hresult(bool*);" & _
		"put_IsScriptEnabled hresult(bool);" & _
		"get_IsWebMessageEnabled hresult(bool*);" & _
		"put_IsWebMessageEnabled hresult(bool);" & _
		"get_AreDefaultScriptDialogsEnabled hresult(bool*);" & _
		"put_AreDefaultScriptDialogsEnabled hresult(bool);" & _
		"get_IsStatusBarEnabled hresult(bool*);" & _
		"put_IsStatusBarEnabled hresult(bool);" & _
		"get_AreDevToolsEnabled hresult(bool*);" & _
		"put_AreDevToolsEnabled hresult(bool);" & _
		"get_AreDefaultContextMenusEnabled hresult(bool*);" & _
		"put_AreDefaultContextMenusEnabled hresult(bool);" & _
		"get_AreHostObjectsAllowed hresult(bool*);" & _
		"put_AreHostObjectsAllowed hresult(bool);" & _
		"get_IsZoomControlEnabled hresult(bool*);" & _
		"put_IsZoomControlEnabled hresult(bool);" & _
		"get_IsBuiltInErrorPageEnabled hresult(bool*);" & _
		"put_IsBuiltInErrorPageEnabled hresult(bool);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2NavigationStartingEventArgs = _
		"get_Uri hresult(ptr*);" & _
		"get_IsUserInitiated hresult(bool*);" & _
		"get_IsRedirected hresult(bool*);" & _
		"get_RequestHeaders hresult(ptr*);" & _
		"get_Cancel hresult(bool*);" & _
		"put_Cancel hresult(bool);" & _
		"get_NavigationId hresult(uint64*);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2NavigationCompletedEventArgs = _
		"get_IsSuccess hresult(bool*);" & _
		"get_WebErrorStatus hresult(int*);" & _
		"get_NavigationId hresult(uint64*);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2NewWindowRequestedEventArgs = _
		"get_Uri hresult(ptr*);" & _
		"put_NewWindow hresult(ptr);" & _
		"get_NewWindow hresult(ptr*);" & _
		"put_Handled hresult(bool);" & _
		"get_Handled hresult(bool*);" & _
		"get_IsUserInitiated hresult(bool*);" & _
		"GetDeferral hresult(ptr*);" & _
		"get_WindowFeatures hresult(ptr*);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2WebMessageReceivedEventArgs = _
		"get_Source hresult(ptr*);" & _
		"get_WebMessageAsJson hresult(ptr*);" & _
		"TryGetWebMessageAsString hresult(ptr*);"
