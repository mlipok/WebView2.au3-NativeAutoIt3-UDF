(() => {
  'use strict';
  const protocol = 'wv2-rpc/1';
  const button = document.getElementById('add');
  const result = document.getElementById('result');
  const pending = new Map();
  let session = '';
  let nextId = 0;

  function call(method, params) {
    if (!session) return Promise.reject(new Error('No authorized session'));
    if (pending.size >= 4) return Promise.reject(new Error('Too many pending requests'));
    const id = ++nextId;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        pending.delete(id);
        reject(new Error('AutoIt response timeout'));
      }, 5000);
      pending.set(id, { resolve, reject, timer });
      chrome.webview.postMessage({ protocol, kind: 'request', session, id, method, params });
    });
  }

  chrome.webview.addEventListener('message', event => {
    const data = event.data;
    if (!data || data.protocol !== protocol) return;
    if (data.kind === 'session') {
      if (typeof data.session !== 'string' || !/^[0-9A-F]{32}$/.test(data.session)) return;
      for (const item of pending.values()) {
        clearTimeout(item.timer);
        item.reject(new Error('Session changed'));
      }
      pending.clear();
      session = data.session;
      nextId = 0;
      button.disabled = false;
      result.textContent = 'Authorized session ready. Click Add sample values.';
      return;
    }
    if (data.kind !== 'response' || data.session !== session || !Number.isSafeInteger(data.id)) return;
    const item = pending.get(data.id);
    if (!item) return;
    pending.delete(data.id);
    clearTimeout(item.timer);
    if (data.ok === true) item.resolve(data.result);
    else item.reject(new Error(data.error || 'AutoIt rejected the request'));
  });

  async function addAndShow() {
    result.textContent = 'Waiting for AutoIt...';
    try {
      const value = await call('add', [2, 3]);
      result.textContent = `AutoIt returned ${value}. Expected: 5.`;
    } catch (error) {
      result.textContent = `Request failed: ${error.message}`;
    }
  }

  button.addEventListener('click', event => {
    if (!event.isTrusted) return;
    chrome.webview.postMessage({ protocol, kind: 'click', caption: button.textContent });
    addAndShow();
  });

  window.__rpcSmoke = addAndShow;

  chrome.webview.postMessage({ protocol, kind: 'ready' });
})();
