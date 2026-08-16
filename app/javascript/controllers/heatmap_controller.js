import { Controller } from "@hotwired/stimulus"

// Hover detail for the watering heatmap. One shared tooltip node positioned
// over the hovered cell, rather than 365 hidden nodes in the DOM — and it
// lives inside the card (which is position:relative) so the horizontal
// scroller can't clip it.
export default class extends Controller {
  static targets = ["tooltip"]

  show(event) {
    const cell = event.currentTarget
    const runs = JSON.parse(cell.dataset.runs || "[]")
    const total = Number(cell.dataset.total || 0)

    let body
    if (total === 0 && runs.length === 0) {
      body = `<div class="text-gray-400">No watering</div>`
    } else {
      const lines = runs
        .map(
          ([name, minutes]) =>
            `<div class="flex justify-between gap-4"><span>${escapeHtml(name)}</span><span class="text-gray-400">${minutes} min</span></div>`
        )
        .join("")
      body = `<div class="font-semibold">${total} min total</div>${lines}`
    }

    this.tooltipTarget.innerHTML = `<div class="text-gray-300">${escapeHtml(cell.dataset.date)}</div>${body}`
    this.tooltipTarget.classList.remove("hidden")
    this.#position(cell)
  }

  hide() {
    this.tooltipTarget.classList.add("hidden")
  }

  // Centre above the cell, then pull back inside the card if that would
  // overflow either edge.
  #position(cell) {
    const card = this.element.getBoundingClientRect()
    const box = cell.getBoundingClientRect()
    const tip = this.tooltipTarget

    const left = box.left - card.left + box.width / 2 - tip.offsetWidth / 2
    const max = this.element.clientWidth - tip.offsetWidth - 8

    tip.style.left = `${Math.max(8, Math.min(left, max))}px`
    tip.style.top = `${box.top - card.top - tip.offsetHeight - 8}px`
  }
}

function escapeHtml(value) {
  const node = document.createElement("div")
  node.textContent = value ?? ""
  return node.innerHTML
}
