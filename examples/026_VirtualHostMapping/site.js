"use strict";

const origin = document.getElementById("origin");
const state = document.getElementById("state");
const send = document.getElementById("send");

origin.textContent = window.location.origin;
const cssLoaded = Array.from(document.styleSheets).some((sheet) =>
  sheet.href && new URL(sheet.href).pathname === "/site.css"
);
state.textContent = cssLoaded
  ? "Local JavaScript and CSS loaded successfully."
  : "The local stylesheet did not load.";

if (window.chrome && window.chrome.webview) {
  window.chrome.webview.postMessage({ type: cssLoaded ? "ready" : "error" });
  send.addEventListener("click", () => {
    window.chrome.webview.postMessage({ type: "button" });
    state.textContent = "Message sent to the AutoIt window.";
  });
} else {
  state.textContent = "WebView2 message bridge is unavailable.";
  send.disabled = true;
}
