import { Controller } from "@hotwired/stimulus"

// Client-side search and sort over a table of challenges.
export default class extends Controller {
  static targets = ["row", "searchInput", "sortSelect"]

  // Called after a Turbo Stream swaps rows in. It has to re-apply BOTH filters:
  // re-sorting alone left rows that the active search had hidden showing again.
  //
  // The stream event fires just *before* Turbo applies the change, so hand back to
  // the event loop first and read the table once it is actually there. (This used to
  // be an addEventListener in connect() with a .bind(this) that no disconnect()
  // could ever have removed.)
  refresh() {
    setTimeout(() => {
      this.sort()
      this.search()
    })
  }

  search() {
    const query = this.searchInputTarget.value.toLowerCase()

    this.rowTargets.forEach(row => {
      row.style.display = row.textContent.toLowerCase().includes(query) ? "" : "none"
    })
  }

  sort() {
    const column = this.sortSelectTarget.value
    if (!column) return

    const rows = [...this.rowTargets]
    if (rows.length === 0) return

    const tbody = this.element.querySelector("tbody")

    rows
      .sort((a, b) => compare(cellValue(a, column), cellValue(b, column)))
      .forEach(row => tbody.appendChild(row))
  }
}

function cellValue(row, column) {
  return row.querySelector(`[data-column="${column}"]`)?.textContent.trim() ?? ""
}

function compare(a, b) {
  const numeric = a !== "" && b !== "" && !isNaN(a) && !isNaN(b)

  return numeric ? Number(a) - Number(b) : a.localeCompare(b)
}
