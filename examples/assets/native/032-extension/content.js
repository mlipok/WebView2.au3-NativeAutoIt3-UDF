(() => {
  const banner = document.createElement("div");
  banner.textContent = "Sample extension is enabled";
  banner.style.cssText = "padding:12px;background:#d8f2dc;color:#103a22;font:16px sans-serif";
  document.body.prepend(banner);
})();
