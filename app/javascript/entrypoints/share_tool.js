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

function addText(){
  return
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

function debugSharing(){
  console.log('Modal ID:', modalId);
  console.log('Chart ID:', chartId);
  console.log('Modal Content:', modalContent);
  console.log('Chart Element:', chartElement);
}

document.addEventListener('DOMContentLoaded', function () {
  document.querySelectorAll('[data-modal-toggle]').forEach(modalToggleButton => {
    modalToggleButton.addEventListener('click', function () {
      const modalId = modalToggleButton.getAttribute('data-modal-target');
      const chartId = modalToggleButton.getAttribute('data-chart-id');
      const modalContent = document.querySelector(`#${modalId} .p-4.md\\:p-5.space-y-4`);
      const chartElement = document.getElementById(chartId);
      console.log(chartElement);
      if (chartElement) {
        const originalDisplay = chartElement.style.display;
        console.log('originalDisplay', originalDisplay);
        if(originalDisplay !== 'block'){
          chartElement.style.display = 'block';
        }

        const elementsToHide = document.querySelectorAll('.hide-from-share');
        elementsToHide.forEach(element => {
          element.style.visibility = 'hidden';
        });

        // Temporarily remove hidden rows
        const hiddenRows = document.querySelectorAll('tr.hide-from-share');
        const removedRows = [];
        hiddenRows.forEach(row => {
          if (row.parentNode) {
            removedRows.push({parent: row.parentNode, row: row});
            row.parentNode.removeChild(row);
          }
        });

        addExtraPadding();

        html2canvas(chartElement).then(canvas => {
          addText(canvas);

          modalContent.innerHTML = '';

          const img = new Image();
          img.src = canvas.toDataURL('image/png');
          img.classList.add('w-full', 'rounded-lg');

          modalContent.appendChild(img);

          // Reinsert hidden rows back to their original position
          removedRows.forEach(({parent, row}) => {
            parent.appendChild(row);
          });

          elementsToHide.forEach(element => {
            element.style.visibility = 'visible';
          });
          removeExtraPadding();
          chartElement.style.display = originalDisplay;

          // Add copy functionality
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

          // Add export functionality
          const exportButton = document.querySelector(`#${modalId} .export-button`);
          if (exportButton) {
            exportButton.addEventListener('click', () => {
              const link = document.createElement('a');
              link.href = canvas.toDataURL('image/png');
              link.download = `${modalId}-chart.png`;
              link.click();
            });
          }
        }).catch(err => {
          console.error('Error capturing canvas:', err);
        });
      }
    });
  });
});
