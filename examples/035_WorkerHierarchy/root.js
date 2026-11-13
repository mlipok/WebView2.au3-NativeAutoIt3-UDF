let child = null;
self.chrome.webview.addEventListener('message', event => {
  const request = event.data;
  if (!request) return;
  if (request.kind === 'spawn-child' && !child) {
    child = new Worker('child.js');
  } else if (request.kind === 'add' && Array.isArray(request.values)) {
    const sum = request.values.reduce((total, value) => total + Number(value), 0);
    self.chrome.webview.postMessage({ kind: 'result', sum });
  }
});
self.chrome.webview.postMessage({ kind: 'ready' });
