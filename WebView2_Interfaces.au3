#include-once
#Tidy_ILC_Pos=44

; #INDEX# =======================================================================================================================
; Title .........: WebView2_Interfaces.au3
; Description ...: COM interface definitions used by the first public WebView2.au3 API surface.
; Author(s) .....: mLipok
; Version .......: 0.6.0
; Remarks .......: Only parameter types required by the implemented UDF surface are intentionally defined.
; ===============================================================================================================================

Global Const $WEBVIEW2_IID_ICoreWebView2Environment = "{B96D755E-0319-4E92-A296-23436F46A1FC}"
Global Const $WEBVIEW2_IID_ICoreWebView2Environment12 = "{F503DB9B-739F-48DD-B151-FDFCF253F54E}"
Global Const $WEBVIEW2_IID_ICoreWebView2SharedBuffer = "{B747A495-0C6F-449E-97B8-2F81E9D6AB43}"
Global Const $WEBVIEW2_IID_ICoreWebView2Controller = "{4D00C0D1-9434-4EB6-8078-8697A560334F}"
Global Const $WEBVIEW2_IID_ICoreWebView2 = "{76ECEACB-0462-4D94-AC83-423A6793775E}"
Global Const $WEBVIEW2_IID_ICoreWebView2_2 = "{9E8F0CF8-E670-4B5E-B2BC-73E061E3184C}"
Global Const $WEBVIEW2_IID_ICoreWebView2_3 = "{A0D6DF20-3B92-416D-AA0C-437A9C727857}"
Global Const $WEBVIEW2_IID_ICoreWebView2_4 = "{20D02D59-6DF2-42DC-BD06-F98A694B1302}"
Global Const $WEBVIEW2_IID_ICoreWebView2_13 = "{F75F09A8-667E-4983-88D6-C8773F315E84}"
Global Const $WEBVIEW2_IID_ICoreWebView2_29 = "{650F917E-CC16-5C8C-9287-B0BBC8A4AB2C}"
Global Const $WEBVIEW2_IID_ICoreWebView2Profile7 = "{7B4C7906-A1AA-4CB4-B723-DB09F813D541}"
Global Const $WEBVIEW2_IID_ICoreWebView2EnvironmentOptions = "{2FDE08A8-1E9A-4766-8C05-95A9CEB9D1C5}"
Global Const $WEBVIEW2_IID_ICoreWebView2EnvironmentOptions6 = "{57D29CC3-C84F-42A0-B0E2-EFFBD5E179DE}"
Global Const $WEBVIEW2_IID_IUnknown = "{00000000-0000-0000-C000-000000000046}"
Global Const $WEBVIEW2_IID_ICoreWebView2Frame = "{F1131A5E-9BA9-11EB-A8B3-0242AC130003}"
Global Const $WEBVIEW2_IID_ICoreWebView2Frame2 = "{7A6A5834-D185-4DBF-B63F-4A9BC43107D4}"
Global Const $WEBVIEW2_IID_ICoreWebView2Frame3 = "{B50D82CC-CC28-481D-9614-CB048895E6A0}"
Global Const $WEBVIEW2_IID_ICoreWebView2Frame4 = "{188782DC-92AA-4732-AB3C-FCC59F6F68B9}"
Global Const $WEBVIEW2_IID_ICoreWebView2Frame5 = "{99D199C4-7305-11EE-B962-0242AC120002}"
Global Const $WEBVIEW2_IID_ICoreWebView2Frame6 = "{0DE611FD-31E9-5DDC-9D71-95EDA26EFF32}"
Global Const $WEBVIEW2_IID_ICoreWebView2Frame7 = "{3598CFA2-D85D-5A9F-9228-4DDE1F59EC64}"
Global Const $WEBVIEW2_IID_ICoreWebView2Frame8 = "{9DEFF655-E3D5-5B8F-9107-52E66B3EC3FC}"
Global Const $WEBVIEW2_IID_ICoreWebView2DedicatedWorkerCreatedEventArgs = "{910C52AF-8129-516D-AB9A-B524E377D8AC}"
Global Const $WEBVIEW2_IID_ICoreWebView2DedicatedWorker = "{66833876-EDBA-5A60-8508-7DA64504A9D2}"
Global Const $WEBVIEW2_IID_ICoreWebView2FrameCreatedEventArgs = "{4D6E7B5E-9BAA-11EB-A8B3-0242AC130003}"
Global Const $WEBVIEW2_IID_ICoreWebView2_8 = "{E9632730-6E1E-43AB-B7B8-7B2C9E62E094}"
Global Const $WEBVIEW2_IID_ICoreWebView2Settings = "{E562E4F0-D7FA-43AC-8D71-C05150499F00}"
Global Const $WEBVIEW2_IID_ICoreWebView2NavigationStartingEventArgs = "{5B495469-E119-438A-9B18-7604F25F2E49}"
Global Const $WEBVIEW2_IID_ICoreWebView2NavigationCompletedEventArgs = "{30D68B7D-20D9-4752-A9CA-EC8448FBB5C1}"
Global Const $WEBVIEW2_IID_ICoreWebView2WebMessageReceivedEventArgs = "{0F99A40C-E962-4207-9E92-E3D542EFF849}"
Global Const $WEBVIEW2_IID_ICoreWebView2NewWindowRequestedEventArgs = "{34ACB11C-FC37-4418-9132-F9C21D1EAFB9}"
Global Const $WEBVIEW2_IID_ICoreWebView2Deferral = "{C10E7F7B-B585-46F0-A623-8BEFBF3E4EE0}"
Global Const $WEBVIEW2_IID_ICoreWebView2PermissionRequestedEventArgs = "{973AE2EF-FF18-4894-8FB2-3C758F046810}"
Global Const $WEBVIEW2_IID_ICoreWebView2PermissionRequestedEventArgs2 = "{74D7127F-9DE6-4200-8734-42D6FB4FF741}"
Global Const $WEBVIEW2_IID_ICoreWebView2PermissionRequestedEventArgs3 = "{E61670BC-3DCE-4177-86D2-C629AE3CB6AC}"
Global Const $WEBVIEW2_IID_ICoreWebView2ScreenCaptureStartingEventArgs = "{892C03FD-AEE3-5EBA-A1FA-6FD2F6484B2B}"
Global Const $WEBVIEW2_IID_ICoreWebView2DownloadStartingEventArgs = "{E99BBE21-43E9-4544-A732-282764EAFA60}"
Global Const $WEBVIEW2_IID_ICoreWebView2DownloadOperation = "{3D6B6CF2-AFE1-44C7-A995-C65117714336}"
Global Const $WEBVIEW2_IID_ICoreWebView2WebResourceResponseReceivedEventArgs = "{D1DB483D-6796-4B8B-80FC-13712BB716F4}"
Global Const $WEBVIEW2_IID_ICoreWebView2WebResourceRequest = "{97055CD4-512C-4264-8B5F-E3F446CEA6A5}"
Global Const $WEBVIEW2_IID_ICoreWebView2WebResourceResponseView = "{79701053-7759-4162-8F7D-F1B3F084928D}"

Global Const $WEBVIEW2_IID_ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler = "{4E8A3389-C9D8-4BD2-B6B5-124FEE6CC14D}"
Global Const $WEBVIEW2_IID_ICoreWebView2CreateCoreWebView2ControllerCompletedHandler = "{6C4819F3-C9B7-4260-8127-C9F5BDE7F68C}"
Global Const $WEBVIEW2_IID_ICoreWebView2NavigationStartingEventHandler = "{9ADBE429-F36D-432B-9DDC-F8881FBD76E3}"
Global Const $WEBVIEW2_IID_ICoreWebView2NavigationCompletedEventHandler = "{D33A35BF-1C49-4F98-93AB-006E0533FE1C}"
Global Const $WEBVIEW2_IID_ICoreWebView2DocumentTitleChangedEventHandler = "{F5F2B923-953E-4042-9F95-F3A118E1AFD4}"
Global Const $WEBVIEW2_IID_ICoreWebView2IsDocumentPlayingAudioChangedEventHandler = "{5DEF109A-2F4B-49FA-B7F6-11C39E513328}"
Global Const $WEBVIEW2_IID_ICoreWebView2IsMutedChangedEventHandler = "{57D90347-CD0E-4952-A4A2-7483A2756F08}"
Global Const $WEBVIEW2_IID_ICoreWebView2WebMessageReceivedEventHandler = "{57213F19-00E6-49FA-8E07-898EA01ECBD2}"
Global Const $WEBVIEW2_IID_ICoreWebView2NewWindowRequestedEventHandler = "{D4C185FE-C81C-4989-97AF-2D3FA7AB5651}"
Global Const $WEBVIEW2_IID_ICoreWebView2FrameCreatedEventHandler = "{38059770-9BAA-11EB-A8B3-0242AC130003}"
Global Const $WEBVIEW2_IID_ICoreWebView2FrameChildFrameCreatedEventHandler = "{569E40E7-46B7-563D-83AE-1073155664D7}"
Global Const $WEBVIEW2_IID_ICoreWebView2FrameDestroyedEventHandler = "{59DD7B4C-9BAA-11EB-A8B3-0242AC130003}"
Global Const $WEBVIEW2_IID_ICoreWebView2FrameNavigationStartingEventHandler = "{E79908BF-2D5D-4968-83DB-263FEA2C1DA3}"
Global Const $WEBVIEW2_IID_ICoreWebView2FrameNavigationCompletedEventHandler = "{609302AD-0E36-4F9A-A210-6A45272842A9}"
Global Const $WEBVIEW2_IID_ICoreWebView2FrameWebMessageReceivedEventHandler = "{E371E005-6D1D-4517-934B-A8F1629C62A5}"
Global Const $WEBVIEW2_IID_ICoreWebView2FramePermissionRequestedEventHandler = "{845D0EDD-8BD8-429B-9915-4821789F23E9}"
Global Const $WEBVIEW2_IID_ICoreWebView2FrameScreenCaptureStartingEventHandler = "{A6C1D8AD-BB80-59C5-895B-FBA1698B9309}"
Global Const $WEBVIEW2_IID_ICoreWebView2ExecuteScriptCompletedHandler = "{49511172-CC67-4BCA-9923-137112F4C4CC}"
Global Const $WEBVIEW2_IID_ICoreWebView2WebResourceResponseReceivedEventHandler = "{7DE9898A-24F5-40C3-A2DE-D4F458E69828}"

Global Const $WEBVIEW2_DTAG_ICoreWebView2Environment = _
		"CreateCoreWebView2Controller hresult(hwnd;ptr);" & _
		"CreateWebResourceResponse hresult();" & _
		"get_BrowserVersionString hresult(ptr*);" & _
		"add_NewBrowserVersionAvailable hresult();" & _
		"remove_NewBrowserVersionAvailable hresult();"

; Environment2 through Environment11 add 16 methods before Environment12.
Global Const $WEBVIEW2_DTAG_ICoreWebView2Environment12 = $WEBVIEW2_DTAG_ICoreWebView2Environment & _
		"CreateWebResourceRequest hresult();" & _
		"CreateCoreWebView2CompositionController hresult();" & _
		"CreateCoreWebView2PointerInfo hresult();" & _
		"GetAutomationProviderForWindow hresult();" & _
		"add_BrowserProcessExited hresult();" & _
		"remove_BrowserProcessExited hresult();" & _
		"CreatePrintSettings hresult();" & _
		"get_UserDataFolder hresult();" & _
		"add_ProcessInfosChanged hresult();" & _
		"remove_ProcessInfosChanged hresult();" & _
		"GetProcessInfos hresult();" & _
		"CreateContextMenuItem hresult();" & _
		"CreateCoreWebView2ControllerOptions hresult();" & _
		"CreateCoreWebView2ControllerWithOptions hresult();" & _
		"CreateCoreWebView2CompositionControllerWithOptions hresult();" & _
		"get_FailureReportFolderPath hresult();" & _
		"CreateSharedBuffer hresult(uint64;ptr*);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2SharedBuffer = _
		"get_Size hresult(uint64*);" & _
		"get_Buffer hresult(ptr*);" & _
		"OpenStream hresult(ptr*);" & _
		"get_FileMappingHandle hresult(ptr*);" & _
		"Close hresult();"

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
		"add_PermissionRequested hresult(ptr;struct*);" & _
		"remove_PermissionRequested hresult(int64);" & _
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
Global Const $WEBVIEW2_DTAG_ICoreWebView2_2 = $WEBVIEW2_DTAG_ICoreWebView2 & _
		"add_WebResourceResponseReceived hresult(ptr;struct*);" & _
		"remove_WebResourceResponseReceived hresult(int64);" & _
		"NavigateWithWebResourceRequest hresult();" & _
		"add_DOMContentLoaded hresult();" & _
		"remove_DOMContentLoaded hresult();" & _
		"get_CookieManager hresult();" & _
		"get_Environment hresult();"

Global Const $WEBVIEW2_DTAG_ICoreWebView2_3 = $WEBVIEW2_DTAG_ICoreWebView2_2 & _
		"TrySuspend hresult();" & _
		"Resume hresult();" & _
		"get_IsSuspended hresult();" & _
		"SetVirtualHostNameToFolderMapping hresult(wstr;wstr;int);" & _
		"ClearVirtualHostNameToFolderMapping hresult(wstr);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2WebResourceResponseReceivedEventArgs = _
		"get_Request hresult(ptr*);" & _
		"get_Response hresult(ptr*);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2WebResourceRequest = _
		"get_Uri hresult(ptr*);" & _
		"put_Uri hresult(wstr);" & _
		"get_Method hresult(ptr*);" & _
		"put_Method hresult(wstr);" & _
		"get_Content hresult(ptr*);" & _
		"put_Content hresult(ptr);" & _
		"get_Headers hresult(ptr*);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2WebResourceResponseView = _
		"get_Headers hresult(ptr*);" & _
		"get_StatusCode hresult(int*);" & _
		"get_ReasonPhrase hresult(ptr*);" & _
		"GetContent hresult(ptr);"

; ICoreWebView2_4 through _8 append methods in their exact WebView2.idl order.
Global Const $WEBVIEW2_DTAG_ICoreWebView2_4 = $WEBVIEW2_DTAG_ICoreWebView2_3 & _
		"add_FrameCreated hresult(ptr;struct*);" & _
		"remove_FrameCreated hresult(int64);" & _
		"add_DownloadStarting hresult(ptr;struct*);" & _
		"remove_DownloadStarting hresult(int64);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2DownloadStartingEventArgs = _
		"get_DownloadOperation hresult(ptr*);" & _
		"get_Cancel hresult(bool*);" & _
		"put_Cancel hresult(bool);" & _
		"get_ResultFilePath hresult(ptr*);" & _
		"put_ResultFilePath hresult(wstr);" & _
		"get_Handled hresult(bool*);" & _
		"put_Handled hresult(bool);" & _
		"GetDeferral hresult(ptr*);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2DownloadOperation = _
		"add_BytesReceivedChanged hresult(ptr;struct*);" & _
		"remove_BytesReceivedChanged hresult(int64);" & _
		"add_EstimatedEndTimeChanged hresult();" & _
		"remove_EstimatedEndTimeChanged hresult();" & _
		"add_StateChanged hresult(ptr;struct*);" & _
		"remove_StateChanged hresult(int64);" & _
		"get_Uri hresult(ptr*);" & _
		"get_ContentDisposition hresult(ptr*);" & _
		"get_MimeType hresult(ptr*);" & _
		"get_TotalBytesToReceive hresult(int64*);" & _
		"get_BytesReceived hresult(int64*);" & _
		"get_EstimatedEndTime hresult(ptr*);" & _
		"get_ResultFilePath hresult(ptr*);" & _
		"get_State hresult(int*);" & _
		"get_InterruptReason hresult(int*);" & _
		"Cancel hresult();" & _
		"Pause hresult();" & _
		"Resume hresult();" & _
		"get_CanResume hresult(bool*);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2_8 = $WEBVIEW2_DTAG_ICoreWebView2_4 & _
		"add_ClientCertificateRequested hresult();" & _
		"remove_ClientCertificateRequested hresult();" & _
		"OpenTaskManagerWindow hresult();" & _
		"PrintToPdf hresult();" & _
		"add_IsMutedChanged hresult(ptr;struct*);" & _
		"remove_IsMutedChanged hresult(int64);" & _
		"get_IsMuted hresult(bool*);" & _
		"put_IsMuted hresult(bool);" & _
		"add_IsDocumentPlayingAudioChanged hresult(ptr;struct*);" & _
		"remove_IsDocumentPlayingAudioChanged hresult(int64);" & _
		"get_IsDocumentPlayingAudio hresult(bool*);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2Frame = _
		"get_Name hresult(ptr*);" & _
		"add_NameChanged hresult();" & _
		"remove_NameChanged hresult();" & _
		"AddHostObjectToScriptWithOrigins hresult(wstr;ptr;uint;ptr);" & _
		"RemoveHostObjectFromScript hresult(wstr);" & _
		"add_Destroyed hresult(ptr;struct*);" & _
		"remove_Destroyed hresult(int64);" & _
		"IsDestroyed hresult(bool*);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2Frame2 = $WEBVIEW2_DTAG_ICoreWebView2Frame & _
		"add_NavigationStarting hresult(ptr;struct*);" & _
		"remove_NavigationStarting hresult(int64);" & _
		"add_ContentLoading hresult();" & _
		"remove_ContentLoading hresult();" & _
		"add_NavigationCompleted hresult(ptr;struct*);" & _
		"remove_NavigationCompleted hresult(int64);" & _
		"add_DOMContentLoaded hresult();" & _
		"remove_DOMContentLoaded hresult();" & _
		"ExecuteScript hresult(wstr;ptr);" & _
		"PostWebMessageAsJson hresult(wstr);" & _
		"PostWebMessageAsString hresult(wstr);" & _
		"add_WebMessageReceived hresult(ptr;struct*);" & _
		"remove_WebMessageReceived hresult(int64);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2Frame3 = $WEBVIEW2_DTAG_ICoreWebView2Frame2 & _
		"add_PermissionRequested hresult(ptr;struct*);" & _
		"remove_PermissionRequested hresult(int64);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2Frame4 = $WEBVIEW2_DTAG_ICoreWebView2Frame3 & _
		"PostSharedBufferToScript hresult(ptr;int;wstr);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2Frame5 = $WEBVIEW2_DTAG_ICoreWebView2Frame4 & _
		"get_FrameId hresult(uint*);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2Frame6 = $WEBVIEW2_DTAG_ICoreWebView2Frame5 & _
		"add_ScreenCaptureStarting hresult(ptr;struct*);" & _
		"remove_ScreenCaptureStarting hresult(int64);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2Frame7 = $WEBVIEW2_DTAG_ICoreWebView2Frame6 & _
		"add_FrameCreated hresult(ptr;struct*);" & _
		"remove_FrameCreated hresult(int64);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2Frame8 = $WEBVIEW2_DTAG_ICoreWebView2Frame7 & _
		"add_DedicatedWorkerCreated hresult(ptr;struct*);" & _
		"remove_DedicatedWorkerCreated hresult(int64);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2DedicatedWorkerCreatedEventArgs = _
		"get_OriginalSourceFrameInfo hresult(ptr*);" & _
		"get_Worker hresult(ptr*);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2DedicatedWorker = _
		"get_ScriptUri hresult(ptr*);" & _
		"add_DedicatedWorkerCreated hresult(ptr;struct*);" & _
		"remove_DedicatedWorkerCreated hresult(int64);" & _
		"add_Destroying hresult(ptr;struct*);" & _
		"remove_Destroying hresult(int64);" & _
		"add_WebMessageReceived hresult(ptr;struct*);" & _
		"remove_WebMessageReceived hresult(int64);" & _
		"PostWebMessageAsJson hresult(wstr);" & _
		"PostWebMessageAsString hresult(wstr);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2FrameCreatedEventArgs = "get_Frame hresult(ptr*);"

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

Global Const $WEBVIEW2_DTAG_ICoreWebView2Deferral = "Complete hresult();"

Global Const $WEBVIEW2_DTAG_ICoreWebView2PermissionRequestedEventArgs = _
		"get_Uri hresult(ptr*);" & _
		"get_PermissionKind hresult(int*);" & _
		"get_IsUserInitiated hresult(bool*);" & _
		"get_State hresult(int*);" & _
		"put_State hresult(int);" & _
		"GetDeferral hresult(ptr*);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2PermissionRequestedEventArgs3 = _
		$WEBVIEW2_DTAG_ICoreWebView2PermissionRequestedEventArgs & _
		"get_Handled hresult(bool*);" & _
		"put_Handled hresult(bool);" & _
		"get_SavesInProfile hresult(bool*);" & _
		"put_SavesInProfile hresult(bool);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2PermissionRequestedEventArgs2 = _
		$WEBVIEW2_DTAG_ICoreWebView2PermissionRequestedEventArgs & _
		"get_Handled hresult(bool*);" & _
		"put_Handled hresult(bool);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2ScreenCaptureStartingEventArgs = _
		"get_Cancel hresult(bool*);" & _
		"put_Cancel hresult(bool);" & _
		"get_Handled hresult(bool*);" & _
		"put_Handled hresult(bool);" & _
		"get_OriginalSourceFrameInfo hresult(ptr*);" & _
		"GetDeferral hresult(ptr*);"

Global Const $WEBVIEW2_DTAG_ICoreWebView2WebMessageReceivedEventArgs = _
		"get_Source hresult(ptr*);" & _
		"get_WebMessageAsJson hresult(ptr*);" & _
		"TryGetWebMessageAsString hresult(ptr*);"
