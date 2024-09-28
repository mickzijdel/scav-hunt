import { Controller } from "@hotwired/stimulus"
import bb, { line } from "billboard.js"

export default class extends Controller {
  static values = {
    createdAtData: Array,
    updatedAtData: Array
  }

  connect() {
    this.renderCreatedAtChart()
    this.renderUpdatedAtChart()
  }

  renderCreatedAtChart() {
    this.renderChart('createdAtChart', this.createdAtDataValue, 'Score Over Time (Created At)')
  }

  renderUpdatedAtChart() {
    this.renderChart('updatedAtChart', this.updatedAtDataValue, 'Score Over Time (Updated At)')
  }

  renderChart(elementId, data, title) {
    console.log("StatisticsController:", title, data);

    bb.generate({
      bindto: `#${elementId}`,
      data: {
        columns: data,
        x: "timestamps",
        type: line()
      },
      axis: {
        x: {
          type: 'timeseries',
          tick: {
            format: '%H:%M'
          },
          label: "Time"
        },
        y: {
          label: "Points"
        }
      },
      title: {
        text: title
      },
      zoom: {
        enabled: true
      },
      point: {
        show: false
      }
    })
  }
}