import { Controller } from "@hotwired/stimulus"

// Renders the 8-aspect avalanche danger rose as inline SVG.
// `roseValue` is a JSON array of {aspect, value, label} entries starting at
// North and proceeding clockwise (N, NE, E, SE, S, SW, W, NW).
//
// Color stops mirror the standard North American avalanche danger scale:
// 0 No Rating, 1-2 Low (green), 3-4 Moderate (yellow), 5-6 Considerable
// (orange), 7-8 High (red), 9-10 Extreme (black).
export default class extends Controller {
  static targets = ["svg"]
  static values = { rose: Array }

  connect() {
    if (!this.hasSvgTarget) return
    this.render()
  }

  roseValueChanged() {
    if (this.hasSvgTarget) this.render()
  }

  render() {
    const svg = this.svgTarget
    const size = 120
    const center = size / 2
    const outer = 56
    const inner = 14
    svg.innerHTML = ""

    const wedges = this.roseValue.length === 8 ? this.roseValue : []
    const slice = (Math.PI * 2) / 8

    wedges.forEach((wedge, i) => {
      const startAngle = -Math.PI / 2 + (i - 0.5) * slice
      const endAngle = startAngle + slice
      const path = this.donutPath(center, center, inner, outer, startAngle, endAngle)
      const el = document.createElementNS("http://www.w3.org/2000/svg", "path")
      el.setAttribute("d", path)
      el.setAttribute("fill", this.colorFor(wedge.value))
      el.setAttribute("stroke", "rgba(255,255,255,0.6)")
      el.setAttribute("stroke-width", "1")
      const title = document.createElementNS("http://www.w3.org/2000/svg", "title")
      title.textContent = `${wedge.aspect}: ${wedge.label}`
      el.appendChild(title)
      svg.appendChild(el)
    })

    const labels = ["N", "E", "S", "W"]
    labels.forEach((label, i) => {
      const angle = -Math.PI / 2 + i * (Math.PI / 2)
      const x = center + Math.cos(angle) * (outer + 6)
      const y = center + Math.sin(angle) * (outer + 6)
      const text = document.createElementNS("http://www.w3.org/2000/svg", "text")
      text.setAttribute("x", x)
      text.setAttribute("y", y + 3)
      text.setAttribute("text-anchor", "middle")
      text.setAttribute("font-size", "10")
      text.setAttribute("fill", "currentColor")
      text.textContent = label
      svg.appendChild(text)
    })
  }

  donutPath(cx, cy, rInner, rOuter, startAngle, endAngle) {
    const x1 = cx + rOuter * Math.cos(startAngle)
    const y1 = cy + rOuter * Math.sin(startAngle)
    const x2 = cx + rOuter * Math.cos(endAngle)
    const y2 = cy + rOuter * Math.sin(endAngle)
    const x3 = cx + rInner * Math.cos(endAngle)
    const y3 = cy + rInner * Math.sin(endAngle)
    const x4 = cx + rInner * Math.cos(startAngle)
    const y4 = cy + rInner * Math.sin(startAngle)
    return [
      `M ${x1} ${y1}`,
      `A ${rOuter} ${rOuter} 0 0 1 ${x2} ${y2}`,
      `L ${x3} ${y3}`,
      `A ${rInner} ${rInner} 0 0 0 ${x4} ${y4}`,
      "Z"
    ].join(" ")
  }

  colorFor(value) {
    if (value <= 0) return "#d6cdbf"
    if (value <= 2) return "#3f9d4d"
    if (value <= 4) return "#f0c419"
    if (value <= 6) return "#e87b1f"
    if (value <= 8) return "#c0392b"
    return "#1f1f1f"
  }
}
