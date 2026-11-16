(() => {
  'use strict';
  const status = document.getElementById('status');
  const post = data => chrome.webview.postMessage(data);
  try {
    const types = ['bar', 'line', 'pie', 'doughnut', 'radar', 'polarArea', 'scatter', 'bubble', 'mixed'];
    const labels = ['Alpha', 'Beta', 'Gamma'];
    let values = [10, 20, 30];
    let currentType = 'bar';
    let chart;
    function rebuild() {
      if (chart) chart.destroy();
      const cartesian = ['bar', 'line', 'scatter', 'bubble', 'mixed'].includes(currentType);
      const points = currentType === 'scatter' || currentType === 'bubble';
      const data = points ? values.map((y, i) => currentType === 'bubble' ? { x: i + 1, y, r: 8 + i * 4 } : { x: i + 1, y }) : values.slice();
      const datasets = [{ label: 'Sample values', data, backgroundColor: ['#76afd6', '#87c59a', '#e4bb6e'], borderColor: '#2772a8', borderWidth: 2 }];
      if (currentType === 'mixed') datasets.push({ type: 'line', label: 'Same values as a line', data: values.slice(), borderColor: '#b24b4b', backgroundColor: '#b24b4b' });
      chart = new Chart(document.getElementById('chart'), {
      type: currentType === 'mixed' ? 'bar' : currentType,
      data: { labels, datasets },
      options: { responsive: true, maintainAspectRatio: false, animation: false,
        scales: cartesian ? { y: { beginAtZero: true, suggestedMax: 50 }, ...(points ? { x: { min: 0, max: 4, ticks: { stepSize: 1 } } } : {}) } : (currentType === 'radar' || currentType === 'polarArea' ? { r: { beginAtZero: true } } : {}),
        onClick(event, elements) {
          if (!event.native?.isTrusted || !elements.length) return;
          const index = elements[0].index;
          const label = labels[index];
          const value = values[index];
          post({ kind: 'click', caption: `Data item ${label}`, label, value });
          status.textContent = `Clicked ${label}: ${value}`;
        }
      }
      });
    }
    window.setChartType = type => {
      if (!types.includes(type)) throw new Error('Unsupported chart type');
      currentType = type;
      rebuild();
      status.textContent = `Chart type: ${type}. Values: ${values.join(', ')}`;
      post({ kind: 'typeChanged', type });
      return window.readChart();
    };
    window.setSample = nextValues => {
      if (!Array.isArray(nextValues) || nextValues.length !== 3 || !nextValues.every(v => Number.isFinite(v) && v >= 0 && v <= 100)) throw new Error('Expected three values from 0 to 100');
      values = nextValues.slice();
      rebuild();
      status.textContent = `Chart type: ${currentType}. Values: ${values.join(', ')}`;
      post({ kind: 'updated', values });
      return values;
    };
    window.readChart = () => ({ version: Chart.version, type: currentType, values: values.slice(), width: chart.width, height: chart.height });
    rebuild();
    status.textContent = `Chart.js ${Chart.version} ready. Values: 10, 20, 30.`;
    post({ kind: 'ready', version: Chart.version });
  } catch (error) {
    status.textContent = `Chart error: ${error.message}`;
    post({ kind: 'error', message: error.message });
  }
})();
