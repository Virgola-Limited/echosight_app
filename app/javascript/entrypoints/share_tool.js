import html2canvas from 'html2canvas';

function addExtraPadding() {
  document.querySelectorAll('.graph-title-text').forEach(element => {
    element.classList.add('extra-padding');
  });
}

function removeExtraPadding() {
  document.querySelectorAll('.graph-title-text').forEach(element => {
    element.classList.remove('extra-padding');
  });
}

function addText(canvas) {
  const context = canvas.getContext('2d');
  const text = "https://app.echosight.io";
  const fontSize = 20;  // Increased font size
  const padding = 10;

  context.font = `${fontSize}px Arial`;
  context.fillStyle = 'black';
  context.textAlign = 'right';
  context.textBaseline = 'bottom';

  const x = canvas.width - padding;
  const y = canvas.height - padding;

  const textWidth = context.measureText(text).width;
  const textHeight = fontSize;
  context.fillStyle = 'rgba(255, 255, 255, 0.7)';
  context.fillRect(x - textWidth - 5, y - textHeight - 5, textWidth + 10, textHeight + 10);

  context.fillStyle = 'black';
  context.fillText(text, x, y);
}

function hideElements(selector) {
  document.querySelectorAll(selector).forEach(element => {
    element.style.visibility = 'hidden';
  });
}

function showElements(selector) {
  document.querySelectorAll(selector).forEach(element => {
    element.style.visibility = 'visible';
  });
}

function removeElements(selector) {
  const elements = document.querySelectorAll(selector);
  const removedElements = [];
  elements.forEach(element => {
    if (element.parentNode) {
      removedElements.push({ parent: element.parentNode, element });
      element.parentNode.removeChild(element);
    }
  });
  return removedElements;
}

function reinsertElements(removedElements) {
  removedElements.forEach(({ parent, element }) => {
    parent.appendChild(element);
  });
}

function handleCopyButton(canvas, modalId) {
  const copyButton = document.querySelector(`#${modalId} .copy-button`);
  if (copyButton) {
    copyButton.addEventListener('click', () => {
      canvas.toBlob(blob => {
        const item = new ClipboardItem({ 'image/png': blob });
        navigator.clipboard.write([item]).then(() => {
          alert('Image copied to clipboard!');
        }).catch(err => {
          console.error('Failed to copy image: ', err);
        });
      });
    });
  }
}

function handleExportButton(canvas, modalId) {
  const exportButton = document.querySelector(`#${modalId} .export-button`);
  if (exportButton) {
    exportButton.addEventListener('click', () => {
      const link = document.createElement('a');
      link.href = canvas.toDataURL('image/png');
      link.download = `${modalId}-chart.png`;
      link.click();
    });
  }
}

function captureChart(chartElement, modalContent, modalId) {
  addExtraPadding();

  html2canvas(chartElement).then(canvas => {

    modalContent.innerHTML = '';

    const img = new Image();
    img.src = canvas.toDataURL('image/png');
    img.classList.add('w-full', 'rounded-lg');

    modalContent.appendChild(img);

    handleCopyButton(canvas, modalId);
    handleExportButton(canvas, modalId);

    removeExtraPadding();
  }).catch(err => {
    console.error('Error capturing canvas:', err);
  });
}

function setupModalToggle() {
  document.querySelectorAll('[data-modal-toggle]').forEach(modalToggleButton => {
    modalToggleButton.addEventListener('click', function () {
      const modalId = modalToggleButton.getAttribute('data-modal-target');
      const chartId = modalToggleButton.getAttribute('data-chart-id');
      const modalContent = document.querySelector(`#${modalId} .p-4.md\\:p-5.space-y-4`);
      const chartElement = document.getElementById(chartId);

      if (chartElement) {
        const originalDisplay = chartElement.style.display;
        chartElement.style.display = 'block';

        hideElements('.hide-from-share');
        const removedRows = removeElements('tr.hide-from-share');

        captureChart(chartElement, modalContent, modalId);

        reinsertElements(removedRows);
        showElements('.hide-from-share');
        chartElement.style.display = originalDisplay;
      }
    });
  });
}

document.addEventListener('DOMContentLoaded', setupModalToggle);
