/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/views/**/*.{html,html.erb}",
    // "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js", // include these if you're using these file types in your project
    // You can also add other paths according to your project structure
    './node_modules/flowbite/**/*.js'
  ],
  theme: {
    extend: {},
  },
  plugins: [
    require('flowbite/plugin')
]
}

