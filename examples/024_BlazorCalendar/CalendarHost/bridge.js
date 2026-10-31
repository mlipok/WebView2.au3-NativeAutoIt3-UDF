(() => {
  const post = message => window.chrome?.webview?.postMessage(message);
  let component;
  window.addEventListener('error', event => post({type:'error', code:'JS_ERROR', message:String(event.message)}));
  window.addEventListener('unhandledrejection', event => post({type:'error', code:'UNHANDLED_REJECTION', message:String(event.reason)}));
  document.addEventListener('dragstart', event => event.preventDefault());
  document.addEventListener('dblclick', event => {
    const slot = event.target.closest?.('[data-range-slot]');
    if (slot && component) component.invokeMethodAsync('DoubleClicked', slot.dataset.rangeSlot)
      .catch(error => post({type:'error', code:'DOUBLE_CLICK', message:String(error)}));
  });
  window.calendarBridge = {
    start(dotnet) {
      component = dotnet;
      window.chrome.webview.addEventListener('message', async event => {
        try { await dotnet.invokeMethodAsync('Receive', JSON.stringify(event.data)); }
        catch (error) { post({type:'error', code:'BRIDGE_RECEIVE', message:String(error)}); }
      });
    },
    send: post
  };
})();
