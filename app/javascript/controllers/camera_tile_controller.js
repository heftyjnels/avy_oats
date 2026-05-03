import { Controller } from "@hotwired/stimulus"

// When a camera snapshot fails to load (UDOT and some resort hotlinks return
// 4xx), swap the tile to a labeled fallback that links out to the official
// source page so the page still works.
export default class extends Controller {
  static targets = ["image", "fallback"]

  connect() {
    if (!this.hasImageTarget) return

    this.errorHandler = () => this.showFallback()
    this.imageTarget.addEventListener("error", this.errorHandler)

    if (this.imageTarget.complete && this.imageTarget.naturalWidth === 0) {
      this.showFallback()
    }
  }

  disconnect() {
    if (this.imageTarget && this.errorHandler) {
      this.imageTarget.removeEventListener("error", this.errorHandler)
    }
  }

  showFallback() {
    if (!this.hasFallbackTarget) return

    this.imageTarget.classList.add("hidden")
    this.fallbackTarget.classList.remove("hidden")
    this.fallbackTarget.classList.add("flex")
  }
}
