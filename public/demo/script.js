// script.js

document.addEventListener('DOMContentLoaded', () => {
    fetch('data.json')
      .then(response => response.json())
      .then(data => initCharts(data))
      .catch(error => console.error('Error loading data:', error));
  });
  
  function initCharts(data) {
    // Followers Over Time Chart
    const ctxFollowers = document.getElementById('followersChart').getContext('2d');
    new Chart(ctxFollowers, {
      type: 'line',
      data: {
        labels: data.followersOverTime.labels,
        datasets: [{
          label: 'Followers Over Time',
          data: data.followersOverTime.data,
          fill: false,
          borderColor: 'rgb(75, 192, 192)',
          tension: 0.1
        }]
      },
      options: {
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    });

    // Engagement Rate Chart
    const ctxEngagement = document.getElementById('engagementChart').getContext('2d');
    new Chart(ctxEngagement, {
      type: 'bar', // assuming you want a bar chart for engagement rate
      data: {
        labels: data.engagementRate.labels,
        datasets: [{
          label: 'Engagement Rate',
          data: data.engagementRate.data,
          backgroundColor: [
            'rgba(255, 99, 132, 0.2)',
            'rgba(54, 162, 235, 0.2)',
            'rgba(255, 206, 86, 0.2)'
          ],
          borderColor: [
            'rgba(255, 99, 132, 1)',
            'rgba(54, 162, 235, 1)',
            'rgba(255, 206, 86, 1)'
          ],
          borderWidth: 1
        }]
      },
      options: {
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    });
  
    // Impressions Over Time Chart
    const ctxImpressions = document.getElementById('impressionsChart').getContext('2d');
    new Chart(ctxImpressions, {
      type: 'line',
      data: {
        labels: data.impressionsOverTime.labels,
        datasets: [{
          label: 'Impressions Over Time',
          data: data.impressionsOverTime.data,
          fill: true,
          backgroundColor: 'rgba(54, 162, 235, 0.2)',
          borderColor: 'rgba(54, 162, 235, 1)',
          borderWidth: 1
        }]
      },
      options: {
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    });

    // Profile Conversion Rate Chart
    const ctxProfileConversion = document.getElementById('profileConversionChart').getContext('2d');
    new Chart(ctxProfileConversion, {
      type: 'bar',
      data: {
        labels: data.profileConversionRate.labels,
        datasets: [{
          label: 'Profile Conversion Rate',
          data: data.profileConversionRate.data,
          backgroundColor: 'rgba(255, 159, 64, 0.2)',
          borderColor: 'rgba(255, 159, 64, 1)',
          borderWidth: 1
        }]
      },
      options: {
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    });
    
    // ... Additional chart initializations here
  }
  
  // ... Additional functions or event listeners here
  