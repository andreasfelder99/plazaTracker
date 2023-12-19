document.addEventListener("DOMContentLoaded", () => {
    // Set up the initial chart configuration
    const ctx = document.getElementById('liveChart').getContext('2d');
    const liveChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: [], // x-axis labels (dates)
        datasets: [{
          label: 'Current Guests',
          data: [], // y-axis data (number of guests)
          backgroundColor: 'rgba(75, 192, 192, 0.2)',
          borderColor: 'rgba(75, 192, 192, 1)',
          borderWidth: 1,
          fill: false
        }]
      },
      options: {
        scales: {
          x: {
            type: 'time',
            time: {
              unit: 'minute',
              parser: 'YYYY-MM-DD HH:mm:ss',
              unitStepSize: 1, // Set the stepSize to 1 unit (1 second)
              displayFormats: {
                second: 'HH:mm:ss'
              },
              adapter: 'moment'
            },
            title: {
              display: true,
              text: 'Time'
            }
          },
          y: {
            title: {
              display: true,
              text: 'Current Guests'
            }
          }
        }
      }
    });

    // Function to update the chart with live API data
    async function updateLiveChart() {
      try {
        // Fetch data from the live API
        const response = await fetch('/admin/getLiveData');
        const jsonData = await response.json();

        // Extract data from JSON
        const trackingData = jsonData.trackingData.data;

        // Check if there is at least one entry in the data array
        const dataEntries = Object.entries(trackingData);

        // Filter out "INIT" entry if there are more entries
        const filteredDataEntries = dataEntries.filter(([key, value]) => key !== "INIT" || dataEntries.length === 1);

        // Sort data entries by timestamp
        filteredDataEntries.sort((a, b) => new Date(a[0]) - new Date(b[0]));

        if (filteredDataEntries.length >= 2) {
          // Include only every 6th entry
          const displayEntries = filteredDataEntries.filter((entry, index) => index % 6 === 0);

          // Update chart data
          liveChart.data.labels = displayEntries.map(([timestamp]) => timestamp);
          liveChart.data.datasets[0].data = displayEntries.map(([, value]) => value);

          // Update the chart
          liveChart.update();

          // Set the x-axis starting point to the timestamp of the first non-"INIT" entry
          liveChart.options.scales.x.min = new Date(displayEntries[0][0]);

          // Set the x-axis ending point to the timestamp of the currently last element
          liveChart.options.scales.x.max = new Date(displayEntries[displayEntries.length - 1][0]);

          // Set the x-axis unit step size to 5 minutes
          liveChart.options.scales.x.time.unitStepSize = 1;
        } else {
          // If there are not enough valid data entries, display an empty chart
          liveChart.data.labels = [];
          liveChart.data.datasets[0].data = [];
          liveChart.update();
        }
      } catch (error) {
        console.error('Error fetching or updating data:', error);
      }
    }




    // Call the updateLiveChart function every 10 seconds
    setInterval(updateLiveChart, 10000);

    // Initial call to populate the chart
    updateLiveChart();
});

