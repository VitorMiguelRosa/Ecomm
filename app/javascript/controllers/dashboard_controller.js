import { Controller } from "@hotwired/stimulus"
import {Chart, registerables} from 'chart.js'

// --- ADD THIS LINE ---
Chart.register(...registerables);
// ---------------------

// Connects to data-controller="dashboard"
export default class extends Controller {
  static values = {
    revenue: Array
  }

  initialize() {
    const data = this.revenueValue.map((item) => item[1]/100.0)
    const labels = this.revenueValue.map((item) => item[0])

    const ctx = document.getElementById("revenueChart")

    new Chart(ctx, {
      type: "line",
      data: {
        labels: labels,
        datasets: [{
          label: "Revenue",
          data: data,
          borderwidth: 3,
          fill: true
        }]
      },
      options: {
        plugins: {
          legend:{
            display:false
          }
        },
        scales: {
          x: {
            // Chart.js will now recognize 'category' as the default for labels on an x-axis
            // You don't explicitly need to set type: 'category' here unless you have a specific reason.
            grid: {
              display: false
            }
          },
          y: {
            grid: {
              border: {
                dash: [5, 5]
              },
              color: "#d4f3ef"
            },
            beginAtZero: true
          }
        }
      }
    })
  }
}