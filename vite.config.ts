import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import FullReload from 'vite-plugin-full-reload'
import StimulusHMR from 'vite-plugin-stimulus-hmr'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    FullReload(['config/routes.rb', 'app/views/**/*', 'app/javascript/controllers/**/*'], { delay: 200 }),
    StimulusHMR(),
  ],
  server: {
    cors: {
      origin: ['https://app.echosight.io', 'https://echosight-production-web-service.onrender.com'],
      methods: ['GET', 'POST', 'OPTIONS', 'HEAD'],
      headers: ['Authorization', 'Content-Type'],
      credentials: true,
      maxAge: 600,
    },
    host: 'localhost',
    port: 3000,
    hmr: {
      host: 'localhost',
    },
  },
})
