import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "searchInput", "sortSelect"]


  search() {
    const query = this.searchInputTarget.value.toLowerCase()

    this.rowTargets.forEach(row => {
      const text = row.textContent.toLowerCase()
      row.style.display = text.includes(query) ? "" : "none"
    })
  }

  sort() {
    const column = this.sortSelectTarget.value
    const rows = Array.from(this.rowTargets)

    console.log("Sorting by", column)

    rows.sort((a, b) => {
      const aElement = a.querySelector(`[data-column="${column}"], [data-scoring-target="${column}"]`)
      const bElement = b.querySelector(`[data-column="${column}"], [data-scoring-target="${column}"]`)

      let aValue, bValue

      if (aElement.tagName === 'INPUT') {
        aValue = aElement.value
        bValue = bElement.value
      } else {
        aValue = aElement.textContent
        bValue = bElement.textContent
      }

      // Check if the values are numbers
      if (!isNaN(aValue) && !isNaN(bValue)) {
        return Number(aValue) - Number(bValue)
      }

      // If not numbers, compare as strings
      return aValue.localeCompare(bValue)
    })
  
    const tbody = this.element.querySelector('tbody')
    rows.forEach(row => tbody.appendChild(row))
  }
}