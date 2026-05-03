import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

// Renders a small inline chart for one weather metric.
// `dataValue` is a JSON array of {t: ISO timestamp, v: number}.
// `typeValue` controls visual treatment: line for temperature/wind/cloud,
// scatter for wind direction (which is bounded 0..360 degrees).
export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    type: String,
    unit: String,
    data: Array
  }

  connect() {
    if (!this.hasCanvasTarget || this.dataValue.length === 0) return
    this.chart = new Chart(this.canvasTarget.getContext("2d"), this.config())
  }

  disconnect() {
    if (this.chart) this.chart.destroy()
  }

  config() {
    const points = this.dataValue.map(({ t, v }) => ({ x: new Date(t).valueOf(), y: v }))
    const isDirection = this.typeValue === "wind_direction"
    const color = this.colorForType()

    return {
      type: isDirection ? "scatter" : "line",
      data: {
        datasets: [{
          label: this.typeValue,
          data: points,
          borderColor: color,
          backgroundColor: this.fillColorForType(),
          borderWidth: 2,
          fill: !isDirection,
          tension: 0.3,
          pointRadius: isDirection ? 2 : 0,
          pointHoverRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false }, tooltip: { enabled: true } },
        scales: {
          x: {
            type: "linear",
            display: false
          },
          y: {
            display: false,
            beginAtZero: this.typeValue === "wind_speed" || this.typeValue === "cloud_cover",
            ...(isDirection ? { min: 0, max: 360 } : {})
          }
        }
      }
    }
  }

  colorForType() {
    switch (this.typeValue) {
      case "temperature": return "#b04a26"
      case "wind_speed": return "#5a4a2f"
      case "wind_direction": return "#3f5a44"
      case "cloud_cover": return "#6b6b6b"
      default: return "#5a4a2f"
    }
  }

  fillColorForType() {
    switch (this.typeValue) {
      case "temperature": return "rgba(176,74,38,0.15)"
      case "wind_speed": return "rgba(90,74,47,0.15)"
      case "cloud_cover": return "rgba(107,107,107,0.18)"
      default: return "rgba(90,74,47,0.15)"
    }
  }
}
