/**
 * Reusable Visualization Components for PowerReview
 * Provides chart rendering functions for consistent data visualization
 */

export interface ChartOptions {
  width?: number;
  height?: number;
  colors?: string[];
  animate?: boolean;
  showLegend?: boolean;
  showTooltip?: boolean;
}

export interface DataPoint {
  label: string;
  value: number;
  color?: string;
  metadata?: any;
}

export interface TimeSeriesData {
  timestamp: Date;
  value: number;
  series?: string;
}

/**
 * Creates an animated donut chart
 */
export function createDonutChart(
  container: HTMLElement,
  data: DataPoint[],
  options: ChartOptions = {}
): void {
  const {
    width = 300,
    height = 300,
    colors = ['#6366f1', '#3b82f6', '#06b6d4', '#10b981', '#f59e0b', '#ef4444'],
    animate = true,
    showTooltip = true
  } = options;

  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  svg.setAttribute('width', width.toString());
  svg.setAttribute('height', height.toString());
  svg.setAttribute('viewBox', `0 0 ${width} ${height}`);

  const centerX = width / 2;
  const centerY = height / 2;
  const outerRadius = Math.min(width, height) / 2 - 20;
  const innerRadius = outerRadius * 0.6;

  const total = data.reduce((sum, d) => sum + d.value, 0);
  let currentAngle = -Math.PI / 2;

  // Create tooltip element
  const tooltip = document.createElement('div');
  tooltip.style.cssText = `
    position: absolute;
    background: #1e293b;
    color: white;
    padding: 0.5rem;
    border-radius: 6px;
    font-size: 0.875rem;
    pointer-events: none;
    opacity: 0;
    transition: opacity 0.3s;
    z-index: 1000;
  `;
  document.body.appendChild(tooltip);

  data.forEach((segment, index) => {
    const angle = (segment.value / total) * Math.PI * 2;
    const endAngle = currentAngle + angle;

    // Create path
    const path = createArcPath(
      centerX,
      centerY,
      innerRadius,
      outerRadius,
      currentAngle,
      endAngle
    );

    const pathElement = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    pathElement.setAttribute('d', path);
    pathElement.setAttribute('fill', segment.color || colors[index % colors.length]);
    pathElement.style.cursor = 'pointer';
    pathElement.style.transition = 'all 0.3s';

    // Add hover effects
    pathElement.addEventListener('mouseenter', (e) => {
      pathElement.style.transform = 'scale(1.05)';
      pathElement.style.filter = 'brightness(1.1)';

      if (showTooltip) {
        const percentage = ((segment.value / total) * 100).toFixed(1);
        tooltip.innerHTML = `
          <strong>${segment.label}</strong><br>
          Value: ${segment.value}<br>
          Percentage: ${percentage}%
        `;
        tooltip.style.opacity = '1';
      }
    });

    pathElement.addEventListener('mousemove', (e) => {
      tooltip.style.left = e.pageX + 10 + 'px';
      tooltip.style.top = e.pageY - 10 + 'px';
    });

    pathElement.addEventListener('mouseleave', () => {
      pathElement.style.transform = 'scale(1)';
      pathElement.style.filter = 'brightness(1)';
      tooltip.style.opacity = '0';
    });

    if (animate) {
      pathElement.style.opacity = '0';
      setTimeout(() => {
        pathElement.style.transition = 'opacity 0.5s';
        pathElement.style.opacity = '1';
      }, index * 100);
    }

    svg.appendChild(pathElement);
    currentAngle = endAngle;
  });

  // Add center text
  const centerText = document.createElementNS('http://www.w3.org/2000/svg', 'text');
  centerText.setAttribute('x', centerX.toString());
  centerText.setAttribute('y', centerY.toString());
  centerText.setAttribute('text-anchor', 'middle');
  centerText.setAttribute('dominant-baseline', 'middle');
  centerText.style.fontSize = '2rem';
  centerText.style.fontWeight = '700';
  centerText.style.fill = '#1e293b';
  centerText.textContent = total.toString();

  svg.appendChild(centerText);
  container.appendChild(svg);
}

/**
 * Creates an animated bar chart with hover effects
 */
export function createBarChart(
  container: HTMLElement,
  data: DataPoint[],
  options: ChartOptions = {}
): void {
  const {
    width = 600,
    height = 400,
    colors = ['#6366f1'],
    animate = true,
    showTooltip = true
  } = options;

  const padding = 40;
  const barWidth = (width - 2 * padding) / data.length * 0.8;
  const barGap = (width - 2 * padding) / data.length * 0.2;
  const maxValue = Math.max(...data.map(d => d.value));

  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  svg.setAttribute('width', width.toString());
  svg.setAttribute('height', height.toString());

  // Draw grid lines
  for (let i = 0; i <= 5; i++) {
    const y = padding + (height - 2 * padding) * (1 - i / 5);
    const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
    line.setAttribute('x1', padding.toString());
    line.setAttribute('y1', y.toString());
    line.setAttribute('x2', (width - padding).toString());
    line.setAttribute('y2', y.toString());
    line.setAttribute('stroke', '#e5e7eb');
    line.setAttribute('stroke-width', '1');
    svg.appendChild(line);

    // Add value labels
    const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
    text.setAttribute('x', (padding - 10).toString());
    text.setAttribute('y', y.toString());
    text.setAttribute('text-anchor', 'end');
    text.setAttribute('dominant-baseline', 'middle');
    text.style.fontSize = '12px';
    text.style.fill = '#64748b';
    text.textContent = Math.round(maxValue * (i / 5)).toString();
    svg.appendChild(text);
  }

  // Create bars
  data.forEach((item, index) => {
    const x = padding + index * (barWidth + barGap) + barGap / 2;
    const barHeight = ((item.value / maxValue) * (height - 2 * padding));
    const y = height - padding - barHeight;

    const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
    rect.setAttribute('x', x.toString());
    rect.setAttribute('width', barWidth.toString());
    rect.setAttribute('fill', item.color || colors[0]);
    rect.style.cursor = 'pointer';

    if (animate) {
      rect.setAttribute('y', (height - padding).toString());
      rect.setAttribute('height', '0');
      
      setTimeout(() => {
        rect.style.transition = 'all 0.5s ease-out';
        rect.setAttribute('y', y.toString());
        rect.setAttribute('height', barHeight.toString());
      }, index * 100);
    } else {
      rect.setAttribute('y', y.toString());
      rect.setAttribute('height', barHeight.toString());
    }

    // Add hover effects
    rect.addEventListener('mouseenter', () => {
      rect.style.filter = 'brightness(1.1)';
    });

    rect.addEventListener('mouseleave', () => {
      rect.style.filter = 'brightness(1)';
    });

    svg.appendChild(rect);

    // Add labels
    const label = document.createElementNS('http://www.w3.org/2000/svg', 'text');
    label.setAttribute('x', (x + barWidth / 2).toString());
    label.setAttribute('y', (height - padding + 20).toString());
    label.setAttribute('text-anchor', 'middle');
    label.style.fontSize = '12px';
    label.style.fill = '#475569';
    label.textContent = item.label;
    svg.appendChild(label);

    // Add value on top
    const value = document.createElementNS('http://www.w3.org/2000/svg', 'text');
    value.setAttribute('x', (x + barWidth / 2).toString());
    value.setAttribute('text-anchor', 'middle');
    value.style.fontSize = '14px';
    value.style.fontWeight = '600';
    value.style.fill = '#1e293b';
    value.textContent = item.value.toString();

    if (animate) {
      value.setAttribute('y', (height - padding).toString());
      value.style.opacity = '0';
      setTimeout(() => {
        value.style.transition = 'all 0.5s ease-out';
        value.setAttribute('y', (y - 10).toString());
        value.style.opacity = '1';
      }, index * 100 + 300);
    } else {
      value.setAttribute('y', (y - 10).toString());
    }

    svg.appendChild(value);
  });

  container.appendChild(svg);
}

/**
 * Creates an animated line chart
 */
export function createLineChart(
  container: HTMLElement,
  data: TimeSeriesData[],
  options: ChartOptions = {}
): void {
  const {
    width = 800,
    height = 400,
    colors = ['#6366f1', '#10b981', '#ef4444'],
    animate = true,
    showLegend = true
  } = options;

  const padding = 60;
  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  svg.setAttribute('width', width.toString());
  svg.setAttribute('height', height.toString());

  // Group data by series
  const series = Array.from(new Set(data.map(d => d.series || 'default')));
  const seriesData = series.map(s => ({
    name: s,
    points: data.filter(d => (d.series || 'default') === s)
  }));

  // Find min/max values
  const allValues = data.map(d => d.value);
  const minValue = Math.min(...allValues);
  const maxValue = Math.max(...allValues);
  const valueRange = maxValue - minValue || 1;

  // Draw grid
  for (let i = 0; i <= 5; i++) {
    const y = padding + (height - 2 * padding) * (i / 5);
    const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
    line.setAttribute('x1', padding.toString());
    line.setAttribute('y1', y.toString());
    line.setAttribute('x2', (width - padding).toString());
    line.setAttribute('y2', y.toString());
    line.setAttribute('stroke', '#e5e7eb');
    line.setAttribute('stroke-width', '1');
    svg.appendChild(line);
  }

  // Draw axes
  const xAxis = document.createElementNS('http://www.w3.org/2000/svg', 'line');
  xAxis.setAttribute('x1', padding.toString());
  xAxis.setAttribute('y1', (height - padding).toString());
  xAxis.setAttribute('x2', (width - padding).toString());
  xAxis.setAttribute('y2', (height - padding).toString());
  xAxis.setAttribute('stroke', '#94a3b8');
  xAxis.setAttribute('stroke-width', '2');
  svg.appendChild(xAxis);

  const yAxis = document.createElementNS('http://www.w3.org/2000/svg', 'line');
  yAxis.setAttribute('x1', padding.toString());
  yAxis.setAttribute('y1', padding.toString());
  yAxis.setAttribute('x2', padding.toString());
  yAxis.setAttribute('y2', (height - padding).toString());
  yAxis.setAttribute('stroke', '#94a3b8');
  yAxis.setAttribute('stroke-width', '2');
  svg.appendChild(yAxis);

  // Draw lines for each series
  seriesData.forEach((series, seriesIndex) => {
    const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    const color = colors[seriesIndex % colors.length];

    const pathData = series.points.map((point, index) => {
      const x = padding + (width - 2 * padding) * (index / (series.points.length - 1));
      const y = padding + (height - 2 * padding) * (1 - (point.value - minValue) / valueRange);
      return `${index === 0 ? 'M' : 'L'} ${x} ${y}`;
    }).join(' ');

    path.setAttribute('d', pathData);
    path.setAttribute('fill', 'none');
    path.setAttribute('stroke', color);
    path.setAttribute('stroke-width', '3');

    if (animate) {
      const length = path.getTotalLength();
      path.style.strokeDasharray = length.toString();
      path.style.strokeDashoffset = length.toString();
      path.style.transition = 'stroke-dashoffset 1.5s ease-out';
      
      setTimeout(() => {
        path.style.strokeDashoffset = '0';
      }, seriesIndex * 200);
    }

    svg.appendChild(path);

    // Add data points
    series.points.forEach((point, index) => {
      const x = padding + (width - 2 * padding) * (index / (series.points.length - 1));
      const y = padding + (height - 2 * padding) * (1 - (point.value - minValue) / valueRange);

      const circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
      circle.setAttribute('cx', x.toString());
      circle.setAttribute('cy', y.toString());
      circle.setAttribute('r', '4');
      circle.setAttribute('fill', color);
      circle.setAttribute('stroke', 'white');
      circle.setAttribute('stroke-width', '2');

      if (animate) {
        circle.style.opacity = '0';
        setTimeout(() => {
          circle.style.transition = 'opacity 0.3s';
          circle.style.opacity = '1';
        }, 1500 + index * 50);
      }

      svg.appendChild(circle);
    });
  });

  // Add legend
  if (showLegend && series.length > 1) {
    const legendY = height - 20;
    let legendX = width / 2 - (series.length * 100) / 2;

    series.forEach((seriesName, index) => {
      const group = document.createElementNS('http://www.w3.org/2000/svg', 'g');
      
      const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
      line.setAttribute('x1', legendX.toString());
      line.setAttribute('y1', legendY.toString());
      line.setAttribute('x2', (legendX + 20).toString());
      line.setAttribute('y2', legendY.toString());
      line.setAttribute('stroke', colors[index % colors.length]);
      line.setAttribute('stroke-width', '3');
      group.appendChild(line);

      const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
      text.setAttribute('x', (legendX + 25).toString());
      text.setAttribute('y', legendY.toString());
      text.setAttribute('dominant-baseline', 'middle');
      text.style.fontSize = '12px';
      text.style.fill = '#475569';
      text.textContent = seriesName;
      group.appendChild(text);

      svg.appendChild(group);
      legendX += 100;
    });
  }

  container.appendChild(svg);
}

/**
 * Creates a heat map visualization
 */
export function createHeatMap(
  container: HTMLElement,
  data: number[][],
  rowLabels: string[],
  colLabels: string[],
  options: ChartOptions = {}
): void {
  const {
    width = 600,
    height = 400,
    colors = ['#dbeafe', '#93c5fd', '#60a5fa', '#3b82f6', '#2563eb', '#1d4ed8'],
    showTooltip = true
  } = options;

  const cellSize = Math.min(
    (width - 100) / colLabels.length,
    (height - 100) / rowLabels.length
  );

  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  svg.setAttribute('width', width.toString());
  svg.setAttribute('height', height.toString());

  // Find min/max values
  const flatData = data.flat();
  const minValue = Math.min(...flatData);
  const maxValue = Math.max(...flatData);
  const range = maxValue - minValue || 1;

  // Create cells
  data.forEach((row, rowIndex) => {
    row.forEach((value, colIndex) => {
      const x = 100 + colIndex * cellSize;
      const y = 50 + rowIndex * cellSize;
      
      const colorIndex = Math.floor(((value - minValue) / range) * (colors.length - 1));
      const color = colors[colorIndex];

      const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
      rect.setAttribute('x', x.toString());
      rect.setAttribute('y', y.toString());
      rect.setAttribute('width', cellSize.toString());
      rect.setAttribute('height', cellSize.toString());
      rect.setAttribute('fill', color);
      rect.setAttribute('stroke', 'white');
      rect.setAttribute('stroke-width', '2');
      rect.style.cursor = 'pointer';

      // Add hover effect
      rect.addEventListener('mouseenter', (e) => {
        rect.style.filter = 'brightness(0.9)';
        if (showTooltip) {
          showHeatmapTooltip(e, rowLabels[rowIndex], colLabels[colIndex], value);
        }
      });

      rect.addEventListener('mouseleave', () => {
        rect.style.filter = 'brightness(1)';
        hideHeatmapTooltip();
      });

      svg.appendChild(rect);
    });
  });

  // Add row labels
  rowLabels.forEach((label, index) => {
    const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
    text.setAttribute('x', '90');
    text.setAttribute('y', (50 + index * cellSize + cellSize / 2).toString());
    text.setAttribute('text-anchor', 'end');
    text.setAttribute('dominant-baseline', 'middle');
    text.style.fontSize = '12px';
    text.style.fill = '#475569';
    text.textContent = label;
    svg.appendChild(text);
  });

  // Add column labels
  colLabels.forEach((label, index) => {
    const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
    text.setAttribute('x', (100 + index * cellSize + cellSize / 2).toString());
    text.setAttribute('y', '40');
    text.setAttribute('text-anchor', 'middle');
    text.style.fontSize = '12px';
    text.style.fill = '#475569';
    text.textContent = label;
    svg.appendChild(text);
  });

  container.appendChild(svg);
}

/**
 * Creates an animated gauge chart
 */
export function createGaugeChart(
  container: HTMLElement,
  value: number,
  maxValue: number = 100,
  options: ChartOptions = {}
): void {
  const {
    width = 300,
    height = 200,
    colors = ['#10b981', '#f59e0b', '#ef4444'],
    animate = true
  } = options;

  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  svg.setAttribute('width', width.toString());
  svg.setAttribute('height', height.toString());
  svg.setAttribute('viewBox', `0 0 ${width} ${height}`);

  const centerX = width / 2;
  const centerY = height - 20;
  const radius = Math.min(width / 2, height) - 40;

  // Create gradient
  const defs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');
  const gradient = document.createElementNS('http://www.w3.org/2000/svg', 'linearGradient');
  gradient.setAttribute('id', 'gaugeGradient');
  gradient.setAttribute('x1', '0%');
  gradient.setAttribute('y1', '0%');
  gradient.setAttribute('x2', '100%');
  gradient.setAttribute('y2', '0%');

  colors.forEach((color, index) => {
    const stop = document.createElementNS('http://www.w3.org/2000/svg', 'stop');
    stop.setAttribute('offset', `${(index / (colors.length - 1)) * 100}%`);
    stop.setAttribute('style', `stop-color:${color};stop-opacity:1`);
    gradient.appendChild(stop);
  });

  defs.appendChild(gradient);
  svg.appendChild(defs);

  // Draw background arc
  const bgArc = createArcPath(
    centerX,
    centerY,
    radius - 10,
    radius + 10,
    Math.PI,
    0
  );

  const bgPath = document.createElementNS('http://www.w3.org/2000/svg', 'path');
  bgPath.setAttribute('d', bgArc);
  bgPath.setAttribute('fill', '#e5e7eb');
  svg.appendChild(bgPath);

  // Draw value arc
  const valueAngle = Math.PI + (value / maxValue) * Math.PI;
  const valueArc = createArcPath(
    centerX,
    centerY,
    radius - 10,
    radius + 10,
    Math.PI,
    valueAngle
  );

  const valuePath = document.createElementNS('http://www.w3.org/2000/svg', 'path');
  valuePath.setAttribute('d', valueArc);
  valuePath.setAttribute('fill', 'url(#gaugeGradient)');

  if (animate) {
    valuePath.style.opacity = '0';
    setTimeout(() => {
      valuePath.style.transition = 'opacity 0.5s';
      valuePath.style.opacity = '1';
    }, 100);
  }

  svg.appendChild(valuePath);

  // Add needle
  const needleAngle = Math.PI + (value / maxValue) * Math.PI;
  const needleX = centerX + Math.cos(needleAngle) * (radius - 20);
  const needleY = centerY + Math.sin(needleAngle) * (radius - 20);

  const needle = document.createElementNS('http://www.w3.org/2000/svg', 'line');
  needle.setAttribute('x1', centerX.toString());
  needle.setAttribute('y1', centerY.toString());
  needle.setAttribute('x2', needleX.toString());
  needle.setAttribute('y2', needleY.toString());
  needle.setAttribute('stroke', '#1e293b');
  needle.setAttribute('stroke-width', '3');
  needle.setAttribute('stroke-linecap', 'round');

  if (animate) {
    needle.style.transform = `rotate(0deg)`;
    needle.style.transformOrigin = `${centerX}px ${centerY}px`;
    needle.style.transition = 'transform 1s ease-out';
    
    setTimeout(() => {
      const degrees = (value / maxValue) * 180;
      needle.style.transform = `rotate(${degrees}deg)`;
    }, 200);
  }

  svg.appendChild(needle);

  // Add center circle
  const centerCircle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
  centerCircle.setAttribute('cx', centerX.toString());
  centerCircle.setAttribute('cy', centerY.toString());
  centerCircle.setAttribute('r', '8');
  centerCircle.setAttribute('fill', '#1e293b');
  svg.appendChild(centerCircle);

  // Add value text
  const valueText = document.createElementNS('http://www.w3.org/2000/svg', 'text');
  valueText.setAttribute('x', centerX.toString());
  valueText.setAttribute('y', (centerY - 30).toString());
  valueText.setAttribute('text-anchor', 'middle');
  valueText.style.fontSize = '2rem';
  valueText.style.fontWeight = '700';
  valueText.style.fill = '#1e293b';
  valueText.textContent = value.toString();
  svg.appendChild(valueText);

  // Add labels
  const minLabel = document.createElementNS('http://www.w3.org/2000/svg', 'text');
  minLabel.setAttribute('x', (centerX - radius).toString());
  minLabel.setAttribute('y', (centerY + 20).toString());
  minLabel.setAttribute('text-anchor', 'middle');
  minLabel.style.fontSize = '12px';
  minLabel.style.fill = '#64748b';
  minLabel.textContent = '0';
  svg.appendChild(minLabel);

  const maxLabel = document.createElementNS('http://www.w3.org/2000/svg', 'text');
  maxLabel.setAttribute('x', (centerX + radius).toString());
  maxLabel.setAttribute('y', (centerY + 20).toString());
  maxLabel.setAttribute('text-anchor', 'middle');
  maxLabel.style.fontSize = '12px';
  maxLabel.style.fill = '#64748b';
  maxLabel.textContent = maxValue.toString();
  svg.appendChild(maxLabel);

  container.appendChild(svg);
}

// Helper functions
function createArcPath(
  cx: number,
  cy: number,
  innerRadius: number,
  outerRadius: number,
  startAngle: number,
  endAngle: number
): string {
  const startInnerX = cx + innerRadius * Math.cos(startAngle);
  const startInnerY = cy + innerRadius * Math.sin(startAngle);
  const endInnerX = cx + innerRadius * Math.cos(endAngle);
  const endInnerY = cy + innerRadius * Math.sin(endAngle);
  
  const startOuterX = cx + outerRadius * Math.cos(startAngle);
  const startOuterY = cy + outerRadius * Math.sin(startAngle);
  const endOuterX = cx + outerRadius * Math.cos(endAngle);
  const endOuterY = cy + outerRadius * Math.sin(endAngle);

  const largeArcFlag = endAngle - startAngle > Math.PI ? 1 : 0;

  return `
    M ${startInnerX} ${startInnerY}
    L ${startOuterX} ${startOuterY}
    A ${outerRadius} ${outerRadius} 0 ${largeArcFlag} 1 ${endOuterX} ${endOuterY}
    L ${endInnerX} ${endInnerY}
    A ${innerRadius} ${innerRadius} 0 ${largeArcFlag} 0 ${startInnerX} ${startInnerY}
    Z
  `;
}

let tooltipElement: HTMLDivElement | null = null;

function showHeatmapTooltip(event: MouseEvent, row: string, col: string, value: number): void {
  if (!tooltipElement) {
    tooltipElement = document.createElement('div');
    tooltipElement.style.cssText = `
      position: absolute;
      background: #1e293b;
      color: white;
      padding: 0.5rem;
      border-radius: 6px;
      font-size: 0.875rem;
      pointer-events: none;
      z-index: 1000;
    `;
    document.body.appendChild(tooltipElement);
  }

  tooltipElement.innerHTML = `
    <strong>${row} - ${col}</strong><br>
    Value: ${value}
  `;
  tooltipElement.style.left = event.pageX + 10 + 'px';
  tooltipElement.style.top = event.pageY - 10 + 'px';
  tooltipElement.style.opacity = '1';
}

function hideHeatmapTooltip(): void {
  if (tooltipElement) {
    tooltipElement.style.opacity = '0';
  }
}

/**
 * Export function to download chart as image
 */
export function exportChartAsImage(container: HTMLElement, filename: string = 'chart'): void {
  const svg = container.querySelector('svg');
  if (!svg) return;

  const svgData = new XMLSerializer().serializeToString(svg);
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d');
  const img = new Image();

  canvas.width = svg.clientWidth;
  canvas.height = svg.clientHeight;

  img.onload = () => {
    ctx?.drawImage(img, 0, 0);
    canvas.toBlob((blob) => {
      if (blob) {
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${filename}.png`;
        a.click();
        URL.revokeObjectURL(url);
      }
    });
  };

  img.src = 'data:image/svg+xml;base64,' + btoa(svgData);
}

/**
 * Export chart data as CSV
 */
export function exportChartData(data: any[], filename: string = 'data'): void {
  let csv = '';
  
  if (data.length > 0) {
    // Get headers
    const headers = Object.keys(data[0]);
    csv += headers.join(',') + '\n';
    
    // Add data rows
    data.forEach(row => {
      const values = headers.map(header => {
        const value = row[header];
        return typeof value === 'string' && value.includes(',') 
          ? `"${value}"` 
          : value;
      });
      csv += values.join(',') + '\n';
    });
  }

  const blob = new Blob([csv], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `${filename}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}