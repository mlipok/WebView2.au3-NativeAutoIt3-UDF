# Example 050: native HTTP authentication

Run `examples/050_HttpAuthentication.au3` with AutoIt x86 or x64 from a complete project copy, including the matching `bin/x86` and `bin/x64` loader folders. The example includes the public UDF directly. No Python, server executable, download, external account or Internet connection is needed.

The main window opens maximized with its title bar and Windows taskbar retained. Its native green log identifies real AutoIt button clicks and subsequent operations; WebView2 shows the local page, and the yellow guide explains the test. The separate owned WebView-only popup follows the existing overlay workaround; resize/move geometry is handled explicitly.

## Test procedure

1. Click **[Automatic login]**. AutoIt should supply the dummy `demo` / `demo` pair and the page should show **Authentication accepted**. The log reports the native request and the server's successful response without printing the password.
2. Click **[Ask for credentials]**. A separate AutoIt-owned popup should display the requesting server URI and authentication challenge, **[User name]** and masked **[Password]** inputs, and **[Log in]** / **[Cancel]**. The fields start with the dummy pair. **[Log in]** completes the retained native request; **[Cancel]**, the popup close button or the 60-second host timeout cancels it. The popup is created from the ordinary GUI loop, never inside the native callback.
3. Click **[Cancel authentication]**. The host should cancel the request and the server must not grant access. WebView2 may show its own failed-navigation/error document; this is not a credential popup.
4. Click **[Wrong password]**. The server should reject the first supplied pair. The host cancels the repeated challenge instead of retrying indefinitely.
5. Click **[Timeout (5 s)]**. The pending request should be cancelled after about five seconds while the AutoIt window stays responsive. **[Leave page]** navigates back to the public local page and invalidates pending requests. Closing the example cancels requests and closes only its own sockets.

## How the technology works

HTTP authentication is a server challenge, not a username/password form in HTML. The example's TCP server binds only to `127.0.0.1` on a free high port. Protected requests receive HTTP 401 with `WWW-Authenticate: Basic`. WebView2 raises the native `BasicAuthenticationRequested` event; AutoIt can supply credentials, cancel, or retain a deferral and respond later. All test credentials are fictitious. Loopback HTTP is deliberate for this offline fixture; use HTTPS for real remote credentials.

Each test starts a new listener port and realm, forcing a fresh authentication challenge instead of allowing cached credentials to bypass it. The server accepts only bounded GET headers, emits short deterministic ASCII pages, closes responses, and never logs Authorization headers. It runs in the same AutoIt event loop as the GUI; its TCP timeout is set to 1 ms so an idle accepted connection does not stall the interface. It creates no firewall rules and does not install anything.

A successful setter/deferral completion is not proof that a server accepted credentials. During the tested flow, the first 401 can produce `NavigationCompleted(False, 17)` (credentials required), followed by the successful authenticated navigation. The smoke test therefore checks server acceptance and successful subsequent navigation separately. A cancelled attempt can end with more than one navigation-completion event.

## Validation boundary

The bounded `--smoke` path uses hidden windows and a unique profile, exercises immediate and deferred success, invalid input without consuming a live request, duplicate responses, explicit cancellation, invalid callback decisions, wrong-password retry cancellation, timeout, navigation cancellation, destruction, controller-slot reuse and cleanup with a pending request. It also checks two concurrent existing async-script requests because native callback indexes share the same internal pool. x86 and x64 passed these checks.

**WIP:** the actual visible credential popup, button sequence and resized layout still need interactive confirmation. No real remote account, proxy, Digest, NTLM, HTTPS server, registry-overflow case or older Runtime was tested. Default browser behavior without registering the new callback is preserved by the opt-in implementation.
