const assetStatus = document.getElementById('asset-status');
assetStatus.textContent = 'Local JavaScript loaded through the mapped host.';
window.demoCheck = () => location.origin === 'https://udf-virtual-host.example'
  && assetStatus.textContent.includes('Local JavaScript loaded')
  && getComputedStyle(document.querySelector('h1')).color === 'rgb(22, 74, 127)';
document.getElementById('send-message').addEventListener('click', () => {
  window.chrome.webview.postMessage('Message from the mapped folder');
});
