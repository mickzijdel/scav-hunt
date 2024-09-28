import { Controller } from "@hotwired/stimulus"
import bb, { bar } from "billboard.js"

export default class extends Controller {
  static values = {
    challengeData: Array
  }

  connect() {
    this.renderChart()
  }

  renderChart() {
    bb.generate({
      bindto: this.element,
      data: {
        columns: this.challengeDataValue,
        type: bar()
      },
      axis: {
        x: {
          label: "Group ID"
        },
        y: {
          label: "Number of Challenges"
        }
      },
      title: {
        text: "Challenges per Group"
      }
    })
  }
}