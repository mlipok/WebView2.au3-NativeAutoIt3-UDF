self.chrome.webview.addEventListener('message', event => {
  const request = event.data;
  if (!request || request.kind !== 'add' || !Array.isArray(request.values)) return;
  const sum = request.values.reduce((total, value) => total + Number(value), 0);
  self.chrome.webview.postMessage({ kind: 'result', sum });
});
self.chrome.webview.postMessage({ kind: 'ready' });
