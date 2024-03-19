/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/views/**/*.{html,html.erb}",
    "./app/components/**/*.{html,html.erb}",
    "./app/javascript/**/*.js",
    './node_modules/flowbite/**/*.js'
  ],
  safelist: [
    // Add any classes here you wish to always include in the final build
  ],
  darkMode: "class", // or 'media' or false
  theme: {
    extend: {
      colors: {
        primary: {
          "50": "#eff6ff",
          "100": "#dbeafe",
          "200": "#bfdbfe",
          "300": "#93c5fd",
          "400": "#60a5fa",
          "500": "#3b82f6",
          "600": "#2563eb",
          "700": "#1d4ed8",
          "800": "#1e40af",
          "900": "#1e3a8a"
        },
      },
      fontFamily: {
        'sans': ['Inter', 'ui-sans-serif', 'system-ui', '-apple-system', 'system-ui', 'Segoe UI', 'Roboto', 'Helvetica Neue', 'Arial', 'Noto Sans', 'sans-serif', 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji'],
        'body': ['Inter', 'ui-sans-serif', 'system-ui', '-apple-system', 'system-ui', 'Segoe UI', 'Roboto', 'Helvetica Neue', 'Arial', 'Noto Sans', 'sans-serif', 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji'],
        'mono': ['ui-monospace', 'SFMono-Regular', 'Menlo', 'Monaco', 'Consolas', 'Liberation Mono', 'Courier New', 'monospace']
      },
      // Add any other custom extensions from the Flowbite config as necessary
    },
  },
  plugins: [
    require('flowbite/plugin')({
      charts: true,
  }),
  ],
}
