# Local draft 4: optional authenticated page-to-AutoIt RPC

## Scope and trust boundary

This layer would sit above the existing web-message and initialization-script APIs. It must not turn every page message into a privileged native command. The host declares an explicit set of allowed methods and trusted HTTPS origins for each view. The default is **no methods allowed**. Navigation to another origin invalidates all pending calls and rotates the session token. The session token is injected only into the intended top-level document at document creation; it must not be placed in a URL, log or persistent storage. A page that can execute arbitrary JavaScript in the trusted origin remains inside the trust boundary; a token does not prevent same-origin XSS.

## Proposed wire protocol, version 1

Page request:

```json
{"protocol":"wv2-rpc/1","kind":"request","session":"opaque-random-token","id":"page-generated-monotonic-id","method":"readSample","params":{"key":"alpha"}}
```

AutoIt response:

```json
{"protocol":"wv2-rpc/1","kind":"response","session":"opaque-random-token","id":"page-generated-monotonic-id","ok":true,"result":{"value":"sample"}}
```

Failure response has `ok:false` and a stable `error` object with `code` and `message`; never include internal paths or secrets. JSON must be parsed as structured data, with bounded byte length and depth. Reject duplicate IDs, unknown methods, wrong protocol/session, untrusted source/origin, and replies for an expired view. The page Promise resolves or rejects exactly once and has a timeout. AutoIt may answer later from its normal event loop; requests requiring a native WebView2 decision remain outside RPC.

## Limits and lifecycle

Proposal: 32 outstanding requests per view, 64 KiB request payload, 64 KiB response payload and 30-second default timeout. The host reports an explicit busy error on overload, rather than dropping a request. Pending calls are rejected on navigation or view destruction. Callbacks are dispatched only after validating origin, protocol, token, ID, method and limits. Only a verified trusted page may invoke allowlisted methods. The bridge is optional and must not modify the existing low-level `_WebView2_PostWebMessageAsJson` or `$WEBVIEW2_EVENT_WEB_MESSAGE_RECEIVED` contract.

## Prerequisites

The native UDF does not currently provide a general JSON parser. A production implementation must select a parser that works under x86/x64 AutoIt without introducing an unapproved runtime dependency, or implement a narrowly scoped, fully bounded decoder. Raw substring checks are not acceptable for security decisions. Token generation must use a cryptographically secure Windows source, not AutoIt's ordinary `Random()`.

## Acceptance checks before integration

Test valid and invalid origins, forged tokens, duplicate IDs, malformed and deeply nested JSON, oversized payloads, overload, navigation before response, view destruction, timeout, and x86/x64 operation. Include an offline example with one harmless allowlisted method and a visible request/result log. This branch contains WIP example `046_RpcPrototype.au3`, which demonstrates one fixed-shape `add(2, 3)` method. It uses a random 128-bit session token, exact trusted page URL, monotonic IDs, four pending slots and delayed responses from the GUI loop. Its strict regex is valid only for that one JSON shape; it is not a general parser or a public UDF API. Bounded x64 and x86 `--smoke` runs reached the page Promise result `AutoIt returned 5`. Manual GUI, malformed-input, navigation and lifetime checks remain before integration.
