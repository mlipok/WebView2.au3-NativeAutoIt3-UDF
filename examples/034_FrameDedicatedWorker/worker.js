self.onmessage = event => {
  self.postMessage('Worker replied to ' + event.data + ' inside the iframe.');
};
